import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property var event: null

  readonly property bool hasProgress: event && event.hasProgress === true
  readonly property real normalizedProgress: hasProgress
    ? Math.max(0, Math.min(1, Number(event.progress || 0))) : 0
  readonly property real messageWidth: Math.min(messageMetrics.advanceWidth, Style.space(190))

  implicitWidth: hasProgress
    ? Style.space(174)
    : Style.bar.iconCanvas + Style.space(8) + messageWidth
  implicitHeight: Style.bar.sizeHorizontal

  TextMetrics {
    id: messageMetrics
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.weight: Font.Medium
    text: root.event ? String(root.event.message || "") : ""
  }

  Row {
    anchors.centerIn: parent
    spacing: Style.space(8)

    OpticalGlyph {
      width: Style.bar.iconCanvas
      height: Style.bar.iconCanvas
      anchors.verticalCenter: parent.verticalCenter
      text: root.event ? String(root.event.glyph || "") : ""
      color: Color.popups.text
      fontFamily: Style.font.family
      fontSize: Style.bar.iconFont
    }

    Item {
      visible: root.hasProgress
      width: visible ? Style.space(82) : 0
      height: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.16)
      }

      Rectangle {
        width: parent.width * root.normalizedProgress
        height: parent.height
        radius: height / 2
        color: Color.accent

        Behavior on width {
          NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
      }
    }

    Text {
      width: root.hasProgress ? Style.space(34) : root.messageWidth
      anchors.verticalCenter: parent.verticalCenter
      text: root.event ? String(root.event.message || "") : ""
      color: Color.popups.text
      font: messageMetrics.font
      horizontalAlignment: root.hasProgress ? Text.AlignRight : Text.AlignLeft
      elide: Text.ElideRight
      maximumLineCount: 1
      renderType: Text.NativeRendering
    }
  }

  Accessible.role: Accessible.StaticText
  Accessible.name: root.event ? String(root.event.accessibleName || "System status") : "System status"
}
