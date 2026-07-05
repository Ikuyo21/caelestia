pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Wallpaper & style")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        StyledClippingRect {
            id: wallWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: {
                const screen = root.nState.screen;
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                const cWidth = root.cappedWidth;
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
            }

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: Config.background.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Wallpaper disabled")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            Item {
                anchors.fill: parent
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }

                Loader {
                    id: wallIndicatorLoader

                    anchors.centerIn: parent

                    opacity: 0
                    active: opacity > 0

                    sourceComponent: StyledRect {
                        implicitWidth: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2
                        implicitHeight: wallLoadingIndicator.implicitSize + Tokens.padding.largeIncreased * 2

                        color: Colours.palette.m3primaryContainer
                        radius: Tokens.rounding.full

                        LoadingIndicator {
                            id: wallLoadingIndicator

                            anchors.centerIn: parent
                            containsIcon: true
                            implicitSize: Math.min(wallWrapper.implicitWidth, wallWrapper.implicitHeight) * 0.4
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }

                Timer {
                    id: wallLoadDebounceTimer

                    interval: 100
                    onTriggered: {
                        if (wallImg.status !== Image.Ready)
                            wallIndicatorLoader.opacity = 1;
                    }
                }

                FadeImage {
                    id: wallImg

                    anchors.fill: parent
                    source: Wallpapers.current
                    preventInit: wallIndicatorLoader.opacity > 0
                    fadeOutAnim: Anim.DefaultEffects
                    fadeInAnim: Anim.SlowEffects

                    onSourceChanged: wallLoadDebounceTimer.restart()

                    onStatusChanged: {
                        if (status === Image.Ready) {
                            wallLoadDebounceTimer.stop();
                            wallIndicatorLoader.opacity = 0;
                        }
                    }
                }
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: qsTr("Wallpapers")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: root.nState.openSubPage(1) // Wallpaper page
            }

            IconTextButton {
                icon: "palette"
                text: qsTr("Colours")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: root.nState.openSubPage(3) // Colours page
            }
        }

        ToggleRow {
            first: true
            text: qsTr("Display wallpaper")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            text: qsTr("Transparency")
            subtext: qsTr("Base %1, layers %2").arg(Colours.transparency.base).arg(Colours.transparency.layers)
            checked: Colours.transparency.enabled
            onToggled: GlobalConfig.appearance.transparency.enabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            last: true
            text: qsTr("Dark theme")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        // Appearance sliders (see CLAUDE.md "Corner rounding & blur/transparency"):
        // all three bind to existing native properties, no new architecture
        SectionHeader {
            text: qsTr("Appearance")
        }

        SliderRow {
            first: true
            icon: "rounded_corner"
            label: qsTr("Corner rounding")
            valueLabel: `${(+Config.appearance.rounding.scale.toFixed(2))}×`
            // scale 0-2, default 1; blob waviness (deformScale) stays fixed per spec
            value: Config.appearance.rounding.scale / 2
            onMoved: v => GlobalConfig.appearance.rounding.scale = +(v * 2).toFixed(2)
        }

        SliderRow {
            icon: "opacity"
            label: qsTr("Transparency")
            enabled: Colours.transparency.enabled
            // Transparency is a global-only option (see tokensattached.cpp:
            // "Transparency is always global"), so the per-monitor Config
            // overlay never mirrors it - reading Config.appearance here would
            // freeze the slider at the default while the write took effect.
            // Read from GlobalConfig, the same object we write to, so the
            // position tracks. Rounding above can read Config because its
            // scale is a normal (per-monitor) property the overlay does sync.
            valueLabel: qsTr("base %1").arg(+GlobalConfig.appearance.transparency.base.toFixed(2))
            value: GlobalConfig.appearance.transparency.base
            onMoved: v => GlobalConfig.appearance.transparency.base = +v.toFixed(2)
        }

        SliderRow {
            id: blurRow

            // Live Hyprland control via the same applyOptions mechanism GameMode
            // uses. Deliberately NOT persisted by the shell: the lasting default
            // lives in hypr/variables.lua (blurSize/blurPasses) or the user's
            // hypr-vars.lua override, and a hyprctl reload restores it.
            // Initialized from the live compositor value (falls back to
            // variables.lua's default of 8)
            property real strength: ((Hypr.options["decoration:blur:size"] ?? 8) / 20) // qmllint disable missing-property

            last: true
            icon: "blur_on"
            label: qsTr("Blur (until next Hyprland reload)")
            valueLabel: qsTr("size %1").arg(Math.round(strength * 20))
            value: strength
            onMoved: v => {
                strength = v;
                Hypr.extras.applyOptions({
                    "decoration:blur:enabled": v > 0 ? 1 : 0,
                    "decoration:blur:size": Math.round(v * 20),
                    "decoration:blur:passes": 2
                });
            }
        }
    }
}
