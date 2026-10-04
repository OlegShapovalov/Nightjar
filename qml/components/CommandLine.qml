import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: cmdBox
    property string activePath: ""
    property var history: []
    property int historyIdx: -1

    signal executeCommand(string command)
    signal escapePressed()

    function focusInput() {
        cmdInput.forceActiveFocus();
    }

    height: 32
    color: "#27272a"
    radius: 6
    border.color: cmdInput.activeFocus ? "#3b82f6" : "#3f3f46"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 6

        Text {
            text: cmdBox.activePath + "$ "
            color: "#3b82f6"
            font.family: "monospace"
            font.bold: true
            font.pixelSize: 12
            elide: Text.ElideMiddle
            Layout.maximumWidth: 320
        }

        TextField {
            id: cmdInput
            Layout.fillWidth: true
            placeholderText: "Введите команду терминала..."
            placeholderTextColor: "#52525b"
            color: "#ffffff"
            font.family: "monospace"
            font.pixelSize: 12
            background: null
            selectByMouse: true

            Keys.onReturnPressed: {
                var cmd = cmdInput.text.trim();
                if (cmd !== "") {
                    cmdBox.history.push(cmd);
                    cmdBox.historyIdx = cmdBox.history.length;
                    cmdBox.executeCommand(cmd);
                    cmdInput.text = "";
                }
            }

            Keys.onEscapePressed: {
                cmdInput.text = "";
                cmdBox.escapePressed();
            }

            Keys.onUpPressed: {
                if (cmdBox.history.length > 0 && cmdBox.historyIdx > 0) {
                    cmdBox.historyIdx--;
                    cmdInput.text = cmdBox.history[cmdBox.historyIdx];
                }
            }

            Keys.onDownPressed: {
                if (cmdBox.historyIdx < cmdBox.history.length - 1) {
                    cmdBox.historyIdx++;
                    cmdInput.text = cmdBox.history[cmdBox.historyIdx];
                } else {
                    cmdBox.historyIdx = cmdBox.history.length;
                    cmdInput.text = "";
                }
            }
        }
    }
}
