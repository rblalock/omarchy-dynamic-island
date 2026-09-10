import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var host
  property var island: host ? host.island : null
  property var registrationBar: null

  readonly property bool inventoryVisible: host && host.inventoryVisible
  readonly property bool transientVisible: host && host.transientVisible
  readonly property bool keyboardInventory: host && host.keyboardInventory
  readonly property int proxyCount: host && host.proxyItems ? host.proxyItems.length : 0
  readonly property bool clockIncluded: island ? island.includeClock : true
  readonly property int rowItemCount: proxyCount + (clockIncluded ? 2 : 0)
  readonly property real rowImplicitWidth: proxyCount * Style.bar.iconSlot
    + (clockIncluded ? 1 + peekClock.implicitWidth : 0)
    + Math.max(0, rowItemCount - 1) * Style.space(2)
  readonly property real activeWidth: inventoryVisible
    ? rowImplicitWidth
    : (transientVisible && island
      ? (island.transientKind === "display" ? displayPill.implicitWidth
        : (island.transientKind === "osd" ? osdPill.implicitWidth : volumePill.implicitWidth))
      : Style.bar.sizeHorizontal)

  implicitWidth: Math.max(Style.bar.sizeHorizontal, activeWidth)
  implicitHeight: Style.bar.sizeHorizontal
  clip: true

  Row {
    id: proxyRow
    anchors.centerIn: parent
    spacing: Style.space(2)
    opacity: root.inventoryVisible ? 1 : 0
    enabled: root.inventoryVisible

    Behavior on opacity {
      enabled: root.island && root.island.motionEnabled
      NumberAnimation {
        duration: root.island ? root.island.contentMotionMs : 0
        easing.type: Easing.OutCubic
      }
    }

    Repeater {
      model: root.host ? root.host.proxyItems : []

      ProxyButton {
        required property int index
        required property var modelData
        readonly property bool activityProxy: String(modelData.id || "") === "omarchy-island.activities"
        readonly property var liveActivity: activityProxy && root.island
          ? root.island.displayActivity : null
        glyph: String(liveActivity ? (liveActivity.glyph || "󰐕") : (modelData.glyph || ""))
        iconKind: String(modelData.iconKind || "")
        glyphFontFamily: modelData.fontFamily ? String(modelData.fontFamily) : Style.font.family
        customUrl: String(activityProxy && liveActivity && root.island
          ? root.island.presentationUrl(liveActivity,
            root.island.eventActive ? "event" : "compact")
          : (modelData.customUrl || ""))
        wheelEnabled: root.island && (
          (String(modelData.kind || "") === "audio" && root.island.audioAvailable)
          || (String(modelData.kind || "") === "display" && root.island.displayAvailable))
        activity: liveActivity || modelData.activity || null
        island: root.island
        bar: root.registrationBar
        interactive: root.inventoryVisible
        selected: root.keyboardInventory
          && root.host.keyboardSelectionId === String(modelData.id || "")
        accessibleName: String(liveActivity
          ? liveActivity.title : (modelData.label || "Open system control"))
        onActivated: root.island.triggerProxy(modelData, root.keyboardInventory)
        onSecondaryActivated: root.island.triggerProxyAction(modelData, "secondary", root.keyboardInventory)
        onMiddleActivated: root.island.triggerProxyAction(modelData, "middle", root.keyboardInventory)
        onHoveredChanged: if (hovered && root.keyboardInventory)
          root.host.keyboardSelectionId = String(modelData.id || "")
        onWheelMoved: function(delta) { root.island.scrollProxy(modelData, delta) }
      }
    }

    Rectangle {
      visible: root.island ? root.island.includeClock : true
      width: 1
      height: Style.space(14)
      anchors.verticalCenter: parent.verticalCenter
      color: Color.popups.border
      opacity: 0.45
    }

    Item {
      visible: root.island ? root.island.includeClock : true
      width: visible ? peekClock.implicitWidth : 0
      height: root.implicitHeight

      ClockButton {
        id: peekClock
        anchors.fill: parent
        accessibleName: "Open calendar"
        format: root.island ? root.island.clockFormat : "h:mm AP"
        cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        bar: root.registrationBar
        interactive: root.inventoryVisible
        onActivated: root.island.triggerClockAction("primary")
        onSecondaryActivated: root.island.triggerClockAction("secondary")
        onMiddleActivated: root.island.triggerClockAction("middle")
        onHoveredChanged: if (hovered && root.keyboardInventory)
          root.host.keyboardSelectionId = "omarchy.clock"
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.space(1)
        width: Style.space(20)
        height: Style.space(2)
        radius: height / 2
        color: Color.accent
        visible: root.keyboardInventory && root.host.keyboardSelectionId === "omarchy.clock"
      }
    }
  }

  VolumePill {
    id: volumePill
    anchors.centerIn: parent
    visible: root.transientVisible && root.island && root.island.transientKind === "audio"
    enabled: visible
    island: root.island
    onActivated: root.island.openAudio()
  }

  DisplayPill {
    id: displayPill
    anchors.centerIn: parent
    visible: root.transientVisible && root.island && root.island.transientKind === "display"
    enabled: visible
    island: root.island
    onActivated: root.island.openDisplay()
  }

  OsdPill {
    id: osdPill
    anchors.centerIn: parent
    visible: root.transientVisible && root.island && root.island.transientKind === "osd"
    event: root.island ? root.island.osdEvent : null
  }
}
