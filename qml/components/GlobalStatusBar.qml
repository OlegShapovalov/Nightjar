import QtQuick
import QtQuick.Layouts

Rectangle {
    id: statusRoot
    property string activePath: ""
    property int selectedCount: 0
    property int totalCount: 0
    property string diskInfo: ""

    height: 24
    color: "#18181b"
    border.color: "#27272a"
    border.width: 1
    radius: 4

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        // Индикатор фокуса
        RowLayout {
            spacing: 6
            Rectangle {
                width: 7
                height: 7
                radius: 4
                color: "#10b981"
            }
            Text {
                text: "Nightjar"
                color: "#71717a"
                font.bold: true
                font.pixelSize: 11
            }
        }

        Rectangle { width: 1; height: 12; color: "#27272a" }

        // Выделение
        Text {
            text: statusRoot.selectedCount > 0 ? 
                  ("Выбрано: " + statusRoot.selectedCount + " из " + statusRoot.totalCount) : 
                  ("Всего объектов: " + statusRoot.totalCount)
            color: statusRoot.selectedCount > 0 ? "#fbbf24" : "#a1a1aa"
            font.pixelSize: 11
            font.bold: statusRoot.selectedCount > 0
        }

        Item { Layout.fillWidth: true } // пружина

        // Место на диске
        Text {
            text: statusRoot.diskInfo
            color: "#71717a"
            font.pixelSize: 11
            font.family: "monospace"
        }
    }
}