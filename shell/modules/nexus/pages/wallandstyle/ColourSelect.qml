pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.services
import qs.modules.nexus.common

// Three fixed themes, no manual seed picker (see CLAUDE.md "Theming
// architecture"): Dark and Light pin the accent to the project pink and go
// through `caelestia scheme set -c`, Dynamic derives the whole palette from
// the wallpaper via `-w`. The shell just watches scheme.json.
PageBase {
    id: root

    // Fixed project accent (soft dusty rose #E39AAE) - Dark/Light pin to it.
    readonly property string accent: "e39aae"
    readonly property string current: Colours.scheme === "dynamic" ? "dynamic" : (Colours.light ? "light" : "dark")

    function apply(theme: string): void {
        if (theme === "dynamic")
            Quickshell.execDetached(["caelestia", "scheme", "set", "-w", "-m", "dark"]);
        else
            Quickshell.execDetached(["caelestia", "scheme", "set", "-c", root.accent, "-m", theme]);
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
            text: qsTr("Theme")
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.small
            spacing: Tokens.spacing.medium

            Repeater {
                model: [
                    ({
                        id: "dark",
                        label: qsTr("Dark"),
                        icon: "dark_mode",
                        desc: qsTr("Fixed dark, pink accent")
                    }),
                    ({
                        id: "light",
                        label: qsTr("Light"),
                        icon: "light_mode",
                        desc: qsTr("Cream, pink accent")
                    }),
                    ({
                        id: "dynamic",
                        label: qsTr("Dynamic"),
                        icon: "wallpaper",
                        desc: qsTr("From the wallpaper")
                    })
                ]

                StyledRect {
                    id: card

                    required property var modelData
                    readonly property bool selected: root.current === modelData.id

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1 // equal thirds
                    implicitHeight: cardCol.implicitHeight + Tokens.padding.large * 2
                    radius: Tokens.rounding.large
                    color: selected ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainer

                    // Selection carries a second indicator beyond the fill:
                    // a hairline plus the corner check below
                    border.width: selected ? 1 : 0
                    border.color: Qt.alpha(Colours.palette.m3primary, 0.5)

                    Behavior on color {
                        CAnim {}
                    }

                    MaterialIcon {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: Tokens.padding.small

                        text: "check_circle"
                        color: Colours.palette.m3onPrimaryContainer
                        fontStyle: Tokens.font.icon.medium
                        fill: 1

                        scale: card.selected ? 1 : 0
                        opacity: card.selected ? 1 : 0

                        Behavior on scale {
                            Anim {
                                type: Anim.FastSpatial
                            }
                        }

                        Behavior on opacity {
                            Anim {
                                type: Anim.FastEffects
                            }
                        }
                    }

                    ColumnLayout {
                        id: cardCol

                        anchors.centerIn: parent
                        width: parent.width - Tokens.padding.medium * 2
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: card.modelData.icon
                            color: card.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            fontStyle: Tokens.font.icon.large
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: card.modelData.label
                            color: card.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                            font: Tokens.font.title.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: card.modelData.desc
                            color: card.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.label.small
                        }
                    }

                    StateLayer {
                        anchors.fill: parent
                        radius: parent.radius
                        onClicked: root.apply(card.modelData.id)
                    }
                }
            }
        }
    }
}
