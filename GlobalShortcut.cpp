#include "GlobalShortcut.h"

#include <QCoreApplication>
#include <QKeyCombination>
#include <QKeySequence>
#include <windows.h>

namespace
{
bool toVirtualKey(int key, unsigned int& virtualKey)
{
    if (key >= Qt::Key_A && key <= Qt::Key_Z) {
        virtualKey = static_cast<unsigned int>(key);
        return true;
    }
    if (key >= Qt::Key_0 && key <= Qt::Key_9) {
        virtualKey = static_cast<unsigned int>(key);
        return true;
    }
    if (key >= Qt::Key_F1 && key <= Qt::Key_F24) {
        virtualKey = VK_F1 + static_cast<unsigned int>(key - Qt::Key_F1);
        return true;
    }

    switch (key) {
    case Qt::Key_Space: virtualKey = VK_SPACE; return true;
    case Qt::Key_Tab: virtualKey = VK_TAB; return true;
    case Qt::Key_Return:
    case Qt::Key_Enter: virtualKey = VK_RETURN; return true;
    case Qt::Key_Escape: virtualKey = VK_ESCAPE; return true;
    case Qt::Key_Backspace: virtualKey = VK_BACK; return true;
    case Qt::Key_Delete: virtualKey = VK_DELETE; return true;
    case Qt::Key_Insert: virtualKey = VK_INSERT; return true;
    case Qt::Key_Home: virtualKey = VK_HOME; return true;
    case Qt::Key_End: virtualKey = VK_END; return true;
    case Qt::Key_PageUp: virtualKey = VK_PRIOR; return true;
    case Qt::Key_PageDown: virtualKey = VK_NEXT; return true;
    case Qt::Key_Left: virtualKey = VK_LEFT; return true;
    case Qt::Key_Right: virtualKey = VK_RIGHT; return true;
    case Qt::Key_Up: virtualKey = VK_UP; return true;
    case Qt::Key_Down: virtualKey = VK_DOWN; return true;
    default: return false;
    }
}
}

GlobalShortcut::GlobalShortcut(QObject* parent)
    : QObject(parent)
{
    if (QCoreApplication::instance()) {
        QCoreApplication::instance()->installNativeEventFilter(this);
    }
}

GlobalShortcut::~GlobalShortcut()
{
    unregisterShortcut();
    if (QCoreApplication::instance()) {
        QCoreApplication::instance()->removeNativeEventFilter(this);
    }
}

void GlobalShortcut::setSequence(const QString& sequence)
{
    const QString normalized = sequence.trimmed();
    if (m_sequence == normalized) {
        return;
    }

    unregisterShortcut();
    m_sequence = normalized;
    emit sequenceChanged();

    if (m_sequence.isEmpty()) {
        setError({});
        return;
    }

    const QKeySequence keySequence =
        QKeySequence::fromString(m_sequence, QKeySequence::PortableText);
    if (keySequence.count() != 1) {
        setError(tr("Enter one key combination."));
        return;
    }

    const QKeyCombination combination = keySequence[0];
    const Qt::KeyboardModifiers qtModifiers = combination.keyboardModifiers();
    unsigned int modifiers = MOD_NOREPEAT;
    if (qtModifiers.testFlag(Qt::ControlModifier)) modifiers |= MOD_CONTROL;
    if (qtModifiers.testFlag(Qt::AltModifier)) modifiers |= MOD_ALT;
    if (qtModifiers.testFlag(Qt::ShiftModifier)) modifiers |= MOD_SHIFT;
    if (qtModifiers.testFlag(Qt::MetaModifier)) modifiers |= MOD_WIN;

    if ((modifiers & (MOD_CONTROL | MOD_ALT | MOD_SHIFT | MOD_WIN)) == 0) {
        setError(tr("A global shortcut must include Ctrl, Alt, Shift, or Win."));
        return;
    }

    unsigned int virtualKey = 0;
    if (!toVirtualKey(combination.key(), virtualKey)) {
        setError(tr("This key is not supported for a global shortcut."));
        return;
    }

    if (!RegisterHotKey(nullptr, ShortcutId, modifiers, virtualKey)) {
        setError(tr("Could not register this shortcut (Windows error %1).")
                     .arg(GetLastError()));
        return;
    }

    m_modifiers = modifiers;
    m_virtualKey = virtualKey;
    setError({});
}

bool GlobalShortcut::nativeEventFilter(const QByteArray&, void* message, qintptr*)
{
    const auto* msg = static_cast<const MSG*>(message);
    if (msg && msg->message == WM_HOTKEY && msg->wParam == ShortcutId) {
        emit activated();
        return true;
    }
    return false;
}

void GlobalShortcut::setError(const QString& error)
{
    if (m_error == error) {
        return;
    }
    m_error = error;
    emit errorChanged();
}

void GlobalShortcut::unregisterShortcut()
{
    if (m_virtualKey != 0) {
        UnregisterHotKey(nullptr, ShortcutId);
        m_virtualKey = 0;
        m_modifiers = 0;
    }
}
