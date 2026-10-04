import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: settingsModal
    anchors.fill: parent
    color: "#cc000000"
    visible: false
    z: 9999

    property var fsManager
    property var theme
    signal settingsChanged()
    signal closed()

    function openSettings() {
        showHiddenSwitch.checked = Boolean(fsManager.getSetting("showHidden", false));
        confirmDeleteSwitch.checked = Boolean(fsManager.getSetting("confirmDelete", true));
        fontSizeCombo.currentIndex = Number(fsManager.getSetting("fontSizeIndex", 1));
        themeCombo.currentIndex = Number(fsManager.getSetting("themeIndex", 0));
        editorInput.text = String(fsManager.getSetting("customEditor", ""));

        var fontList = fsManager.getAvailableFonts();
        fontCombo.model = fontList;
        var savedFont = String(fsManager.getSetting("fontFamily", ""));
        var foundIdx = 0;
        for (var i = 0; i < fontList.length; i++) {
            if (fontList[i] === savedFont) {
                foundIdx = i;
                break;
            }
        }
        fontCombo.currentIndex = foundIdx;

        visible = true;
        settingsModal.forceActiveFocus();
    }

    function saveAndClose() {
        fsManager.saveSetting("showHidden", Boolean(showHiddenSwitch.checked));
        fsManager.saveSetting("confirmDelete", Boolean(confirmDeleteSwitch.checked));
        fsManager.saveSetting("fontSizeIndex", Number(fontSizeCombo.currentIndex));
        fsManager.saveSetting("themeIndex", Number(themeCombo.currentIndex));
        fsManager.saveSetting("customEditor", String(editorInput.text.trim()));
        
        var selectedFont = fontCombo.currentIndex > 0 ? fontCombo.currentText : "";
        fsManager.saveSetting("fontFamily", selectedFont);

        settingsChanged();
        close();
    }

    function close() {
        visible = false;
        closed();
    }

    Keys.onEscapePressed: close()

    MouseArea {
        anchors.fill: parent
        onClicked: settingsModal.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 580
        height: 520
        color: settingsModal.theme ? settingsModal.theme.bgSurface : "#1f1f23"
        border.color: settingsModal.theme ? settingsModal.theme.accent : "#3b82f6"
        border.width: 1
        radius: 8

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Настройки Nightjar"
                    color: settingsModal.theme ? settingsModal.theme.accent : "#3b82f6"
                    font.bold: true
                    font.pixelSize: 15
                    Layout.fillWidth: true
                }
                Text {
                    text: "[Esc для отмены]"
                    color: settingsModal.theme ? settingsModal.theme.textSecondary : "#71717a"
                    font.pixelSize: 11
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: settingsModal.theme ? settingsModal.theme.border : "#27272a" }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                // Тема оформления
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text { text: "Тема оформления"; color: settingsModal.theme ? settingsModal.theme.textPrimary : "#ffffff"; font.pixelSize: 13 }
                        Text { text: "Пресеты палитры или следование за темой системы"; color: settingsModal.theme ? settingsModal.theme.textSecondary : "#71717a"; font.pixelSize: 11 }
                    }
                    ComboBox {
                        id: themeCombo
                        model: [
                            "Nightjar Dark",
                            "Catppuccin Mocha",
                            "Dracula",
                            "Monokai Pro",
                            "Clean Light",
                            "Системная тема (Auto)"
                        ]
                        Layout.preferredWidth: 190
                    }
                }

                // Семейство шрифта
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text { text: "Шрифт файловых списков"; color: settingsModal.theme ? settingsModal.theme.textPrimary : "#ffffff"; font.pixelSize: 13 }
                        Text { text: "Системные моноширинные шрифты Arch Linux"; color: settingsModal.theme ? settingsModal.theme.textSecondary : "#71717a"; font.pixelSize: 11 }
                    }
                    ComboBox {
                        id: fontCombo
                        Layout.preferredWidth: 190
                    }
                }

                // Размер шрифта
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text { text: "Размер шрифта в списках"; color: settingsModal.theme ? settingsModal.theme.textPrimary : "#ffffff"; font.pixelSize: 13 }
                        Text { text: "Масштаб элементов в панелях файлов"; color: settingsModal.theme ? settingsModal.theme.textSecondary : "#71717a"; font.pixelSize: 11 }
                    }
                    ComboBox {
                        id: fontSizeCombo
                        model: ["Мелкий (11px)", "Средний (12px)", "Крупный (14px)"]
                        Layout.preferredWidth: 190
                    }
                }

                // Показывать скрытые файлы
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text { text: "Показывать скрытые файлы"; color: settingsModal.theme ? settingsModal.theme.textPrimary : "#ffffff"; font.pixelSize: 13 }
                        Text { text: "Отображать файлы и папки с точкой (.)"; color: settingsModal.theme ? settingsModal.theme.textSecondary : "#71717a"; font.pixelSize: 11 }
                    }
                    Switch { id: showHiddenSwitch }
                }

                // Подтверждение удаления
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true
                        Text { text: "Подтверждение удаления (F8)"; color: settingsModal.theme ? settingsModal.theme.textPrimary : "#ffffff"; font.pixelSize: 13 }
                        Text { text: "Запрашивать диалог перед удалением"; color: settingsModal.theme ? settingsModal.theme.textSecondary : "#71717a"; font.pixelSize: 11 }
                    }
                    Switch { id: confirmDeleteSwitch }
                }

                // Кастомный редактор
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text { text: "Команда редактора файлов (F4)"; color: settingsModal.theme ? settingsModal.theme.textPrimary : "#ffffff"; font.pixelSize: 13 }
                    TextField {
                        id: editorInput
                        Layout.fillWidth: true
                        placeholderText: "Оставьте пустым для $EDITOR или укажите: nvim, code, kate..."
                        placeholderTextColor: settingsModal.theme ? settingsModal.theme.textSecondary : "#71717a"
                        color: settingsModal.theme ? settingsModal.theme.textPrimary : "#ffffff"
                        background: Rectangle {
                            color: settingsModal.theme ? settingsModal.theme.bgInput : "#27272a"
                            radius: 4
                            border.color: editorInput.activeFocus ? (settingsModal.theme ? settingsModal.theme.accent : "#3b82f6") : (settingsModal.theme ? settingsModal.theme.border : "#27272a")
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }
                Button {
                    text: "Отмена"
                    onClicked: settingsModal.close()
                }
                Button {
                    text: "Сохранить"
                    highlighted: true
                    onClicked: settingsModal.saveAndClose()
                }
            }
        }
    }
}
