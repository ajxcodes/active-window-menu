import QtQuick
import QtQuick.Layouts

//Custom item to make the code look cleaner
Item {
    required property real length
    Layout.minimumWidth:  isVertical?parent.width :length
    Layout.maximumWidth:  isVertical?parent.width :length
    Layout.minimumHeight:!isVertical?parent.height:length
    Layout.maximumHeight:!isVertical?parent.height:length
    Layout.fillHeight:   !isVertical
    Layout.fillWidth:    isVertical
    /*Rectangle{
        color: "green"
        anchors.fill: parent
        border.color: "red"
        border.width: 1
    }*/
}
