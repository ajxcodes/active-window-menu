import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3
import org.kde.iconthemes as KIconThemes
import org.kde.ksvg as KSvg

import "../../tools/Tools.js" as Tools

Kirigami.ScrollablePage {
    id: root
    readonly property alias cfg_firstSpace: firstSpace.value
    readonly property alias cfg_useNativeMargins: useNativeMarginsChk.checked
    readonly property alias cfg_highlightBleed: highlightBleed.value
    readonly property alias cfg_midSpace: midSpace.value
    readonly property alias cfg_lastSpace: lastSpace.value
    readonly property alias cfg_txt: txt.text
    readonly property alias cfg_altTxt: altTxt.text
    readonly property alias cfg_onlyShowInactiveWithMultipleActivities: onlyShowInactiveWithMultipleActivitiesChk.checked
    readonly property alias cfg_isBold: boldChk.checked
    readonly property alias cfg_isItalic: italicChk.checked
    readonly property alias cfg_isCaps: capsChk.checked
    readonly property alias cfg_fontSize: fontSize.value
    readonly property alias cfg_useSystemFontSize: useSystemFontSizeChk.checked
    readonly property alias cfg_verticalOffset: verticalOffset.value
    readonly property alias cfg_visible: iconChk.checked
    readonly property alias cfg_lengthKind: lengthKind.currentIndex
    readonly property alias cfg_fixedLength: fixedLength.value
    readonly property alias cfg_fillThickness: fillThickness.checked
    readonly property alias cfg_noIcon: noIcon.checked
    readonly property alias cfg_activityIcon: activityIcon.checked
    readonly property alias cfg_customIcon: iconDialog.value
    readonly property alias cfg_txtSameFound: txtSameFound.text
    readonly property alias cfg_customSize: customSize.value
    readonly property alias cfg_elidePos: elidePos.currentIndex

    header : MockWidget{}
    
    ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.FormLayout {
            Layout.fillWidth: true

            Item {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Typography & Text")
            }

            PC3.ComboBox {
                id: activeTextPreset
                Kirigami.FormData.label: i18n("Active Window Text:")
                model: [
                    { text: i18n("Application Name"), value: "%a" },
                    { text: i18n("Window Title"), value: "%w" },
                    { text: i18n("App Name - Window Title"), value: "%a - %w" },
                    { text: i18n("Activity Info"), value: "%q" },
                    { text: i18n("Custom..."), value: "" }
                ]
                textRole: "text"
                valueRole: "value"
                currentIndex: {
                    for (var i = 0; i < count; ++i) {
                        if (model[i].value === txt.text) return i;
                    }
                    return count - 1;
                }
                onActivated: {
                    if (currentValue !== "") {
                        txt.text = currentValue;
                    }
                }
            }

            RowLayout {
                visible: activeTextPreset.currentIndex === activeTextPreset.count - 1
                PC3.TextField {
                    id: txt
                    Layout.fillWidth: true
                }
                PC3.ToolButton {
                    icon.name: "documentinfo"
                    PC3.ToolTip{ text: i18n("Substitutions: %a (App), %w (Title), %q (Activity)") }
                }
            }
            
            PC3.TextField { 
                id: txtSameFound 
                Kirigami.FormData.label: i18n("When App and Title match:")
            }

            PC3.TextField {
                id: altTxt
                Kirigami.FormData.label: i18n("Inactive Window Text:")
            }

            PC3.CheckBox {
                id: onlyShowInactiveWithMultipleActivitiesChk
                text: i18n("Only show when more than one activity is running")
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Text Formatting:")
                PC3.SpinBox{
                    id: fontSize
                    from: 8
                    to: 64
                    enabled: !useSystemFontSizeChk.checked
                }
                PC3.ToolButton{
                    id: boldChk
                    checkable: true
                    icon.name: "format-text-bold"
                    display: AbstractButton.IconOnly
                    height: Kirigami.Units.smallSpacing
                    PC3.ToolTip{ text: i18n("<b>Bold</b>") }
                }
                PC3.ToolButton{
                    id: italicChk
                    checkable: true
                    display: AbstractButton.IconOnly
                    icon.name: "format-text-italic"
                    height: Kirigami.Units.smallSpacing
                    PC3.ToolTip{ text: i18n("<i>Italic</i>") }
                }
                PC3.ToolButton{
                    id: capsChk
                    checkable: true
                    icon.name: "format-text-capitalize"
                    display: AbstractButton.IconOnly
                    height: Kirigami.Units.smallSpacing
                    PC3.ToolTip{ text: i18n("<b>C</b>apitalize") }
                }
            }

            PC3.CheckBox {
                id: useSystemFontSizeChk
                Kirigami.FormData.label: i18n("System Font Size:")
                text: i18n("Match Plasma system font size")
            }

            PC3.SpinBox {
                id: verticalOffset
                Kirigami.FormData.label: i18n("Vertical Offset:")
                from: -50
                to: 50
                stepSize: 1
                textFromValue: function(value, locale) {
                    return value > 0 ? "+" + value + " px" : value + " px";
                }
                valueFromText: function(text, locale) {
                    return parseInt(text) || 0;
                }
            }

            PC3.ComboBox {
                id: elidePos
                Kirigami.FormData.label: i18n("Elide Position:")
                model: ["None","Left","Middle","Right"]
                visible: lengthKind.currentIndex > 0
            }

            Item {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Icon Visibility")
            }

            PC3.Switch {
                id: iconChk
                Kirigami.FormData.label: i18n("Show Icon:")
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Icon Size:")
                RadioButton{
                    id: customThickness
                    text: i18n("Custom Size")
                    checked: !fillThickness.checked
                }
                RadioButton{
                    id: fillThickness
                    text: i18n("Fill Thickness")
                }
            }

            PC3.SpinBox{
                id: customSize
                from: 8
                to: 50
                enabled: customThickness.checked
            }

            RowLayout {
                Kirigami.FormData.label: i18n("Placeholder icon:")
                RadioButton{
                    id: customIcon
                    text: i18n("Custom")
                    checked: !activityIcon.checked && !noIcon.checked
                }
                RadioButton{
                    id: activityIcon
                    text: i18n("Activity")
                }
                RadioButton{
                    id: noIcon
                    text: i18n("None")
                }
            }
            IconDialog{
                id: iconDialog
                visible: customIcon.checked
            }

            Item {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: i18n("Spacing & Margins")
            }

            PC3.ComboBox {
                id:lengthKind
                Kirigami.FormData.label: i18n("Length Limit:")
                model: ["Based on contents","Fixed Length","Maximum Length"]
            }

            RowLayout{
                Kirigami.FormData.label: i18n("Custom length:")
                visible: lengthKind.currentIndex > 0
                PC3.Slider{
                    id:fixedLength
                    from: 24
                    to: 1500
                    stepSize:1
                }
                PC3.Label{
                    text: fixedLength.value+" px"
                }
            }

            PC3.Switch {
                id: useNativeMarginsChk
                Kirigami.FormData.label: i18n("Native Plasma Margins:")
                text: i18n("Match Global Menu spacing")
            }

            PC3.SpinBox {
                id: highlightBleed
                Kirigami.FormData.label: i18n("Highlight bleed:")
                from: -50
                to: 50
            }

            PC3.SpinBox {
                id: firstSpace
                Kirigami.FormData.label: i18n("Space before icon:")
                from: 0
                to: 999
            }
            PC3.SpinBox {
                id: midSpace
                Kirigami.FormData.label: i18n("Space between icon/text:")
                from: 0
                to: 999
            }
            PC3.SpinBox {
                id: lastSpace
                Kirigami.FormData.label: i18n("Space after text:")
                from: 0
                to: 999
            }
        }
    }
}
