/*
    SPDX-FileCopyrightText: 2021 Vlad Zahorodnii <vlad.zahorodnii@kde.org>
    SPDX-FileCopyrightText: 2022 ivan tkachenko <me@ratijas.tk>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

// Fork note: the desktop bar no longer supports deleting or renaming virtual
// desktops; the "Add Virtual Desktop" button remains.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWinComponents
import org.kde.kwin.private.effects
import org.kde.plasma.components as PC3

Item {
    id: bar

    readonly property real desktopHeight: Kirigami.Units.gridUnit * 5
    readonly property real desktopWidth: desktopHeight * targetScreen.geometry.width / targetScreen.geometry.height
    readonly property real columnHeight: desktopHeight + Kirigami.Units.gridUnit
    readonly property real columnWidth: desktopWidth + Kirigami.Units.gridUnit
    readonly property int desktopCount: desktopRepeater.count
    readonly property int highlightThickness: Kirigami.Units.smallSpacing

    property bool verticalDesktopBar
    property KWinComponents.WindowModel windowModel
    property alias desktopModel: desktopRepeater.model
    property QtObject selectedDesktop: null
    property var heap

    implicitHeight: columnHeight + 2 * Kirigami.Units.smallSpacing
    implicitWidth: columnWidth + 2 * Kirigami.Units.smallSpacing

    Flickable {
        anchors.fill: parent
        leftMargin: Math.max(((width - contentWidth) / 2) + bar.highlightThickness, 0)
        topMargin: Math.max(((height - contentHeight) / 2) + bar.highlightThickness, 0)
        contentWidth: contentItem.childrenRect.width
        contentHeight: contentItem.childrenRect.height
        interactive: contentWidth > width
        clip: true
        flickableDirection: Flickable.HorizontalFlick

        Grid {
            spacing: Kirigami.Units.largeSpacing + bar.highlightThickness
            columns: verticalDesktopBar ? 1 : desktopCount + 1

            Repeater {
                id: desktopRepeater

                Column {
                    id: delegate
                    activeFocusOnTab: true
                    width: bar.desktopWidth
                    height: bar.columnHeight
                    spacing: Kirigami.Units.smallSpacing

                    required property KWinComponents.VirtualDesktop desktop
                    required property int index

                    Keys.onEnterPressed: activate();
                    Keys.onReturnPressed: activate();
                    Keys.onSpacePressed: activate();

                    Keys.onLeftPressed: nextItemInFocusChain(LayoutMirroring.enabled).forceActiveFocus(Qt.BacktabFocusReason);
                    Keys.onRightPressed: nextItemInFocusChain(!LayoutMirroring.enabled).forceActiveFocus(Qt.TabFocusReason);

                    function activate() {
                        if (KWinComponents.SceneView.currentDesktop === delegate.desktop) {
                            effect.deactivate()
                        } else {
                            KWinComponents.SceneView.currentDesktop = delegate.desktop;
                        }
                    }

                    Item {
                        width: bar.desktopWidth
                        height: bar.desktopHeight


                        HoverHandler {
                            id: thumbnailHover
                        }

                        DesktopView {
                            id: thumbnail

                            width: targetScreen.geometry.width
                            height: targetScreen.geometry.height
                            windowModel: bar.windowModel
                            desktop: delegate.desktop
                            scale: bar.desktopHeight / targetScreen.geometry.height
                            transformOrigin: Item.TopLeft


                            layer.textureSize: Qt.size(bar.desktopWidth, bar.desktopHeight)
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    anchors.centerIn: parent
                                    width: thumbnail.width
                                    height: thumbnail.height
                                    // Using 5% of width since that's constant even under scaling:
                                    radius: width / 20
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Kirigami.Units.cornerRadius
                            color: "transparent"
                            border.width: 1
                            border.color: highlight.visible ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        }

                        Highlight {
                            id: highlight
                            active: delegate.activeFocus || bar.selectedDesktop === delegate.desktop
                            hovered: thumbnailHover.hovered
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: mouse => {
                                mouse.accepted = true;
                                delegate.activate();
                            }
                        }

                        DropArea {
                            anchors.fill: parent
                            onEntered: (drag) => {
                                drag.accepted = true;
                            }
                            onDropped: drop => {
                                drop.accepted = true;
                                // dragging a KWin::Window
                                if (drag.source.desktops.length === 0 || drag.source.desktops.indexOf(delegate.desktop) !== -1) {
                                    drop.action = Qt.IgnoreAction;
                                    return;
                                }
                                drag.source.desktops = [delegate.desktop];
                            }
                        }
                    }

                    // Workspace renaming is disabled in this fork; the name is read-only
                    Item {
                        id: label
                        width: bar.desktopWidth
                        height: Kirigami.Units.gridUnit

                        PC3.Label {
                            anchors.fill: parent
                            elide: Text.ElideRight
                            text: delegate.desktop.name
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            PC3.Button {
                width: bar.desktopWidth
                height: bar.desktopHeight

                text: if (desktopCount < desktopModel.maximum) {
                    i18nd("kwin", "Add Virtual Desktop")
                } else {
                    i18nd("kwin", "Virtual Desktop limit reached")
                }
                icon.name: "list-add"
                display: PC3.AbstractButton.IconOnly
                enabled: desktopCount < desktopModel.maximum

                Highlight {
                    active: parent.activeFocus
                    hovered: parent.hovered && parent.enabled
                }

                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                PC3. ToolTip.delay: Kirigami.Units.toolTipDelay
                Accessible.name: text

                Keys.onReturnPressed: action.trigger()
                Keys.onEnterPressed: action.trigger()

                Keys.onLeftPressed: nextItemInFocusChain(LayoutMirroring.enabled).forceActiveFocus(Qt.BacktabFocusReason);
                Keys.onRightPressed: nextItemInFocusChain(!LayoutMirroring.enabled).forceActiveFocus(Qt.TabFocusReason);

                onClicked: desktopModel.create(desktopModel.rowCount())

                DropArea {
                    anchors.fill: parent
                    onEntered: drag => {
                        drag.accepted = desktopCount < desktopModel.maximum;
                    }
                    onDropped: drag => {
                        drag.source.desktops = [desktopModel.create(desktopModel.rowCount())];
                    }
                }
            }

            component Highlight: Rectangle {
                required property bool active
                required property bool hovered
                visible: active || hovered
                anchors.fill: parent
                anchors.margins: -bar.highlightThickness
                radius: Kirigami.Units.cornerRadius
                color: Kirigami.Theme.highlightColor
                opacity: !active && hovered ? 0.5 : 1.0
                z: -10
            }
        }
    }
}
