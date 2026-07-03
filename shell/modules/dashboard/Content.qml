pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.filedialog

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property FileDialog facePicker

    readonly property real nonAnimWidth: dash.implicitWidth + Tokens.padding.large * 2
    readonly property real nonAnimHeight: dash.implicitHeight + Tokens.padding.large * 2

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    Dash {
        id: dash

        anchors.fill: parent
        anchors.margins: Tokens.padding.large

        visibilities: root.visibilities
        facePicker: root.facePicker
    }

    Behavior on implicitWidth {
        Anim {}
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
