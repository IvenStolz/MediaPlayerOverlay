#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <qqmlcontext.h>
#include <QQuickWindow>
#include <QIcon>

#include "MediaManager.h"

#ifdef Q_OS_WIN
#include "WindowBlur.h"
#endif

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/SpotifyRemote/assets/icon.png"));
    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection
    );

#ifdef Q_OS_WIN
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [](QObject *object, const QUrl &) {
            if (auto *window = qobject_cast<QQuickWindow *>(object)) {
                HWND hwnd = reinterpret_cast<HWND>(window->winId());
                enableWindowBlur(hwnd);
            }
        },
        Qt::DirectConnection
    );
#endif

    MediaManager mediaManager;
    engine.rootContext()->setContextProperty("mediaManager", &mediaManager);
    engine.load(QUrl(QStringLiteral("qrc:/SpotifyRemote/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    return app.exec();
}