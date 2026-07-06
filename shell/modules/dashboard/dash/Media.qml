pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

// Slim media row (approved mockup): small album-art thumbnail, track/artist,
// a single play/pause icon. No progress arc, no skip buttons, no position
// polling - the previous card's Timer and CircularProgress are gone with it.
StyledRect {
    id: root

    readonly property var player: Players.active

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer
    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        StyledClippingRect {
            implicitWidth: Tokens.sizes.dashboard.mediaArtSize
            implicitHeight: Tokens.sizes.dashboard.mediaArtSize
            radius: Tokens.rounding.small
            color: Colours.tPalette.m3surfaceContainerHighest

            MaterialIcon {
                anchors.centerIn: parent
                text: "music_note"
                color: Colours.palette.m3onSurfaceVariant
                visible: art.status !== Image.Ready
            }

            Image {
                id: art

                anchors.fill: parent
                source: Players.getArtUrl(root.player)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                animate: true
                text: (root.player?.trackTitle ?? "") || qsTr("No media")
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                animate: true
                text: (root.player?.trackArtist ?? "") || qsTr("Nothing playing")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        MaterialIcon {
            text: root.player?.isPlaying ? "pause" : "play_arrow"
            color: root.player?.canTogglePlaying ? Colours.palette.m3primary : Colours.palette.m3outline
            fontStyle: Tokens.font.icon.medium

            StateLayer {
                anchors.fill: parent
                anchors.margins: -Tokens.padding.small
                radius: Tokens.rounding.full
                disabled: !root.player?.canTogglePlaying
                onClicked: root.player?.togglePlaying()
            }
        }
    }
}
