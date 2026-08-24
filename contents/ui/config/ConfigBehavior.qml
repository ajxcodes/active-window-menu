import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.kirigami as Kirigami

Kirigami.ScrollablePage {
    readonly property alias cfg_filterByScreen: filterByScreenChk.checked
    readonly property alias cfg_filterByMaximized: filterByMaximizedChk.checked
    readonly property alias cfg_showTooltip: showTooltipChk.checked
    readonly property alias cfg_maxminAllowed: maxminAllowed.checked
    readonly property alias cfg_scrollAllowed: scrollAllowed.checked
    readonly property alias cfg_forceQuitConfirm: forceQuitConfirm.checked
    readonly property alias cfg_showPrefsItem: showPrefsItemChk.checked
    readonly property alias cfg_leftClickAction: leftClickAction.currentIndex
    readonly property alias cfg_middleClickAction: middleClickAction.currentIndex

    Kirigami.FormLayout {
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Window Tracking")
        }

        PC3.Switch {
            id: filterByScreenChk
            Kirigami.FormData.label: i18n("Show only from current screen:")
        }
        PC3.Switch {
            id: filterByMaximizedChk
            Kirigami.FormData.label: i18n("Show only when maximized:")
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Mouse Clicks")
        }

        PC3.ComboBox {
            id: leftClickAction
            Kirigami.FormData.label: i18n("Left-Click Action:")
            model: [
                i18n("Open Context Menu"),
                i18n("Show App Window"),
                i18n("Do Nothing")
            ]
        }

        PC3.ComboBox {
            id: middleClickAction
            Kirigami.FormData.label: i18n("Middle-Click Action:")
            model: [
                i18n("Close Window"),
                i18n("Do Nothing")
            ]
        }

        PC3.Switch {
            id: maxminAllowed
            Kirigami.FormData.label: i18n("Double-Click to maximize/minimize:")
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Hover & Scrolling")
        }

        PC3.Switch {
            id: showTooltipChk
            Kirigami.FormData.label: i18n("Show tooltip on hover:")
        }

        PC3.Switch {
            id: scrollAllowed
            Kirigami.FormData.label: i18n("Scroll through tasks:")
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Advanced")
        }

        PC3.Switch {
            id: forceQuitConfirm
            Kirigami.FormData.label: i18n("Confirm Force Quit:")
        }

        PC3.Switch {
            id: showPrefsItemChk
            Kirigami.FormData.label: i18n("Show App Settings/Preferences menu item:")
        }
    }
}
