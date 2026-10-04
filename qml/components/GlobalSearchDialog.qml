import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: searchModal
    anchors.fill: parent
    color: "#cc09090b"
    visible: false
    z: 9999

    property var fsManager
    property string initialPath: ""
    property var searchResults: []

    signal navigateTo(string fullPath)
    signal closed()

    function openAt(path) {
        initialPath = path;
        pathInput.text = path;
        nameInput.text = "";
        textInput.text = "";
        searchResults = [];
        statusText.text = "Введите параметры и нажмите поиск";
        visible = true;
        nameInput.forceActiveFocus();
    }

    function close() {
        visible = false;
        closed();
    }

    function runSearch() {
        statusText.text = "Выполняется поиск...";
        searchResults = [];
        searchTimer.restart();
    }

    Timer {
        id: searchTimer
        interval: 30
        repeat: false
        onTriggered: {
            var res = fsManager.searchFiles(pathInput.text, nameInput.text, textInput.text);
            searchResults = res;
            statusText.text = "Найдено объектов: " + res.length;
        }
    }

    Keys.onEscapePressed: close()

    MouseArea {
        anchors.fill: parent
        onClicked: searchModal.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 820
        height: 580
        color: "#18181b"
        border.color: "#3b82f6"
        border.width: 1
        radius: 8

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Глобальный поиск файлов (Alt+F7)"
                    color: "#60a5fa"
                    font.bold: true
                    font.pixelSize: 15
                    Layout.fillWidth: true
                }
                Text {
                    text: "[Esc для закрытия]"
                    color: "#71717a"
                    font.pixelSize: 11
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#27272a" }

            GridLayout {
                columns: 3
                rowSpacing: 8
                columnSpacing: 10
                Layout.fillWidth: true

                Text { text: "Каталог:"; color: "#d4d4d8"; font.pixelSize: 12 }
                TextField {
                    id: pathInput
                    Layout.fillWidth: true
                    color: "#ffffff"
                    background: Rectangle { color: "#27272a"; radius: 4; border.color: pathInput.activeFocus ? "#3b82f6" : "#3f3f46" }
                }
                Item { width: 100 }

                Text { text: "Имя файла:"; color: "#d4d4d8"; font.pixelSize: 12 }
                TextField {
                    id: nameInput
                    placeholderText: "Например: *.cpp или имя файла..."
                    placeholderTextColor: "#52525b"
                    Layout.fillWidth: true
                    color: "#ffffff"
                    background: Rectangle { color: "#27272a"; radius: 4; border.color: nameInput.activeFocus ? "#3b82f6" : "#3f3f46" }
                    Keys.onReturnPressed: searchModal.runSearch()
                }
                Button {
                    text: "Искать"
                    highlighted: true
                    onClicked: searchModal.runSearch()
                }

                Text { text: "Текст внутри:"; color: "#d4d4d8"; font.pixelSize: 12 }
                TextField {
                    id: textInput
                    placeholderText: "Искать текст внутри файлов (опционально)..."
                    placeholderTextColor: "#52525b"
                    Layout.fillWidth: true
                    color: "#ffffff"
                    background: Rectangle { color: "#27272a"; radius: 4; border.color: textInput.activeFocus ? "#3b82f6" : "#3f3f46" }
                    Keys.onReturnPressed: searchModal.runSearch()
                }
                Text {
                    id: statusText
                    text: "Готов к поиску"
                    color: "#71717a"
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#1f1f23"
                radius: 4
                border.color: "#27272a"
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        height: 22
                        Text { text: "Имя файла / Путь"; color: "#71717a"; font.bold: true; font.pixelSize: 11; Layout.fillWidth: true }
                        Text { text: "Размер"; color: "#71717a"; font.bold: true; font.pixelSize: 11; width: 80; horizontalAlignment: Text.AlignRight }
                        Text { text: "Изменен"; color: "#71717a"; font.bold: true; font.pixelSize: 11; width: 110; horizontalAlignment: Text.AlignRight }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#27272a" }

                    ListView {
                        id: resultsList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: searchModal.searchResults

                        delegate: Rectangle {
                            width: resultsList.width
                            height: 26
                            color: ListView.isCurrentItem ? "#3b82f6" : (index % 2 === 0 ? "transparent" : "#27272a")
                            radius: 3

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 6

                                Text {
                                    text: (modelData.isDir ? "📁 " : "📄 ") + modelData.path
                                    color: ListView.isCurrentItem ? "#ffffff" : "#d4d4d8"
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: modelData.size
                                    color: ListView.isCurrentItem ? "#dbeafe" : "#71717a"
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignRight
                                    width: 80
                                }
                                Text {
                                    text: modelData.modified
                                    color: ListView.isCurrentItem ? "#dbeafe" : "#71717a"
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignRight
                                    width: 110
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: resultsList.currentIndex = index
                                onDoubleClicked: {
                                    searchModal.navigateTo(modelData.path);
                                    searchModal.close();
                                }
                            }
                        }

                        Keys.onReturnPressed: {
                            if (currentIndex >= 0 && currentIndex < searchResults.length) {
                                searchModal.navigateTo(searchResults[currentIndex].path);
                                searchModal.close();
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Двойной клик или Enter — перейти к файлу в панели"
                    color: "#71717a"
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Закрыть"
                    onClicked: searchModal.close()
                }
            }
        }
    }
}