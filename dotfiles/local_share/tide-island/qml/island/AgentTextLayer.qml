import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import IslandBackend

Item {
    id: root

    signal closeRequested
    signal promptSubmitted(string prompt)

    property bool showCondition: false
    property string iconFontFamily: ""
    property string textFontFamily: ""
    property string heroFontFamily: ""

    property string inputPrompt: ""
    property string responseOutput: ""
    property bool hasResponse: responseOutput.trim() !== ""
    property bool isExecuting: false

    // --- Measurement strategy (same pattern as NotificationLayer) ---
    // Off-screen probe measures text height at a fixed width, avoiding binding loops.
    readonly property real textAreaWidth: 380
    readonly property real horizontalPadding: 20
    readonly property real verticalPadding: 16
    readonly property real inputHeight: 40
    readonly property real spacing: 8
    readonly property real maxResponseHeight: 460

    readonly property real measuredResponseHeight: Math.min(
        maxResponseHeight,
        Math.max(60, responseProbe.implicitHeight + 28)
    )
    readonly property real preferredHeight: {
        if (!hasResponse) return inputHeight + verticalPadding * 2;
        return inputHeight + spacing + measuredResponseHeight + verticalPadding * 2;
    }
    readonly property real preferredWidth: 420

    // Off-screen invisible probe — measures text at fixed width to avoid circular dependency
    TextEdit {
        id: responseProbe
        x: -10000
        y: -10000
        width: root.textAreaWidth
        opacity: 0
        text: root.responseOutput
        font.family: root.textFontFamily
        font.pixelSize: 14
        font.weight: Font.Normal
        wrapMode: TextEdit.Wrap
        textFormat: TextEdit.MarkdownText
        readOnly: true
    }

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
            root.grabKeyboardFocus();
        }
    }

    function grabKeyboardFocus() {
        root.focus = true;
        root.forceActiveFocus();
        promptInput.forceActiveFocus();
    }

    Process {
        id: agentProcess
        command: ["python3", "/home/adrxlv/.local/share/tide-island/bin/tide_agent_client.py", "prompt", root.inputPrompt]

        stdout: SplitParser {
            onRead: function(data) {
                try {
                    root.isExecuting = false;
                    const res = JSON.parse(data);
                    if (res.status === "success" && res.response) {
                        root.responseOutput = res.response;
                    } else if (res.status === "error" || res.status === "offline") {
                        root.responseOutput = res.error || "Erro de execução.";
                    } else {
                        root.responseOutput = res.response || res.message || data;
                    }
                } catch (e) {
                    root.isExecuting = false;
                    root.responseOutput = data;
                }
            }
        }

        onExited: {
            root.isExecuting = false;
        }
    }

    function submitPrompt() {
        if (root.inputPrompt.trim() === "") return;
        root.isExecuting = true;
        root.responseOutput = "";
        agentProcess.command = ["python3", "/home/adrxlv/.local/share/tide-island/bin/tide_agent_client.py", "prompt", root.inputPrompt];
        agentProcess.running = true;
    }

    Keys.onEscapePressed: {
        root.closeRequested();
    }

    // ─── Visual Layout ───────────────────────────────────────────
    Item {
        id: contentLayout
        anchors.fill: parent
        anchors.topMargin: root.verticalPadding
        anchors.bottomMargin: root.verticalPadding
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding

        // ─── Input Field ─────────────────────────────────────────
        Rectangle {
            id: inputContainer
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.inputHeight
            radius: root.inputHeight / 2
            color: Qt.rgba(1, 1, 1, 0.06)
            border.color: promptInput.activeFocus ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Behavior on border.color { ColorAnimation { duration: 200; easing.type: Easing.InOutQuad } }

            TextInput {
                id: promptInput
                anchors.left: parent.left
                anchors.right: indicatorBars.visible ? indicatorBars.left : parent.right
                anchors.leftMargin: 18
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: "#f0f0f5"
                selectionColor: "#0a84ff"
                selectedTextColor: "#ffffff"
                font.family: root.textFontFamily
                font.pixelSize: 14
                font.weight: Font.Normal
                clip: true
                selectByMouse: true
                text: root.inputPrompt

                Text {
                    text: "Ask Tide…"
                    color: Qt.rgba(1, 1, 1, 0.3)
                    font: parent.font
                    visible: !parent.text && !parent.inputMethodComposing
                    anchors.verticalCenter: parent.verticalCenter
                }

                onTextChanged: {
                    if (root.inputPrompt !== text)
                        root.inputPrompt = text;
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.submitPrompt();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        root.closeRequested();
                        event.accepted = true;
                    }
                }
            }

            SwipeCavaBars {
                id: indicatorBars
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                barCount: 4
                barWidth: 3
                barSpacing: 2
                minimumBarHeight: 3
                barColor: Qt.rgba(1, 1, 1, 0.6)
                isPlaying: root.isExecuting
                visible: root.isExecuting
            }
        }

        // ─── Response Area ───────────────────────────────────────
        Item {
            id: responseContainer
            anchors.top: inputContainer.bottom
            anchors.topMargin: root.spacing
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.hasResponse
            opacity: root.hasResponse ? 1 : 0
            clip: true

            Behavior on opacity {
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
            }

            // Subtle top separator line
            Rectangle {
                id: topSeparator
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
                radius: 0.5
            }

            Flickable {
                id: responseFlick
                anchors.top: topSeparator.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 2
                anchors.rightMargin: 2
                contentHeight: responseTextEdit.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                TextEdit {
                    id: responseTextEdit
                    width: responseFlick.width
                    text: root.responseOutput
                    color: Qt.rgba(1, 1, 1, 0.88)
                    font.family: root.textFontFamily
                    font.pixelSize: 14
                    font.weight: Font.Normal
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.MarkdownText
                    selectedTextColor: "#ffffff"
                    selectionColor: "#0a84ff"
                }
            }

            // Scroll fade at bottom when content overflows
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 24
                visible: responseFlick.contentHeight > responseFlick.height
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.7) }
                }
            }
        }
    }
}
