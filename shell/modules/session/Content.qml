pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

Column {
    id: root

    required property DrawerVisibilities visibilities

    padding: Tokens.padding.large
    rightPadding: CUtils.clamp(padding - Config.border.thickness, 0, padding)
    spacing: Tokens.spacing.small

    StyledText {
        text: qsTr("[ Session ]")
        color: Colours.palette.m3primary
        font: Tokens.font.title.medium
        bottomPadding: Tokens.spacing.medium
    }

    SessionEntry {
        id: logout

        label: qsTr("Logout")
        command: Config.session.commands.logout

        KeyNavigation.down: shutdown

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.visibilities.launcher)
                    logout.forceActiveFocus();
            }

            target: root.visibilities
        }
    }

    SessionEntry {
        id: shutdown

        label: qsTr("Shutdown")
        command: Config.session.commands.shutdown

        KeyNavigation.up: logout
        KeyNavigation.down: hibernate
    }

    SessionEntry {
        id: hibernate

        label: qsTr("Hibernate")
        command: Config.session.commands.hibernate

        KeyNavigation.up: shutdown
        KeyNavigation.down: reboot
    }

    SessionEntry {
        id: reboot

        label: qsTr("Reboot")
        command: Config.session.commands.reboot

        KeyNavigation.up: hibernate
    }

    component SessionEntry: StyledRect {
        id: entry

        required property string label
        required property list<string> command

        function exec(): void {
            if (!SessionManager.exec(command))
                Quickshell.execDetached(command);
        }

        implicitWidth: Tokens.sizes.session.width
        implicitHeight: text.implicitHeight + Tokens.padding.large * 2

        radius: stateLayer.pressed ? Tokens.rounding.medium : Tokens.rounding.large
        color: activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

        RadiusBehavior on radius {}

        // Highlight bar on the focused entry
        StyledRect {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.small

            implicitWidth: entry.activeFocus ? Tokens.padding.extraSmall : 0
            implicitHeight: entry.height - Tokens.padding.medium * 2

            radius: Tokens.rounding.full
            color: Colours.palette.m3primary

            Behavior on implicitWidth {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        StyledText {
            id: text

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.extraLarge

            text: entry.label
            color: entry.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            font: Tokens.font.body.large
        }

        StateLayer {
            id: stateLayer

            anchors.fill: parent
            radius: parent.radius

            onClicked: {
                entry.forceActiveFocus();
                entry.exec();
            }
        }

        Keys.onEnterPressed: exec()
        Keys.onReturnPressed: exec()
        Keys.onEscapePressed: root.visibilities.session = false
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }
    }

    component RadiusBehavior: Behavior {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
