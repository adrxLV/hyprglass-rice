import QtQuick
import IslandBackend

Item {
    id: root

    readonly property var userConfig: UserConfig

    signal buttonPressed()
    signal clicked()

    property string kind: "play"
    property string textFontFamily: ""
    readonly property bool down: controlArea.pressed

    width: 34
    height: 34
    scale: controlArea.pressed ? 0.85 : (controlArea.containsMouse ? 1.05 : 1.0)
    opacity: enabled ? 1.0 : 0.45

    Behavior on scale {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    // Flash circle backdrop on click/press, fading out when released
    Rectangle {
        anchors.centerIn: parent
        width: 34
        height: 34
        radius: 17
        color: StyleTokens.cardFillActive
        opacity: controlArea.pressed ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: controlArea.pressed ? 50 : 350
                easing.type: Easing.OutCubic
            }
        }
    }

    // Previous: Double left triangles touching physically (eb6f + eb6f)
    Row {
        visible: root.kind === "previous"
        anchors.centerIn: parent
        spacing: -4.6

        Text {
            text: ""
            color: controlArea.pressed ? StyleTokens.textSecondary : StyleTokens.textPrimary
            font.pixelSize: 20
            font.family: userConfig.iconFontFamily !== "" ? userConfig.iconFontFamily : root.textFontFamily
        }
        Text {
            text: ""
            color: controlArea.pressed ? StyleTokens.textSecondary : StyleTokens.textPrimary
            font.pixelSize: 20
            font.family: userConfig.iconFontFamily !== "" ? userConfig.iconFontFamily : root.textFontFamily
        }
    }

    // Next: Double right triangles touching physically (eb70 + eb70)
    Row {
        visible: root.kind === "next"
        anchors.centerIn: parent
        spacing: -4.6

        Text {
            text: ""
            color: controlArea.pressed ? StyleTokens.textSecondary : StyleTokens.textPrimary
            font.pixelSize: 20
            font.family: userConfig.iconFontFamily !== "" ? userConfig.iconFontFamily : root.textFontFamily
        }
        Text {
            text: ""
            color: controlArea.pressed ? StyleTokens.textSecondary : StyleTokens.textPrimary
            font.pixelSize: 20
            font.family: userConfig.iconFontFamily !== "" ? userConfig.iconFontFamily : root.textFontFamily
        }
    }

    // Play / Pause: f04b (play) / f04c (pause)
    Text {
        visible: root.kind === "play" || root.kind === "pause"
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.kind === "play" ? 1 : 0
        text: root.kind === "pause" ? "" : ""
        color: controlArea.pressed ? StyleTokens.textSecondary : StyleTokens.textPrimary
        font.pixelSize: 22
        font.family: userConfig.iconFontFamily !== "" ? userConfig.iconFontFamily : root.textFontFamily
    }

    MouseArea {
        id: controlArea
        anchors.fill: parent
        anchors.margins: -4
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        onPressed: function(mouse) {
            root.buttonPressed();
            mouse.accepted = true;
        }
        onClicked: root.clicked()
    }
}
