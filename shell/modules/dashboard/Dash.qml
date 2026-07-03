import "dash"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.services

ColumnLayout {
    id: root

    required property DrawerVisibilities visibilities
    required property FileDialog facePicker

    spacing: Tokens.spacing.medium

    RowLayout {
        // Media drives the strip height even when hidden, so toggling it
        // doesn't collapse the user/clock cards
        Layout.preferredHeight: media.implicitHeight
        spacing: Tokens.spacing.medium

        Rect {
            Layout.preferredWidth: dateTime.implicitWidth
            Layout.fillHeight: true

            radius: Tokens.rounding.large

            DateTime {
                id: dateTime
            }
        }

        Rect {
            Layout.preferredWidth: Tokens.sizes.dashboard.userWidth
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.extraLarge

            User {
                visibilities: root.visibilities
                facePicker: root.facePicker
            }
        }

        Rect {
            visible: Config.dashboard.showMedia
            Layout.preferredWidth: media.implicitWidth
            Layout.fillHeight: true

            radius: Tokens.rounding.extraLarge * 2

            Media {
                id: media
            }
        }
    }

    Performance {
        visible: Config.dashboard.showPerformance
        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
    }

    component Rect: StyledRect {
        color: Colours.tPalette.m3surfaceContainer
    }
}
