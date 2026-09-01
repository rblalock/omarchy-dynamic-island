import QtQuick
import qs.Commons
import qs.Ui as Ui
import "components"

Ui.BarWidget {
  id: root

  moduleName: "rblalock.omarchy-island"

  readonly property var island: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName) : null
  readonly property var proxyItems: filteredProxyItems(island ? island.peekItems : [])
  readonly property var restActivity: island
    ? (island.restContent === "activity" ? island.displayActivity : island.restActivity) : null
  readonly property string restPresentation: island && restActivity
    ? island.restPresentation(restActivity) : "hidden"
  readonly property bool companionAtRest: island && restActivity && !island.eventActive
    && island.restContent === "auto" && restPresentation === "companion"
  readonly property bool activityAtRest: island && restActivity && (
    island.restContent === "activity"
    || (island.restContent === "auto" && !companionAtRest))
  readonly property bool keyboardInventory: island && island.keyboardPeekActive
    && typeof island.activeBarHost === "function" && island.activeBarHost() === root
  readonly property bool osdTransientHere: island && island.transientActive
    && island.transientKind === "osd" && island.osdScreenName === hostScreenName
  readonly property bool inventoryVisible: keyboardInventory || (revealIntent && !osdTransientHere)
  readonly property bool transientVisible: island && island.transientActive && !inventoryVisible
    && (island.transientKind !== "osd"
      || osdTransientHere)
  readonly property bool revealed: inventoryVisible
  readonly property string restMode: inventoryVisible ? "peek"
    : (transientVisible ? "transient"
      : (companionAtRest ? "companion" : (activityAtRest ? "activity" : "clock")))
  property bool revealIntent: false
  property string keyboardSelectionId: ""
  property var clockAdapter: stockClockLoader.item
  property var indicatorAdapter: stockIndicatorLoader.item
  property var keyboardAdapter: stockKeyboardLoader.item

  readonly property string hostScreenName: {
    var window = bar && typeof bar.targetWindow === "function"
      ? bar.targetWindow(root) : (root.QsWindow ? root.QsWindow.window : null)
    return window && window.screen ? String(window.screen.name || "") : ""
  }
  readonly property real horizontalPadding: Style.space(4)
  readonly property real restWidth: transientVisible
    ? (island.transientKind === "display" ? displayPill.implicitWidth
      : (island.transientKind === "osd" ? osdPill.implicitWidth : volumePill.implicitWidth))
    : (companionAtRest ? companionRest.implicitWidth
      : (activityAtRest ? activityPill.implicitWidth : restClock.implicitWidth))
  readonly property real expandedWidth: Math.max(restWidth, proxyRow.implicitWidth)
  readonly property real targetWidth: inventoryVisible ? expandedWidth : restWidth
  readonly property bool inheritTransparentBar: bar && bar.transparent === true
    && (!island || island.backgroundOverride === "")
  readonly property real surfaceTargetOpacity: inheritTransparentBar
    && !inventoryVisible && !transientVisible ? 0 : 1
  readonly property real borderTargetOpacity: inventoryVisible || transientVisible
    || (island && island.styleName === "outline") ? 1 : 0
  readonly property real surfaceRadius: {
    var inherited = island ? island.cornerRadius : Style.cornerRadius
    if (island && island.styleName === "pill") return implicitHeight / 2
    if (island && island.styleName === "soft-square") return Style.space(9)
    return Math.min(inherited, implicitHeight / 2)
  }

  implicitWidth: targetWidth + horizontalPadding * 2
  implicitHeight: Style.bar.sizeHorizontal
  clip: true

  function filteredProxyItems(values) {
    var result = []
    var source = values && typeof values.length === "number" ? values : []
    for (var i = 0; i < source.length; i++) {
      var item = source[i]
      if (!item || String(item.id || "") === "" || String(item.id) === moduleName) continue
      result.push(item)
    }
    return result
  }

  // Omarchy's bar owns the top-level left-button gesture so widgets can be
  // dragged. Expose the stock click-target contract for the current Rest
  // presentation; individual Peek controls register themselves below.
  function triggerPress(button) {
    if (!island || button !== Qt.LeftButton) return
    if (inventoryVisible) return
    if (transientVisible) {
      if (island.transientKind === "display") island.openDisplay()
      else if (island.transientKind === "audio") island.openAudio()
      return
    } else if (activityAtRest || companionAtRest) island.activateActivity(restActivity)
    else island.triggerClockAction("primary")
  }

  function configureClockAdapter() {
    var adapter = clockAdapter
    if (!adapter || !island) return
    if ("bar" in adapter) adapter.bar = root.bar
    if ("settings" in adapter) adapter.settings = {
      id: "omarchy.clock",
      format: island.clockFormat,
      formatAlt: "d MMMM 'W'ww yyyy",
      verticalFormat: island.clockFormat,
      verticalFormatAlt: "dd\nMMM\n'W'ww\n''yy"
    }
  }

  function configureStockAdapter(adapter, pluginId) {
    if (!adapter) return
    if ("bar" in adapter) adapter.bar = root.bar
    if ("settings" in adapter) adapter.settings = { id: String(pluginId || "") }
    if (island) Qt.callLater(island.refreshStockState)
  }

  function stockAdapter(pluginId) {
    var id = String(pluginId || "")
    if (id === "omarchy.indicators") return indicatorAdapter
    if (id === "omarchy.keyboard-layout") return keyboardAdapter
    return null
  }

  function triggerClockAdapterAction(action) {
    var adapter = clockAdapter
    if (!adapter) return false
    action = String(action || "primary")
    if (action === "primary") {
      if (typeof adapter.togglePanel === "function") adapter.togglePanel()
      else if (typeof adapter.toggle === "function") adapter.toggle()
      else return false
      return true
    }
    if (action === "secondary" && typeof adapter.cycleFormat === "function") {
      adapter.cycleFormat()
      if (island && "activeFormat" in adapter)
        island.setClockFormat(String(adapter.activeFormat || ""), true)
      return true
    }
    return false
  }

  function keyboardIds() {
    var result = []
    for (var i = 0; i < proxyItems.length; i++) result.push(String(proxyItems[i].id))
    if (island && island.includeClock) result.push("omarchy.clock")
    return result
  }

  function keyboardItemCount() {
    return keyboardIds().length
  }

  function ensureKeyboardSelection() {
    var ids = keyboardIds()
    if (ids.length === 0) {
      keyboardSelectionId = ""
      return
    }
    if (ids.indexOf(keyboardSelectionId) === -1) keyboardSelectionId = ids[0]
  }

  function moveKeyboardSelection(delta) {
    var ids = keyboardIds()
    if (ids.length === 0) return false
    var current = ids.indexOf(keyboardSelectionId)
    if (current < 0) current = 0
    var next = ((current + Number(delta || 0)) % ids.length + ids.length) % ids.length
    keyboardSelectionId = ids[next]
    return true
  }

  function selectKeyboardBoundary(last) {
    var ids = keyboardIds()
    if (ids.length === 0) return false
    keyboardSelectionId = ids[last ? ids.length - 1 : 0]
    return true
  }

  function activateKeyboardSelection() {
    ensureKeyboardSelection()
    if (!island || keyboardSelectionId === "") return false
    if (keyboardSelectionId === "omarchy.clock")
      return island.triggerClockAction("primary")
    for (var i = 0; i < proxyItems.length; i++)
      if (String(proxyItems[i].id) === keyboardSelectionId)
        return island.triggerProxy(proxyItems[i], true)
    return false
  }

  function activateKeyboardIndex(index) {
    var ids = keyboardIds()
    var requested = Number(index)
    if (!Number.isInteger(requested) || requested < 0 || requested >= ids.length) return false
    keyboardSelectionId = ids[requested]
    return activateKeyboardSelection()
  }

  function handleKeyboardKey(key, modifiers) {
    if (!keyboardInventory) return false
    if (key >= Qt.Key_1 && key <= Qt.Key_9)
      return activateKeyboardIndex(key - Qt.Key_1)
    if (key === Qt.Key_0) return activateKeyboardIndex(9)
    if (key === Qt.Key_Left || key === Qt.Key_Up || key === Qt.Key_H || key === Qt.Key_K)
      return moveKeyboardSelection(-1)
    if (key === Qt.Key_Right || key === Qt.Key_Down || key === Qt.Key_J || key === Qt.Key_L
        || key === Qt.Key_Tab)
      return moveKeyboardSelection((modifiers & Qt.ShiftModifier) && key === Qt.Key_Tab ? -1 : 1)
    if (key === Qt.Key_Backtab) return moveKeyboardSelection(-1)
    if (key === Qt.Key_Home) return selectKeyboardBoundary(false)
    if (key === Qt.Key_End) return selectKeyboardBoundary(true)
    if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space)
      return activateKeyboardSelection()
    if (key === Qt.Key_Escape) {
      island.closeRetained()
      return true
    }
    return false
  }

  function debugState() {
    return {
      screen: hostScreenName,
      visible: visible,
      revealed: revealed,
      inventoryVisible: inventoryVisible,
      keyboardInventory: keyboardInventory,
      keyboardSelection: keyboardSelectionId,
      revealIntent: revealIntent,
      activityAtRest: activityAtRest,
      companionAtRest: companionAtRest,
      restMode: restMode,
      restPresentation: restPresentation,
      transientVisible: transientVisible,
      osdTransientHere: osdTransientHere,
      restWidth: Number(restWidth || 0),
      expandedWidth: Number(expandedWidth || 0),
      implicitWidth: Number(implicitWidth || 0),
      rowImplicitWidth: Number(proxyRow.implicitWidth || 0),
      borderOpacity: Number(expandingBorder.opacity || 0),
      surfaceOpacity: Number(islandSurface.opacity || 0),
      surfaceTargetOpacity: surfaceTargetOpacity,
      barTransparent: bar ? bar.transparent === true : false,
      clockAdapterReady: clockAdapter !== null,
      indicatorAdapterReady: indicatorAdapter !== null,
      keyboardAdapterReady: keyboardAdapter !== null,
      proxyItems: proxyItems.map(function(item) { return String(item.id || "") })
    }
  }

  function registerWithService() {
    if (island && typeof island.registerBarHost === "function") island.registerBarHost(root)
  }

  function unregisterFromService() {
    if (island && typeof island.unregisterBarHost === "function") island.unregisterBarHost(root)
  }

  onIslandChanged: {
    registerWithService()
    configureClockAdapter()
  }
  onBarChanged: configureClockAdapter()
  onClockAdapterChanged: configureClockAdapter()
  onIndicatorAdapterChanged: configureStockAdapter(indicatorAdapter, "omarchy.indicators")
  onKeyboardAdapterChanged: configureStockAdapter(keyboardAdapter, "omarchy.keyboard-layout")
  onKeyboardInventoryChanged: {
    if (keyboardInventory) Qt.callLater(ensureKeyboardSelection)
    else keyboardSelectionId = ""
  }
  Component.onCompleted: registerWithService()
  Component.onDestruction: unregisterFromService()

  Timer {
    id: collapseDelay
    interval: root.island ? root.island.collapseDelayMs : 95
    onTriggered: root.revealIntent = false
  }

  // Omarchy's calendar is owned by its clock bar widget. Keep one transparent,
  // one-pixel instance per Island host so the real calendar can anchor to the
  // Island even when the visible stock clock is absent from shell.json.
  // Pointer handling remains entirely with Island's own clock buttons.
  Loader {
    id: stockClockLoader
    active: root.island && root.island.clockWidgetUrl !== ""
      && !root.island.hasMountedStockWidget("omarchy.clock")
    source: active ? root.island.clockWidgetUrl : ""
    x: Math.round((root.width - width) / 2)
    y: root.height - height
    width: 1
    height: 1
    opacity: 0
    z: -100
    onLoaded: root.configureClockAdapter()
  }

  Loader {
    id: stockIndicatorLoader
    active: root.island && !root.island.hasMountedStockWidget("omarchy.indicators")
    source: active ? root.island.pluginEntryPointUrl("omarchy.indicators", "barWidget") : ""
    width: 1
    height: 1
    opacity: 0
    z: -100
    onLoaded: root.configureStockAdapter(item, "omarchy.indicators")
  }

  Loader {
    id: stockKeyboardLoader
    active: root.island && !root.island.hasMountedStockWidget("omarchy.keyboard-layout")
    source: active ? root.island.pluginEntryPointUrl("omarchy.keyboard-layout", "barWidget") : ""
    width: 1
    height: 1
    opacity: 0
    z: -100
    onLoaded: root.configureStockAdapter(item, "omarchy.keyboard-layout")
  }

  Connections {
    target: root.island
    enabled: root.island !== null
    ignoreUnknownSignals: true
    function onConfiguredClockFormatChanged() {
      if (root.island.clockFormatOverride === "") root.configureClockAdapter()
    }
  }

  Ui.BorderSurface {
    id: islandSurface
    anchors.fill: parent
    radius: root.surfaceRadius
    color: root.island && root.island.backgroundOverride !== ""
      ? root.island.backgroundOverride : Color.popups.background
    opacity: root.surfaceTargetOpacity
    borderSpec: Border.none()

    Behavior on opacity {
      enabled: root.island && root.island.motionEnabled
      NumberAnimation {
        duration: root.island ? root.island.contentMotionMs : 0
        easing.type: Easing.OutCubic
      }
    }
  }

  // The stock bar uses tonal separation without outlining every module. Keep
  // Rest equally quiet, then reveal the Island boundary only when its larger
  // Peek surface needs one. Explicit `outline` style remains always outlined.
  Ui.BorderSurface {
    id: expandingBorder
    anchors.fill: parent
    radius: root.surfaceRadius
    color: "transparent"
    opacity: root.borderTargetOpacity
    visible: opacity > 0
    borderSpec: Border.surfaceSpec("popups", "border",
      root.island && root.island.borderOverride !== "" ? root.island.borderOverride : Color.popups.border,
      root.island && root.island.styleName === "outline" ? 2 : 1)

    Behavior on opacity {
      enabled: root.island && root.island.motionEnabled
      NumberAnimation {
        duration: root.island ? root.island.contentMotionMs : 0
        easing.type: Easing.OutCubic
      }
    }
  }

  Item {
    id: viewport
    anchors.fill: parent
    anchors.leftMargin: root.horizontalPadding
    anchors.rightMargin: root.horizontalPadding
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
        model: root.proxyItems

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
          bar: root.bar
          interactive: root.inventoryVisible
          selected: root.keyboardInventory && root.keyboardSelectionId === String(modelData.id || "")
          accessibleName: String(liveActivity
            ? liveActivity.title : (modelData.label || "Open system control"))
          onActivated: root.island.triggerProxy(modelData, root.keyboardInventory)
          onSecondaryActivated: root.island.triggerProxyAction(modelData, "secondary", root.keyboardInventory)
          onMiddleActivated: root.island.triggerProxyAction(modelData, "middle", root.keyboardInventory)
          onHoveredChanged: if (hovered && root.keyboardInventory)
            root.keyboardSelectionId = String(modelData.id || "")
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
          bar: root.bar
          interactive: root.inventoryVisible
          onActivated: root.island.triggerClockAction("primary")
          onSecondaryActivated: root.island.triggerClockAction("secondary")
          onMiddleActivated: root.island.triggerClockAction("middle")
          onHoveredChanged: if (hovered && root.keyboardInventory)
            root.keyboardSelectionId = "omarchy.clock"
        }

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(1)
          width: Style.space(20)
          height: Style.space(2)
          radius: height / 2
          color: Color.accent
          visible: root.keyboardInventory && root.keyboardSelectionId === "omarchy.clock"
        }
      }
    }

    ClockButton {
      id: restClock
      anchors.centerIn: parent
      width: implicitWidth
      height: parent.height
      visible: !root.inventoryVisible && !root.activityAtRest
        && !root.companionAtRest && !root.transientVisible
      enabled: visible
      format: root.island ? root.island.clockFormat : "h:mm AP"
      cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
      bar: root.bar
      interactive: visible
      accessibleName: "Open calendar"
      onActivated: if (root.island) root.island.triggerClockAction("primary")
      onSecondaryActivated: if (root.island) root.island.triggerClockAction("secondary")
      onMiddleActivated: if (root.island) root.island.triggerClockAction("middle")
    }

    ActivityPill {
      id: activityPill
      anchors.centerIn: parent
      visible: root.activityAtRest && !root.inventoryVisible && !root.transientVisible
      enabled: visible
      island: root.island
      activity: root.restActivity
      onActivated: if (root.island) root.island.activateActivity(root.restActivity)
    }

    Row {
      id: companionRest
      anchors.centerIn: parent
      spacing: Style.space(4)
      visible: root.companionAtRest && !root.inventoryVisible && !root.transientVisible
      enabled: visible

      ActivityPill {
        id: companionActivity
        markOnly: true
        height: root.implicitHeight
        island: root.island
        activity: root.restActivity
        onActivated: if (root.island) root.island.activateActivity(root.restActivity)
      }

      ClockButton {
        id: companionClock
        height: root.implicitHeight
        accessibleName: "Open calendar"
        format: root.island ? root.island.clockFormat : "h:mm AP"
        cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        bar: root.bar
        interactive: companionRest.visible
        onActivated: if (root.island) root.island.triggerClockAction("primary")
        onSecondaryActivated: if (root.island) root.island.triggerClockAction("secondary")
        onMiddleActivated: if (root.island) root.island.triggerClockAction("middle")
      }
    }

    VolumePill {
      id: volumePill
      anchors.centerIn: parent
      visible: root.transientVisible && root.island.transientKind === "audio"
      enabled: visible
      island: root.island
      onActivated: root.island.openAudio()
    }

    DisplayPill {
      id: displayPill
      anchors.centerIn: parent
      visible: root.transientVisible && root.island.transientKind === "display"
      enabled: visible
      island: root.island
      onActivated: root.island.openDisplay()
    }

    OsdPill {
      id: osdPill
      anchors.centerIn: parent
      visible: root.transientVisible && root.island.transientKind === "osd"
      event: root.island ? root.island.osdEvent : null
    }
  }

  MouseArea {
    id: revealPointer
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    hoverEnabled: true
    propagateComposedEvents: true

    onContainsMouseChanged: {
      if (containsMouse) {
        collapseDelay.stop()
        root.revealIntent = true
      } else collapseDelay.restart()
    }
  }

  Behavior on implicitWidth {
    enabled: root.island && root.island.motionEnabled
    NumberAnimation {
      duration: root.island
        ? (root.revealed ? root.island.motionExpandMs : root.island.motionCollapseMs) : 0
      easing.type: Easing.OutCubic
    }
  }
}
