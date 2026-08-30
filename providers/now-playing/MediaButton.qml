import QtQuick
import qs.Commons
import qs.Ui as Ui

Item {
  id: root

  property string glyph: ""
  property string label: "Media action"
  signal activated()

  readonly property bool hovered: pointer.containsMouse

  implicitWidth: Style.space(44)
  implicitHeight: Style.space(40)
  activeFocusOnTab: true
  opacity: enabled ? 1 : 0.34

  Keys.onReturnPressed: if (enabled) activated()
  Keys.onEnterPressed: if (enabled) activated()
  Keys.onSpacePressed: if (enabled) activated()

  Ui.BorderSurface {
    anchors.fill: parent
    radius: Math.min(Style.cornerRadius, height / 2)
    color: pointer.pressed ? Style.pressedFillFor(Color.popups.text, Color.accent)
      : root.activeFocus ? Style.focusFillFor(Color.popups.text, Color.accent)
      : root.hovered ? Style.hoverFillFor(Color.popups.text, Color.accent)
      : "transparent"
    borderSpec: Border.none()

    Behavior on color { ColorAnimation { duration: 90 } }
  }

  Text {
    anchors.centerIn: parent
    text: root.glyph
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.iconLarge
    renderType: Text.NativeRendering
  }

  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    width: Style.space(14)
    height: Style.space(2)
    radius: height / 2
    color: Color.accent
    opacity: root.activeFocus ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.forceActiveFocus(Qt.MouseFocusReason)
      root.activated()
    }
  }

  Accessible.role: Accessible.Button
  Accessible.name: root.label
  Accessible.onPressAction: if (root.enabled) root.activated()
}
