#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "filemanager.h"

int main(int argc, char *argv[]) {
    qputenv("QT_LOGGING_RULES", "cosmic_config.*=false;qt.qpa.*=false");

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    qmlRegisterType<FileManager>("Commander", 1, 0, "FileManager");

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("Nightjar", "Main");
    return app.exec();
}
