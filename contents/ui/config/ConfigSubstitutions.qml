import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

Kirigami.ScrollablePage {
    id: subsPage
    
    property var cfg_subsMatchApp: []
    property var cfg_subsMatchTitle: []
    property var cfg_subsReplace: []

    onCfg_subsMatchAppChanged: updateModel()
    onCfg_subsMatchTitleChanged: updateModel()
    onCfg_subsReplaceChanged: updateModel()
    
    function updateModel() {
        if (updatingFromModel) return;
        subsModel.clear();
        let count = Math.min(cfg_subsMatchApp.length, cfg_subsMatchTitle.length, cfg_subsReplace.length);
        for (let i = 0; i < count; i++) {
            subsModel.append({
                appMatch: cfg_subsMatchApp[i] || "",
                titleMatch: cfg_subsMatchTitle[i] || "",
                replaceText: cfg_subsReplace[i] || ""
            });
        }
    }
    
    property bool updatingFromModel: false
    function saveToConfig() {
        updatingFromModel = true;
        let apps = [];
        let titles = [];
        let reps = [];
        for (let i = 0; i < subsModel.count; i++) {
            let item = subsModel.get(i);
            apps.push(item.appMatch);
            titles.push(item.titleMatch);
            reps.push(item.replaceText);
        }
        cfg_subsMatchApp = apps;
        cfg_subsMatchTitle = titles;
        cfg_subsReplace = reps;
        updatingFromModel = false;
    }

    ListModel {
        id: subsModel
    }

    property alias cfg_subsAdvancedMode: advancedModeCheckbox.checked
    
    header: Kirigami.InlineMessage {
        Layout.fillWidth: true
        text: cfg_subsAdvancedMode 
               ? i18n("App overrides let you rename apps that report ugly or generic names.<br><br>" +
                      "<b>Example:</b> To rename <i>Telegram Desktop</i> to just <i>Telegram</i>:<br>" +
                      "• Match App: <code>Telegram.*</code><br>" +
                      "• Match Title: <code>.*</code><br>" +
                      "• Replace with: <code>Telegram</code><br><br>" +
                      "<i>Note: Match fields use Regular Expressions. Use <code>.*</code> to match anything, and <code>%w</code> in the replacement to insert the window's original title.</i>")
               : i18n("App overrides let you rename apps that report ugly or generic names.<br><br>" +
                      "<b>Example:</b> To rename <i>Telegram Desktop</i> to just <i>Telegram</i>:<br>" +
                      "• App Name: <code>Telegram</code><br>" +
                      "• Replace with: <code>Telegram</code><br><br>" +
                      "<i>Note: Matches are case-insensitive. Use <code>%w</code> in the replacement to insert the window's original title.</i>")
        type: Kirigami.MessageType.Information
        visible: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        PC3.CheckBox {
            id: advancedModeCheckbox
            text: i18n("Advanced Mode (Regex & Window Title matching)")
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: subsModel
            clip: true
            spacing: Kirigami.Units.smallSpacing
            
            delegate: Kirigami.Card {
                Layout.fillWidth: true
                width: listView.width
                
                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    PC3.TextField {
                        Layout.fillWidth: true
                        placeholderText: cfg_subsAdvancedMode ? i18n("App Regex (e.g. Telegram.*)") : i18n("App Name (e.g. Telegram)")
                        text: model.appMatch
                        onTextChanged: {
                            if (model.appMatch !== text) {
                                subsModel.setProperty(index, "appMatch", text);
                                saveToConfig();
                            }
                        }
                    }
                    
                    PC3.TextField {
                        visible: cfg_subsAdvancedMode
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                        placeholderText: i18n("Title Regex (e.g. .*)")
                        text: model.titleMatch
                        onTextChanged: {
                            if (model.titleMatch !== text) {
                                subsModel.setProperty(index, "titleMatch", text);
                                saveToConfig();
                            }
                        }
                    }
                    
                    PC3.TextField {
                        Layout.fillWidth: true
                        placeholderText: i18n("Replace with...")
                        text: model.replaceText
                        onTextChanged: {
                            if (model.replaceText !== text) {
                                subsModel.setProperty(index, "replaceText", text);
                                saveToConfig();
                            }
                        }
                    }
                    
                    PC3.ToolButton {
                        icon.name: "list-remove"
                        PC3.ToolTip { text: i18n("Remove Override") }
                        onClicked: {
                            subsModel.remove(index);
                            saveToConfig();
                        }
                    }
                }
            }
        }
        
        PC3.Button {
            Layout.alignment: Qt.AlignHCenter
            text: i18n("Add Override")
            icon.name: "list-add"
            onClicked: {
                if (cfg_subsAdvancedMode) {
                    subsModel.append({ appMatch: ".*", titleMatch: ".*", replaceText: "" });
                } else {
                    subsModel.append({ appMatch: "", titleMatch: "", replaceText: "" });
                }
                saveToConfig();
                listView.positionViewAtEnd();
            }
        }
    }
}
