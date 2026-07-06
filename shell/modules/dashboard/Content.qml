import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    readonly property real nonAnimWidth: dash.implicitWidth + Tokens.padding.large * 2
    readonly property real nonAnimHeight: dash.implicitHeight + Tokens.padding.large * 2

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    Dash {
        id: dash

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
    }

    Behavior on implicitWidth {
        Anim {}
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
