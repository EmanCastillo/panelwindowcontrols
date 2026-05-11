/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 * Plasma 6.6-safe window buttons applet.
 * A Plasma 6.6-safe window buttons applet inspired by moodyhunter's original widget behavior.
 * Original GitHub: https://github.com/moodyhunter/applet-window-buttons6
 *
 * Design notes:
 * - Used TaskManager.TasksModel instead of KDecoration/KWin private APIs.
 * - Used Plasma/Kirigami controls and icon names so the widget remains theme-agnostic.
 * - Reads KWin's button order from kwinrc, but renders buttons with safe Plasma components.
 * - The button row slides/collapses when no active task is available.
 */

import QtQuick
import QtQuick.Layouts
import QtCore
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    // Use custom representation and avoid Plasma drawing a widget background.
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.constraintHints: Plasmoid.CanFillArea

    // Panel orientation and user-configurable sizing.
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property int configuredButtonSize: Math.max(16, Plasmoid.configuration.buttonSize || 22)
    readonly property int configuredSpacing: Math.max(0, Plasmoid.configuration.spacing || 0)

    // Small internal padding so buttons do not collide with neighboring panel widgets.
    readonly property int leadingGap: Kirigami.Units.smallSpacing
    readonly property int trailingGap: Kirigami.Units.smallSpacing

    // KWin titlebar button order fallback:
    // I = minimize, A = maximize/restore, X = close.
    property string kwinButtonOrder: "IAX"
    property string kwinButtonsOnLeft: ""
    property string kwinButtonsOnRight: "IAX"

    readonly property string manualButtonOrder: Plasmoid.configuration.manualButtonOrder || "IAX"

    readonly property string effectiveLeftOrder: Plasmoid.configuration.followKWinButtonOrder
    ? root.kwinButtonsOnLeft
    : ""

    readonly property string effectiveRightOrder: Plasmoid.configuration.followKWinButtonOrder
    ? root.kwinButtonsOnRight
    : root.manualButtonOrder

    readonly property string effectiveButtonOrder: Plasmoid.configuration.useSplitButtonGroups
    ? root.effectiveLeftOrder + root.effectiveRightOrder
    : (Plasmoid.configuration.followKWinButtonOrder ? root.kwinButtonOrder : root.manualButtonOrder)

    readonly property var visibleButtonOrder: root.effectiveButtonOrder.split("").filter(function(button) {
        return button === "I" || button === "A" || button === "X";
    })

    // Animation state: collapse the applet when there is no active task, unless the user explicitly
    // configured it to stay visible.
    readonly property bool windowAllowedByMode: !Plasmoid.configuration.onlyShowForMaximized
    || (root.activeTask && root.activeTask.isMaximized)

    readonly property bool buttonsShown: root.windowAllowedByMode
    && (Plasmoid.configuration.showWhenNoWindow || root.activeTask !== null)

    readonly property int expandedAppletWidth: configuredButtonSize * visibleButtonOrder.length + leadingGap + trailingGap

    // The applet width itself is animated, which lets panel neighbors slide naturally.
    property int appletWidth: buttonsShown ? expandedAppletWidth : 0

    Behavior on appletWidth {
        enabled: Plasmoid.configuration.enableAnimations
        NumberAnimation {
            duration: Plasmoid.configuration.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    // Cached active task information. activeIndex is needed for TaskManager actions.
    property var activeIndex: null
    property var activeTask: null

    // Report the size Plasma should reserve in the panel.
    Layout.minimumWidth: vertical ? configuredButtonSize : appletWidth
    Layout.preferredWidth: vertical ? configuredButtonSize : appletWidth
    Layout.maximumWidth: vertical ? configuredButtonSize : appletWidth
    Layout.minimumHeight: vertical ? buttons.implicitHeight : configuredButtonSize
    Layout.preferredHeight: vertical ? buttons.implicitHeight : configuredButtonSize
    Layout.maximumHeight: vertical ? buttons.implicitHeight : configuredButtonSize

    Component.onCompleted: {
        if (Plasmoid.configuration.followKWinButtonOrder) {
            readKwinButtonOrder()
        }
    }

    // Read KWin's configured titlebar button layout from ~/.config/kwinrc.
    function readKwinButtonOrder() {
        const path = StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/kwinrc";
        const url = "file://" + path;
        const xhr = new XMLHttpRequest();

        xhr.open("GET", url, false);

        try {
            xhr.send();
        } catch (e) {
            root.kwinButtonsOnLeft = "";
            root.kwinButtonsOnRight = "IAX";
            root.kwinButtonOrder = "IAX";
            return;
        }

        if (xhr.status !== 0 && xhr.status !== 200) {
            root.kwinButtonsOnLeft = "";
            root.kwinButtonsOnRight = "IAX";
            root.kwinButtonOrder = "IAX";
            return;
        }

        const lines = xhr.responseText.split(/\r?\n/);
        let inGroup = false;
        let left = "";
        let right = "IAX";

        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i].trim();

            if (line === "[org.kde.kdecoration2]") {
                inGroup = true;
                continue;
            }

            if (inGroup && line.startsWith("[") && line.endsWith("]")) {
                break;
            }

            if (!inGroup || line.length === 0 || line.startsWith("#")) {
                continue;
            }

            if (line.startsWith("ButtonsOnLeft=")) {
                left = line.substring("ButtonsOnLeft=".length);
            } else if (line.startsWith("ButtonsOnRight=")) {
                right = line.substring("ButtonsOnRight=".length);
            }
        }

        root.kwinButtonsOnLeft = left;
        root.kwinButtonsOnRight = right;

        const order = left + right;
        root.kwinButtonOrder = order.length > 0 ? order : "IAX";
    }

    // These provide the current virtual desktop and activity for task filtering.
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    // Task model used to find and control the active window.
    TaskManager.TasksModel {
        id: tasksModel

        virtualDesktop: virtualDesktopInfo.currentDesktop
        activity: activityInfo.currentActivity
        screenGeometry: Plasmoid.containment.screenGeometry

        filterByVirtualDesktop: true
        filterByActivity: true
        filterByScreen: false
        filterNotMinimized: false
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortLastActivated

        onDataChanged: root.refreshActiveTask()
        onRowsInserted: root.refreshActiveTask()
        onRowsRemoved: root.refreshActiveTask()
        onModelReset: root.refreshActiveTask()

        Component.onCompleted: root.refreshActiveTask()
    }

    // Safety refresh for cases where task state changes do not emit the exact signal we expect.
    Timer {
        interval: 150
        repeat: true
        running: true
        onTriggered: root.refreshActiveTask()
    }

    // Timer for KWin refresh (if option is enabled)
    Timer {
        id: kwinConfigRefreshTimer
        interval: 1000
        repeat: true
        running: Plasmoid.configuration.liveKWinUpdates
        onTriggered: {
            if (Plasmoid.configuration.followKWinButtonOrder) {
                root.readKwinButtonOrder()
            }
        }
    }

    // Convert a row number into a TasksModel index safely.
    function makeIndex(row) {
        if (row < 0 || row >= tasksModel.count) {
            return null;
        }

        return tasksModel.makeModelIndex(row);
    }

    // Build a small JS object for the task data this plasmoid needs.
    function taskAt(row) {
        const idx = makeIndex(row);

        if (!idx) {
            return null;
        }

        return tasksModel.data(idx, TaskManager.AbstractTasksModel.AppName) !== undefined ? {
            row: row,
            index: idx,
            appName: tasksModel.data(idx, TaskManager.AbstractTasksModel.AppName),
            isActive: !!tasksModel.data(idx, TaskManager.AbstractTasksModel.IsActive),
            isMinimized: !!tasksModel.data(idx, TaskManager.AbstractTasksModel.IsMinimized),
            isMaximized: !!tasksModel.data(idx, TaskManager.AbstractTasksModel.IsMaximized),
            isClosable: tasksModel.data(idx, TaskManager.AbstractTasksModel.IsClosable) !== false,
            isMinimizable: tasksModel.data(idx, TaskManager.AbstractTasksModel.IsMinimizable) !== false,
            isMaximizable: tasksModel.data(idx, TaskManager.AbstractTasksModel.IsMaximizable) !== false,
            isLauncher: !!tasksModel.data(idx, TaskManager.AbstractTasksModel.IsLauncher),
            isStartup: !!tasksModel.data(idx, TaskManager.AbstractTasksModel.IsStartup)
        } : null;
    }

    // Prefer the active window. If none is marked active, keep a non-launcher fallback.
    function refreshActiveTask() {
        let fallback = null;

        for (let row = 0; row < tasksModel.count; ++row) {
            const task = taskAt(row);

            if (!task || task.isLauncher || task.isStartup) {
                continue;
            }

            if (!fallback) {
                fallback = task;
            }

            if (task.isActive) {
                activeTask = task;
                activeIndex = task.index;
                return;
            }
        }

        activeTask = fallback;
        activeIndex = fallback ? fallback.index : null;
    }

    // Window actions delegated to TaskManager.
    function minimize() {
        if (activeIndex) {
            tasksModel.requestToggleMinimized(activeIndex);
        }
    }

    function maximizeRestore() {
        if (activeIndex) {
            tasksModel.requestToggleMaximized(activeIndex);
        }
    }

    function closeWindow() {
        if (activeIndex) {
            tasksModel.requestClose(activeIndex);
        }
    }

    // Per-button visibility comes from the widget preferences.
    function buttonVisible(button) {
        if (button === "I") {
            return Plasmoid.configuration.showMinimize !== false;
        }

        if (button === "A") {
            return Plasmoid.configuration.showMaximize !== false;
        }

        if (button === "X") {
            return Plasmoid.configuration.showClose !== false;
        }

        return false;
    }

    // Disable buttons when the active task does not support the requested action.
    function buttonEnabled(button) {
        if (!root.activeTask) {
            return false;
        }

        if (button === "I") {
            return root.activeTask.isMinimizable;
        }

        if (button === "A") {
            return root.activeTask.isMaximizable;
        }

        if (button === "X") {
            return root.activeTask.isClosable;
        }

        return false;
    }

    // Standard icon names keep the widget theme-agnostic.
    function buttonIcon(button) {
        if (button === "I") {
            return "window-minimize";
        }

        if (button === "A") {
            return root.activeTask && root.activeTask.isMaximized ? "window-restore" : "window-maximize";
        }

        if (button === "X") {
            return "window-close";
        }

        return "";
    }

    function buttonTooltip(button) {
        if (button === "I") {
            return i18n("Minimize");
        }

        if (button === "A") {
            return root.activeTask && root.activeTask.isMaximized ? i18n("Restore") : i18n("Maximize");
        }

        if (button === "X") {
            return i18n("Close");
        }

        return "";
    }

    // Dispatch button code to the matching window action.
    function activateButton(button) {
        if (button === "I") {
            root.minimize();
        } else if (button === "A") {
            root.maximizeRestore();
        } else if (button === "X") {
            root.closeWindow();
        }
    }

    fullRepresentation: Item {
        id: compactRoot

        // The representation width follows the animated applet width.
        implicitWidth: root.appletWidth
        implicitHeight: buttons.implicitHeight

        // Keep the representation alive so slide-out animation can play.
        visible: true
        clip: true

        RowLayout {
            id: buttons

            // Slide the button row out of the clipped area when hidden.
            x: root.buttonsShown ? root.leadingGap : -buttons.implicitWidth
            anchors.verticalCenter: parent.verticalCenter

            opacity: !root.buttonsShown ? 0.0
                : Plasmoid.configuration.dimInactive && root.activeTask && !root.activeTask.isActive ? 0.65
                : 1.0

            Behavior on x {
                enabled: Plasmoid.configuration.enableAnimations
                NumberAnimation {
                    duration: Plasmoid.configuration.animationDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                enabled: Plasmoid.configuration.enableAnimations
                NumberAnimation {
                    duration: Math.max(80, Plasmoid.configuration.animationDuration / 2)
                    easing.type: Easing.OutCubic
                }
            }

            spacing: root.configuredSpacing
            layoutDirection: Qt.LeftToRight

            // Render buttons in KWin's configured order.
            Repeater {
                model: root.visibleButtonOrder

                WindowButton {
                    required property string modelData

                    visible: root.buttonVisible(modelData)
                    enabled: root.buttonEnabled(modelData)
                    icon.name: root.buttonIcon(modelData)
                    text: ""
                    toolTipText: root.buttonTooltip(modelData)
                    onClicked: root.activateButton(modelData)
                }
            }
        }
    }
}
