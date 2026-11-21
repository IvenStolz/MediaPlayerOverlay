#pragma once

#include <QObject>
#include <QTimer>
#include <QCursor>
#include <QGuiApplication>
#include <QScreen>
#include <QRect>

class EdgeTrigger : public QObject {
    Q_OBJECT

    // Schnittstelle für SettingsWindow.qml
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QString edge READ edge WRITE setEdge NOTIFY edgeChanged) // "right" oder "left"
    Q_PROPERTY(int holdDurationMs READ holdDurationMs WRITE setHoldDurationMs NOTIFY holdDurationMsChanged)
    Q_PROPERTY(int edgeThresholdPx READ edgeThresholdPx WRITE setEdgeThresholdPx NOTIFY edgeThresholdPxChanged)

public:
    explicit EdgeTrigger(QObject *parent = nullptr) : QObject(parent) {
        m_pollTimer.setInterval(80);
        connect(&m_pollTimer, &QTimer::timeout, this, &EdgeTrigger::checkCursor);
        m_pollTimer.start();

        m_holdTimer.setSingleShot(true);
        m_holdTimer.setInterval(m_holdDurationMs);
        connect(&m_holdTimer, &QTimer::timeout, this, [this]() {
            if (!m_enabled) return;
            const QPoint pos = QCursor::pos();
            QScreen *screen = QGuiApplication::screenAt(pos);
            if (!screen) return;

            // availableGeometry() berücksichtigt die Windows-Taskleiste
            const QRect avail = screen->availableGeometry();
            emit triggered(avail.x(), avail.y(), avail.width(), avail.height(), pos.y());
        });
    }

    bool enabled() const { return m_enabled; }
    void setEnabled(bool value) {
        if (m_enabled == value) return;
        m_enabled = value;
        if (!m_enabled) {
            m_holdTimer.stop();
            m_edgeHovered = false;
        }
        emit enabledChanged();
    }

    QString edge() const { return m_edge; }
    void setEdge(const QString &value) {
        const QString normalized = (value.toLower() == "left") ? "left" : "right";
        if (m_edge == normalized) return;
        m_edge = normalized;
        m_holdTimer.stop();
        m_edgeHovered = false;
        emit edgeChanged();
    }

    int holdDurationMs() const { return m_holdDurationMs; }
    void setHoldDurationMs(int ms) {
        const int clamped = qMax(100, ms);
        if (m_holdDurationMs == clamped) return;
        m_holdDurationMs = clamped;
        m_holdTimer.setInterval(m_holdDurationMs);
        emit holdDurationMsChanged();
    }

    int edgeThresholdPx() const { return m_edgeThresholdPx; }
    void setEdgeThresholdPx(int px) {
        const int clamped = qMax(1, px);
        if (m_edgeThresholdPx == clamped) return;
        m_edgeThresholdPx = clamped;
        emit edgeThresholdPxChanged();
    }

signals:
    void enabledChanged();
    void edgeChanged();
    void holdDurationMsChanged();
    void edgeThresholdPxChanged();

    // Übergibt die exakten Koordinaten des aktiven Monitors + Maus-Y
    void triggered(int screenX, int screenY, int screenWidth, int screenHeight, int cursorY);

private:
    void checkCursor() {
        if (!m_enabled) return;

        const QPoint pos = QCursor::pos();
        QScreen *screen = QGuiApplication::screenAt(pos);
        if (!screen) return;

        const QRect geom = screen->geometry();
        bool atOuterEdge = false;

        if (m_edge == "right") {
            const bool nearRight = pos.x() >= (geom.right() - m_edgeThresholdPx);
            // Multi-Monitor-Check: Liegt rechts daneben ein weiterer Monitor?
            const bool hasNeighborRight = QGuiApplication::screenAt(QPoint(geom.right() + 5, pos.y())) != nullptr;
            atOuterEdge = nearRight && !hasNeighborRight;
        } else {
            const bool nearLeft = pos.x() <= (geom.left() + m_edgeThresholdPx);
            // Multi-Monitor-Check: Liegt links daneben ein weiterer Monitor?
            const bool hasNeighborLeft = QGuiApplication::screenAt(QPoint(geom.left() - 5, pos.y())) != nullptr;
            atOuterEdge = nearLeft && !hasNeighborLeft;
        }

        if (atOuterEdge && !m_edgeHovered) {
            m_edgeHovered = true;
            m_holdTimer.start();
        } else if (!atOuterEdge && m_edgeHovered) {
            m_edgeHovered = false;
            m_holdTimer.stop();
        }
    }

    QTimer m_pollTimer;
    QTimer m_holdTimer;
    bool m_enabled = true;
    bool m_edgeHovered = false;
    QString m_edge = "right";
    int m_holdDurationMs = 1000;
    int m_edgeThresholdPx = 2;
};