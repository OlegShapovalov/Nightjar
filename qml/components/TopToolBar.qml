import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    height: 38
    color: theme ? theme.bgSurface : "#1f1f23"
    radius: 6
    border.color: theme ? theme.border : "#27272a"
    border.width: 1

    property var theme

    signal refreshClicked()
    signal newTabClicked()
    signal searchClicked()
    signal renameClicked()
    signal packClicked()
    signal unpackClicked()
    signal copyClicked()
    signal moveClicked()
    signal deleteClicked()
    signal terminalClicked()
    signal helpClicked()
    signal settingsClicked()
    signal connectClicked()

    component ToolButtonCustom: Rectangle {
        property string iconText: ""
        property string tooltipText: ""
        signal clicked()

        width: 32
        height: 30
        radius: 4
        color: btnMouse.containsMouse ? (root.theme ? root.theme.accent : "#3b82f6") : 
               (btnMouse.pressed ? (root.theme ? root.theme.accentActive : "#2563eb") : (root.theme ? root.theme.bgInput : "#27272a"))

        Text {
            anchors.centerIn: parent
            text: iconText
            font.pixelSize: 14
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        ToolTip.visible: btnMouse.containsMouse
        ToolTip.text: tooltipText
        ToolTip.delay: 400
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 6

        ToolButtonCustom {
            iconText: "🔄"
            tooltipText: "Обновить панели"
            onClicked: root.refreshClicked()
        }

        ToolButtonCustom {
            iconText: "📑"
            tooltipText: "Новая вкладка (Ctrl+T)"
            onClicked: root.newTabClicked()
        }

        Rectangle { width: 1; height: 20; color: root.theme ? root.theme.border : "#3f3f46" }

        ToolButtonCustom {
            iconText: "🌐"
            tooltipText: "Подключиться к SSH / серверу (Ctrl+F)"
            onClicked: root.connectClicked()
        }

        ToolButtonCustom {
            iconText: "🔎"
            tooltipText: "Глобальный поиск (Alt+F7)"
            onClicked: root.searchClicked()
        }

        ToolButtonCustom {
            iconText: "📦"
            tooltipText: "Упаковать в архив (Alt+F5)"
            onClicked: root.packClicked()
        }
        ToolButtonCustom {
            iconText: "📂"
            tooltipText: "Распаковать архив (Alt+F9)"
            onClicked: root.unpackClicked()
        }

        ToolButtonCustom {
            iconText: "🏷️"
            tooltipText: "Групповое переименование (Ctrl+M)"
            onClicked: root.renameClicked()
        }

        Rectangle { width: 1; height: 20; color: root.theme ? root.theme.border : "#3f3f46" }

        ToolButtonCustom {
            iconText: "📋"
            tooltipText: "Копировать в соседнюю панель (F5)"
            onClicked: root.copyClicked()
        }
        ToolButtonCustom {
            iconText: "✂️"
            tooltipText: "Переместить в соседнюю панель (F6)"
            onClicked: root.moveClicked()
        }
        ToolButtonCustom {
            iconText: "🗑️"
            tooltipText: "Удалить выбранное (F8)"
            onClicked: root.deleteClicked()
        }

        Item { Layout.fillWidth: true }

        ToolButtonCustom {
            iconText: "⚙️"
            tooltipText: "Настройки (Ctrl+,)"
            onClicked: root.settingsClicked()
        }

        ToolButtonCustom {
            iconText: "❓"
            tooltipText: "Справка и горячие клавиши (F1)"
            onClicked: root.helpClicked()
        }

        ToolButtonCustom {
            iconText: "💻"
            tooltipText: "Фокус на терминальную строку"
            onClicked: root.terminalClicked()
        }
    }
}
