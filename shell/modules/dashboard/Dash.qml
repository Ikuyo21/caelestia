import "dash"
import QtQuick.Layouts
import Caelestia.Config
import qs.components

// Minimal dashboard (approved mockup): four stat tiles + one slim media row.
// The old user card, clock, and big media widget are gone.
ColumnLayout {
    id: root

    spacing: Tokens.spacing.small

    Performance {
        visible: Config.dashboard.showPerformance
        Layout.fillWidth: true
    }

    Media {
        visible: Config.dashboard.showMedia
        Layout.fillWidth: true
    }
}
