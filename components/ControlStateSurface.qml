import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property bool hovered: false
  property bool pressed: false
  property bool focused: false
  property bool selected: false
  property bool chinVisible: focused
  property color normalColor: "transparent"
  property real cornerRadius: Style.cornerRadius
  property real inset: Style.space(2)
  property real chinWidth: Style.space(18)

  BorderSurface {
    anchors.fill: parent
    anchors.margins: root.inset
    radius: Math.min(root.cornerRadius, height / 2)
    color: root.pressed
      ? Style.pressedFillFor(Color.popups.text, Color.accent)
      : (root.focused
      ? Style.focusFillFor(Color.popups.text, Color.accent)
      : (root.hovered
      ? Style.hoverFillFor(Color.popups.text, Color.accent)
      : (root.selected
      ? Style.selectedFillFor(Color.popups.text, Color.accent)
      : root.normalColor)))
    borderSpec: Border.none()

    Behavior on color { ColorAnimation { duration: 90 } }
  }

  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: root.inset
    width: Math.min(root.chinWidth,
      Math.max(0, root.width - (root.inset + Style.space(4)) * 2))
    height: Math.max(1, Style.space(2))
    radius: height / 2
    color: Color.accent
    opacity: root.chinVisible ? 1 : 0
    visible: opacity > 0

    Behavior on opacity { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
  }
}
