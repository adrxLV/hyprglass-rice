import QtQuick
import IslandBackend

Rectangle {
    id: root

    signal interactionStarted()
    signal valueMoved(real value)
    signal commitRequested()
    signal cancelRequested()

    property string title: ""
    property string iconText: ""
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property real value: 0
    property real knobSize: 24
    property color moduleColor: StyleTokens.module
    property color moduleHover: StyleTokens.moduleHover
    property color trackColor: StyleTokens.track
    property color textPrimary: StyleTokens.textPrimary
    property color textSecondary: StyleTokens.textSecondary
    readonly property bool pressed: sliderArea.pressed

    function clamp01(nextValue) {
        return Math.max(0, Math.min(1, nextValue));
    }

    radius: 20
    color: StyleTokens.clearBlack
    clip: true

    MatteSurface {
        anchors.fill: parent
        radius: root.radius
        hovered: sliderArea.containsMouse
        pressed: sliderArea.pressed
    }

    Item {
        anchors.fill: parent
        anchors.margins: 12

        Text {
            id: cardTitle
            anchors.left: parent.left
            anchors.top: parent.top
            text: root.title
            color: root.textPrimary
            font.pixelSize: 13
            font.family: root.textFontFamily
            font.weight: Font.DemiBold
        }

        // Percentage value text at top right
        Text {
            anchors.right: parent.right
            anchors.baseline: cardTitle.baseline
            text: Math.round(root.value * 100) + "%"
            color: root.textSecondary
            font.pixelSize: 11
            font.family: root.textFontFamily
            font.weight: Font.Medium
        }

        // macOS Apple Style Capsule Slider Track
        Rectangle {
            id: sliderTrack
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 28
            radius: 14
            color: Qt.rgba(0, 0, 0, 0.2)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.1)
            clip: true

            // Filled white capsule portion (macOS Control Center style)
            Rectangle {
                id: fillBar
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.value <= 0.001 ? 0 : Math.max(sliderTrack.height, sliderTrack.width * root.value)
                radius: sliderTrack.radius
                color: "#ffffff"
                opacity: 0.95

                Behavior on width {
                    enabled: !sliderArea.pressed
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }

            // Left icon — adapts color dynamically for contrast over white fill
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.iconText
                color: root.value > 0.15 ? "#181a20" : root.textSecondary
                font.pixelSize: 13
                font.family: root.iconFontFamily
                z: 5

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
            }

            MouseArea {
                id: sliderArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function update(mouseX) {
                    root.valueMoved(root.clamp01(mouseX / width));
                }

                onPressed: function(mouse) {
                    root.interactionStarted();
                    update(mouse.x);
                }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        update(mouse.x);
                }
                onReleased: root.commitRequested()
                onCanceled: root.cancelRequested()
            }
        }
    }
}
