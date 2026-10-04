import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia

Rectangle {
    id: previewModal
    anchors.fill: parent
    color: "#e609090b"
    visible: false
    z: 9999

    property string fileName: ""
    property string filePath: ""
    property string fileType: "text" // "image", "audio", "office", "text"
    property var fsManager

    signal closed()

    function show(name, path, fsMgr) {
        fileName = name;
        filePath = path;
        fsManager = fsMgr;

        var lower = name.toLowerCase();
        var dotIdx = lower.lastIndexOf(".");
        var ext = dotIdx !== -1 ? lower.substring(dotIdx + 1) : "";

        // Определение типа файла
        var imgExts = ["png", "jpg", "jpeg", "svg", "webp", "gif", "bmp", "ico"];
        var audioExts = ["mp3", "wav", "ogg", "flac", "aac", "m4a"];
        var officeExts = ["doc", "docx", "xls", "xlsx", "ppt", "pptx", "odt", "ods", "odp", "pdf", "rtf"];

        if (imgExts.indexOf(ext) !== -1) {
            fileType = "image";
            imgView.source = "file://" + path;
        } else if (audioExts.indexOf(ext) !== -1) {
            fileType = "audio";
            player.source = "file://" + path;
            player.play();
        } else if (officeExts.indexOf(ext) !== -1) {
            fileType = "office";
        } else {
            fileType = "text";
            textContent.text = fsManager.readFilePreview(path);
        }

        visible = true;
        previewModal.forceActiveFocus();
    }

    function close() {
        if (player.playbackState === MediaPlayer.PlayingState) {
            player.stop();
        }
        player.source = "";
        imgView.source = "";
        textContent.text = "";
        visible = false;
        closed();
    }

    function formatTime(ms) {
        var totalSec = Math.floor(ms / 1000);
        var m = Math.floor(totalSec / 60);
        var s = totalSec % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    Keys.onEscapePressed: close()
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_F3) {
            close();
            event.accepted = true;
        } else if (event.key === Qt.Key_Space && fileType === "audio") {
            if (player.playbackState === MediaPlayer.PlayingState) {
                player.pause();
            } else {
                player.play();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Return && fileType === "office") {
            if (fsManager) fsManager.openFile(filePath);
            close();
            event.accepted = true;
        }
    }

    // Аудиодвижок
    MediaPlayer {
        id: player
        audioOutput: AudioOutput {
            id: audioOut
            volume: 1.0
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: previewModal.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.92, 1100)
        height: Math.min(parent.height * 0.90, 780)
        color: "#18181b"
        border.color: "#3b82f6"
        border.width: 1
        radius: 8

        MouseArea { anchors.fill: parent } // перехват клика внутри контейнера

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // Верхняя шапка
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 22
                    height: 22
                    radius: 4
                    color: "#27272a"
                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (previewModal.fileType === "image") return "🖼️";
                            if (previewModal.fileType === "audio") return "🎵";
                            if (previewModal.fileType === "office") return "📑";
                            return "📝";
                        }
                        font.pixelSize: 12
                    }
                }

                Text {
                    text: previewModal.fileName
                    color: "#60a5fa"
                    font.bold: true
                    font.pixelSize: 14
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }

                Text {
                    text: "[Esc / F3 для закрытия]"
                    color: "#71717a"
                    font.pixelSize: 11
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#27272a" }

            // Контентная область
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // 1. Просмотр изображений
                ColumnLayout {
                    anchors.fill: parent
                    visible: previewModal.fileType === "image"
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#121214"
                        radius: 6
                        clip: true

                        Image {
                            id: imgView
                            anchors.fill: parent
                            anchors.margins: 10
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                            mipmap: true
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: imgView.status === Image.Ready ? 
                                  ("Разрешение: " + imgView.sourceSize.width + " × " + imgView.sourceSize.height + " px") : 
                                  "Загрузка изображения..."
                            color: "#a1a1aa"
                            font.pixelSize: 11
                        }
                    }
                }

                // 2. Аудиоплеер
                Item {
                    anchors.fill: parent
                    visible: previewModal.fileType === "audio"

                    Rectangle {
                        anchors.centerIn: parent
                        width: 480
                        height: 260
                        color: "#1f1f23"
                        radius: 8
                        border.color: "#27272a"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 16

                            // Анимированная иконка пластинки
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 72
                                height: 72
                                radius: 36
                                color: "#27272a"
                                border.color: player.playbackState === MediaPlayer.PlayingState ? "#3b82f6" : "#3f3f46"
                                border.width: 2

                                Text {
                                    anchors.centerIn: parent
                                    text: "🎧"
                                    font.pixelSize: 32
                                }
                            }

                            Text {
                                text: previewModal.fileName
                                color: "#f4f4f5"
                                font.bold: true
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }

                            // Полоса воспроизведения (слайдер)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Slider {
                                    id: audioSlider
                                    Layout.fillWidth: true
                                    from: 0
                                    to: player.duration > 0 ? player.duration : 100
                                    value: player.position
                                    onMoved: player.setPosition(value)
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: previewModal.formatTime(player.position)
                                        color: "#71717a"
                                        font.family: "monospace"
                                        font.pixelSize: 11
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: previewModal.formatTime(player.duration)
                                        color: "#71717a"
                                        font.family: "monospace"
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            // Кнопки управления
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 14

                                Button {
                                    text: player.playbackState === MediaPlayer.PlayingState ? "⏸️ Пауза" : "▶️ Воспроизвести"
                                    highlighted: true
                                    onClicked: {
                                        if (player.playbackState === MediaPlayer.PlayingState) {
                                            player.pause();
                                        } else {
                                            player.play();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // 3. Карточка офисных документов
                Item {
                    anchors.fill: parent
                    visible: previewModal.fileType === "office"

                    Rectangle {
                        anchors.centerIn: parent
                        width: 440
                        height: 220
                        color: "#1f1f23"
                        radius: 8
                        border.color: "#27272a"
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 14

                            Text {
                                text: "📄"
                                font.pixelSize: 42
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Внешний документ / Офисный файл"
                                color: "#f4f4f5"
                                font.bold: true
                                font.pixelSize: 14
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "Для просмотра и редактирования нажмите кнопку ниже или клавишу Enter"
                                color: "#a1a1aa"
                                font.pixelSize: 12
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Button {
                                text: "Открыть в системном приложении (Enter)"
                                highlighted: true
                                Layout.alignment: Qt.AlignHCenter
                                onClicked: {
                                    if (previewModal.fsManager) {
                                        previewModal.fsManager.openFile(previewModal.filePath);
                                    }
                                    previewModal.close();
                                }
                            }
                        }
                    }
                }

                // 4. Текстовый просмотрщик (код, markdown, логи)
                ScrollView {
                    anchors.fill: parent
                    visible: previewModal.fileType === "text"
                    clip: true

                    TextArea {
                        id: textContent
                        readOnly: true
                        selectByMouse: true
                        color: "#e4e4e7"
                        selectionColor: "#2563eb"
                        selectedTextColor: "#ffffff"
                        font.family: "monospace"
                        font.pixelSize: 12
                        wrapMode: TextArea.Wrap
                        background: Rectangle {
                            color: "#121214"
                            radius: 4
                        }
                    }
                }
            }
        }
    }
}
