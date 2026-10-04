import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: renameModal
    anchors.fill: parent
    color: "#cc09090b"
    visible: false
    z: 9999

    property var rawFiles: []
    property var previewModel: []
    property var fsManager

    signal applied()
    signal closed()

    function openWithFiles(files) {
        rawFiles = files.filter(f => f.name !== "..");
        if (rawFiles.length === 0) return;

        patternInput.text = "[N]";
        findInput.text = "";
        replaceInput.text = "";
        startCounter.value = 1;
        stepCounter.value = 1;
        digitsCounter.value = 2;

        updatePreview();
        visible = true;
        patternInput.forceActiveFocus();
    }

    function close() {
        visible = false;
        closed();
    }

    function updatePreview() {
        var res = [];
        var start = startCounter.value;
        var step = stepCounter.value;
        var digits = digitsCounter.value;
        var pat = patternInput.text;
        var findTxt = findInput.text;
        var repTxt = replaceInput.text;

        for (var i = 0; i < rawFiles.length; i++) {
            var origName = rawFiles[i].name;
            var dirPath = rawFiles[i].path.substring(0, rawFiles[i].path.lastIndexOf("/"));

            var dotIdx = origName.lastIndexOf(".");
            var baseName = (dotIdx > 0) ? origName.substring(0, dotIdx) : origName;
            var ext = (dotIdx > 0) ? origName.substring(dotIdx + 1) : "";

            var num = start + i * step;
            var numStr = String(num);
            while (numStr.length < digits) {
                numStr = "0" + numStr;
            }

            var out = pat.replace(/\[N\]/g, baseName)
                         .replace(/\[C\]/g, numStr)
                         .replace(/\[E\]/g, ext);

            if (ext.length > 0 && pat.indexOf("[E]") === -1) {
                out += "." + ext;
            }

            if (findTxt.length > 0) {
                out = out.split(findTxt).join(repTxt);
            }

            res.push({
                oldName: origName,
                newName: out,
                oldPath: rawFiles[i].path,
                newPath: dirPath + "/" + out
            });
        }
        previewModel = res;
    }

    Keys.onEscapePressed: close()

    MouseArea {
        anchors.fill: parent
        onClicked: renameModal.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 780
        height: 540
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
                    text: "Групповое переименование (Multi-Rename)"
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
                columns: 4
                rowSpacing: 8
                columnSpacing: 12
                Layout.fillWidth: true

                Text { text: "Маска имени:"; color: "#d4d4d8"; font.pixelSize: 12 }
                TextField {
                    id: patternInput
                    text: "[N]"
                    Layout.fillWidth: true
                    color: "#ffffff"
                    background: Rectangle { color: "#27272a"; radius: 4; border.color: patternInput.activeFocus ? "#3b82f6" : "#3f3f46" }
                    onTextChanged: renameModal.updatePreview()
                }

                RowLayout {
                    Layout.columnSpan: 2
                    spacing: 4
                    Button {
                        text: "[N] Имя"
                        onClicked: { patternInput.text += "[N]"; patternInput.forceActiveFocus(); }
                    }
                    Button {
                        text: "[C] Счётчик"
                        onClicked: { patternInput.text += "[C]"; patternInput.forceActiveFocus(); }
                    }
                    Button {
                        text: "[E] Расширение"
                        onClicked: { patternInput.text += "[E]"; patternInput.forceActiveFocus(); }
                    }
                }

                Text { text: "Найти:"; color: "#d4d4d8"; font.pixelSize: 12 }
                TextField {
                    id: findInput
                    placeholderText: "Что заменить..."
                    placeholderTextColor: "#52525b"
                    Layout.fillWidth: true
                    color: "#ffffff"
                    background: Rectangle { color: "#27272a"; radius: 4; border.color: findInput.activeFocus ? "#3b82f6" : "#3f3f46" }
                    onTextChanged: renameModal.updatePreview()
                }

                Text { text: "Заменить на:"; color: "#d4d4d8"; font.pixelSize: 12 }
                TextField {
                    id: replaceInput
                    placeholderText: "На что..."
                    placeholderTextColor: "#52525b"
                    Layout.fillWidth: true
                    color: "#ffffff"
                    background: Rectangle { color: "#27272a"; radius: 4; border.color: replaceInput.activeFocus ? "#3b82f6" : "#3f3f46" }
                    onTextChanged: renameModal.updatePreview()
                }

                Text { text: "Параметры [C]:"; color: "#d4d4d8"; font.pixelSize: 12 }
                RowLayout {
                    Layout.columnSpan: 3
                    spacing: 12

                    Text { text: "Старт:"; color: "#a1a1aa"; font.pixelSize: 11 }
                    SpinBox {
                        id: startCounter
                        from: 0; to: 9999; value: 1
                        onValueChanged: renameModal.updatePreview()
                    }

                    Text { text: "Шаг:"; color: "#a1a1aa"; font.pixelSize: 11 }
                    SpinBox {
                        id: stepCounter
                        from: 1; to: 100; value: 1
                        onValueChanged: renameModal.updatePreview()
                    }

                    Text { text: "Знаков:"; color: "#a1a1aa"; font.pixelSize: 11 }
                    SpinBox {
                        id: digitsCounter
                        from: 1; to: 6; value: 2
                        onValueChanged: renameModal.updatePreview()
                    }
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
                        Text { text: "Старое имя"; color: "#71717a"; font.bold: true; font.pixelSize: 11; Layout.fillWidth: true }
                        Text { text: "→"; color: "#3b82f6"; font.bold: true; font.pixelSize: 11; width: 24; horizontalAlignment: Text.AlignHCenter }
                        Text { text: "Новое имя"; color: "#60a5fa"; font.bold: true; font.pixelSize: 11; Layout.fillWidth: true }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: "#27272a" }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: renameModal.previewModel

                        delegate: Rectangle {
                            width: parent.width
                            height: 24
                            color: index % 2 === 0 ? "transparent" : "#27272a"
                            radius: 3

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 4

                                Text {
                                    text: modelData.oldName
                                    color: "#a1a1aa"
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "→"
                                    color: "#52525b"
                                    font.pixelSize: 11
                                    width: 24
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    text: modelData.newName
                                    color: modelData.oldName !== modelData.newName ? "#34d399" : "#e4e4e7"
                                    font.bold: modelData.oldName !== modelData.newName
                                    font.family: "monospace"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                Button {
                    text: "Отмена"
                    onClicked: renameModal.close()
                }

                Button {
                    text: "Выполнить переименование"
                    highlighted: true
                    onClicked: {
                        if (renameModal.previewModel.length > 0) {
                            fsManager.renameItems(renameModal.previewModel);
                            renameModal.applied();
                            renameModal.close();
                        }
                    }
                }
            }
        }
    }
}