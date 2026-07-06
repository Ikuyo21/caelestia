pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

// Minimal notification toast (approved mockup): app icon, summary + time,
// one truncated body line, an X to close. Fixed height - no expand/collapse,
// no progress ring, no copy button, no action buttons, no content images.
// Urgency is two-state: critical gets the error-coloured icon slot and
// container, everything else (including low) renders normal.
StyledRect {
    id: root

    required property NotifData modelData
    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
    readonly property bool hasAppIcon: modelData.appIcon.length > 0
    readonly property int bodyTextFormat: /[<*_`#\[\]]/.test(modelData.body) ? Text.MarkdownText : Text.PlainText
    readonly property int nonAnimHeight: Math.max(icon.height, summary.implicitHeight + bodyPreview.height) + inner.anchors.margins * 2

    color: critical ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer
    radius: Tokens.rounding.large

    implicitHeight: inner.implicitHeight

    x: implicitWidth
    Component.onCompleted: {
        x = 0;
        modelData.lock(this);
    }
    Component.onDestruction: modelData.unlock(this)

    Behavior on x {
        Anim {
            easing: Tokens.anim.emphasizedDecel
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: pressed ? Qt.ClosedHandCursor : undefined
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        preventStealing: true

        onEntered: root.modelData.timer.stop()
        onExited: {
            if (!pressed)
                root.modelData.timer.start();
        }

        // Horizontal swipe to dismiss stays; the old vertical swipe-to-expand
        // gesture is gone along with the expanded state
        drag.target: parent
        drag.axis: Drag.XAxis

        onPressed: event => {
            root.modelData.timer.stop();
            if (event.button === Qt.MiddleButton)
                root.modelData.close();
        }
        onReleased: () => {
            if (!containsMouse)
                root.modelData.timer.start();

            if (Math.abs(root.x) < root.implicitWidth * Config.notifs.clearThreshold)
                root.x = 0;
            else
                root.modelData.popup = false;
        }

        Item {
            id: inner

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.medium

            implicitHeight: root.nonAnimHeight

            // Icon-only, always - content images (album art, photos) are
            // intentionally never shown, even when the notification has one
            StyledRect {
                id: icon

                anchors.left: parent.left
                anchors.top: parent.top

                implicitWidth: TokenConfig.sizes.notifs.image
                implicitHeight: TokenConfig.sizes.notifs.image
                radius: Tokens.rounding.full
                color: root.critical ? Colours.palette.m3error : Colours.palette.m3secondaryContainer

                Loader {
                    asynchronous: true
                    active: root.hasAppIcon
                    anchors.centerIn: parent
                    width: Math.round(parent.width * 0.6)
                    height: Math.round(parent.width * 0.6)

                    sourceComponent: ColouredIcon {
                        anchors.fill: parent
                        source: Quickshell.iconPath(root.modelData.appIcon)
                        colour: root.critical ? Colours.palette.m3onError : Colours.palette.m3onSecondaryContainer
                        layer.enabled: root.modelData.appIcon.endsWith("symbolic")
                    }
                }

                Loader {
                    asynchronous: true
                    active: !root.hasAppIcon
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1

                    sourceComponent: MaterialIcon {
                        text: Icons.getNotifIcon(root.modelData.summary, root.modelData.urgency)
                        color: root.critical ? Colours.palette.m3onError : Colours.palette.m3onSecondaryContainer
                        fontStyle: Tokens.font.icon.medium
                    }
                }
            }

            StyledText {
                id: summary

                anchors.top: parent.top
                anchors.left: icon.right
                anchors.leftMargin: Tokens.spacing.medium

                animate: true
                text: summaryMetrics.elidedText
                maximumLineCount: 1
            }

            TextMetrics {
                id: summaryMetrics

                text: root.modelData.summary
                font: summary.font
                elide: Text.ElideRight
                elideWidth: closeBtn.x - time.width - timeSep.width - summary.x - root.Tokens.spacing.small * 3
            }

            StyledText {
                id: timeSep

                anchors.top: parent.top
                anchors.left: summary.right
                anchors.leftMargin: Tokens.spacing.small

                text: "•"
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            StyledText {
                id: time

                anchors.top: parent.top
                anchors.left: timeSep.right
                anchors.leftMargin: Tokens.spacing.small

                animate: true
                horizontalAlignment: Text.AlignLeft
                text: root.modelData.timeStr
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            // The only action: close
            Item {
                id: closeBtn

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: -Tokens.padding.extraSmall

                implicitWidth: closeIcon.implicitHeight
                implicitHeight: closeIcon.implicitHeight

                StateLayer {
                    radius: Tokens.rounding.full
                    color: root.critical ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    onClicked: root.modelData.close()
                }

                MaterialIcon {
                    id: closeIcon

                    anchors.centerIn: parent
                    text: "close"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }
            }

            // Always a single truncated preview line - fixed height, no toggle
            StyledText {
                id: bodyPreview

                anchors.left: summary.left
                anchors.right: closeBtn.left
                anchors.top: summary.bottom
                anchors.rightMargin: Tokens.spacing.small

                animate: true
                textFormat: root.bodyTextFormat
                text: bodyPreviewMetrics.elidedText
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                height: text ? implicitHeight : 0
            }

            TextMetrics {
                id: bodyPreviewMetrics

                text: root.modelData.body
                font: bodyPreview.font
                elide: Text.ElideRight
                elideWidth: bodyPreview.width
            }
        }
    }
}
