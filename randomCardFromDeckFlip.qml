import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15

Window {
    id: window
    width: 635 * 0.7
    height: 890 * 0.7
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window

    property real flipAngle: 0

    // Active selection
    property string currentSuit: ""
    property string currentRank: ""
    property var currentCardMap: ({})   // cellId -> text (pip or letter)

    property var pipPatterns: ({
        "A":  [8],
        "2":  [4,12],
        "3":  [4,8,12],
        "4":  [1,3,13,15],
        "5":  [1,3,8,13,15],
        "6":  [1,3,7,9,13,15],
        "7":  [1,3,7,8,9,13,15],
        "8":  [1,3,4,6,10,12,13,15],
        "9":  [1,3,4,6,8,10,12,13,15],
        "10": [1,2,3,4,6,10,12,13,14,15]
    })

    // Build full deck programmatically, reuse patterns across suits
    function buildDeck() {
        var suits = ["♥","♦","♠","♣"]
        var deck = {}
        for (var si = 0; si < suits.length; ++si) {
            var s = suits[si]
            deck[s] = {}
            for (var rank in pipPatterns) {
                var map = {}
                for (var i = 0; i < pipPatterns[rank].length; ++i) {
                    map[pipPatterns[rank][i]] = s
                }
                deck[s][rank] = map
            }
            // Faces: center suit; corners shown by overlays
            deck[s]["J"] = { 8: s }
            deck[s]["Q"] = { 8: s }
            deck[s]["K"] = { 8: s }
        }
        return deck
    }

    property var cardDeck: buildDeck()

    function suitColor(s) {
        return (s === "♥" || s === "♦") ? "crimson" : "black"
    }

    function chooseRandomCard() {
        var suits = Object.keys(cardDeck)
        if (!suits.length) return
        var s = suits[Math.floor(Math.random()*suits.length)]
        var ranks = Object.keys(cardDeck[s])
        if (!ranks.length) return
        var r = ranks[Math.floor(Math.random()*ranks.length)]
        currentSuit = s
        currentRank = r
        currentCardMap = cardDeck[s][r]
    }

    Component.onCompleted: chooseRandomCard()

    // Outer container to simulate padding
    Item {
        id: paddedContainer
        anchors.fill: parent
        anchors.margins: 20

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 20
            color: "transparent"
            layer.enabled: true
            layer.smooth: true

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (flipAnim.running) return
                    // pick next card then flip
                    chooseRandomCard()
                    flipAnim.start()
                }
            }

            Item {
                id: flipContainer
                anchors.fill: parent

                // Front face
                Rectangle {
                    id: front
                    anchors.fill: parent
                    radius: 20
                    color: "#ffffff"
                    border.color: "#cccccc"
                    antialiasing: true
                    visible: flipAngle <= 90 || flipAngle >= 270
                    z: visible ? 1 : 0

                    // Corner overlays (always visible when front/back shown)
                    Item {
                        anchors.fill: parent

                        Column {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: -2
                            Text {
                                text: currentRank
                                color: suitColor(currentSuit)
                                font.pixelSize: 26
                                font.bold: true
                                visible: currentRank !== ""
                            }
                            Text {
                                text: currentSuit
                                color: suitColor(currentSuit)
                                font.pixelSize: 22
                                visible: currentSuit !== ""
                            }
                        }

                        Column {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 10
                            spacing: -2
                            // rotated to mimic playing card corner orientation
                            Text {
                                text: currentRank
                                color: suitColor(currentSuit)
                                font.pixelSize: 26
                                font.bold: true
                                visible: currentRank !== ""
                                rotation: 180
                            }
                            Text {
                                text: currentSuit
                                color: suitColor(currentSuit)
                                font.pixelSize: 22
                                visible: currentSuit !== ""
                                rotation: 180
                            }
                        }
                    }

                    GridLayout {
                        id: gridFront
                        anchors.fill: parent
                        anchors.margins: 60
                        columns: 3
                        rowSpacing: 0
                        columnSpacing: 0

                        Repeater {
                            model: 15
                            Rectangle {
                                property int cellId: index + 1
                                color: "transparent"
                                border.width: 0
                                // Stable sizing using Layout hints
                                Layout.preferredWidth: gridFront.width / 3
                                Layout.preferredHeight: gridFront.height / 5
                                width: Layout.preferredWidth
                                height: Layout.preferredHeight

                                Text {
                                    anchors.centerIn: parent
                                    text: currentCardMap[parent.cellId] ? currentCardMap[parent.cellId] : ""
                                    visible: text.length > 0
                                    color: suitColor(currentSuit)
                                    font.bold: true
                                    font.pixelSize: Math.min(parent.width, parent.height) * 0.6
                                }
                            }
                        }
                    }

                    transform: Rotation {
                        origin.x: front.width / 2
                        origin.y: front.height / 2
                        axis.y: 1
                        angle: flipAngle
                    }
                }

                // Back face (mirrors front layout)
                Rectangle {
                    id: back
                    anchors.fill: parent
                    radius: 20
                    color: "#ffffff"
                    border.color: "#cccccc"
                    antialiasing: true
                    visible: flipAngle > 90 && flipAngle < 270
                    z: visible ? 1 : 0

                    Item {
                        anchors.fill: parent

                        Column {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.margins: 10
                            spacing: -2
                            Text {
                                text: currentRank
                                color: suitColor(currentSuit)
                                font.pixelSize: 26
                                font.bold: true
                                visible: currentRank !== ""
                            }
                            Text {
                                text: currentSuit
                                color: suitColor(currentSuit)
                                font.pixelSize: 22
                                visible: currentSuit !== ""
                            }
                        }

                        Column {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 10
                            spacing: -2
                            Text {
                                text: currentRank
                                color: suitColor(currentSuit)
                                font.pixelSize: 26
                                font.bold: true
                                visible: currentRank !== ""
                                rotation: 180
                            }
                            Text {
                                text: currentSuit
                                color: suitColor(currentSuit)
                                font.pixelSize: 22
                                visible: currentSuit !== ""
                                rotation: 180
                            }
                        }
                    }

                    GridLayout {
                        id: gridBack
                        anchors.fill: parent
                        anchors.margins: 60
                        columns: 3
                        rowSpacing: 0
                        columnSpacing: 0

                        Repeater {
                            model: 15
                            Rectangle {
                                property int cellId: index + 1
                                color: "transparent"
                                border.width: 0
                                Layout.preferredWidth: gridBack.width / 3
                                Layout.preferredHeight: gridBack.height / 5
                                width: Layout.preferredWidth
                                height: Layout.preferredHeight

                                Text {
                                    anchors.centerIn: parent
                                    text: currentCardMap[parent.cellId] ? currentCardMap[parent.cellId] : ""
                                    visible: text.length > 0
                                    color: suitColor(currentSuit)
                                    font.bold: true
                                    font.pixelSize: Math.min(parent.width, parent.height) * 0.6
                                }
                            }
                        }
                    }

                    transform: Rotation {
                        origin.x: back.width / 2
                        origin.y: back.height / 2
                        axis.y: 1
                        angle: flipAngle + 180
                    }
                }
            }
        }
    }

    PropertyAnimation {
        id: flipAnim
        target: window
        property: "flipAngle"
        from: flipAngle
        to: flipAngle + 180
        duration: 500
        easing.type: Easing.InOutCubic
        onStopped: flipAngle = flipAngle % 360
    }
}
