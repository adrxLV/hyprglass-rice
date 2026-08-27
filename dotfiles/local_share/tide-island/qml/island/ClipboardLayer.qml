import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import IslandBackend

Item {
    id: root

    signal closeRequested

    property bool showCondition: false
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property int selectedIndex: 0
    property string searchQuery: ""
    property string toastMessage: ""

    readonly property real cardHeight: 46
    readonly property real cardGap: 6

    focus: showCondition
    activeFocusOnTab: true
    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: root.showCondition ? 240 : 120
            easing.type: Easing.InOutQuad
        }
    }

    ListModel {
        id: rawClipboardModel
    }

    ListModel {
        id: filteredClipboardModel
    }

    function refreshFilteredModel() {
        filteredClipboardModel.clear();
        const query = searchQuery.trim().toLowerCase();
        for (var i = 0; i < rawClipboardModel.count; i++) {
            const item = rawClipboardModel.get(i);
            if (query === "" || item.summary.toLowerCase().indexOf(query) !== -1 || item.clipId.indexOf(query) !== -1) {
                filteredClipboardModel.append({
                    "clipId": item.clipId,
                    "summary": item.summary,
                    "isImage": item.isImage
                });
            }
        }
        if (filteredClipboardModel.count > 0) {
            if (selectedIndex < 0 || selectedIndex >= filteredClipboardModel.count) {
                selectedIndex = 0;
            }
        } else {
            selectedIndex = -1;
        }
    }

    Process {
        id: fetchClipboardProcess
        command: ["bash", "-c", "mkdir -p /tmp/tide-clipboard-cache && cliphist list | head -n 50 | while read -r id rest; do if [[ \"$rest\" == *\"binary data\"* ]]; then cliphist decode \"$id\" > \"/tmp/tide-clipboard-cache/${id}.png\" 2>/dev/null; fi; echo -e \"${id}\t${rest}\"; done"]

        stdout: SplitParser {
            onRead: function(line) {
                const trimmed = line.trim();
                if (!trimmed) return;

                var cId = "";
                var cText = "";
                const tabIndex = trimmed.indexOf("\t");
                if (tabIndex !== -1) {
                    cId = trimmed.substring(0, tabIndex).trim();
                    cText = trimmed.substring(tabIndex + 1).trim();
                } else {
                    const parts = trimmed.split(/\s+/);
                    cId = parts[0];
                    cText = trimmed.substring(cId.length).trim();
                }

                const isBinary = cText.indexOf("[[ binary data") !== -1;

                rawClipboardModel.append({
                    "clipId": cId,
                    "summary": cText,
                    "isImage": isBinary
                });
            }
        }

        onStarted: {
            rawClipboardModel.clear();
        }

        onExited: {
            refreshFilteredModel();
        }
    }

    Timer {
        id: autoRefreshTimer
        interval: 2500
        repeat: true
        running: root.showCondition && !fetchClipboardProcess.running
        onTriggered: fetchClipboardProcess.running = true
    }

    onShowConditionChanged: {
        if (showCondition) {
            searchQuery = "";
            selectedIndex = 0;
            toastMessage = "";
            fetchClipboardProcess.running = true;
            root.grabKeyboardFocus();
        }
    }

    onSearchQueryChanged: {
        refreshFilteredModel();
    }

    function grabKeyboardFocus() {
        root.focus = true;
        root.forceActiveFocus();
        if (searchInput.visible) {
            searchInput.forceActiveFocus();
        }
    }

    function showToast(msg) {
        toastMessage = msg;
        toastTimer.restart();
    }

    Timer {
        id: toastTimer
        interval: 1800
        repeat: false
        onTriggered: root.toastMessage = ""
    }

    function copySelectedItem() {
        if (selectedIndex >= 0 && selectedIndex < filteredClipboardModel.count) {
            const item = filteredClipboardModel.get(selectedIndex);
            copyItem(item.clipId, item.summary);
        }
    }

    function copyItem(clipId, summaryText) {
        if (!clipId) return;
        Quickshell.execDetached(["bash", "-c", "cliphist decode " + clipId + " | wl-copy"]);
        showToast("Copied!");
        Qt.callLater(function() {
            root.closeRequested();
        });
    }

    function deleteSelectedItem() {
        if (selectedIndex >= 0 && selectedIndex < filteredClipboardModel.count) {
            const item = filteredClipboardModel.get(selectedIndex);
            deleteItem(item.clipId, selectedIndex);
        }
    }

    function deleteItem(clipId, index) {
        if (!clipId) return;
        Quickshell.execDetached(["bash", "-c", "cliphist decode " + clipId + " | cliphist delete"]);

        for (var i = 0; i < rawClipboardModel.count; i++) {
            if (rawClipboardModel.get(i).clipId === clipId) {
                rawClipboardModel.remove(i);
                break;
            }
        }
        refreshFilteredModel();
        showToast("Item removed");
    }

    Keys.onPressed: event => {
        const count = filteredClipboardModel.count;
        switch (event.key) {
        case Qt.Key_Escape:
            root.closeRequested();
            event.accepted = true;
            break;
        case Qt.Key_Down:
        case Qt.Key_J:
            if (count > 0) {
                root.selectedIndex = Math.min(root.selectedIndex + 1, count - 1);
                listView.positionViewAtIndex(root.selectedIndex, ListView.Beginning);
            }
            event.accepted = true;
            break;
        case Qt.Key_Up:
        case Qt.Key_K:
            if (count > 0) {
                root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                listView.positionViewAtIndex(root.selectedIndex, ListView.Beginning);
            }
            event.accepted = true;
            break;
        case Qt.Key_Home:
            if (count > 0) {
                root.selectedIndex = 0;
                listView.positionViewAtIndex(0, ListView.Beginning);
            }
            event.accepted = true;
            break;
        case Qt.Key_End:
            if (count > 0) {
                root.selectedIndex = count - 1;
                listView.positionViewAtIndex(count - 1, ListView.Beginning);
            }
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.copySelectedItem();
            event.accepted = true;
            break;
        case Qt.Key_Delete:
        case Qt.Key_Backspace:
            if (event.modifiers & Qt.ShiftModifier || event.key === Qt.Key_Delete) {
                root.deleteSelectedItem();
                event.accepted = true;
            }
            break;
        }
    }

    Column {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 14
        anchors.bottomMargin: 12
        spacing: 10

        // Header Container
        Item {
            width: parent.width
            height: 28

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: StyleTokens.cardFillActive

                    Text {
                        anchors.centerIn: parent
                        text: "󰅍"
                        font.family: root.iconFontFamily
                        font.pixelSize: 14
                        color: StyleTokens.accent
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Clipboard History"
                    font.family: root.textFontFamily
                    font.pixelSize: 14
                    font.bold: true
                    color: StyleTokens.textPrimary
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 18
                    width: countText.implicitWidth + 12
                    radius: 9
                    color: StyleTokens.module

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: filteredClipboardModel.count
                        font.family: root.textFontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: StyleTokens.textSecondary
                    }
                }
            }

            // Right side Header (Toast Notification Pill)
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    visible: root.toastMessage !== ""
                    height: 22
                    width: toastText.implicitWidth + 14
                    radius: 11
                    color: StyleTokens.cardFillActive
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: toastText
                        anchors.centerIn: parent
                        text: root.toastMessage
                        font.family: root.textFontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: StyleTokens.accent
                    }
                }
            }
        }

        // Search Input Bar
        Rectangle {
            width: parent.width
            height: 30
            radius: 8
            color: StyleTokens.module
            border.width: searchInput.activeFocus ? 1 : 0
            border.color: StyleTokens.accent

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    font.family: root.iconFontFamily
                    font.pixelSize: 12
                    color: StyleTokens.textSecondary
                }

                TextInput {
                    id: searchInput
                    width: parent.width - 30
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.textFontFamily
                    font.pixelSize: 12
                    color: StyleTokens.textPrimary
                    selectByMouse: true
                    clip: true
                    text: root.searchQuery
                    onTextChanged: root.searchQuery = text

                    Text {
                        text: "Search clipboard..."
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        color: StyleTokens.textSecondary
                        visible: !parent.text && !parent.inputMethodComposing
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Up || event.key === Qt.Key_Return || event.key === Qt.Key_Escape) {
                            root.Keys.onPressed(event);
                        }
                    }
                }
            }
        }

        // Empty state or Scrollable List
        Item {
            width: parent.width
            height: 218
            clip: true

            Text {
                visible: filteredClipboardModel.count === 0
                anchors.centerIn: parent
                text: fetchClipboardProcess.running ? "A carregar histórico..." : "Histórico vazio"
                font.family: root.textFontFamily
                font.pixelSize: 13
                color: StyleTokens.textSecondary
            }

            ListView {
                id: listView
                anchors.fill: parent
                model: filteredClipboardModel
                spacing: root.cardGap
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: root.selectedIndex

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.selectedIndex === index
                    readonly property bool isHovered: cardMouseArea.containsMouse

                    width: listView.width
                    height: root.cardHeight
                    radius: 10
                    color: isSelected || isHovered ? StyleTokens.cardFillActive : StyleTokens.module
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? StyleTokens.accent : StyleTokens.overviewInnerBorder

                    scale: isHovered ? 1.01 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: cardMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = index;
                            root.copySelectedItem();
                        }
                    }

                    // Left side: Index badge or Image thumbnail
                    Item {
                        id: leftContainer
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: modelData.isImage ? 34 : 28
                        height: modelData.isImage ? 34 : 22

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: isSelected ? StyleTokens.accent : StyleTokens.overviewInnerBorder
                            clip: true

                            Image {
                                visible: modelData.isImage
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: modelData.isImage ? ("file:///tmp/tide-clipboard-cache/" + modelData.clipId + ".png") : ""
                                cache: false
                            }

                            Text {
                                visible: !modelData.isImage
                                anchors.centerIn: parent
                                text: "#" + (index + 1)
                                font.family: root.textFontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: isSelected ? "#ffffff" : StyleTokens.textSecondary
                            }
                        }
                    }

                    // Right side: Delete action button
                    Row {
                        id: rightContainer
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Rectangle {
                            width: 24
                            height: 24
                            radius: 6
                            color: delMouse.containsMouse ? "#e06c75" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "󰅖"
                                font.family: root.iconFontFamily
                                font.pixelSize: 12
                                color: delMouse.containsMouse ? "#ffffff" : StyleTokens.textSecondary
                                opacity: isSelected || isHovered ? 1.0 : 0.4
                            }

                            MouseArea {
                                id: delMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.deleteItem(modelData.clipId, index);
                                }
                            }
                        }
                    }

                    // Center Text Preview (anchored strictly between leftContainer and rightContainer to prevent overlap!)
                    Text {
                        id: contentPreview
                        anchors.left: leftContainer.right
                        anchors.leftMargin: 10
                        anchors.right: rightContainer.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.isImage
                            ? ("Imagem (" + modelData.summary.replace("[[ binary data ", "").replace(" ]]", "") + ")")
                            : modelData.summary
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        color: isSelected || isHovered ? StyleTokens.textPrimary : StyleTokens.textSecondary
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        clip: true
                    }
                }
            }
        }

        // Keyboard hints footer
        Row {
            width: parent.width
            height: 16
            spacing: 12

            Text {
                text: "↑↓ / j,k Navigate"
                font.family: root.textFontFamily
                font.pixelSize: 10
                color: StyleTokens.textSecondary
                opacity: 0.7
            }

            Text {
                text: "↵ Copy"
                font.family: root.textFontFamily
                font.pixelSize: 10
                color: StyleTokens.textSecondary
                opacity: 0.7
            }

            Text {
                text: "Del Delete"
                font.family: root.textFontFamily
                font.pixelSize: 10
                color: StyleTokens.textSecondary
                opacity: 0.7
            }

            Text {
                text: "Esc Close"
                font.family: root.textFontFamily
                font.pixelSize: 10
                color: StyleTokens.textSecondary
                opacity: 0.7
            }
        }
    }
}
