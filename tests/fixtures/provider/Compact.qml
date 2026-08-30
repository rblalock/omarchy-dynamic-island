import QtQuick
import qs.Commons

Item {
  property var island: null
  property var activity: null
  property var bar: null
  implicitWidth: Style.space(28)
  implicitHeight: Style.space(20)

  Text {
    anchors.centerIn: parent
    text: "HC"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.weight: Font.Bold
    renderType: Text.NativeRendering
  }
}
