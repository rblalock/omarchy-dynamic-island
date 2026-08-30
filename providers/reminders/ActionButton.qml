import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string glyph: ""
  property string label: "Action"
  property bool destructive: false
  signal activated()

  readonly property bool hovered: pointer.containsMouse

  implicitWidth: Style.space(112)
  implicitHeight: Style.space(42)
  activeFocusOnTab: true

  Keys.onReturnPressed: root.activated()
  Keys.onEnterPressed: root.activated()
  Keys.onSpacePressed: root.activated()

  BorderSurface {
    anchors.fill: parent
    radius: Math.min(root.islandRadius, height / 2)
    color: pointer.pressed ? Style.pressedFillFor(Color.popups.text, Color.accent)
      : root.activeFocus ? Style.focusFillFor(Color.popups.text, Color.accent)
      : root.hovered ? Style.hoverFillFor(Color.popups.text, Color.accent)
      : "transparent"
    borderSpec: Border.none()
  }

  property real islandRadius: Style.cornerRadius

  Row {
    anchors.centerIn: parent
    spacing: Style.space(6)

    Text {
      text: root.glyph
      color: root.destructive ? Color.urgent : Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.icon
      renderType: Text.NativeRendering
    }

    Text {
      text: root.label
      color: root.destructive ? Color.urgent : Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.weight: Font.Medium
      renderType: Text.NativeRendering
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onContainsMouseChanged: if (containsMouse) root.forceActiveFocus(Qt.MouseFocusReason)
    onClicked: root.activated()
  }

  Accessible.role: Accessible.Button
  Accessible.name: root.label
  Accessible.onPressAction: root.activated()
}
