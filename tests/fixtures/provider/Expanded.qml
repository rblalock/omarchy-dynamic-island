import QtQuick
import qs.Commons

Item {
  property var island: null
  property var activity: null
  property var bar: null
  implicitWidth: 240
  implicitHeight: 120

  Column {
    anchors.fill: parent
    spacing: Style.space(8)

    Text {
      text: "CUSTOM PROVIDER VIEW"
      color: Color.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.weight: Font.Bold
      renderType: Text.NativeRendering
    }

    Text {
      width: parent.width
      text: activity ? activity.title : "Harness activity"
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.title
      font.weight: Font.DemiBold
      renderType: Text.NativeRendering
    }

    Text {
      width: parent.width
      text: activity ? activity.subtitle : "Plugin-supplied expanded presentation"
      color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.64)
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      wrapMode: Text.WordWrap
      renderType: Text.NativeRendering
    }

    Rectangle {
      width: parent.width
      height: Style.space(4)
      radius: height / 2
      color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.12)

      Rectangle {
        width: parent.width * 0.64
        height: parent.height
        radius: height / 2
        color: Color.accent
      }
    }
  }
}
