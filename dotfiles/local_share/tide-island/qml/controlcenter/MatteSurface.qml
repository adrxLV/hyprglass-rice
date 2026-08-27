import QtQuick
import IslandBackend

Item {
    id: root

    property real radius: 20
    property bool hovered: false
    property bool pressed: false
    readonly property real innerRadius: Math.max(0, radius - 1)

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.pressed ? Qt.rgba(1, 1, 1, 0.15) : (root.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
        border.width: 1
        border.color: root.pressed ? Qt.rgba(1, 1, 1, 0.22) : (root.hovered ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.08))

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }
}
