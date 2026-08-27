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

    property string inputQuery: ""
    property string displayTitle: ""
    property string mainResult: ""
    property var rootsList: []
    property var graphData: null
    property bool hasGraph: false
    readonly property bool hasResult: mainResult !== ""
    property string toastMessage: ""

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

    Process {
        id: calcProcess
        command: ["python3", "/home/adrxlv/.local/share/tide-island/bin/calc_engine.py", root.inputQuery]

        stdout: SplitParser {
            onRead: function(data) {
                try {
                    const res = JSON.parse(data);
                    if (res.status === "success" && root.inputQuery.trim() !== "") {
                        root.displayTitle = res.display_title || "";
                        root.mainResult = res.main_result || "";
                        root.rootsList = res.roots || [];
                        root.hasGraph = res.has_graph === true;
                        root.graphData = res.has_graph ? (res.graph || null) : null;
                        graphCanvas.requestPaint();
                    } else {
                        root.clearResult();
                    }
                } catch (e) {
                    root.clearResult();
                }
            }
        }
    }

    function clearResult() {
        root.mainResult = "";
        root.rootsList = [];
        root.hasGraph = false;
        root.graphData = null;
        root.displayTitle = "";
    }

    Timer {
        id: debounceTimer
        interval: 160
        repeat: false
        onTriggered: {
            if (root.inputQuery.trim() !== "") {
                calcProcess.running = true;
            } else {
                root.clearResult();
            }
        }
    }

    onInputQueryChanged: {
        if (inputQuery.trim() === "") {
            debounceTimer.stop();
            if (calcProcess.running) calcProcess.running = false;
            root.clearResult();
        } else {
            debounceTimer.restart();
        }
    }

    onShowConditionChanged: {
        if (showCondition) {
            toastMessage = "";
            if (inputQuery.trim() !== "") {
                calcProcess.running = true;
            } else {
                root.clearResult();
            }
            root.grabKeyboardFocus();
        }
    }

    function grabKeyboardFocus() {
        root.focus = true;
        root.forceActiveFocus();
        calcInput.forceActiveFocus();
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

    function copyResultToClipboard() {
        if (mainResult !== "") {
            Quickshell.execDetached(["bash", "-c", "echo -n '" + mainResult + "' | wl-copy"]);
            showToast("Copied!");
        }
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Escape:
            root.closeRequested();
            event.accepted = true;
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.copyResultToClipboard();
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

        // Header — icon badge + title + toast
        Item {
            id: headerRow
            width: parent.width
            height: 26
            anchors.top: parent.top

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: Qt.rgba(1, 1, 1, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "󰪚"
                        font.family: root.iconFontFamily
                        font.pixelSize: 13
                        color: StyleTokens.accent
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Calculator"
                    font.family: root.textFontFamily
                    font.pixelSize: 14
                    font.bold: true
                    color: StyleTokens.textPrimary
                }
            }

            // Toast pill
            Rectangle {
                visible: root.toastMessage !== ""
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 22
                width: toastText.implicitWidth + 14
                radius: 11
                color: Qt.rgba(1, 1, 1, 0.12)

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

        // Input field
        Rectangle {
            id: inputRow
            anchors.top: headerRow.bottom
            anchors.topMargin: 10
            width: parent.width
            height: 34
            radius: 12
            color: calcInput.activeFocus ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
            border.width: 1
            border.color: calcInput.activeFocus ? StyleTokens.inputBorder : Qt.rgba(1, 1, 1, 0.1)

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    font.family: root.iconFontFamily
                    font.pixelSize: 13
                    color: StyleTokens.textMuted
                }

                TextInput {
                    id: calcInput
                    width: parent.width - 32
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.textFontFamily
                    font.pixelSize: 14
                    color: StyleTokens.textPrimary
                    selectByMouse: true
                    clip: true
                    text: root.inputQuery
                    onTextChanged: root.inputQuery = text

                    Text {
                        text: "Ex: 2x + 1 = 0  or  f(x) = x² − 4"
                        font.family: root.textFontFamily
                        font.pixelSize: 12
                        color: StyleTokens.textMuted
                        visible: !parent.text && !parent.inputMethodComposing
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.Keys.onPressed(event);
                        }
                    }
                }
            }
        }

        // Result area — fills remaining space between input and footer
        Item {
            id: resultArea
            anchors.top: inputRow.bottom
            anchors.topMargin: 10
            anchors.bottom: footerRow.top
            anchors.bottomMargin: 8
            width: parent.width
            visible: root.inputQuery.trim() !== "" && root.mainResult !== ""
            opacity: visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
            }

            // COMPACT MODE — no graph (arithmetic / equation)
            Item {
                visible: !root.hasGraph
                anchors.fill: parent

                // Single result display — centered vertically in the available space
                Rectangle {
                    visible: root.mainResult !== ""
                    anchors.centerIn: parent
                    width: parent.width
                    height: root.rootsList.length >= 2 ? resultColumn.implicitHeight + 24 : 52
                    radius: 16
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)

                    Behavior on height {
                        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                    }

                    Column {
                        id: resultColumn
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: root.mainResult
                            font.family: root.textFontFamily
                            font.pixelSize: root.rootsList.length >= 2 ? 17 : 20
                            font.bold: true
                            color: StyleTokens.accent
                            anchors.horizontalCenter: parent.horizontalCenter
                            elide: Text.ElideRight
                        }

                        // Solution pills row — only when 2+ solutions
                        Row {
                            visible: root.rootsList.length >= 2
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8

                            Repeater {
                                model: root.rootsList

                                delegate: Rectangle {
                                    height: 24
                                    width: rootText.implicitWidth + 16
                                    radius: 12
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.1)

                                    Text {
                                        id: rootText
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.family: root.textFontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: StyleTokens.textPrimary
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // GRAPH MODE — f(x) declaration
            Row {
                visible: root.hasGraph
                anchors.fill: parent
                spacing: 12

                // Left: result + solutions
                Column {
                    width: 220
                    height: parent.height
                    spacing: 10

                    Rectangle {
                        width: parent.width
                        height: 52
                        radius: 16
                        color: "transparent"
                        border.width: 1
                        border.color: StyleTokens.accent

                        Text {
                            anchors.centerIn: parent
                            text: root.mainResult
                            font.family: root.textFontFamily
                            font.pixelSize: 15
                            font.bold: true
                            color: StyleTokens.accent
                            elide: Text.ElideRight
                            width: parent.width - 20
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Rectangle {
                        visible: root.rootsList.length >= 2
                        width: parent.width
                        height: parent.height - 62
                        radius: 16
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.1)
                        clip: true

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Text {
                                text: "Solutions:"
                                font.family: root.textFontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: StyleTokens.textSecondary
                            }

                            Repeater {
                                model: root.rootsList

                                delegate: Rectangle {
                                    width: parent.width
                                    height: 26
                                    radius: 13
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.1)

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData
                                        font.family: root.textFontFamily
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: StyleTokens.textPrimary
                                    }
                                }
                            }
                        }
                    }
                }

                // Right: 2D Graph Canvas
                Rectangle {
                    width: parent.width - 232
                    height: parent.height
                    radius: 16
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    clip: true

                    Canvas {
                        id: graphCanvas
                        anchors.fill: parent
                        anchors.margins: 6

                        onPaint: {
                            if (!root.hasGraph) return;

                            const ctx = getContext("2d");
                            const w = width;
                            const h = height;

                            ctx.clearRect(0, 0, w, h);

                            const g = root.graphData;
                            const xMin = g ? g.xMin : -10.0;
                            const xMax = g ? g.xMax : 10.0;
                            const yMin = g ? g.yMin : -10.0;
                            const yMax = g ? g.yMax : 10.0;

                            function toScreenX(x) { return (x - xMin) / (xMax - xMin) * w; }
                            function toScreenY(y) { return h - (y - yMin) / (yMax - yMin) * h; }

                            // Grid
                            const gridColor = Qt.rgba(1, 1, 1, 0.06);
                            ctx.strokeStyle = gridColor;
                            ctx.lineWidth = 1;
                            for (var gx = -10; gx <= 10; gx += 2) {
                                var sx = toScreenX(gx);
                                ctx.beginPath();
                                ctx.moveTo(sx, 0);
                                ctx.lineTo(sx, h);
                                ctx.stroke();
                            }
                            for (var gy = Math.ceil(yMin); gy <= yMax; gy += Math.max(1, Math.round((yMax - yMin) / 10))) {
                                var sy = toScreenY(gy);
                                ctx.beginPath();
                                ctx.moveTo(0, sy);
                                ctx.lineTo(w, sy);
                                ctx.stroke();
                            }

                            // Axes
                            const axisColor = Qt.rgba(1, 1, 1, 0.2);
                            const originX = toScreenX(0);
                            const originY = toScreenY(0);

                            ctx.strokeStyle = axisColor;
                            ctx.lineWidth = 1.5;

                            if (originY >= 0 && originY <= h) {
                                ctx.beginPath();
                                ctx.moveTo(0, originY);
                                ctx.lineTo(w, originY);
                                ctx.stroke();
                            }
                            if (originX >= 0 && originX <= w) {
                                ctx.beginPath();
                                ctx.moveTo(originX, 0);
                                ctx.lineTo(originX, h);
                                ctx.stroke();
                            }

                            // Function curve
                            if (g && g.points && g.points.length > 1) {
                                ctx.strokeStyle = StyleTokens.accent;
                                ctx.lineWidth = 2.5;
                                ctx.beginPath();

                                var first = true;
                                for (var i = 0; i < g.points.length; i++) {
                                    var px = toScreenX(g.points[i][0]);
                                    var py = toScreenY(g.points[i][1]);

                                    if (py >= -50 && py <= h + 50) {
                                        if (first) {
                                            ctx.moveTo(px, py);
                                            first = false;
                                        } else {
                                            ctx.lineTo(px, py);
                                        }
                                    } else {
                                        first = true;
                                    }
                                }
                                ctx.stroke();

                                // Zero dots
                                if (g.zeros) {
                                    for (var z = 0; z < g.zeros.length; z++) {
                                        var zx = toScreenX(g.zeros[z][0]);
                                        var zy = toScreenY(g.zeros[z][1]);

                                        ctx.fillStyle = StyleTokens.danger;
                                        ctx.beginPath();
                                        ctx.arc(zx, zy, 4.5, 0, 2 * Math.PI);
                                        ctx.fill();

                                        ctx.strokeStyle = StyleTokens.white;
                                        ctx.lineWidth = 1;
                                        ctx.stroke();
                                    }
                                }
                            }
                        }
                    }

                    // Legend pill
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: 8
                        height: 20
                        width: legendText.implicitWidth + 14
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.08)

                        Text {
                            id: legendText
                            anchors.centerIn: parent
                            text: root.displayTitle !== "" ? root.displayTitle : "2D Graph"
                            font.family: root.textFontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: StyleTokens.accent
                        }
                    }
                }
            }
        }

        // Keyboard hints footer
        Row {
            id: footerRow
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Text {
                visible: root.mainResult !== ""
                text: "↵ Copy"
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
