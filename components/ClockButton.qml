import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root

  property string accessibleName: "Open launcher"
  property string format: "h:mm AP"
  property bool vertical: false
  property real cornerRadius: Style.cornerRadius
  property bool interactive: true
  property var bar: null
  property var registeredBar: null
  signal activated()
  signal secondaryActivated()
  signal middleActivated()

  readonly property string displayText: Qt.formatDateTime(clock.date, format)
  readonly property bool hovered: pointer.containsMouse

  implicitWidth: vertical
    ? (bar ? bar.barSize : Style.bar.sizeVertical)
    : label.implicitWidth + Style.space(14)
  implicitHeight: vertical
    ? Math.max(Style.bar.sizeVertical, label.implicitHeight + Style.space(12))
    : Math.max(label.implicitHeight, Style.bar.sizeHorizontal)
  activeFocusOnTab: true
  Keys.onReturnPressed: root.activated()
  Keys.onEnterPressed: root.activated()
  Keys.onSpacePressed: root.activated()

  function triggerPress(button) {
    if (button === Qt.RightButton) root.secondaryActivated()
    else if (button === Qt.MiddleButton) root.middleActivated()
    else root.activated()
  }

  function syncClickRegistration() {
    if (registeredBar && registeredBar.unregisterClickTarget)
      registeredBar.unregisterClickTarget(root)
    registeredBar = root.bar
    if (registeredBar && registeredBar.registerClickTarget)
      registeredBar.registerClickTarget(root)
  }

  onBarChanged: syncClickRegistration()
  Component.onCompleted: syncClickRegistration()
  Component.onDestruction: if (registeredBar && registeredBar.unregisterClickTarget)
    registeredBar.unregisterClickTarget(root)

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  ControlStateSurface {
    anchors.fill: parent
    cornerRadius: root.cornerRadius
    hovered: root.hovered
    pressed: pointer.pressed
    focused: root.activeFocus
  }

  Text {
    id: label
    anchors.fill: parent
    text: root.displayText
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: root.vertical ? Style.font.caption : Style.font.bodySmall
    font.weight: Font.Medium
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    lineHeight: 1
    wrapMode: Text.NoWrap
    renderType: Text.NativeRendering
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) { root.triggerPress(mouse.button) }
  }

  Accessible.role: Accessible.Button
  Accessible.name: accessibleName
  Accessible.onPressAction: root.activated()
}
