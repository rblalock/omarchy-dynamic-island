import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property var activity: null
  property var bar: null

  readonly property var recordingData: activity && activity.data ? activity.data : ({})
  readonly property string state: String(recordingData.state || "recording")
  readonly property int elapsedSeconds: Math.max(0, Math.floor(Number(recordingData.elapsedSeconds) || 0))

  implicitWidth: content.implicitWidth
  implicitHeight: Style.bar.iconCanvas

  function elapsedText(seconds) {
    var value = Math.max(0, Math.floor(Number(seconds) || 0))
    var hours = Math.floor(value / 3600)
    var minutes = Math.floor((value % 3600) / 60)
    var remainder = value % 60
    var shortClock = minutes + ":" + (remainder < 10 ? "0" : "") + remainder
    return hours > 0 ? hours + ":" + (minutes < 10 ? "0" : "") + shortClock : shortClock
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
        text: root.state === "saved" ? "󰄬" : "󰻂"
        color: root.state === "recording"
          ? Color.urgent : (root.bar ? root.bar.foreground : Color.popups.text)
        fontFamily: Style.font.family
        fontSize: Style.bar.iconFont
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.state === "saved" ? "Saved"
        : root.state === "stopping" ? "Saving" : root.elapsedText(root.elapsedSeconds)
      color: root.bar ? root.bar.foreground : Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.weight: Font.DemiBold
      renderType: Text.NativeRendering
    }
  }
}
