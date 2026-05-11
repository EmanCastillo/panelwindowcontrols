import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

PlasmaComponents3.ToolButton {
    id: root

    property string toolTipText: ""

    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
    Layout.minimumWidth: Kirigami.Units.iconSizes.smallMedium
    Layout.minimumHeight: Kirigami.Units.iconSizes.smallMedium
    Layout.maximumWidth: Kirigami.Units.iconSizes.smallMedium
    Layout.maximumHeight: Kirigami.Units.iconSizes.smallMedium

    implicitWidth: Kirigami.Units.iconSizes.smallMedium
    implicitHeight: Kirigami.Units.iconSizes.smallMedium

    flat: true
    hoverEnabled: true
    text: ""

    icon.width: Kirigami.Units.iconSizes.small
    icon.height: Kirigami.Units.iconSizes.small

    opacity: enabled ? 1.0 : 0.45

    scale: hovered && Plasmoid.configuration.enableHoverEffect ? 1.08 : 1.0

    Behavior on scale {
        enabled: Plasmoid.configuration.enableAnimations
        NumberAnimation {
            duration: Math.max(80, Plasmoid.configuration.animationDuration / 2)
            easing.type: Easing.OutCubic
        }
    }

    PlasmaComponents3.ToolTip.text: root.toolTipText
    PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
}
