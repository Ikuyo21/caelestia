pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

// The two theming modes, one pipeline (CLAUDE.md "Theming architecture"):
// dynamic derives the palette from the wallpaper, pick-your-own derives it
// from a single seed colour. Both go through the caelestia wrapper ->
// matugen; the shell just watches scheme.json. Rebuilt from the upstream
// "under construction" stub.
PageBase {
    id: root

    // Pending seed; #29D3F0 is the project default (electric cyan)
    property color seed: "#29D3F0"
    readonly property bool dynamic: Colours.scheme === "dynamic"
    readonly property string seedHex: root.seed.toString().slice(1)

    function applySeed(): void {
        Quickshell.execDetached(["caelestia", "scheme", "set", "-c", root.seedHex]);
    }

    title: qsTr("Colours")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Scheme mode")
        }

        ToggleRow {
            first: true
            last: true
            text: qsTr("Dynamic colours")
            subtext: qsTr("Derive the palette from the wallpaper instead of a picked seed")
            checked: root.dynamic
            onToggled: {
                if (checked)
                    Quickshell.execDetached(["caelestia", "scheme", "set", "-w"]);
                else
                    root.applySeed();
            }
        }

        SectionHeader {
            text: qsTr("Seed colour")
        }

        ConnectedRect {
            id: seedCard

            first: true
            Layout.fillWidth: true
            implicitHeight: seedLayout.implicitHeight + Tokens.padding.largeIncreased * 2

            ColumnLayout {
                id: seedLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                RowLayout {
                    spacing: Tokens.spacing.medium

                    StyledRect {
                        implicitWidth: Tokens.padding.extraLarge * 2
                        implicitHeight: Tokens.padding.extraLarge * 2
                        radius: Tokens.rounding.full
                        color: root.seed

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: `#${root.seedHex.toUpperCase()}`
                            font: Tokens.font.title.medium
                        }

                        StyledText {
                            text: root.dynamic ? qsTr("Applying a seed switches off dynamic colours") : qsTr("The whole palette is derived from this one colour")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                        }
                    }

                    IconTextButton {
                        icon: "check"
                        text: qsTr("Apply")
                        font: Tokens.font.body.large
                        isRound: true
                        shapeMorph: true
                        horizontalPadding: Tokens.padding.extraLarge
                        verticalPadding: Tokens.padding.medium
                        onClicked: root.applySeed()
                    }
                }

                // Curated presets, cyan first (the project default seed)
                RowLayout {
                    Layout.topMargin: Tokens.spacing.small
                    spacing: Tokens.spacing.medium

                    Repeater {
                        model: ["#29D3F0", "#7C6CF0", "#F06CA8", "#F05B4E", "#F0A329", "#5FD068"]

                        StyledRect {
                            id: swatch

                            required property string modelData

                            implicitWidth: Tokens.padding.extraLarge + Tokens.padding.medium * 2
                            implicitHeight: implicitWidth
                            radius: Tokens.rounding.full
                            color: swatch.modelData

                            border.width: Qt.colorEqual(root.seed, swatch.modelData) ? 2 : 0
                            border.color: Colours.palette.m3onSurface

                            StateLayer {
                                anchors.fill: parent
                                radius: parent.radius
                                onClicked: root.seed = swatch.modelData
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }

        SliderRow {
            last: true
            icon: "palette"
            label: qsTr("Hue")
            valueLabel: `${Math.round(root.seed.hsvHue * 360)}°`
            value: Math.max(0, root.seed.hsvHue)
            onMoved: v => root.seed = Qt.hsva(v, Math.max(0.4, root.seed.hsvSaturation), Math.max(0.5, root.seed.hsvValue), 1)
        }
    }
}
