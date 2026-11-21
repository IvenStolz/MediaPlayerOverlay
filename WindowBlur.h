#pragma once

#ifdef Q_OS_WIN

#include <windows.h>
#include <dwmapi.h>

#ifndef DWMWA_WINDOW_CORNER_PREFERENCE
#define DWMWA_WINDOW_CORNER_PREFERENCE 33
#endif
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

// --- Structs für den echten Blur auf rahmenlosen Fenstern ---
enum ACCENT_STATE {
    ACCENT_DISABLED = 0,
    ACCENT_ENABLE_GRADIENT = 1,
    ACCENT_ENABLE_TRANSPARENTGRADIENT = 2,
    ACCENT_ENABLE_BLURBEHIND = 3,
    ACCENT_ENABLE_ACRYLICBLURBEHIND = 4,
    ACCENT_ENABLE_HOSTBACKDROP = 5,
    ACCENT_INVALID_STATE = 6
};

struct ACCENT_POLICY {
    ACCENT_STATE AccentState;
    DWORD AccentFlags;
    DWORD GradientColor;
    DWORD AnimationId;
};

enum WINDOWCOMPOSITIONATTRIB {
    WCA_ACCENT_POLICY = 19
};

struct WINDOWCOMPOSITIONATTRIBDATA {
    WINDOWCOMPOSITIONATTRIB Attrib;
    PVOID pvData;
    SIZE_T cbData;
};

typedef BOOL(WINAPI *pSetWindowCompositionAttribute)(HWND, WINDOWCOMPOSITIONATTRIBDATA *);

inline pSetWindowCompositionAttribute windowCompositionAttributeFunction()
{
    static auto function = reinterpret_cast<pSetWindowCompositionAttribute>(
        GetProcAddress(GetModuleHandleW(L"user32.dll"), "SetWindowCompositionAttribute"));
    return function;
}

inline void enableWindowBlur(HWND hwnd, DWORD tintColor = 0x20000000)
{
    if (!hwnd) return;

    // 1. Dark Mode für OS-Schatten und Menüs erzwingen
    BOOL darkMode = TRUE;
    DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &darkMode, sizeof(darkMode));

    // 2. Native, geglättete Windows 11 Ecken aktivieren
    int cornerPref = 2; // DWMWCP_ROUND
    DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE, &cornerPref, sizeof(cornerPref));

    // 3. Den "alten" Acrylic Blur anwenden (ignoriert die Rahmen-Pflicht von Windows 11)
    const auto setWindowCompositionAttribute = windowCompositionAttributeFunction();
    if (setWindowCompositionAttribute) {
        ACCENT_POLICY accent{};
        accent.AccentState = ACCENT_ENABLE_ACRYLICBLURBEHIND;
        // Nutzt den tintColor Parameter (Standard: 0x20000000 -> 12% Schwarz)
        accent.GradientColor = tintColor;

        WINDOWCOMPOSITIONATTRIBDATA data{};
        data.Attrib = WCA_ACCENT_POLICY;
        data.pvData = &accent;
        data.cbData = sizeof(accent);

        setWindowCompositionAttribute(hwnd, &data);
    }
}

inline void disableWindowBlur(HWND hwnd)
{
    if (!hwnd)
        return;

    const auto setWindowCompositionAttribute = windowCompositionAttributeFunction();
    if (!setWindowCompositionAttribute)
        return;

    ACCENT_POLICY accent{};
    accent.AccentState = ACCENT_DISABLED;

    WINDOWCOMPOSITIONATTRIBDATA data{};
    data.Attrib = WCA_ACCENT_POLICY;
    data.pvData = &accent;
    data.cbData = sizeof(accent);

    setWindowCompositionAttribute(hwnd, &data);
}

#endif // Q_OS_WIN