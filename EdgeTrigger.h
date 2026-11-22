#pragma once

#include <QObject>
#include <QTimer>
#include <QCursor>
#include <QGuiApplication>
#include <QScreen>
#include <QRect>
#include <QVariantList>
#include <QVariantMap>
#include <QHash>
#include <QSet>
#include <QFileInfo>
#include <QImage>
#include <QBuffer>
#include <QtMath>

#ifdef Q_OS_WIN
#include <windows.h>
#include <shellapi.h>
#include <shobjidl.h>
#endif

class EdgeTrigger : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(QString edge READ edge WRITE setEdge NOTIFY edgeChanged)
    Q_PROPERTY(int holdDurationMs READ holdDurationMs WRITE setHoldDurationMs NOTIFY holdDurationMsChanged)
    Q_PROPERTY(int edgeThresholdPx READ edgeThresholdPx WRITE setEdgeThresholdPx NOTIFY edgeThresholdPxChanged)

    /** Settings interface for proximity glow tracking. */
    Q_PROPERTY(bool proximityEnabled READ proximityEnabled WRITE setProximityEnabled NOTIFY proximityEnabledChanged)
    Q_PROPERTY(int proximityDistancePx READ proximityDistancePx WRITE setProximityDistancePx NOTIFY proximityDistancePxChanged)

    /** Settings interface for fullscreen and per-application behavior rules. */
    Q_PROPERTY(bool fullscreenEnabled READ fullscreenEnabled WRITE setFullscreenEnabled NOTIFY behaviorRulesChanged)
    Q_PROPERTY(QString fullscreenHoldKey READ fullscreenHoldKey WRITE setFullscreenHoldKey NOTIFY behaviorRulesChanged)
    Q_PROPERTY(QVariantList appRules READ appRules WRITE setAppRules NOTIFY behaviorRulesChanged)

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
            if (!m_enabled || !isTriggerAllowedForForeground()) return;
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
            m_edgeHovered = false;
            resetProximity();
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

    bool fullscreenEnabled() const { return m_fullscreenEnabled; }
    void setFullscreenEnabled(bool value) {
        if (m_fullscreenEnabled == value) return;
        m_fullscreenEnabled = value;
        emit behaviorRulesChanged();
    }

    QString fullscreenHoldKey() const { return m_fullscreenHoldKey; }
    void setFullscreenHoldKey(const QString &key) {
        if (m_fullscreenHoldKey == key) return;
        m_fullscreenHoldKey = key.trimmed();
        emit behaviorRulesChanged();
    }

    QVariantList appRules() const { return m_appRules; }
    void setAppRules(const QVariantList &rules) {
        m_appRules = rules;
        m_appRuleLookup.clear();
        for (const QVariant &item : rules) {
            const QVariantMap map = item.toMap();
            const QString exe = map.value(QStringLiteral("exe")).toString().trimmed().toLower();
            if (exe.isEmpty()) continue;

            AppRule rule;
            rule.enabled = map.value(QStringLiteral("enabled"), true).toBool();
            rule.holdKey = map.value(QStringLiteral("holdKey")).toString().trimmed();
            m_appRuleLookup.insert(exe, rule);
        }
        emit behaviorRulesChanged();
    }

    qreal proximity() const { return m_proximity; }
    int cursorY() const { return m_cursorY; }
    int screenX() const { return m_screenGeometry.x(); }
    int screenY() const { return m_screenGeometry.y(); }
    int screenWidth() const { return m_screenGeometry.width(); }
    int screenHeight() const { return m_screenGeometry.height(); }

    Q_INVOKABLE bool triggerAtCursor() {
        const QPoint pos = QCursor::pos();
        QScreen *screen = QGuiApplication::screenAt(pos);
        if (!screen) return false;

        const QRect available = screen->availableGeometry();
        emit triggered(available.x(), available.y(), available.width(),
                       available.height(), pos.y());
        return true;
    }

    /** Returns visible top-level applications with their executable name and icon data URL. */
    Q_INVOKABLE QVariantList getRunningApplications() {
        QVariantList apps;
#ifdef Q_OS_WIN
        struct EnumContext {
            QSet<QString> seenExe;
            QVariantList *result = nullptr;
            QHash<QString, QString> *iconCache = nullptr;
            DWORD selfPid = 0;
        };

        EnumContext ctx;
        ctx.result = &apps;
        ctx.iconCache = &m_exeIconCache;
        ctx.selfPid = GetCurrentProcessId();

        EnumWindows([](HWND hwnd, LPARAM lParam) -> BOOL {
            auto *context = reinterpret_cast<EnumContext *>(lParam);
            if (!IsWindowVisible(hwnd) || GetWindow(hwnd, GW_OWNER) != nullptr) {
                return TRUE;
            }
            if (GetWindowTextLengthW(hwnd) == 0) {
                return TRUE;
            }

            DWORD pid = 0;
            GetWindowThreadProcessId(hwnd, &pid);
            if (pid == 0 || pid == context->selfPid) {
                return TRUE;
            }

            const QString exePath = processPathForPid(pid);
            if (exePath.isEmpty()) {
                return TRUE;
            }

            const QFileInfo info(exePath);
            const QString exeName = info.fileName();
            const QString key = exeName.toLower();
            if (key.isEmpty() || context->seenExe.contains(key)) {
                return TRUE;
            }
            context->seenExe.insert(key);

            if (!context->iconCache->contains(key)) {
                context->iconCache->insert(key, loadIconFromPath(exePath));
            }

            context->result->append(QVariantMap{
                {QStringLiteral("exe"), exeName},
                {QStringLiteral("displayName"), info.completeBaseName()},
                {QStringLiteral("iconUrl"), context->iconCache->value(key)}
            });
            return TRUE;
        }, reinterpret_cast<LPARAM>(&ctx));
#endif
        return apps;
    }

signals:
    void enabledChanged();
    void edgeChanged();
    void holdDurationMsChanged();
    void edgeThresholdPxChanged();
    void proximityEnabledChanged();
    void proximityDistancePxChanged();
    void behaviorRulesChanged();
    void proximityChanged();
    void cursorYChanged();
    void screenGeometryChanged();

    void triggered(int screenX, int screenY, int screenWidth, int screenHeight, int cursorY);

private:
    struct AppRule {
        bool enabled = true;
        QString holdKey;
    };

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

#ifdef Q_OS_WIN
    static QString processPathForPid(DWORD pid) {
        HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
        if (!process) return {};

        wchar_t buffer[MAX_PATH];
        DWORD size = MAX_PATH;
        QString path;
        if (QueryFullProcessImageNameW(process, 0, buffer, &size)) {
            path = QString::fromWCharArray(buffer, static_cast<int>(size));
        }
        CloseHandle(process);
        return path;
    }

    static QString loadIconFromPath(const QString &exePath) {
        const HRESULT comResult = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
        const bool shouldUninit = SUCCEEDED(comResult);

        IShellItem *shellItem = nullptr;
        IShellItemImageFactory *imageFactory = nullptr;
        HBITMAP bitmap = nullptr;
        QString iconUrl;

        const std::wstring widePath = exePath.toStdWString();
        if (SUCCEEDED(SHCreateItemFromParsingName(widePath.c_str(), nullptr, IID_PPV_ARGS(&shellItem)))
            && SUCCEEDED(shellItem->QueryInterface(IID_PPV_ARGS(&imageFactory)))
            && SUCCEEDED(imageFactory->GetImage(SIZE{64, 64}, SIIGBF_ICONONLY | SIIGBF_BIGGERSIZEOK, &bitmap))) {
            BITMAP bmpDesc{};
            if (GetObjectW(bitmap, sizeof(bmpDesc), &bmpDesc)
                && bmpDesc.bmWidth > 0 && bmpDesc.bmHeight > 0) {
                QImage image(bmpDesc.bmWidth, bmpDesc.bmHeight, QImage::Format_ARGB32);
                BITMAPINFO bmpInfo{};
                bmpInfo.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
                bmpInfo.bmiHeader.biWidth = bmpDesc.bmWidth;
                bmpInfo.bmiHeader.biHeight = -bmpDesc.bmHeight;
                bmpInfo.bmiHeader.biPlanes = 1;
                bmpInfo.bmiHeader.biBitCount = 32;
                bmpInfo.bmiHeader.biCompression = BI_RGB;

                HDC dc = GetDC(nullptr);
                const int lines = GetDIBits(dc, bitmap, 0, static_cast<UINT>(bmpDesc.bmHeight),
                                            image.bits(), &bmpInfo, DIB_RGB_COLORS);
                ReleaseDC(nullptr, dc);

                if (lines > 0) {
                    QByteArray data;
                    QBuffer buffer(&data);
                    if (buffer.open(QIODevice::WriteOnly) && image.save(&buffer, "PNG")) {
                        iconUrl = QStringLiteral("data:image/png;base64,") + data.toBase64();
                    }
                }
            }
        }

        if (bitmap) DeleteObject(bitmap);
        if (imageFactory) imageFactory->Release();
        if (shellItem) shellItem->Release();
        if (shouldUninit) CoUninitialize();
        return iconUrl;
    }

    static bool isWindowFullscreen(HWND hwnd) {
        if (!hwnd) return false;

        wchar_t className[64]{};
        GetClassNameW(hwnd, className, 64);
        const QString cls = QString::fromWCharArray(className);
        if (cls == QLatin1String("Progman") || cls == QLatin1String("WorkerW")
            || cls == QLatin1String("Shell_TrayWnd")) {
            return false;
        }

        QUERY_USER_NOTIFICATION_STATE state{};
        if (SUCCEEDED(SHQueryUserNotificationState(&state))
            && state == QUNS_RUNNING_D3D_FULL_SCREEN) {
            return true;
        }

        RECT winRect{};
        if (!GetWindowRect(hwnd, &winRect)) return false;

        HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
        MONITORINFO monitorInfo{};
        monitorInfo.cbSize = sizeof(monitorInfo);
        if (!GetMonitorInfoW(monitor, &monitorInfo)) return false;

        const RECT &mon = monitorInfo.rcMonitor;
        return winRect.left <= mon.left && winRect.top <= mon.top
            && winRect.right >= mon.right && winRect.bottom >= mon.bottom;
    }

    static int vkCodeFromKeyName(const QString &keyName) {
        const QString k = keyName.trimmed().toLower();
        if (k.isEmpty()) return 0;
        if (k == QLatin1String("alt")) return VK_MENU;
        if (k == QLatin1String("ctrl")) return VK_CONTROL;
        if (k == QLatin1String("shift")) return VK_SHIFT;
        if (k == QLatin1String("meta") || k == QLatin1String("win")) return VK_LWIN;
        if (k == QLatin1String("space")) return VK_SPACE;
        if (k == QLatin1String("tab")) return VK_TAB;
        if (k.size() == 1) {
            const QChar ch = k.at(0).toUpper();
            if ((ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9')) {
                return ch.unicode();
            }
        }
        if (k.startsWith('f')) {
            bool ok = false;
            const int fn = k.mid(1).toInt(&ok);
            if (ok && fn >= 1 && fn <= 24) {
                return VK_F1 + (fn - 1);
            }
        }
        return 0;
    }

    static bool isHoldKeyPressed(const QString &holdKey) {
        if (holdKey.isEmpty()) return true;
        const int vk = vkCodeFromKeyName(holdKey);
        if (vk == 0) return true;
        return (GetAsyncKeyState(vk) & 0x8000) != 0;
    }
#endif

    /** Evaluates app-specific and fullscreen rules in priority order. */
    bool isTriggerAllowedForForeground() const {
#ifdef Q_OS_WIN
        HWND foreground = GetForegroundWindow();
        if (!foreground) return true;

        DWORD pid = 0;
        GetWindowThreadProcessId(foreground, &pid);
        if (pid == GetCurrentProcessId()) return true;

        // 1. Specific application rule (highest priority).
        if (!m_appRuleLookup.isEmpty() && pid != 0) {
            const QString exeName = QFileInfo(processPathForPid(pid)).fileName().toLower();
            const auto it = m_appRuleLookup.constFind(exeName);
            if (it != m_appRuleLookup.cend()) {
                return it->enabled && isHoldKeyPressed(it->holdKey);
            }
        }

        // 2. Global fullscreen rule.
        if (isWindowFullscreen(foreground)) {
            return m_fullscreenEnabled && isHoldKeyPressed(m_fullscreenHoldKey);
        }
#endif
        // 3. Default behavior.
        return true;
    }

    void checkCursor() {
        if (!m_enabled) return;

        const QPoint pos = QCursor::pos();
        QScreen *screen = QGuiApplication::screenAt(pos);
        if (!screen) return;

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

        const bool inZone = !hasNeighbor && (distanceToEdge <= qMax(m_edgeThresholdPx, m_proximityDistancePx));
        if (inZone && !isTriggerAllowedForForeground()) {
            m_edgeHovered = false;
            m_holdTimer.stop();
            resetProximity();
            return;
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
    bool m_proximityEnabled = true;
    bool m_fullscreenEnabled = true;
    QString m_fullscreenHoldKey;
    QVariantList m_appRules;
    QHash<QString, AppRule> m_appRuleLookup;
    QHash<QString, QString> m_exeIconCache;
    QString m_edge = "right";
    int m_holdDurationMs = 1000;
    int m_edgeThresholdPx = 2;
    int m_proximityDistancePx = 140;
    qreal m_proximity = 0.0;
    int m_cursorY = 0;
    QRect m_screenGeometry;
};