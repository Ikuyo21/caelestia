import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

StyledRect {
    id: root

    required property string icon
    required property string label
    required property string subLabel
    required property color accent
    required property real usage
    required property real temperature

    color: Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.extraLarge

    implicitWidth: Tokens.sizes.dashboard.perfHeroCardWidth
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        RowLayout {
            spacing: Tokens.spacing.medium

            MaterialIcon {
                text: root.icon
                color: root.accent
                fontStyle: Tokens.font.icon.medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: root.label
                    font: Tokens.font.title.medium
                    color: root.accent
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.subLabel
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }
            }

            StyledText {
                text: isNaN(root.usage) ? "...%" : Math.round(root.usage * 100) + "%"
                color: root.accent
                font: Tokens.font.headline.small
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            value: root.usage
            implicitHeight: Tokens.padding.small
            fgColour: root.accent
            indeterminate: isNaN(root.usage)
        }

        RowLayout {
            Layout.topMargin: Tokens.spacing.small
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: root.temperature > 90 ? "thermometer_alert" : "thermometer"
                color: root.temperature > 90 ? Colours.palette.m3error : root.accent
                fontStyle: Tokens.font.icon.medium
                fill: 1
            }

            StyledText {
                text: `${Math.ceil(GlobalConfig.services.useFahrenheitPerformance ? root.temperature * 1.8 + 32 : root.temperature)}°${GlobalConfig.services.useFahrenheitPerformance ? "F" : "C"}`
                font: Tokens.font.body.builders.medium.build()
            }

            Item {
                Layout.fillWidth: true
            }
        }

        StyledProgressBar {
            Layout.fillWidth: true
            value: root.temperature / 100
            implicitHeight: Tokens.padding.small
            fgColour: root.accent
            indeterminate: isNaN(root.usage) || isNaN(root.temperature)
        }
    }
}
