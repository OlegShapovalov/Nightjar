#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QPalette>
#include <QColor>
#include <cstdlib>
#include "filemanager.h"

int main(int argc, char *argv[]) {
    qputenv("QT_LOGGING_RULES", "cosmic_config.*=false;qt.qpa.*=false");

    // 1. Автоподстановка платформенной темы для GTK-окружений (Cinnamon, GNOME, XFCE)
    // Если переменная не выставлена пользователем, пробуем задействовать qt6ct
    if (!qEnvironmentVariableIsSet("QT_QPA_PLATFORMTHEME")) {
        qputenv("QT_QPA_PLATFORMTHEME", "qt6ct");
    }

    QGuiApplication app(argc, argv);

    // 2. Включаем современный стиль элементов управления Qt Quick Controls
    // Стиль Fusion отлично уважает QPalette и тему qt6ct
    if (QQuickStyle::name().isEmpty()) {
        QQuickStyle::setStyle("Fusion");
    }

    // 3. Страховка по контрастности на случай запуска без qt6ct
    const QPalette &pal = QGuiApplication::palette();
    QColor baseColor = pal.color(QPalette::Base);
    QColor textColor = pal.color(QPalette::Text);

    // Если разница в яркости между фоном и текстом слишком мала (текст сливается)
    if (std::abs(baseColor.lightness() - textColor.lightness()) < 80) {
        QPalette dark;
        dark.setColor(QPalette::Window, QColor(30, 30, 30));
        dark.setColor(QPalette::WindowText, QColor(220, 220, 220));
        dark.setColor(QPalette::Base, QColor(24, 24, 24));
        dark.setColor(QPalette::AlternateBase, QColor(32, 32, 32));
        dark.setColor(QPalette::ToolTipBase, QColor(220, 220, 220));
        dark.setColor(QPalette::ToolTipText, QColor(20, 20, 20));
        dark.setColor(QPalette::Text, QColor(220, 220, 220));
        dark.setColor(QPalette::Button, QColor(35, 35, 35));
        dark.setColor(QPalette::ButtonText, QColor(220, 220, 220));
        dark.setColor(QPalette::Highlight, QColor(42, 130, 218));
        dark.setColor(QPalette::HighlightedText, QColor(255, 255, 255));

        QGuiApplication::setPalette(dark);
    }

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