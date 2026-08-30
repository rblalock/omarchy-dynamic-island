import QtQuick
import qs.Commons

Item {
  property var island: null
  property var activity: null
  property var bar: null
  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  Text {
    id: label
    text: activity ? "H  " + activity.title : "H"
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    font.weight: Font.DemiBold
    renderType: Text.NativeRendering
  }
}
