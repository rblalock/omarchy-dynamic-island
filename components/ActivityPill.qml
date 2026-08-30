import QtQuick
import qs.Commons
import qs.Ui as Ui

Item {
  id: root
  property var island: null
  property var activity: island
    ? (island.eventActive && island.eventActivity ? island.eventActivity : island.currentActivity) : null
  property bool markOnly: false
  readonly property string customUrl: island && activity
    ? island.presentationUrl(activity, island.eventActive ? "event" : "minimal") : ""
  signal activated()

  function injectCustom() {
    if (!customLoader.item) return
    if ("island" in customLoader.item) customLoader.item.island = root.island
    if ("activity" in customLoader.item) customLoader.item.activity = root.activity
    if ("bar" in customLoader.item) customLoader.item.bar = root.island
      ? root.island.stockBar() : null
  }

  readonly property bool customReady: customLoader.status === Loader.Ready && customLoader.item
  readonly property real customWidth: customReady
    ? customLoader.item.implicitWidth + Style.space(8) : Style.bar.iconSlot

  implicitWidth: markOnly
    ? Math.max(Style.bar.iconSlot, customWidth)
    : (customReady
      ? Math.max(Style.space(64), customLoader.item.implicitWidth + Style.space(12))
      : fallback.implicitWidth + Style.space(16))
  implicitHeight: Style.bar.sizeHorizontal
  activeFocusOnTab: true
  Keys.onReturnPressed: root.activated()
  Keys.onEnterPressed: root.activated()
  Keys.onSpacePressed: root.activated()
  onActivityChanged: injectCustom()
  onIslandChanged: injectCustom()

  Loader {
    id: customLoader
    anchors.fill: parent
    anchors.margins: Style.space(4)
    active: root.customUrl !== ""
    source: active ? root.customUrl : ""
    onLoaded: root.injectCustom()
  }

  Row {
    id: fallback
    anchors.centerIn: parent
    visible: !root.markOnly && (customLoader.status !== Loader.Ready || !customLoader.item)
    spacing: Style.space(6)

    Text {
      text: root.activity ? root.activity.glyph : "󰐕"
      color: root.activity && root.activity.attention === "critical" ? Color.urgent : Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.icon
      renderType: Text.NativeRendering
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.activity ? root.activity.title : "Omarchy Island"
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.weight: Font.Medium
      renderType: Text.NativeRendering
    }
  }

  Ui.OpticalGlyph {
    anchors.centerIn: parent
    width: Style.bar.iconCanvas
    height: Style.bar.iconCanvas
    visible: root.markOnly && (customLoader.status !== Loader.Ready || !customLoader.item)
    text: root.activity ? root.activity.glyph : "󰐕"
    color: root.activity && root.activity.attention === "critical"
      ? Color.urgent : Color.popups.text
    fontFamily: Style.font.family
    fontSize: Style.bar.iconFont
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    gesturePolicy: TapHandler.ReleaseWithinBounds
    onTapped: root.activated()
  }
  HoverHandler { cursorShape: Qt.PointingHandCursor }

  Accessible.role: Accessible.Button
  Accessible.name: root.activity ? root.activity.title : "Open Omarchy Island"
  Accessible.onPressAction: root.activated()
}
