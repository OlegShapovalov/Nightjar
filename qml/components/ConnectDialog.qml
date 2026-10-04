import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: connectModal
    anchors.fill: parent
    color: "#cc000000"
    visible: false
    z: 9999

    property var theme
    property var fsManager
    signal connected(string targetPath)
    signal closed()

    function openDialog() {
        hostInput.text = fsManager.getSetting("lastSshHost", "192.168.1.135");
        portInput.text = String(fsManager.getSetting("lastSshPort", 1234));
        userInput.text = fsManager.getSetting("lastSshUser", "user");
        passInput.text = "";
        pathInput.text = "/";
        statusText.text = "";
        busyIndicator.running = false;
        connectBtn.enabled = true;

        visible = true;
        hostInput.forceActiveFocus();
    }

    function close() {
        visible = false;
        closed();
    }

    function startConnect() {
        var h = hostInput.text.trim();
        var u = userInput.text.trim();
        var p = parseInt(portInput.text.trim());
        var pwd = passInput.text;
        var rPath = pathInput.text.trim();

        if (h === "" || u === "") {
            statusText.text = "Укажите хост и имя пользователя!";
            return;
        }

        // Сохраняем для удобства
        fsManager.saveSetting("lastSshHost", h);
        fsManager.saveSetting("lastSshPort", p);
        fsManager.saveSetting("lastSshUser", u);

        statusText.text = "Подключение к " + u + "@" + h + "...";
        busyIndicator.running = true;
        connectBtn.enabled = false;

        fsManager.mountSsh(h, p, u, pwd, rPath);
    }

    Connections {
        target: fsManager
        function onSshMountFinished(success, mountPath, errorMessage) {
            busyIndicator.running = false;
            connectBtn.enabled = true;
            if (success) {
                connectModal.connected(mountPath);
                connectModal.close();
            } else {
                statusText.text = errorMessage;
            }
        }
    }

    Keys.onEscapePressed: close()

    MouseArea {
        anchors.fill: parent
        onClicked: connectModal.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 480
        height: 420
        color: connectModal.theme ? connectModal.theme.bgSurface : "#1f1f23"
        border.color: connectModal.theme ? connectModal.theme.accent : "#3b82f6"
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
                    text: "🌐 Подключение к серверу (SSH / SFTP)"
                    color: connectModal.theme ? connectModal.theme.accent : "#3b82f6"
                    font.bold: true
                    font.pixelSize: 15
                    Layout.fillWidth: true
                }
                Text {
                    text: "[Esc для отмены]"
                    color: connectModal.theme ? connectModal.theme.textSecondary : "#71717a"
                    font.pixelSize: 11
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: connectModal.theme ? connectModal.theme.border : "#27272a" }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                // Хост и Порт
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Хост / IP-адрес"; color: connectModal.theme ? connectModal.theme.textPrimary : "#ffffff"; font.pixelSize: 12 }
                        TextField {
                            id: hostInput
                            Layout.fillWidth: true
                            placeholderText: "например: 192.168.1.135"
                            placeholderTextColor: connectModal.theme ? connectModal.theme.textSecondary : "#71717a"
                            color: connectModal.theme ? connectModal.theme.textPrimary : "#ffffff"
                            background: Rectangle {
                                color: connectModal.theme ? connectModal.theme.bgInput : "#27272a"
                                radius: 4
                                border.color: hostInput.activeFocus ? (connectModal.theme ? connectModal.theme.accent : "#3b82f6") : (connectModal.theme ? connectModal.theme.border : "#27272a")
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 90
                        spacing: 2
                        Text { text: "Порт"; color: connectModal.theme ? connectModal.theme.textPrimary : "#ffffff"; font.pixelSize: 12 }
                        TextField {
                            id: portInput
                            Layout.fillWidth: true
                            text: "22"
                            placeholderTextColor: connectModal.theme ? connectModal.theme.textSecondary : "#71717a"
                            color: connectModal.theme ? connectModal.theme.textPrimary : "#ffffff"
                            background: Rectangle {
                                color: connectModal.theme ? connectModal.theme.bgInput : "#27272a"
                                radius: 4
                                border.color: portInput.activeFocus ? (connectModal.theme ? connectModal.theme.accent : "#3b82f6") : (connectModal.theme ? connectModal.theme.border : "#27272a")
                            }
                        }
                    }
                }

                // Пользователь
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Имя пользователя"; color: connectModal.theme ? connectModal.theme.textPrimary : "#ffffff"; font.pixelSize: 12 }
                    TextField {
                        id: userInput
                        Layout.fillWidth: true
                        placeholderText: "user"
                        placeholderTextColor: connectModal.theme ? connectModal.theme.textSecondary : "#71717a"
                        color: connectModal.theme ? connectModal.theme.textPrimary : "#ffffff"
                        background: Rectangle {
                            color: connectModal.theme ? connectModal.theme.bgInput : "#27272a"
                            radius: 4
                            border.color: userInput.activeFocus ? (connectModal.theme ? connectModal.theme.accent : "#3b82f6") : (connectModal.theme ? connectModal.theme.border : "#27272a")
                        }
                    }
                }

                // Пароль
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Пароль (оставьте пустым для SSH-ключа)"; color: connectModal.theme ? connectModal.theme.textPrimary : "#ffffff"; font.pixelSize: 12 }
                    TextField {
                        id: passInput
                        Layout.fillWidth: true
                        echoMode: TextInput.Password
                        placeholderText: "Пароль"
                        placeholderTextColor: connectModal.theme ? connectModal.theme.textSecondary : "#71717a"
                        color: connectModal.theme ? connectModal.theme.textPrimary : "#ffffff"
                        background: Rectangle {
                            color: connectModal.theme ? connectModal.theme.bgInput : "#27272a"
                            radius: 4
                            border.color: passInput.activeFocus ? (connectModal.theme ? connectModal.theme.accent : "#3b82f6") : (connectModal.theme ? connectModal.theme.border : "#27272a")
                        }
                    }
                }

                // Удалённая папка
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: "Удалённый путь"; color: connectModal.theme ? connectModal.theme.textPrimary : "#ffffff"; font.pixelSize: 12 }
                    TextField {
                        id: pathInput
                        Layout.fillWidth: true
                        text: "/"
                        placeholderTextColor: connectModal.theme ? connectModal.theme.textSecondary : "#71717a"
                        color: connectModal.theme ? connectModal.theme.textPrimary : "#ffffff"
                        background: Rectangle {
                            color: connectModal.theme ? connectModal.theme.bgInput : "#27272a"
                            radius: 4
                            border.color: pathInput.activeFocus ? (connectModal.theme ? connectModal.theme.accent : "#3b82f6") : (connectModal.theme ? connectModal.theme.border : "#27272a")
                        }
                    }
                }
            }

            // Статус и индикатор загрузки
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                BusyIndicator {
                    id: busyIndicator
                    running: false
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                }
                Text {
                    id: statusText
                    Layout.fillWidth: true
                    color: "#f87171"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Item { Layout.fillWidth: true }
                Button {
                    text: "Отмена"
                    onClicked: connectModal.close()
                }
                Button {
                    id: connectBtn
                    text: "Подключить"
                    highlighted: true
                    onClicked: connectModal.startConnect()
                }
            }
        }
    }
}
