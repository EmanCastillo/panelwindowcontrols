import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3

Kirigami.FormLayout {
    property alias cfg_enableAnimations: enableAnimations.checked
    property alias cfg_showMinimize: showMinimize.checked
    property alias cfg_showMaximize: showMaximize.checked
    property alias cfg_showClose: showClose.checked
    property alias cfg_showWhenNoWindow: showWhenNoWindow.checked
    property alias cfg_followKWinButtonOrder: followKWinButtonOrder.checked
    property alias cfg_animationDuration: animationDuration.value
    property alias cfg_onlyShowForMaximized: onlyShowForMaximized.checked
    property alias cfg_dimInactive: dimInactive.checked
    property alias cfg_enableHoverEffect: enableHoverEffect.checked
    property alias cfg_manualButtonOrder: manualButtonOrder.text
    property alias cfg_useSplitButtonGroups: useSplitButtonGroups.checked
    property alias cfg_liveKWinUpdates: liveKWinUpdates.checked


    PlasmaComponents3.CheckBox {
        id: enableAnimations
        text: i18n("Enable button animations")
    }

    PlasmaComponents3.CheckBox {
        id: showMinimize
        text: i18n("Show minimize button")
    }

    PlasmaComponents3.CheckBox {
        id: showMaximize
        text: i18n("Show maximize button")
    }

    PlasmaComponents3.CheckBox {
        id: showClose
        text: i18n("Show close button")
    }

    PlasmaComponents3.CheckBox {
        id: showWhenNoWindow
        text: i18n("Show when no window is active")
    }

    PlasmaComponents3.CheckBox {
        id: followKWinButtonOrder
        text: i18n("Follow KWin button order")
    }

    PlasmaComponents3.SpinBox {
        id: animationDuration
        Kirigami.FormData.label: i18n("Animation duration:")
        from: 80
        to: 1000
        stepSize: 20
        textFromValue: function(value) {
            return i18n("%1 ms", value)
        }
    }

    PlasmaComponents3.CheckBox {
        id: onlyShowForMaximized
        text: i18n("Only show for maximized windows")
    }

    PlasmaComponents3.CheckBox {
        id: dimInactive
        text: i18n("Dim inactive windows")
    }

    PlasmaComponents3.CheckBox {
        id: enableHoverEffect
        text: i18n("Enable hover effect")
    }

    PlasmaComponents3.CheckBox {
        id: useSplitButtonGroups
        text: i18n("Use left/right KWin button groups")
    }

    PlasmaComponents3.CheckBox {
        id: liveKWinUpdates
        text: i18n("Live-update KWin button order")
    }

    PlasmaComponents3.TextField {
        id: manualButtonOrder
        Kirigami.FormData.label: i18n("Manual button order:")
        placeholderText: "IAX"
    }
}
