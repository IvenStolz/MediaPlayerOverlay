#pragma once

#include <QAbstractNativeEventFilter>
#include <QObject>
#include <QString>

class GlobalShortcut final : public QObject, public QAbstractNativeEventFilter
{
    Q_OBJECT
    Q_PROPERTY(QString sequence READ sequence WRITE setSequence NOTIFY sequenceChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit GlobalShortcut(QObject* parent = nullptr);
    ~GlobalShortcut() override;

    QString sequence() const { return m_sequence; }
    QString error() const { return m_error; }
    void setSequence(const QString& sequence);

    bool nativeEventFilter(const QByteArray& eventType, void* message,
                           qintptr* result) override;

signals:
    void sequenceChanged();
    void errorChanged();
    void activated();

private:
    void setError(const QString& error);
    void unregisterShortcut();

    QString m_sequence;
    QString m_error;
    unsigned int m_virtualKey = 0;
    unsigned int m_modifiers = 0;
    static constexpr int ShortcutId = 0x4D50;
};
