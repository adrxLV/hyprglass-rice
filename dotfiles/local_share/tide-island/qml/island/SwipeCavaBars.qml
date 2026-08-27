import QtQuick

Item {
    id: root

    property var levels: [0, 0, 0, 0, 0, 0, 0, 0]
    property bool isPlaying: true
    property int barCount: Math.max(1, levelCount() > 0 ? levelCount() : 5)
    property real barWidth: 3
    property real barSpacing: 3
    property real minimumBarHeight: 4
    property color barColor: "white"

    property real visualizerPhase: 0

    Timer {
        interval: 50
        running: root.isPlaying && !root.hasRealCavaData()
        repeat: true
        onTriggered: {
            root.visualizerPhase += 0.18;
            if (root.visualizerPhase > Math.PI * 2)
                root.visualizerPhase -= Math.PI * 2;
        }
    }

    function hasRealCavaData() {
        if (!levels) return false;
        const count = Number(levels.length);
        if (!isFinite(count) || count === 0) return false;
        for (let i = 0; i < count; i++) {
            if (Number(levels[i]) > 0.02) return true;
        }
        return false;
    }

    function levelCount() {
        if (hasRealCavaData()) {
            const count = Number(levels.length);
            return isFinite(count) && count > 0 ? Math.floor(count) : 5;
        }
        return 5;
    }

    function levelAt(index) {
        if (hasRealCavaData()) {
            return Number(levels[index]);
        }
        if (isPlaying) {
            const phase = visualizerPhase + index * 0.78;
            const primary = (Math.sin(phase) + 1) * 0.5;
            const secondary = (Math.sin(phase * 2 + index * 0.95) + 1) * 0.5;
            return 0.22 + primary * 0.42 + secondary * 0.24;
        }
        return 0;
    }

    implicitWidth: barCount * barWidth + Math.max(0, barCount - 1) * barSpacing
    implicitHeight: 18
    width: implicitWidth
    height: implicitHeight

    Row {
        anchors.fill: parent
        spacing: root.barSpacing

        Repeater {
            model: root.barCount

            delegate: Rectangle {
                readonly property real rawLevel: root.levelAt(index)
                readonly property real clampedLevel: Math.max(0, Math.min(1, isNaN(rawLevel) ? 0 : rawLevel))

                width: root.barWidth
                height: root.minimumBarHeight + (parent.height - root.minimumBarHeight) * clampedLevel
                radius: width / 2
                color: root.barColor
                anchors.verticalCenter: parent.verticalCenter

                Behavior on height {
                    NumberAnimation {
                        duration: 90
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }
}
