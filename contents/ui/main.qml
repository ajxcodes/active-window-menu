import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.ksvg 1.0 as KSvg
import org.kde.taskmanager       as TaskManager
import org.kde.kirigami          as Kirigami
import org.kde.activities        as Activities
import "../tools/Tools.js"       as Tools

PlasmoidItem {
    id: root
    Plasmoid.constraintHints:   Plasmoid.CanFillArea
    Plasmoid.backgroundHints:   root.expanded ? PlasmaCore.Types.NoBackground : PlasmaCore.Types.DefaultBackground
    preferredRepresentation:    Plasmoid.compactRepresentation

    property int titleImplicitWidth: titleLayout.implicitWidth + (cfg.useNativeMargins ? frame.margins.left + frame.margins.right : 0)
    property int titleImplicitHeight: titleLayout.implicitHeight + (cfg.useNativeMargins ? frame.margins.top + frame.margins.bottom : 0)
    
    function closeAboutWindow() {
        if (aboutWindow.visible) {
            aboutWindow.visible = false;
        }
    }
    
    function showFallbackAboutWindow() {
        aboutWindow.targetAppName = root.activeTaskItem ? root.activeTaskItem.appName : "Mac Title Menu";
        aboutWindow.targetAppId = root.activeTaskItem ? root.activeTaskItem.modelAppId : "";
        aboutWindow.targetAppPid = root.activeTaskItem ? root.activeTaskItem.modelAppPid : "";
        aboutWindow.targetGenericName = root.activeTaskItem ? root.activeTaskItem.modelGenericName : "";
        aboutWindow.targetTitle = root.text;
        aboutWindow.targetIcon = root.icon;
        aboutWindow.visible = true;
        aboutWindow.requestActivate();
    }

    readonly property bool isVertical:              plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool existsWindowActive:      windowInfoLoader.item && windowInfoLoader.item.existsWindowActive
    readonly property bool isActiveWindowPinned:    existsWindowActive && activeTaskItem.isOnAllDesktops
    readonly property bool isActiveWindowMaximized: existsWindowActive && activeTaskItem.isMaximized
    readonly property var cfg:                      plasmoid.configuration
    property bool isAboutOpen:                      aboutWindow.visible
    property string aboutWindowTitle:               aboutWindow.title
    property bool recentlyClosedAbout:              false
    
    Timer {
        id: aboutCloseDelayTimer
        interval: 500
        repeat: false
        onTriggered: root.recentlyClosedAbout = false
    }
    property alias macAppMenuPopup:                 macAppMenuPopup
    property bool itemHovered:                      false
    property bool itemPressed:                      false

    property Item activeTaskItem:                   windowInfoLoader.item.activeTaskItem
    property var icon:                              Tools.getIcon()
    property string text:                           Tools.getText()
    states: [
        State{
            name: "editMode"
            when:  Plasmoid.containment.corona?.editMode?true:false
            PropertyChanges{
                target: root
                text:   "Edit Mode"
                icon:   "document-edit"
                Layout.minimumWidth: isVertical?parent.width:root.titleImplicitWidth
                Layout.maximumWidth: Layout.minimumWidth
                Layout.minimumHeight: isVertical?root.titleImplicitHeight:parent.height
                Layout.maximumHeight: Layout.minimumHeight
            }
        },
        State{
            name: "contentsLength"
            when: cfg.lengthKind === 0 && !isVertical
            PropertyChanges{
                target: root
                Layout.minimumWidth: root.titleImplicitWidth
                Layout.maximumWidth: Layout.minimumWidth
                Layout.fillHeight:   true
            }
        },
        State{
            name: "fixedLength"
            when: cfg.lengthKind === 1 && !isVertical
            PropertyChanges{
                target: root
                Layout.minimumWidth: cfg.fixedLength
                Layout.maximumWidth: cfg.fixedLength
                Layout.fillHeight:   true
            }
        },
        State{
            name: "maximumLength"
            when: cfg.lengthKind === 2 && !isVertical
            PropertyChanges{
                target: root
                Layout.minimumWidth: Math.min(cfg.fixedLength,root.titleImplicitWidth)
                Layout.maximumWidth: Math.min(cfg.fixedLength,root.titleImplicitWidth)
                Layout.fillHeight:   true
            }
        },
        State{
            name: "contentsLengthVert"
            when: cfg.lengthKind === 0 && isVertical
            PropertyChanges{
                target: root
                Layout.minimumHeight: root.titleImplicitHeight
                Layout.maximumHeight: Layout.minimumHeight
                Layout.fillWidth:     true
            }
        },
        State{
            name: "fixedLengthVert"
            when: cfg.lengthKind === 1 && isVertical
            PropertyChanges{
                target: root
                Layout.minimumHeight: cfg.fixedLength
                Layout.maximumHeight: cfg.fixedLength
                Layout.fillWidth:     true
            }
        },
        State{
            name: "maximumLengthVert"
            when: cfg.lengthKind === 2 && isVertical
            PropertyChanges{
                target: root
                Layout.minimumHeight: Math.min(cfg.fixedLength,root.titleImplicitHeight)
                Layout.maximumHeight: Math.min(cfg.fixedLength,root.titleImplicitHeight)
                Layout.fillWidth:     true
            }
        }
    ]

    TaskManager.ActivityInfo { id: activityInfo }
    Activities.ActivityInfo { id: fullActivityInfo; activityId: ":current" }
    TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }
    Loader {
        id: windowInfoLoader
        sourceComponent: plasmaTasksModel
        Component{
            id: plasmaTasksModel
            PlasmaTasksModel{}
        }
    }
    KSvg.FrameSvgItem {
        id: frame
        anchors.fill: parent
        anchors.leftMargin: -cfg.highlightBleed
        anchors.rightMargin: -cfg.highlightBleed
        visible: root.macAppMenuPopup.status === PlasmaExtras.Menu.Open || root.itemHovered
        imagePath: "widgets/menubaritem"
        prefix: {
            if (root.macAppMenuPopup.status === PlasmaExtras.Menu.Open || root.itemPressed) {
                return "pressed";
            } else {
                return "hover";
            }
        }
    }
    Title { 
        id: titleLayout
        anchors.fill: parent
        anchors.leftMargin: cfg.useNativeMargins ? frame.margins.left : 0
        anchors.rightMargin: cfg.useNativeMargins ? frame.margins.right : 0
        anchors.topMargin: cfg.useNativeMargins ? frame.margins.top : 0
        anchors.bottomMargin: cfg.useNativeMargins ? frame.margins.bottom : 0
    }

    PlasmaExtras.Menu {
        id: macAppMenuPopup
        visualParent: root

        PlasmaExtras.MenuItem {
            text: i18n("About %1", root.activeTaskItem ? root.activeTaskItem.appName : "")
            onClicked: Qt.callLater(function(){
                var service = root.activeTaskItem ? root.activeTaskItem.dbusAppMenuServiceName : "";
                var path = root.activeTaskItem ? root.activeTaskItem.dbusAppMenuObjectPath : "";
                
                if (service !== "" && path !== "") {
                    // Try using the DBus Python Script
                    // Note: plasmoid.file is avoided here because it can fail to resolve during plasmoid updates.
                    var scriptPath = Qt.resolvedUrl("../scripts/trigger_about.py").toString().replace("file://", "");
                    dbusTriggerSource.connectSource('python3 ' + scriptPath + ' ' + service + ' ' + path);
                } else {
                    // Fallback instantly if no DBus AppMenu is available
                    aboutWindow.targetAppName = root.activeTaskItem ? root.activeTaskItem.appName : "Mac Title Menu";
                    aboutWindow.targetAppId = root.activeTaskItem ? root.activeTaskItem.modelAppId : "";
                    aboutWindow.targetAppPid = root.activeTaskItem ? root.activeTaskItem.modelAppPid : "";
                    aboutWindow.targetGenericName = root.activeTaskItem ? root.activeTaskItem.modelGenericName : "";
                    aboutWindow.targetTitle = root.text;
                    aboutWindow.targetIcon = root.icon;
                    aboutWindow.visible = true;
                    aboutWindow.requestActivate();
                }
            })
        }
        PlasmaExtras.MenuItem { separator: true }

        PlasmaExtras.MenuItem {
            text: root.activeTaskItem && root.activeTaskItem.isMinimized ? i18n("Restore") : i18n("Minimize")
            onClicked: Qt.callLater(function(){
                if(existsWindowActive) windowInfoLoader.item.toggleMinimized();
            })
        }

        PlasmaExtras.MenuItem {
            text: root.activeTaskItem && root.activeTaskItem.isMaximized ? i18n("Restore") : i18n("Maximize")
            onClicked: Qt.callLater(function(){
                if(existsWindowActive) windowInfoLoader.item.toggleMaximized();
            })
        }

        PlasmaExtras.MenuItem {
            text: i18n("Keep Above")
            onClicked: Qt.callLater(function(){
                if(existsWindowActive) windowInfoLoader.item.toggleKeepAbove();
            })
        }

        PlasmaExtras.MenuItem {
            text: i18n("Pin to all Desktops")
            onClicked: Qt.callLater(function(){
                if(existsWindowActive) windowInfoLoader.item.togglePinToAllDesktops();
            })
        }
        PlasmaExtras.MenuItem { separator: true }

        PlasmaExtras.MenuItem {
            text: i18n("Close")
            onClicked: Qt.callLater(function(){
                if(existsWindowActive) windowInfoLoader.item.requestClose();
            })
        }
    }
    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        active: text !== ""
        interactive: true
        location: plasmoid.location
        visible: cfg.showTooltip
        mainItem: RowLayout {
            spacing:                    Kirigami.Units.largeSpacing
            Layout.margins:             Kirigami.Units.smallSpacing
            Kirigami.Icon {
                source: root.icon
            }
            PlasmaComponents.Label {
                id: fullText
                elide:Text.ElideRight
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: Text.AlignVCenter
                text:root.text
            }
        }
    }

    ActionsMouseArea {}

    Plasma5Support.DataSource {
        id: dbusTriggerSource
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            if (sourceName.indexOf("trigger_about.py") === -1) return;
            
            var output = (data.stdout || "").trim();
            if (output === "SUCCESS") {
                disconnectSource(sourceName);
            } else if (output === "NOT_FOUND" || output === "ERROR") {
                disconnectSource(sourceName);
                root.showFallbackAboutWindow();
            } else if (data["exit code"] !== undefined || data.exitCode !== undefined) {
                // Process exited without finding the about menu
                disconnectSource(sourceName);
                root.showFallbackAboutWindow();
            }
        }
    }

    Window {
        id: aboutWindow
        
        property string targetAppName: "Mac Title Menu"
        property string targetAppId: ""
        property string targetAppPid: ""
        property string targetGenericName: ""
        property string targetTitle: ""
        property var targetIcon: ""

        title: i18n("About %1", targetAppName)
        width: Kirigami.Units.gridUnit * 22
        height: aboutLayout.implicitHeight + Kirigami.Units.largeSpacing * 2
        x: Screen.width / 2 - width / 2
        y: Screen.height / 2 - height / 2
        color: Kirigami.Theme.backgroundColor
        flags: Qt.Dialog | Qt.WindowCloseButtonHint | Qt.WindowTitleHint

        onVisibleChanged: {
            if (!visible) {
                root.recentlyClosedAbout = true;
                aboutCloseDelayTimer.restart();
            }
        }
        
        onActiveChanged: {
            if (visible && !active) {
                // Auto-close on focus loss.
                // Note: The onVisibleChanged handler below safely triggers the recentlyClosedAbout timer to prevent race conditions.
                visible = false;
            }
        }

        ColumnLayout {
            id: aboutLayout
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                source: aboutWindow.targetIcon
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: aboutWindow.targetAppName
                font.bold: true
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5
            }
            
            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: aboutWindow.targetGenericName !== "" ? aboutWindow.targetGenericName : "Application"
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.9
                opacity: 0.8
                visible: aboutWindow.targetAppName !== "Mac Title Menu"
            }

            Item { Layout.preferredHeight: Kirigami.Units.smallSpacing } // Small Spacer

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: aboutWindow.targetTitle
                elide: Text.ElideRight
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.9
                visible: aboutWindow.targetTitle !== aboutWindow.targetAppName && aboutWindow.targetTitle !== ""
            }
            
            Kirigami.SelectableLabel {
                Layout.alignment: Qt.AlignHCenter
                text: aboutWindow.targetAppId
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8
                visible: aboutWindow.targetAppId !== ""
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                visible: aboutWindow.targetAppPid !== ""
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: "PID:"
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8
                }

                Kirigami.SelectableLabel {
                    text: aboutWindow.targetAppPid
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.8
                }
            }

            Item { Layout.fillHeight: true } // Spacer

            PlasmaComponents.Button {
                Layout.alignment: Qt.AlignHCenter
                text: i18n("Close")
                onClicked: aboutWindow.visible = false
            }
        }
    }
}
