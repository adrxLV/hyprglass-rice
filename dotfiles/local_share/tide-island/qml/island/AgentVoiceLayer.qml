import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import IslandBackend

Item {
    id: root

    signal closeRequested
    signal submitRequested(string voiceText)

    property bool showCondition: false
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property string heroFontFamily: ""

    property bool isListening: true
    property bool isThinking: false
    property string resultText: ""

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

    Keys.onEscapePressed: {
        root.closeRequested();
    }

    Keys.onReturnPressed: {
        if (root.isListening) {
            root.finishListening();
        }
    }
    Keys.onEnterPressed: {
        if (root.isListening) {
            root.finishListening();
        }
    }

    Process {
        id: voiceProcess
        command: ["python3", "/home/adrxlv/.local/share/tide-island/bin/tide_agent_client.py", "prompt", "Comando de voz", "--speak"]

        stdout: SplitParser {
            onRead: function(data) {
                try {
                    root.isThinking = false;
                    const res = JSON.parse(data);
                    if (res.status === "success" && res.response) {
                        root.resultText = res.response;
                    }
                } catch (e) {
                    root.isThinking = false;
                }
            }
        }
    }

    function finishListening() {
        if (!isListening) return;
        isListening = false;
        isThinking = true;
        silenceTimer.stop();
        voiceProcess.running = true;
        root.submitRequested("Comando de voz");
    }

    // Auto silence detection timer (stops listening when user stops speaking for 2.5 seconds)
    Timer {
        id: silenceTimer
        interval: 2500
        running: root.showCondition && root.isListening
        repeat: false
        onTriggered: {
            root.finishListening();
        }
    }

    // Music Menu Cava Visualizer Bars inside clean circle
    Item {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height

        SwipeCavaBars {
            anchors.centerIn: parent
            barCount: 7
            barWidth: 4
            barSpacing: 5
            minimumBarHeight: 6
            barColor: "white"
            isPlaying: root.showCondition && (root.isListening || root.isThinking)
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.isListening) {
                root.finishListening();
            } else {
                root.closeRequested();
            }
        }
    }
}
