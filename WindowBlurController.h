#pragma once

#include <QObject>
#include <QQuickWindow>

#ifdef Q_OS_WIN
#include <QDebug>
#include <windows.h>
#include "WindowBlur.h"
#endif

class WindowBlurController : public QObject
{
    Q_OBJECT

public:
    using QObject::QObject;

    Q_INVOKABLE void configureSettingsWindow(QQuickWindow* window)
    {
#ifdef Q_OS_WIN
        if (!window)
            return;

        const HWND hwnd = reinterpret_cast<HWND>(window->winId());
        updateWindowStyle(hwnd, GWL_STYLE, WS_SYSMENU | WS_MINIMIZEBOX | WS_MAXIMIZEBOX, 0);
        updateWindowStyle(hwnd, GWL_EXSTYLE, WS_EX_APPWINDOW, WS_EX_TOOLWINDOW);
#else
        Q_UNUSED(window);
#endif
    }

    Q_INVOKABLE void configureOverlayWindow(QQuickWindow* window)
    {
#ifdef Q_OS_WIN
        if (!window)
            return;

        const HWND hwnd = reinterpret_cast<HWND>(window->winId());
        updateWindowStyle(hwnd, GWL_EXSTYLE, WS_EX_TOOLWINDOW, WS_EX_APPWINDOW);
#else
        Q_UNUSED(window);
#endif
    }

    Q_INVOKABLE void setOverlayWindowBlur(QQuickWindow* window, bool enabled)
    {
#ifdef Q_OS_WIN
        if (!window)
            return;

        const HWND hwnd = reinterpret_cast<HWND>(window->winId());
        if (enabled)
            enableWindowBlur(hwnd);
        else
            disableWindowBlur(hwnd);
#else
        Q_UNUSED(window);
        Q_UNUSED(enabled);
#endif
    }

    Q_INVOKABLE void applySettingsWindowBlur(QQuickWindow* window)
    {
#ifdef Q_OS_WIN
        if (window) {
            enableWindowBlur(reinterpret_cast<HWND>(window->winId()), 0x5092B38F);
        }
#else
        Q_UNUSED(window);
#endif
    }

private:
#ifdef Q_OS_WIN
    static void updateWindowStyle(HWND hwnd, int index, LONG_PTR add, LONG_PTR remove)
    {
        SetLastError(ERROR_SUCCESS);
        const LONG_PTR currentStyle = GetWindowLongPtrW(hwnd, index);
        if (currentStyle == 0 && GetLastError() != ERROR_SUCCESS) {
            qWarning() << "Could not read native window style:" << GetLastError();
            return;
        }

        const LONG_PTR updatedStyle = (currentStyle | add) & ~remove;
        if (updatedStyle == currentStyle)
            return;

        SetLastError(ERROR_SUCCESS);
        const LONG_PTR previousStyle = SetWindowLongPtrW(hwnd, index, updatedStyle);
        if (previousStyle == 0 && GetLastError() != ERROR_SUCCESS) {
            qWarning() << "Could not update native window style:" << GetLastError();
            return;
        }

        if (!SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                          SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER
                              | SWP_NOACTIVATE | SWP_FRAMECHANGED)) {
            qWarning() << "Could not refresh native window style:" << GetLastError();
        }
    }
#endif
};
