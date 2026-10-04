import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: helpRoot
    anchors.fill: parent
    color: "#cc09090b"
    visible: false
    z: 9999

    signal closed()

    function open() {
        visible = true;
        forceActiveFocus();
    }

    function close() {
        visible = false;
        closed();
    }

    Keys.onEscapePressed: close()
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_F1) {
            close();
            event.accepted = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: helpRoot.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 620
        height: 480
        color: "#18181b"
        border.color: "#3b82f6"
        border.width: 1
        radius: 8

        MouseArea { anchors.fill: parent } // перехват клика внутри карточки

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Горячие клавиши Nightjar"
                    color: "#60a5fa"
                    font.bold: true
                    font.pixelSize: 16
                    Layout.fillWidth: true
                }
                Text {
                    text: "[Esc / F1 для закрытия]"
                    color: "#71717a"
                    font.pixelSize: 11
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#27272a" }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 16
                    width: parent.width

                    component KeyBadge: RowLayout {
                        property string keyName: ""
                        property string desc: ""
                        spacing: 8

                        Rectangle {
                            height: 24
                            implicitWidth: kText.implicitWidth + 12
                            radius: 4
                            color: "#27272a"
                            border.color: "#3f3f46"
                            border.width: 1

                            Text {
                                id: kText
                                anchors.centerIn: parent
                                text: keyName
                                color: "#3b82f6"
                                font.bold: true
                                font.family: "monospace"
                                font.pixelSize: 11
                            }
                        }

                        Text {
                            text: desc
                            color: "#d4d4d8"
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                    }

                    // Навигация и выделение
                    KeyBadge { keyName: "Tab"; desc: "Переключить активную панель" }
                    KeyBadge { keyName: "ПКМ + Протяжка"; desc: "Выделение группы файлов мышью" }
                    KeyBadge { keyName: "Insert"; desc: "Выделить текущий файл/папку" }
                    KeyBadge { keyName: "Space"; desc: "Вычислить точный размер папки" }
                    KeyBadge { keyName: "Печать букв"; desc: "Живой поиск (Quick Search)" }
                    KeyBadge { keyName: "Esc"; desc: "Сбросить поисковый фильтр" }

                    // Вкладки
                    KeyBadge { keyName: "Ctrl+T"; desc: "Открыть новую вкладку каталога" }
                    KeyBadge { keyName: "Ctrl+W / СКМ"; desc: "Закрыть текущую вкладку" }

                    // Буфер обмена
                    KeyBadge { keyName: "Ctrl+Shift+C"; desc: "Копировать абсолютные пути файлов" }
                    KeyBadge { keyName: "Alt+C / Ctrl+P"; desc: "Копировать только имена файлов" }

                    // Операции
                    KeyBadge { keyName: "F3"; desc: "Быстрый просмотр содержимого (Quick Look)" }
                    KeyBadge { keyName: "F4"; desc: "Редактирование в $EDITOR / $VISUAL" }
                    KeyBadge { keyName: "F5"; desc: "Копирование в противоположную панель" }
                    KeyBadge { keyName: "F6"; desc: "Перемещение в противоположную панель" }
                    KeyBadge { keyName: "F7"; desc: "Создать новую папку" }
                    KeyBadge { keyName: "F8"; desc: "Удалить выбранные объекты" }

                    // Архивация
                    KeyBadge { keyName: "Alt+F5"; desc: "Упаковать в .tar.gz или .zip" }
                    KeyBadge { keyName: "Alt+F9"; desc: "Распаковать архив в соседнюю панель" }
                }
            }
        }
    }
}