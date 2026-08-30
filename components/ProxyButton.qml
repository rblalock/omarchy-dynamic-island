import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string glyph: ""
  property string iconKind: ""
  property string glyphFontFamily: Style.font.family
  property string accessibleName: "System control"
  property bool selected: false
  property bool wheelEnabled: false
  property bool interactive: true
  property string customUrl: ""
  property var island: null
  property var bar: null
  property var activity: null
  property var registeredBar: null
  readonly property bool hovered: pointer.containsMouse
  signal activated()
  signal secondaryActivated()
  signal middleActivated()
  signal wheelMoved(real delta)

  width: Style.bar.iconSlot
  height: Style.bar.iconSlot
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

  function injectCustom() {
    if (!customLoader.item) return
    if ("island" in customLoader.item) customLoader.item.island = root.island
    if ("activity" in customLoader.item) customLoader.item.activity = root.activity
    if ("bar" in customLoader.item) customLoader.item.bar = root.island
      ? root.island.stockBar() : null
  }

  onBarChanged: syncClickRegistration()
  onActivityChanged: injectCustom()
  onIslandChanged: injectCustom()
  Component.onCompleted: syncClickRegistration()
  Component.onDestruction: if (registeredBar && registeredBar.unregisterClickTarget)
    registeredBar.unregisterClickTarget(root)

  ControlStateSurface {
    anchors.fill: parent
    cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
    hovered: root.hovered
    pressed: pointer.pressed
    focused: root.activeFocus
    selected: root.selected
  }

  OpticalGlyph {
    anchors.centerIn: parent
    width: Style.bar.iconCanvas
    height: Style.bar.iconCanvas
    visible: root.iconKind === "" && (!customLoader.active || customLoader.status !== Loader.Ready || !customLoader.item)
    text: root.glyph
    color: Color.popups.text
    fontFamily: root.glyphFontFamily
    fontSize: Style.bar.iconFont
  }

  TailscaleGlyph {
    anchors.centerIn: parent
    visible: root.iconKind === "tailscale"
    iconSize: Style.space(11)
    color: Color.popups.text
  }

  Loader {
    id: customLoader
    anchors.centerIn: parent
    width: parent.width - Style.space(6)
    height: parent.height - Style.space(6)
    active: root.customUrl !== ""
    source: active ? root.customUrl : ""
    onLoaded: root.injectCustom()
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    enabled: root.interactive
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) { root.triggerPress(mouse.button) }
    onWheel: function(wheel) {
      if (root.wheelEnabled) root.wheelMoved(wheel.angleDelta.y)
      else wheel.accepted = false
    }
  }

  Accessible.role: Accessible.Button
  Accessible.name: accessibleName
  Accessible.onPressAction: root.activated()
}
