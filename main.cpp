#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <qqmlcontext.h>
#include <QIcon>

#include "EdgeTrigger.h"
#include "GlobalShortcut.h"
#include "MediaManager.h"
#include "WindowBlurController.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/MediaPlayerOverlay/assets/icon.png"));
    QQmlApplicationEngine engine;

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [&app](const QUrl& url) {
            qCritical().noquote() << "QML root creation failed:" << url;
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );

    QObject::connect(
        &engine,
        &QQmlEngine::warnings,
        &app,
        [](const QList<QQmlError>& warnings) {
            for (const QQmlError& warning : warnings) {
                qWarning().noquote() << warning.toString();
            }
        }
    );

    MediaManager mediaManager;
    WindowBlurController windowBlurController;
    EdgeTrigger edgeTrigger;
    GlobalShortcut globalShortcut;
    engine.rootContext()->setContextProperty("mediaManager", &mediaManager);
    engine.rootContext()->setContextProperty("windowBlurController", &windowBlurController);
    engine.rootContext()->setContextProperty("edgeTrigger", &edgeTrigger);
    engine.rootContext()->setContextProperty("globalShortcutManager", &globalShortcut);
    engine.load(QUrl(QStringLiteral("qrc:/MediaPlayerOverlay/Main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "QML engine loaded no root objects.";
        return -1;
    }

    return app.exec();
}