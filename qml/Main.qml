import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Commander 1.0
import "components"

ApplicationWindow {
    id: root
    width: 1180
    height: 760
    visible: true
    title: "Nightjar"
    color: appTheme.bgApp

    Theme {
        id: appTheme
    }

    FileManager {
        id: fsManager
        onCommandFinished: root.refreshBoth()
        onArchiveOperationFinished: root.refreshBoth()

        onCopyProgress: (progress, currentFileName, copiedSizeStr, totalSizeStr, speedStr, etaStr) => {
            copyProgressBar.value = progress;
            copyStatusFile.text = currentFileName;
            copyStatusDetails.text = copiedSizeStr + " / " + totalSizeStr + "  (" + speedStr + ")";
            copyStatusEta.text = "Осталось: " + etaStr;
            if (!copyProgressDialog.opened) copyProgressDialog.open();
        }

        onCopyFinished: (success, wasCancelled) => {
            copyProgressDialog.close();
            root.refreshBoth();
            activePane.list.forceActiveFocus();
        }
    }

    property var activePane: leftPane
    property var targetPane: rightPane

    property bool showHiddenFiles: false
    property bool confirmDeletion: true
    property int listFontSize: 12
    property string customEditorCmd: ""

    // Буфер операции копирования
    property var pendingCopyPaths: []
    property string pendingCopyDest: ""

    function applySettings() {
        showHiddenFiles = Boolean(fsManager.getSetting("showHidden", false));
        confirmDeletion = Boolean(fsManager.getSetting("confirmDelete", true));
        
        var fIndex = Number(fsManager.getSetting("fontSizeIndex", 1));
        if (fIndex === 0) listFontSize = 11;
        else if (fIndex === 1) listFontSize = 12;
        else listFontSize = 14;

        appTheme.currentTheme = Number(fsManager.getSetting("themeIndex", 0));
        var userFont = String(fsManager.getSetting("fontFamily", ""));
        appTheme.fontFamily = (userFont && userFont !== "") ? userFont : "monospace";

        customEditorCmd = String(fsManager.getSetting("customEditor", ""));

        leftPane.showHidden = showHiddenFiles;
        leftPane.itemFontSize = listFontSize;
        leftPane.paneFontFamily = appTheme.fontFamily;

        rightPane.showHidden = showHiddenFiles;
        rightPane.itemFontSize = listFontSize;
        rightPane.paneFontFamily = appTheme.fontFamily;

        root.refreshBoth();
    }

    function saveSession() {
        var isMax = (root.visibility === Window.Maximized);
        fsManager.saveSetting("windowMaximized", Boolean(isMax));
        if (!isMax) {
            fsManager.saveSetting("windowWidth", Number(root.width));
            fsManager.saveSetting("windowHeight", Number(root.height));
            fsManager.saveSetting("windowX", Number(root.x));
            fsManager.saveSetting("windowY", Number(root.y));
        }

        var leftState = leftPane.getTabsState();
        var leftArr = [];
        for (var i = 0; i < leftState.tabs.length; i++) leftArr.push(String(leftState.tabs[i]));
        fsManager.saveSetting("leftTabs", leftArr);
        fsManager.saveSetting("leftActiveTab", Number(leftState.activeIdx));

        var rightState = rightPane.getTabsState();
        var rightArr = [];
        for (var j = 0; j < rightState.tabs.length; j++) rightArr.push(String(rightState.tabs[j]));
        fsManager.saveSetting("rightTabs", rightArr);
        fsManager.saveSetting("rightActiveTab", Number(rightState.activeIdx));

        fsManager.saveSetting("activePaneIsLeft", Boolean(activePane === leftPane));
    }

    function restoreSession() {
        var savedW = Number(fsManager.getSetting("windowWidth", 1180));
        var savedH = Number(fsManager.getSetting("windowHeight", 760));
        var savedX = Number(fsManager.getSetting("windowX", -1));
        var savedY = Number(fsManager.getSetting("windowY", -1));
        var isMaximized = Boolean(fsManager.getSetting("windowMaximized", false));

        if (savedW > 400 && savedH > 300) {
            root.width = savedW;
            root.height = savedH;
        }
        if (savedX >= 0 && savedY >= 0) {
            root.x = savedX;
            root.y = savedY;
        }
        if (isMaximized) {
            root.visibility = Window.Maximized;
        }

        var leftTabs = fsManager.getSetting("leftTabs", []);
        var leftIdx = Number(fsManager.getSetting("leftActiveTab", 0));
        leftPane.restoreTabs(leftTabs, leftIdx);

        var rightTabs = fsManager.getSetting("rightTabs", []);
        var rightIdx = Number(fsManager.getSetting("rightActiveTab", 0));
        rightPane.restoreTabs(rightTabs, rightIdx);

        var isLeftActive = Boolean(fsManager.getSetting("activePaneIsLeft", true));
        setFocusTo(isLeftActive ? leftPane : rightPane);
    }

    Component.onCompleted: {
        applySettings();
        restoreSession();
    }

    onClosing: {
        saveSession();
    }

    function setFocusTo(pane) {
        activePane = pane;
        targetPane = (pane === leftPane ? rightPane : leftPane);
        leftPane.isActive = (pane === leftPane);
        rightPane.isActive = (pane === rightPane);
        pane.list.forceActiveFocus();
    }

    function switchFocus() {
        setFocusTo(activePane === leftPane ? rightPane : leftPane);
    }

    function refreshBoth() {
        leftPane.loadDir(leftPane.currentPath);
        rightPane.loadDir(rightPane.currentPath);
    }

    // 1. Показываем диалог подтверждения целевого пути
    function requestCopyConfirmation(paths, destDir) {
        if (!paths || paths.length === 0 || !destDir) return;
        pendingCopyPaths = paths;
        pendingCopyDest = destDir;
        destinationConfirmText.text = "Скопировать объектов: " + paths.length + "\n\nВ каталог назначения:\n" + destDir + "\n\nПуть указан верно?";
        copyConfirmDestinationDialog.open();
    }

    // 2. Проверяем конфликты имён перед реальным запуском копирования
    function executeCopyOperation(paths, destDir) {
        var conflicts = fsManager.getConflictingFiles(paths, destDir);
        if (conflicts && conflicts.length > 0) {
            pendingCopyPaths = paths;
            pendingCopyDest = destDir;
            conflictText.text = "В каталоге назначения уже существуют файлы (" + conflicts.length + " шт.):\n" + conflicts.slice(0, 3).join(", ") + (conflicts.length > 3 ? "..." : "") + "\n\nПерезаписать существующие объекты?";
            overwriteConfirmDialog.open();
        } else {
            fsManager.copyItems(paths, destDir, true);
        }
    }

    // Отслеживание курсора при Drag-and-Drop и подсветка строк-папок
    function checkHoverOverPanes(wx, wy) {
        var leftPt = root.contentItem.mapToItem(leftPane, wx, wy);
        var inLeft = (leftPt.x >= 0 && leftPt.x <= leftPane.width && leftPt.y >= 0 && leftPt.y <= leftPane.height);

        var rightPt = root.contentItem.mapToItem(rightPane, wx, wy);
        var inRight = (rightPt.x >= 0 && rightPt.x <= rightPane.width && rightPt.y >= 0 && rightPt.y <= rightPane.height);

        leftPane.isDropTarget = inLeft && (activePane !== leftPane);
        rightPane.isDropTarget = inRight && (activePane !== rightPane);

        if (leftPane.isDropTarget) {
            leftPane.updateHoverIndex(wx, wy);
        } else {
            leftPane.hoveredDropIndex = -1;
        }

        if (rightPane.isDropTarget) {
            rightPane.updateHoverIndex(wx, wy);
        } else {
            rightPane.hoveredDropIndex = -1;
        }
    }

    // Бросок мыши: вычисляем точную целевую папку и запрашиваем подтверждение пути
    function handleDrop(wx, wy, paths) {
        leftPane.isDropTarget = false;
        leftPane.hoveredDropIndex = -1;
        rightPane.isDropTarget = false;
        rightPane.hoveredDropIndex = -1;

        if (!paths || paths.length === 0) return;

        var leftPt = root.contentItem.mapToItem(leftPane, wx, wy);
        var inLeft = (leftPt.x >= 0 && leftPt.x <= leftPane.width && leftPt.y >= 0 && leftPt.y <= leftPane.height);

        var rightPt = root.contentItem.mapToItem(rightPane, wx, wy);
        var inRight = (rightPt.x >= 0 && rightPt.x <= rightPane.width && rightPt.y >= 0 && rightPt.y <= rightPane.height);

        if (inLeft && activePane !== leftPane) {
            var targetFolder = leftPane.getTargetFolderAt(wx, wy);
            requestCopyConfirmation(paths, targetFolder);
        } else if (inRight && activePane !== rightPane) {
            var targetFolder2 = rightPane.getTargetFolderAt(wx, wy);
            requestCopyConfirmation(paths, targetFolder2);
        }
    }

    function triggerPack() {
        var paths = activePane.getSelectedOrCurrentPaths();
        if (paths.length === 0) return;
        var defaultName = "archive.tar.gz";
        var item = activePane.getCurrentItem();
        if (item && item.name !== "..") defaultName = item.name + ".tar.gz";
        archiveNameInput.text = defaultName;
        packDialog.open();
    }

    function triggerUnpack() {
        var item = activePane.getCurrentItem();
        if (item && !item.isDir && fsManager.isArchiveFile(item.name)) unpackDialog.open();
    }

    function openRenameDialog() {
        var items = [];
        var pane = activePane;
        if (!pane.list.model) return;
        for (var i = 0; i < pane.list.model.length; i++) {
            if (pane.list.model[i].selected && pane.list.model[i].name !== "..") {
                items.push(pane.list.model[i]);
            }
        }
        if (items.length === 0) {
            var cur = pane.getCurrentItem();
            if (cur && cur.name !== "..") items.push(cur);
        }
        if (items.length > 0) {
            multiRenameDialog.openWithFiles(items);
        }
    }

    function openSearchDialog() {
        globalSearchDialog.openAt(activePane.currentPath);
    }

    function openSettingsDialog() {
        settingsDialog.openSettings();
    }

    function openConnectDialog() {
        connectDialog.openDialog();
    }

    function triggerDelete() {
        var paths = activePane.getSelectedOrCurrentPaths();
        if (paths.length === 0) return;
        if (confirmDeletion) {
            deleteDialog.open();
        } else {
            fsManager.deleteItems(paths);
            activePane.loadDir(activePane.currentPath);
        }
    }

    function navigateToPath(fullPath) {
        var lastSlash = fullPath.lastIndexOf("/");
        if (lastSlash !== -1) {
            var dirPath = fullPath.substring(0, lastSlash);
            var fileName = fullPath.substring(lastSlash + 1);
            activePane.loadDir(dirPath);
            for (var i = 0; i < activePane.list.model.length; i++) {
                if (activePane.list.model[i].name === fileName) {
                    activePane.list.currentIndex = i;
                    break;
                }
            }
        }
    }

    function triggerPreview() {
        var item = activePane.getCurrentItem();
        if (item && !item.isDir) {
            previewOverlay.show(item.name, item.path, fsManager);
        }
    }

    // Хоткеи
    Shortcut { sequence: "Tab"; onActivated: root.switchFocus() }
    Shortcut { sequence: "F1"; onActivated: helpOverlay.open() }
    Shortcut { sequence: "Ctrl+,"; onActivated: root.openSettingsDialog() }
    Shortcut { sequence: "Ctrl+F"; onActivated: root.openConnectDialog() }

    Shortcut {
        sequence: "Ctrl+T"
        onActivated: root.activePane.addNewTab()
    }
    Shortcut {
        sequence: "Ctrl+W"
        onActivated: root.activePane.closeCurrentTab()
    }
    Shortcut {
        sequence: "Ctrl+M"
        onActivated: root.openRenameDialog()
    }
    Shortcut {
        sequence: "Alt+F7"
        onActivated: root.openSearchDialog()
    }

    Shortcut {
        sequence: "F3"
        onActivated: root.triggerPreview()
    }
    Shortcut { sequence: "Ctrl+Shift+C"; onActivated: root.activePane.copyPathsToClipboard() }
    Shortcut { sequences: ["Alt+C", "Ctrl+P", "Ctrl+Alt+C"]; onActivated: root.activePane.copyNamesToClipboard() }
    Shortcut {
        sequence: "F4"
        onActivated: {
            var item = activePane.getCurrentItem();
            if (item && !item.isDir) fsManager.editFile(item.path, customEditorCmd);
        }
    }
    Shortcut { 
        sequence: "F5"
        onActivated: {
            var paths = activePane.getSelectedOrCurrentPaths();
            if (paths.length > 0) root.requestCopyConfirmation(paths, targetPane.currentPath);
        }
    }
    Shortcut { sequence: "F6"; onActivated: if (activePane.getSelectedOrCurrentPaths().length > 0) moveDialog.open() }
    Shortcut { sequence: "F7"; onActivated: { folderNameInput.text = ""; mkdirDialog.open(); } }
    Shortcut { sequences: ["F8", "Delete"]; onActivated: root.triggerDelete() }
    Shortcut {
        sequence: "Shift+Delete"
        onActivated: {
            var paths = root.activePane.getSelectedOrCurrentPaths();
            if (paths.length > 0) {
                fsManager.deleteItems(paths);
                root.activePane.loadDir(root.activePane.currentPath);
            }
        }
    }
    Shortcut { sequence: "Alt+F5"; onActivated: root.triggerPack() }
    Shortcut { sequence: "Alt+F9"; onActivated: root.triggerUnpack() }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        TopToolBar {
            id: topToolbar
            theme: appTheme
            Layout.fillWidth: true
            onRefreshClicked: root.refreshBoth()
            onNewTabClicked: root.activePane.addNewTab()
            onConnectClicked: root.openConnectDialog()
            onSearchClicked: root.openSearchDialog()
            onRenameClicked: root.openRenameDialog()
            onPackClicked: root.triggerPack()
            onUnpackClicked: root.triggerUnpack()
            onCopyClicked: {
                var paths = activePane.getSelectedOrCurrentPaths();
                if (paths.length > 0) root.requestCopyConfirmation(paths, targetPane.currentPath);
            }
            onMoveClicked: if (activePane.getSelectedOrCurrentPaths().length > 0) moveDialog.open()
            onDeleteClicked: root.triggerDelete()
            onSettingsClicked: root.openSettingsDialog()
            onTerminalClicked: cmdLine.focusInput()
            onHelpClicked: helpOverlay.open()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            FilePane {
                id: leftPane
                theme: appTheme
                Layout.fillWidth: true
                Layout.fillHeight: true
                isActive: true
                fsManager: fsManager
                showHidden: root.showHiddenFiles
                itemFontSize: root.listFontSize
                onActivated: root.setFocusTo(leftPane)
                onRefreshRequested: root.refreshBoth()
            }

            FilePane {
                id: rightPane
                theme: appTheme
                Layout.fillWidth: true
                Layout.fillHeight: true
                isActive: false
                fsManager: fsManager
                showHidden: root.showHiddenFiles
                itemFontSize: root.listFontSize
                onActivated: root.setFocusTo(rightPane)
                onRefreshRequested: root.refreshBoth()
            }
        }

        CommandLine {
            id: cmdLine
            Layout.fillWidth: true
            activePath: root.activePane.currentPath
            onExecuteCommand: (cmd) => fsManager.runCommand(root.activePane.currentPath, cmd)
            onEscapePressed: root.activePane.list.forceActiveFocus()
        }

        GlobalStatusBar {
            Layout.fillWidth: true
            activePath: root.activePane.currentPath
            selectedCount: root.activePane.getSelectedCount()
            totalCount: root.activePane.list.model ? root.activePane.list.model.length : 0
            diskInfo: root.activePane.diskInfo
        }
    }

    ConnectDialog {
        id: connectDialog
        theme: appTheme
        fsManager: fsManager
        onConnected: (targetPath) => { root.activePane.addNewTab(targetPath); }
        onClosed: activePane.list.forceActiveFocus()
    }

    SettingsDialog {
        id: settingsDialog
        theme: appTheme
        fsManager: fsManager
        onSettingsChanged: root.applySettings()
        onClosed: activePane.list.forceActiveFocus()
    }

    GlobalSearchDialog {
        id: globalSearchDialog
        fsManager: fsManager
        onNavigateTo: (path) => root.navigateToPath(path)
        onClosed: activePane.list.forceActiveFocus()
    }

    MultiRenameDialog {
        id: multiRenameDialog
        fsManager: fsManager
        onApplied: root.refreshBoth()
        onClosed: activePane.list.forceActiveFocus()
    }

    HelpOverlay {
        id: helpOverlay
        onClosed: activePane.list.forceActiveFocus()
    }

    PreviewOverlay {
        id: previewOverlay
        onClosed: activePane.list.forceActiveFocus()
    }

    // 1. Диалог подтверждения пути назначения
    Dialog {
        id: copyConfirmDestinationDialog
        anchors.centerIn: parent
        width: 440
        title: "Подтверждение копирования"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        Text {
            id: destinationConfirmText
            text: ""
            color: appTheme.textPrimary
            wrapMode: Text.Wrap
            width: parent.width - 24
        }
        onAccepted: {
            root.executeCopyOperation(pendingCopyPaths, pendingCopyDest);
            activePane.list.forceActiveFocus();
        }
        onRejected: {
            pendingCopyPaths = [];
            pendingCopyDest = "";
            activePane.list.forceActiveFocus();
        }
    }

    // 2. Диалог перезаписи существующих файлов (при конфликте)
    Dialog {
        id: overwriteConfirmDialog
        anchors.centerIn: parent
        width: 420
        title: "Конфликт имён"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        Text {
            id: conflictText
            text: ""
            color: appTheme.textPrimary
            wrapMode: Text.Wrap
            width: parent.width - 24
        }
        onAccepted: {
            fsManager.copyItems(pendingCopyPaths, pendingCopyDest, true);
            pendingCopyPaths = [];
            pendingCopyDest = "";
            activePane.list.forceActiveFocus();
        }
        onRejected: {
            pendingCopyPaths = [];
            pendingCopyDest = "";
            activePane.list.forceActiveFocus();
        }
    }

    // 3. Диалог прогресса копирования в стиле Total Commander
    Dialog {
        id: copyProgressDialog
        anchors.centerIn: parent
        width: 440
        title: "Копирование файлов..."
        modal: true
        closePolicy: Popup.NoAutoClose

        ColumnLayout {
            spacing: 8
            width: parent.width

            Text {
                id: copyStatusFile
                text: "Подготовка..."
                color: appTheme.textPrimary
                font.bold: true
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }

            ProgressBar {
                id: copyProgressBar
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                value: 0.0
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    id: copyStatusDetails
                    text: "0 B / 0 B (0 B/s)"
                    color: appTheme.textSecondary
                    font.pixelSize: 11
                    Layout.fillWidth: true
                }
                Text {
                    id: copyStatusEta
                    text: "Осталось: --"
                    color: appTheme.textSecondary
                    font.pixelSize: 11
                }
            }

            Button {
                text: "Отмена"
                Layout.alignment: Qt.AlignRight
                onClicked: fsManager.cancelCopy()
            }
        }
    }

    Dialog {
        id: moveDialog
        anchors.centerIn: parent
        width: 380
        title: "Перемещение"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        Text {
            text: "Переместить объектов: " + activePane.getSelectedOrCurrentPaths().length + "\nВ: " + targetPane.currentPath
            color: appTheme.textPrimary
        }
        onAccepted: {
            fsManager.moveItems(activePane.getSelectedOrCurrentPaths(), targetPane.currentPath);
            root.refreshBoth();
            activePane.list.forceActiveFocus();
        }
        onRejected: activePane.list.forceActiveFocus()
    }

    Dialog {
        id: mkdirDialog
        anchors.centerIn: parent
        width: 320
        title: "Создать каталог"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        TextField {
            id: folderNameInput
            placeholderText: "Имя папки"
            selectByMouse: true
            width: 280
            focus: true
            Keys.onReturnPressed: mkdirDialog.accept()
        }
        onAccepted: {
            if (folderNameInput.text.trim() !== "") {
                fsManager.createDirectory(activePane.currentPath, folderNameInput.text.trim());
                activePane.loadDir(activePane.currentPath);
            }
            activePane.list.forceActiveFocus();
        }
        onRejected: activePane.list.forceActiveFocus()
    }

    Dialog {
        id: deleteDialog
        anchors.centerIn: parent
        width: 360
        title: "Удаление"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        Text {
            text: "Удалить выбранные объекты (" + activePane.getSelectedOrCurrentPaths().length + " шт.)?"
            color: appTheme.textPrimary
        }
        onAccepted: {
            fsManager.deleteItems(activePane.getSelectedOrCurrentPaths());
            activePane.loadDir(activePane.currentPath);
            activePane.list.forceActiveFocus();
        }
        onRejected: activePane.list.forceActiveFocus()
    }

    Dialog {
        id: packDialog
        anchors.centerIn: parent
        width: 400
        title: "Упаковать в архив (Alt+F5)"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        ColumnLayout {
            spacing: 10
            width: parent.width
            Text {
                text: "Создать архив в целевой панели:\n" + targetPane.currentPath
                color: appTheme.textSecondary
            }
            TextField {
                id: archiveNameInput
                Layout.fillWidth: true
                placeholderText: "Имя архива (.tar.gz или .zip)"
                selectByMouse: true
                focus: true
                Keys.onReturnPressed: packDialog.accept()
            }
        }
        onAccepted: {
            var name = archiveNameInput.text.trim();
            if (name !== "") {
                var targetFile = targetPane.currentPath + "/" + name;
                fsManager.packArchive(activePane.getSelectedOrCurrentPaths(), targetFile, activePane.currentPath);
            }
            activePane.list.forceActiveFocus();
        }
        onRejected: activePane.list.forceActiveFocus()
    }

    Dialog {
        id: unpackDialog
        anchors.centerIn: parent
        width: 420
        title: "Распаковать архив (Alt+F9)"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        ColumnLayout {
            spacing: 10
            width: parent.width
            Text {
                text: {
                    var item = activePane.getCurrentItem();
                    return "Распаковать архив:\n" + (item ? item.name : "") + "\n\nВ каталог:\n" + targetPane.currentPath;
                }
                color: appTheme.textPrimary
            }
        }
        onAccepted: {
            var item = activePane.getCurrentItem();
            if (item && !item.isDir) fsManager.unpackArchive(item.path, targetPane.currentPath);
            activePane.list.forceActiveFocus();
        }
        onRejected: activePane.list.forceActiveFocus()
    }
}