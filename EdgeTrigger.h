#pragma once

#include <QObject>
#include <QTimer>
#include <QCursor>
#include <QGuiApplication>
#include <QScreen>
#include <QRect>
#include <QtMath>

class EdgeTrigger : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QString edge READ edge WRITE setEdge NOTIFY edgeChanged)
    Q_PROPERTY(int holdDurationMs READ holdDurationMs WRITE setHoldDurationMs NOTIFY holdDurationMsChanged)
    Q_PROPERTY(int edgeThresholdPx READ edgeThresholdPx WRITE setEdgeThresholdPx NOTIFY edgeThresholdPxChanged)

    /** Settings interface for proximity glow tracking. */
    Q_PROPERTY(bool proximityEnabled READ proximityEnabled WRITE setProximityEnabled NOTIFY proximityEnabledChanged)
    Q_PROPERTY(int proximityDistancePx READ proximityDistancePx WRITE setProximityDistancePx NOTIFY proximityDistancePxChanged)
    Q_PROPERTY(bool cursorAtEdge READ cursorAtEdge NOTIFY cursorAtEdgeChanged)

    /** Normalized cursor proximity to the active outer edge (0.0 = far, 1.0 = at edge). */
    Q_PROPERTY(qreal proximity READ proximity NOTIFY proximityChanged)
    Q_PROPERTY(int cursorY READ cursorY NOTIFY cursorYChanged)
    Q_PROPERTY(int screenX READ screenX NOTIFY screenGeometryChanged)
    Q_PROPERTY(int screenY READ screenY NOTIFY screenGeometryChanged)
    Q_PROPERTY(int screenWidth READ screenWidth NOTIFY screenGeometryChanged)
    Q_PROPERTY(int screenHeight READ screenHeight NOTIFY screenGeometryChanged)

public:
    explicit EdgeTrigger(QObject *parent = nullptr) : QObject(parent) {
        m_pollTimer.setInterval(IdlePollIntervalMs);
        connect(&m_pollTimer, &QTimer::timeout, this, &EdgeTrigger::checkCursor);
        m_pollTimer.start();

        m_holdTimer.setSingleShot(true);
        m_holdTimer.setInterval(m_holdDurationMs);
        connect(&m_holdTimer, &QTimer::timeout, this, [this]() {
            if (!m_enabled) return;
            const QPoint pos = QCursor::pos();
            QScreen *screen = QGuiApplication::screenAt(pos);
            if (!screen) return;

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
            resetProximity();
        } else if (m_cursorAtEdge) {
            m_holdTimer.start();
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
        resetProximity();
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

    bool proximityEnabled() const { return m_proximityEnabled; }
    void setProximityEnabled(bool value) {
        if (m_proximityEnabled == value) return;
        m_proximityEnabled = value;
        if (!m_proximityEnabled) {
            resetProximity();
        }
        emit proximityEnabledChanged();
    }

    int proximityDistancePx() const { return m_proximityDistancePx; }
    void setProximityDistancePx(int px) {
        const int clamped = qMax(20, px);
        if (m_proximityDistancePx == clamped) return;
        m_proximityDistancePx = clamped;
        emit proximityDistancePxChanged();
    }

    qreal proximity() const { return m_proximity; }
    int cursorY() const { return m_cursorY; }
    int screenX() const { return m_screenGeometry.x(); }
    int screenY() const { return m_screenGeometry.y(); }
    int screenWidth() const { return m_screenGeometry.width(); }
    int screenHeight() const { return m_screenGeometry.height(); }
    bool cursorAtEdge() const { return m_cursorAtEdge; }

    Q_INVOKABLE bool triggerAtCursor() {
        const QPoint pos = QCursor::pos();
        QScreen *screen = QGuiApplication::screenAt(pos);
        if (!screen) return false;

        const QRect available = screen->availableGeometry();
        emit triggered(available.x(), available.y(), available.width(),
                       available.height(), pos.y());
        return true;
    }

signals:
    void enabledChanged();
    void edgeChanged();
    void holdDurationMsChanged();
    void edgeThresholdPxChanged();
    void proximityEnabledChanged();
    void proximityDistancePxChanged();
    void cursorAtEdgeChanged();
    void proximityChanged();
    void cursorYChanged();
    void screenGeometryChanged();

    void triggered(int screenX, int screenY, int screenWidth, int screenHeight, int cursorY);

private:
    static constexpr int IdlePollIntervalMs = 80;
    static constexpr int ActivePollIntervalMs = 16;

    void setPollInterval(int intervalMs) {
        if (m_pollTimer.interval() != intervalMs) {
            m_pollTimer.setInterval(intervalMs);
        }
    }

    void resetProximity() {
        if (m_proximity > 0.0) {
            m_proximity = 0.0;
            emit proximityChanged();
        }
        setPollInterval(IdlePollIntervalMs);
    }

    void checkCursor() {
        const QPoint pos = QCursor::pos();
        QScreen *screen = QGuiApplication::screenAt(pos);
        if (!screen) {
            if (m_cursorAtEdge) {
                m_cursorAtEdge = false;
                emit cursorAtEdgeChanged();
            }
            m_holdTimer.stop();
            return;
        }

        const QRect geom = screen->geometry();
        bool hasNeighbor = false;
        int distanceToEdge = 0;

        if (m_edge == "right") {
            hasNeighbor = QGuiApplication::screenAt(QPoint(geom.right() + 5, pos.y())) != nullptr;
            distanceToEdge = qMax(0, geom.right() - pos.x());
        } else {
            hasNeighbor = QGuiApplication::screenAt(QPoint(geom.left() - 5, pos.y())) != nullptr;
            distanceToEdge = qMax(0, pos.x() - geom.left());
        }

        const bool atOuterEdge = !hasNeighbor && (distanceToEdge <= m_edgeThresholdPx);

        if (m_proximityEnabled && !hasNeighbor && distanceToEdge <= m_proximityDistancePx) {
            const qreal linear = 1.0 - (static_cast<qreal>(distanceToEdge) / m_proximityDistancePx);
            const qreal nextProximity = qBound(0.0, linear * linear, 1.0);

            if (m_screenGeometry != geom) {
                m_screenGeometry = geom;
                emit screenGeometryChanged();
            }
            if (m_cursorY != pos.y()) {
                m_cursorY = pos.y();
                emit cursorYChanged();
            }
            if (!qFuzzyCompare(m_proximity + 1.0, nextProximity + 1.0)) {
                m_proximity = nextProximity;
                emit proximityChanged();
            }
            setPollInterval(ActivePollIntervalMs);
        } else {
            resetProximity();
        }

        if (atOuterEdge != m_cursorAtEdge) {
            m_cursorAtEdge = atOuterEdge;
            emit cursorAtEdgeChanged();
        }

        if (atOuterEdge && m_enabled && !m_edgeHovered) {
            m_edgeHovered = true;
            m_holdTimer.start();
        } else if ((!atOuterEdge || !m_enabled) && m_edgeHovered) {
            m_edgeHovered = false;
            m_holdTimer.stop();
        }
    }

    QTimer m_pollTimer;
    QTimer m_holdTimer;
    bool m_enabled = true;
    bool m_edgeHovered = false;
    bool m_cursorAtEdge = false;
    bool m_proximityEnabled = true;
    QString m_edge = "right";
    int m_holdDurationMs = 500;
    int m_edgeThresholdPx = 2;
    int m_proximityDistancePx = 140;
    qreal m_proximity = 0.0;
    int m_cursorY = 0;
    QRect m_screenGeometry;
};