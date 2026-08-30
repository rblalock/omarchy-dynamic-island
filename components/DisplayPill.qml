import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property var island: null
  signal activated()

  implicitWidth: Style.space(174)
  implicitHeight: Style.bar.sizeHorizontal
  activeFocusOnTab: true
  Keys.onReturnPressed: root.activated()
  Keys.onEnterPressed: root.activated()
  Keys.onSpacePressed: root.activated()

  Row {
    anchors.centerIn: parent
    spacing: Style.space(8)

    OpticalGlyph {
      width: Style.bar.iconCanvas
      height: Style.bar.iconCanvas
      anchors.verticalCenter: parent.verticalCenter
      text: root.island ? root.island.displayIcon : "󰍹"
      color: Color.popups.text
      fontFamily: Style.font.family
      fontSize: Style.bar.iconFont
    }

    Item {
      width: Style.space(82)
      height: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter

      Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.16)
      }

      Rectangle {
        width: parent.width * (root.island ? root.island.displayBrightness : 0)
        height: parent.height
        radius: height / 2
        color: Color.accent
      }
    }

    Text {
      width: Style.space(34)
      anchors.verticalCenter: parent.verticalCenter
      text: Math.round((root.island ? root.island.displayBrightness : 0) * 100) + "%"
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.weight: Font.Medium
      horizontalAlignment: Text.AlignRight
      renderType: Text.NativeRendering
    }
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    gesturePolicy: TapHandler.ReleaseWithinBounds
    onTapped: root.activated()
  }
  HoverHandler { cursorShape: Qt.PointingHandCursor }

  Accessible.role: Accessible.Button
  Accessible.name: "Brightness "
    + Math.round((root.island ? root.island.displayBrightness : 0) * 100)
    + " percent. Open display controls"
  Accessible.onPressAction: root.activated()
}
