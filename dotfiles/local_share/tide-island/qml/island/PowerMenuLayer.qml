import QtQuick
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

    readonly property var powerActions: [
        {
            "id": "poweroff",
            "title": "Power Off",
            "icon": "",
            "color": "#e06c75",
            "command": ["bash", "-c", "systemctl poweroff"]
        },
        {
            "id": "reboot",
            "title": "Restart",
            "icon": "",
            "color": "#e5c07b",
            "command": ["bash", "-c", "systemctl reboot"]
        },
        {
            "id": "suspend",
            "title": "Sleep",
            "icon": "",
            "color": "#61afef",
            "command": ["bash", "-c", "systemctl suspend"]
        },
        {
            "id": "lock",
            "title": "Lock",
            "icon": "",
            "color": "#c678dd",
            "command": ["bash", "-c", "hyprlock || loginctl lock-session"]
        },
        {
            "id": "logout",
            "title": "Log Out",
            "icon": "",
            "color": "#98c379",
            "command": ["bash", "-c", "hyprctl dispatch exit 0 || loginctl terminate-user $USER"]
        }
    ]

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

    onShowConditionChanged: {
        if (showCondition) {
            selectedIndex = 0;
            root.grabKeyboardFocus();
        }
    }

    function grabKeyboardFocus() {
        root.focus = true;
        root.forceActiveFocus();
    }

    function triggerAction(action) {
        if (!action || !action.command) return;
        Quickshell.execDetached(action.command);
        root.closeRequested();
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape:
            root.closeRequested();
            event.accepted = true;
            break;
        case Qt.Key_Right:
        case Qt.Key_Down:
        case Qt.Key_L:
        case Qt.Key_Tab:
            root.selectedIndex = (root.selectedIndex + 1) % root.powerActions.length;
            event.accepted = true;
            break;
        case Qt.Key_Left:
        case Qt.Key_Up:
        case Qt.Key_H:
        case Qt.Key_Backtab:
            root.selectedIndex = (root.selectedIndex - 1 + root.powerActions.length) % root.powerActions.length;
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            if (root.selectedIndex >= 0 && root.selectedIndex < root.powerActions.length) {
                root.triggerAction(root.powerActions[root.selectedIndex]);
            }
            event.accepted = true;
            break;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 14
        anchors.bottomMargin: 14

        // Header
        Row {
            id: headerRow
            anchors.top: parent.top
            anchors.left: parent.left
            spacing: 8

            Rectangle {
                width: 26
                height: 26
                radius: 13
                color: Qt.rgba(1, 1, 1, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: "󰐥"
                    font.family: root.iconFontFamily
                    font.pixelSize: 13
                    color: StyleTokens.accent
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Session"
                font.family: root.textFontFamily
                font.pixelSize: 14
                font.bold: true
                color: StyleTokens.textPrimary
            }
        }

        // Action buttons row
        Row {
            anchors.top: headerRow.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            Repeater {
                model: root.powerActions

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.selectedIndex === index
                    readonly property bool isHovered: mouseArea.containsMouse
                    readonly property bool isActive: isSelected || isHovered

                    width: 100
                    height: 90
                    radius: 16
                    color: isActive ? StyleTokens.cardFillActive : "transparent"
                    border.width: 1
                    border.color: isSelected ? modelData.color : (isHovered ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08))

                    scale: isActive ? 1.04 : 1.0
                    transformOrigin: Item.Center

                    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedIndex = index;
                            root.triggerAction(modelData);
                        }
                        onEntered: root.selectedIndex = index
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 38
                            height: 38
                            radius: 19
                            color: modelData.color
                            opacity: isActive ? 1.0 : 0.85
                            anchors.horizontalCenter: parent.horizontalCenter

                            Behavior on opacity { NumberAnimation { duration: 160 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: root.iconFontFamily
                                font.pixelSize: 17
                                color: "#ffffff"
                            }
                        }

                        Text {
                            text: modelData.title
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: isActive ? StyleTokens.textPrimary : StyleTokens.textSecondary
                            anchors.horizontalCenter: parent.horizontalCenter
                            elide: Text.ElideRight

                            Behavior on color { ColorAnimation { duration: 160 } }
                        }
                    }
                }
            }
        }

        // Keyboard hints footer
        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Text {
                text: "← → Navigate"
                font.family: root.textFontFamily
                font.pixelSize: 10
                color: StyleTokens.textMuted
            }

            Text {
                text: "↵ Select"
                font.family: root.textFontFamily
                font.pixelSize: 10
                color: StyleTokens.textMuted
            }

            Text {
                text: "Esc Close"
                font.family: root.textFontFamily
                font.pixelSize: 10
                color: StyleTokens.textMuted
            }
        }
    }
}
