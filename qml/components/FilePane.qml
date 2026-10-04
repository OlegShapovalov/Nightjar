import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: pane
    color: theme ? theme.bgApp : "#18181b"
    border.color: isActive ? (theme ? theme.accent : "#3b82f6") : (theme ? theme.border : "#27272a")
    border.width: 1
    radius: 6

    property var theme
    property bool isActive: false
    property string currentPath: ""
    property var fsManager
    property string sortBy: "name"
    property bool sortAsc: true
    property string diskInfo: ""
    property bool showHidden: false
    property int itemFontSize: 12
    property string paneFontFamily: "monospace"

    property alias list: fileList

    signal activated()
    signal refreshRequested()

    ListModel {
        id: tabsModel
    }

    property int currentTabIndex: 0

    function getDirName(p) {
        if (!p || p === "/") return "/";
        var parts = p.split("/").filter(Boolean);
        return parts.length > 0 ? parts[parts.length - 1] : "/";
    }

    function addNewTab(path) {
        var p = path ? path : currentPath;
        tabsModel.append({ path: p, title: getDirName(p) });
        currentTabIndex = tabsModel.count - 1;
        loadDir(p);
    }

    function closeCurrentTab() {
        if (tabsModel.count > 1) {
            tabsModel.remove(currentTabIndex);
            if (currentTabIndex >= tabsModel.count) {
                currentTabIndex = tabsModel.count - 1;
            }
            loadDir(tabsModel.get(currentTabIndex).path);
        }
    }

    function switchToTab(idx) {
        if (idx >= 0 && idx < tabsModel.count) {
            currentTabIndex = idx;
            loadDir(tabsModel.get(idx).path);
        }
    }

    function loadDir(path) {
        currentPath = path;
        if (tabsModel.count > 0 && currentTabIndex < tabsModel.count) {
            tabsModel.setProperty(currentTabIndex, "path", path);
            tabsModel.setProperty(currentTabIndex, "title", getDirName(path));
        }
        var files = fsManager.readDir(path, sortBy, sortAsc, showHidden);
        fileList.model = files;
        fileList.currentIndex = 0;
        diskInfo = fsManager.getFreeDiskSpace(path);
    }

    function getTabsState() {
        var paths = [];
        for (var i = 0; i < tabsModel.count; i++) {
            paths.push(tabsModel.get(i).path);
        }
        return {
            tabs: paths,
            activeIdx: currentTabIndex
        };
    }

    function restoreTabs(paths, activeIdx) {
        tabsModel.clear();
        if (!paths || paths.length === 0) {
            addNewTab(fsManager.homePath());
            return;
        }
        for (var i = 0; i < paths.length; i++) {
            tabsModel.append({ path: paths[i], title: getDirName(paths[i]) });
        }
        var targetIndex = (activeIdx >= 0 && activeIdx < tabsModel.count) ? activeIdx : 0;
        currentTabIndex = targetIndex;
        loadDir(tabsModel.get(targetIndex).path);
    }

    function toggleSort(type) {
        if (sortBy === type) {
            sortAsc = !sortAsc;
        } else {
            sortBy = type;
            sortAsc = true;
        }
        loadDir(currentPath);
    }

    function getSelectedOrCurrentPaths() {
        var paths = [];
        if (!fileList.model) return paths;
        for (var i = 0; i < fileList.model.length; i++) {
            if (fileList.model[i].selected && fileList.model[i].name !== "..") {
                paths.push(fileList.model[i].path);
            }
        }
        if (paths.length === 0 && fileList.currentIndex >= 0 && fileList.currentIndex < fileList.model.length) {
            var item = fileList.model[fileList.currentIndex];
            if (item.name !== "..") paths.push(item.path);
        }
        return paths;
    }

    function getCurrentItem() {
        if (fileList.model && fileList.currentIndex >= 0 && fileList.currentIndex < fileList.model.length) {
            return fileList.model[fileList.currentIndex];
        }
        return null;
    }

    function getSelectedCount() {
        var count = 0;
        if (!fileList.model) return count;
        for (var i = 0; i < fileList.model.length; i++) {
            if (fileList.model[i].selected && fileList.model[i].name !== "..") count++;
        }
        return count;
    }

    function copyPathsToClipboard() {
        var paths = getSelectedOrCurrentPaths();
        if (paths.length > 0) fsManager.copyToClipboard(paths);
    }

    function copyNamesToClipboard() {
        var names = [];
        if (!fileList.model) return;
        for (var i = 0; i < fileList.model.length; i++) {
            if (fileList.model[i].selected && fileList.model[i].name !== "..") {
                names.push(fileList.model[i].name);
            }
        }
        if (names.length === 0) {
            var cur = getCurrentItem();
            if (cur && cur.name !== "..") names.push(cur.name);
        }
        if (names.length > 0) fsManager.copyToClipboard(names);
    }

    MouseArea {
        anchors.fill: parent
        onPressed: pane.activated()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        // Вкладки
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: pane.theme ? pane.theme.bgApp : "#18181b"

            RowLayout {
                anchors.fill: parent
                spacing: 4

                ListView {
                    id: tabsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    model: tabsModel
                    clip: true
                    spacing: 4

                    delegate: Rectangle {
                        width: Math.min(140, tabText.implicitWidth + 36)
                        height: 26
                        radius: 4
                        color: index === pane.currentTabIndex ? 
                               (pane.isActive ? (pane.theme ? pane.theme.accentActive : "#2563eb") : (pane.theme ? pane.theme.border : "#3f3f46")) : 
                               (pane.theme ? pane.theme.bgSurface : "#27272a")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            spacing: 4

                            Text {
                                id: tabText
                                text: model.title
                                color: "#ffffff"
                                font.pixelSize: 11
                                font.bold: index === pane.currentTabIndex
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "×"
                                color: closeMouse.containsMouse ? "#ef4444" : "#a1a1aa"
                                font.bold: true
                                font.pixelSize: 13
                                visible: tabsModel.count > 1

                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        pane.activated();
                                        tabsModel.remove(index);
                                        if (pane.currentTabIndex >= tabsModel.count) {
                                            pane.currentTabIndex = tabsModel.count - 1;
                                        }
                                        pane.loadDir(tabsModel.get(pane.currentTabIndex).path);
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: {
                                pane.activated();
                                pane.switchToTab(index);
                            }
                        }
                    }
                }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 4
                    color: newTabMouse.containsMouse ? (pane.theme ? pane.theme.accent : "#3b82f6") : (pane.theme ? pane.theme.bgSurface : "#27272a")

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: pane.theme ? pane.theme.textPrimary : "#ffffff"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    MouseArea {
                        id: newTabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pane.activated();
                            pane.addNewTab();
                        }
                    }
                }
            }
        }

        // Адресная строка + кнопка Unmount для SSH
        Rectangle {
            Layout.fillWidth: true
            height: 24
            color: pane.theme ? pane.theme.bgInput : "#27272a"
            radius: 4

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: pane.currentPath
                    color: pane.theme ? pane.theme.textPrimary : "#e4e4e7"
                    font.family: pane.paneFontFamily
                    font.bold: true
                    font.pixelSize: 11
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideLeft
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: fsManager.isMountedPath(pane.currentPath)
                    width: 90
                    height: 18
                    radius: 3
                    color: unmountMouse.containsMouse ? "#ef4444" : "#b91c1c"

                    Text {
                        anchors.centerIn: parent
                        text: "⏏ Отключить"
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: unmountMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var mPath = pane.currentPath;
                            pane.loadDir(fsManager.homePath());
                            fsManager.unmountPath(mPath);
                        }
                    }
                }
            }
        }

        // Заголовки колонок
        Rectangle {
            Layout.fillWidth: true
            height: 22
            color: pane.theme ? pane.theme.bgSurface : "#1f1f23"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true
                    height: parent.height
                    color: "transparent"
                    Text {
                        text: "Имя " + (pane.sortBy === "name" ? (pane.sortAsc ? "▲" : "▼") : "")
                        color: pane.theme ? pane.theme.textSecondary : "#a1a1aa"; font.bold: true; font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    MouseArea { anchors.fill: parent; onClicked: pane.toggleSort("name") }
                }

                Rectangle {
                    width: 80
                    height: parent.height
                    color: "transparent"
                    Text {
                        text: "Размер " + (pane.sortBy === "size" ? (pane.sortAsc ? "▲" : "▼") : "")
                        color: pane.theme ? pane.theme.textSecondary : "#a1a1aa"; font.bold: true; font.pixelSize: 11
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    MouseArea { anchors.fill: parent; onClicked: pane.toggleSort("size") }
                }

                Rectangle {
                    width: 120
                    height: parent.height
                    color: "transparent"
                    Text {
                        text: "Дата " + (pane.sortBy === "date" ? (pane.sortAsc ? "▲" : "▼") : "")
                        color: pane.theme ? pane.theme.textSecondary : "#a1a1aa"; font.bold: true; font.pixelSize: 11
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    MouseArea { anchors.fill: parent; onClicked: pane.toggleSort("date") }
                }
            }
        }

        // Список файлов
        ListView {
            id: fileList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true

            delegate: Rectangle {
                width: fileList.width
                height: pane.itemFontSize + 12
                radius: 3
                color: {
                    if (modelData.selected) return "#831843";
                    if (ListView.isCurrentItem && pane.isActive) return pane.theme ? pane.theme.accentActive : "#2563eb";
                    if (ListView.isCurrentItem && !pane.isActive) return pane.theme ? pane.theme.border : "#3f3f46";
                    return index % 2 === 0 ? "transparent" : (pane.theme ? pane.theme.rowAlternate : "#1f1f23");
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    spacing: 6

                    Text {
                        text: modelData.isDir ? "📁" : "📄"
                        font.pixelSize: pane.itemFontSize
                    }

                    Text {
                        text: modelData.name
                        color: modelData.selected ? "#fbcfe8" : (modelData.isDir ? (pane.theme ? pane.theme.dirColor : "#60a5fa") : (pane.theme ? pane.theme.textPrimary : "#ffffff"))
                        font.bold: modelData.isDir
                        font.family: pane.paneFontFamily
                        font.pixelSize: pane.itemFontSize
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: modelData.size
                        color: modelData.selected ? "#fbcfe8" : (pane.theme ? pane.theme.textSecondary : "#a1a1aa")
                        font.family: pane.paneFontFamily
                        font.pixelSize: pane.itemFontSize
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 80
                    }

                    Text {
                        text: modelData.modified
                        color: modelData.selected ? "#fbcfe8" : (pane.theme ? pane.theme.textSecondary : "#71717a")
                        font.family: pane.paneFontFamily
                        font.pixelSize: pane.itemFontSize
                        horizontalAlignment: Text.AlignRight
                        Layout.preferredWidth: 120
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        pane.activated();
                        if (mouse.button === Qt.RightButton) {
                            if (modelData.name !== "..") {
                                var m = fileList.model;
                                m[index].selected = !m[index].selected;
                                fileList.model = m;
                            }
                        } else {
                            fileList.currentIndex = index;
                        }
                    }
                    onDoubleClicked: {
                        pane.activated();
                        if (modelData.isDir) {
                            pane.loadDir(modelData.path);
                        } else {
                            fsManager.openFile(modelData.path);
                        }
                    }
                }
            }

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    var item = pane.getCurrentItem();
                    if (item) {
                        if (item.isDir) pane.loadDir(item.path);
                        else fsManager.openFile(item.path);
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backspace) {
                    var parentPath = pane.currentPath.substring(0, pane.currentPath.lastIndexOf("/"));
                    if (parentPath === "") parentPath = "/";
                    pane.loadDir(parentPath);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Insert) {
                    if (fileList.model && fileList.currentIndex >= 0) {
                        var cur = fileList.model[fileList.currentIndex];
                        if (cur.name !== "..") {
                            var arr = fileList.model;
                            arr[fileList.currentIndex].selected = !arr[fileList.currentIndex].selected;
                            fileList.model = arr;
                        }
                        if (fileList.currentIndex < fileList.model.length - 1) {
                            fileList.currentIndex++;
                        }
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Space) {
                    var curItem = pane.getCurrentItem();
                    if (curItem && curItem.isDir && curItem.name !== "..") {
                        var sizeStr = fsManager.calculateDirSize(curItem.path);
                        var copyM = fileList.model;
                        copyM[fileList.currentIndex].size = sizeStr;
                        fileList.model = copyM;
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
