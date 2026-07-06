pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

// Minimal performance strip (approved mockup): four small stat tiles in a
// row - muted label, percentage, thin accent progress bar. No icons, no
// circular gauges, no per-card detail views.
RowLayout {
    id: root

    spacing: Tokens.spacing.small

    Tile {
        shown: Config.dashboard.performance.showCpu
        label: qsTr("CPU")
        usage: Cpu.percentage
        refService: Cpu
    }

    Tile {
        shown: Config.dashboard.performance.showGpu && Gpu.type !== Gpu.None
        label: qsTr("GPU")
        usage: Gpu.percentage
        refService: Gpu
    }

    Tile {
        shown: Config.dashboard.performance.showMemory
        label: qsTr("RAM")
        usage: Memory.percentage
        refService: Memory
    }

    Tile {
        shown: Config.dashboard.performance.showStorage
        label: qsTr("Storage")
        usage: Storage.primaryDisk?.perc ?? 0
        refService: Storage
    }

    component Tile: Loader {
        id: tile

        required property bool shown
        required property string label
        required property real usage
        // The native services are ref-counted; holding a ServiceRef while the
        // tile is loaded keeps its poller alive (and only then)
        required property var refService

        Layout.preferredWidth: Tokens.sizes.dashboard.statTileWidth
        Layout.fillWidth: true
        visible: shown
        active: shown

        sourceComponent: StyledRect {
            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainer
            implicitHeight: col.implicitHeight + Tokens.padding.medium * 2

            ServiceRef {
                service: tile.refService
            }

            ColumnLayout {
                id: col

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.extraSmall

                StyledText {
                    text: tile.label
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }

                StyledText {
                    animate: true
                    text: `${Math.round(tile.usage * 100)}%`
                    // Mono digits: percentages change every poll, and
                    // fixed-width figures keep the tile from jittering
                    font: Tokens.font.mono.builders.large.weight(Font.Medium).build()
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.spacing.extraSmall / 2
                    implicitHeight: Tokens.sizes.dashboard.statBarHeight
                    radius: implicitHeight / 2
                    color: Colours.tPalette.m3surfaceContainerHighest

                    StyledRect {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.max(0, Math.min(1, tile.usage))
                        radius: parent.radius
                        color: Colours.palette.m3primary

                        Behavior on width {
                            Anim {}
                        }
                    }
                }
            }
        }
    }
}
