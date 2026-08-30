import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property var island: null
  property var activity: null
  property var bar: null
  property double nowSeconds: Date.now() / 1000

  readonly property double deadline: Number(activity ? activity.deadline || 0 : 0)
  readonly property int remainingSeconds: Math.max(0, Math.ceil(deadline - nowSeconds))

  implicitWidth: content.implicitWidth
  implicitHeight: Style.bar.iconCanvas

  function remainingText(seconds) {
    var value = Math.max(0, Number(seconds) || 0)
    if (value >= 3600) return Math.ceil(value / 3600) + "h"
    if (value >= 60) return Math.ceil(value / 60) + "m"
    return Math.ceil(value) + "s"
  }

  Row {
    id: content
    anchors.centerIn: parent
    spacing: Style.space(5)

    Item {
      width: Style.bar.iconCanvas
      height: Style.bar.iconCanvas

      OpticalGlyph {
        anchors.fill: parent
        text: "󰢌"
        color: root.bar ? root.bar.foreground : Color.popups.text
        fontFamily: Style.font.family
        fontSize: Style.bar.iconFont
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.remainingText(root.remainingSeconds)
      color: root.bar ? root.bar.foreground : Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.weight: Font.DemiBold
      renderType: Text.NativeRendering
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.visible && root.deadline > 0
    onTriggered: root.nowSeconds = Date.now() / 1000
  }
}
