/*
    SPDX-FileCopyrightText: 2021 Vlad Zahorodnii <vlad.zahorodnii@kde.org>
    SPDX-FileCopyrightText: 2022 ivan tkachenko <me@ratijas.tk>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

// Fork note: creating, deleting and renaming virtual desktops from the
// desktop bar is only available when the effect's "workspace management"
// toggle is enabled; unless then the names are read-only labels.

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
    // Fork: the effect's "workspace management" toggle, propagated from
    // OverviewEffect (C++) on reconfigure.
    readonly property bool workspaceManagement: effect.workspaceManagement

    property bool verticalDesktopBar
    property KWinComponents.WindowModel windowModel
    property QtObject selectedDesktop: null
    property var heap

    implicitHeight: columnHeight + 2 * Kirigami.Units.smallSpacing
    implicitWidth: columnWidth + 2 * Kirigami.Units.smallSpacing

    KWinComponents.VirtualDesktopModel {
        id: virtualDesktopModel
    }

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
            // Fork: one extra cell for the "Add Virtual Desktop" button, only
            // when workspace management is enabled.
            columns: verticalDesktopBar ? 1 : desktopCount + (bar.workspaceManagement ? 1 : 0)

            Repeater {
                id: desktopRepeater
                model: virtualDesktopModel

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

                    // Fork: workspace management hotkeys, only while the
                    // toggle is enabled (Delete = delete desktop,
                    // F2 = rename desktop).
                    Keys.onDeletePressed: if (bar.workspaceManagement) remove();

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_F2 && bar.workspaceManagement) {
                            event.accepted = true;
                            label.startEditing();
                        }
                    }

                    function remove() {
                        if (desktopRepeater.count === 1) {
                            return;
                        }
                        if (delegate.activeFocus) {
                            if (delegate.index === 0) {
                                desktopRepeater.itemAt(1).forceActiveFocus();
                            } else {
                                desktopRepeater.itemAt(delegate.index - 1).forceActiveFocus();
                            }
                        }
                        virtualDesktopModel.remove(delegate.index);
                    }

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

                        // Fork: hover "Delete Virtual Desktop" button, only
                        // while the "workspace management" toggle is enabled.
                        Loader {
                            LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
                            active: bar.workspaceManagement && !bar.heap.dragActive
                                && (hoverHandler.hovered || Kirigami.Settings.tabletMode || Kirigami.Settings.hasTransientTouchInput)
                                && desktopCount > 1
                            anchors.right: parent.right
                            anchors.top: parent.top
                            sourceComponent: PC3.Button {
                                text: i18nd("kwin", "Delete Virtual Desktop")
                                icon.name: "delete"
                                display: PC3.AbstractButton.IconOnly

                                PC3.ToolTip.text: text
                                PC3.ToolTip.visible: hovered
                                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay

                                onClicked: delegate.remove()
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

                    // Fork: name editing only with the "workspace management"
                    // toggle enabled; click-to-rename is gated on it too.
                    Item {
                        id: label
                        width: bar.desktopWidth
                        height: Kirigami.Units.gridUnit
                        state: "normal"

                        PC3.Label {
                            anchors.fill: parent
                            elide: Text.ElideRight
                            text: delegate.desktop.name
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            visible: label.state === "normal"
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: bar.workspaceManagement
                            onPressed: mouse => {
                                mouse.accepted = true;
                                label.startEditing();
                            }
                        }

                        Loader {
                            active: label.state === "editing"
                            anchors.fill: parent
                            sourceComponent: PC3.TextField {
                                topPadding: 0
                                bottomPadding: 0
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: delegate.desktop.name
                                onEditingFinished: {
                                    delegate.desktop.name = text;
                                    label.stopEditing();
                                }
                                Keys.onEscapePressed: label.stopEditing();
                                Component.onCompleted: forceActiveFocus();
                            }
                        }

                        states: [
                            State {
                                name: "normal"
                            },
                            State {
                                name: "editing"
                            }
                        ]

                        function startEditing() {
                            state = "editing";
                        }
                        function stopEditing() {
                            state = "normal";
                        }
                    }

                    HoverHandler {
                        id: hoverHandler
                    }
                }
            }

            // Fork: "Add Virtual Desktop" button at the end of the bar, only
            // while the "workspace management" toggle is enabled.
            PC3.Button {
                visible: bar.workspaceManagement
                width: bar.desktopWidth
                height: bar.desktopHeight

                text: if (desktopCount < virtualDesktopModel.maximum) {
                    i18nd("kwin", "Add Virtual Desktop")
                } else {
                    i18nd("kwin", "Virtual Desktop limit reached")
                }
                icon.name: "list-add"
                display: PC3.AbstractButton.IconOnly
                enabled: desktopCount < virtualDesktopModel.maximum

                Highlight {
                    active: parent.activeFocus
                    hovered: parent.hovered && parent.enabled
                }

                PC3.ToolTip.text: text
                PC3.ToolTip.visible: hovered
                PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
                Accessible.name: text

                Keys.onReturnPressed: action.trigger()
                Keys.onEnterPressed: action.trigger()

                Keys.onLeftPressed: nextItemInFocusChain(LayoutMirroring.enabled).forceActiveFocus(Qt.BacktabFocusReason);
                Keys.onRightPressed: nextItemInFocusChain(!LayoutMirroring.enabled).forceActiveFocus(Qt.TabFocusReason);

                onClicked: virtualDesktopModel.create(virtualDesktopModel.rowCount())

                DropArea {
                    anchors.fill: parent
                    onEntered: drag => {
                        drag.accepted = desktopCount < virtualDesktopModel.maximum;
                    }
                    onDropped: drag => {
                        drag.source.desktops = [virtualDesktopModel.create(virtualDesktopModel.rowCount())];
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
