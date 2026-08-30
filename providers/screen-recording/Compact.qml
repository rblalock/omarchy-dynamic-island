import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property var island: null
  property var activity: null
  property var bar: null

  implicitWidth: Style.bar.iconCanvas
  implicitHeight: Style.bar.iconCanvas

  OpticalGlyph {
    anchors.fill: parent
    text: "󰻂"
    color: Color.urgent
    fontFamily: Style.font.family
    fontSize: Style.bar.iconFont
  }
}
