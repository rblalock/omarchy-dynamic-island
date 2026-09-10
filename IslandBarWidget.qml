import QtQuick
import Quickshell
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
  readonly property bool inventoryVisible: keyboardInventory
    || (revealIntent && !osdTransientHere && (!island || island.retainedMode === ""))
  readonly property bool transientVisible: island && island.transientActive && !inventoryVisible
    && (island.transientKind !== "osd"
      || osdTransientHere)
  readonly property bool revealed: inventoryVisible
  readonly property bool sideCompactVisible: vertical && (inventoryVisible || transientVisible)
  readonly property string restMode: inventoryVisible ? "peek"
    : (transientVisible ? "transient"
      : (companionAtRest ? "companion" : (activityAtRest ? "activity" : "clock")))
  property bool revealIntent: false
  property string keyboardSelectionId: ""
  property var clockAdapter: stockClockLoader.item
  property var indicatorAdapter: stockIndicatorLoader.item
  property var keyboardAdapter: stockKeyboardLoader.item
  property var audioAdapter: stockAudioLoader.item
  property var displayAdapter: stockDisplayLoader.item
  property var trayAdapter: stockTrayLoader.item
  property var bluetoothAdapter: stockBluetoothLoader.item
  property var networkAdapter: stockNetworkLoader.item
  property var powerAdapter: stockPowerLoader.item

  readonly property string hostScreenName: {
    var window = root.hostWindow()
    return window && window.screen ? String(window.screen.name || "") : ""
  }
  readonly property string barPosition: bar ? String(bar.position || "top") : "top"
  readonly property real horizontalPadding: Style.space(4)
  readonly property real restWidth: transientVisible
    ? compactSurface.implicitWidth
    : (companionAtRest ? companionRest.implicitWidth
      : (activityAtRest ? activityPill.implicitWidth : restClock.implicitWidth))
  readonly property real expandedWidth: Math.max(restWidth, compactSurface.implicitWidth)
  readonly property real targetWidth: inventoryVisible ? expandedWidth : restWidth
  readonly property bool inheritTransparentBar: bar && bar.transparent === true
    && (!island || island.backgroundOverride === "")
  readonly property real surfaceTargetOpacity: inheritTransparentBar
    && !inventoryVisible && !transientVisible ? 0 : 1
  readonly property real borderTargetOpacity: inventoryVisible || transientVisible
    || (island && island.styleName === "outline") ? 1 : 0
  readonly property real surfaceRadius: {
    var inherited = island ? island.cornerRadius : Style.cornerRadius
    if (island && island.styleName === "pill") return Math.min(implicitWidth, implicitHeight) / 2
    if (island && island.styleName === "soft-square") return Style.space(9)
    return Math.min(inherited, Math.min(implicitWidth, implicitHeight) / 2)
  }
  readonly property real adapterAnchorX: vertical
    ? (barPosition === "left" ? Math.max(0, barSize - 1) : 0)
    : Math.round((Math.max(1, width > 0 ? width : implicitWidth) - 1) / 2)
  readonly property real adapterAnchorY: vertical
    ? Math.round((Math.max(1, height > 0 ? height : implicitHeight) - 1) / 2)
    : (barPosition === "bottom" ? 0 : Math.max(0, (height > 0 ? height : implicitHeight) - 1))

  implicitWidth: vertical ? barSize : targetWidth + horizontalPadding * 2
  implicitHeight: vertical ? barSize : Style.bar.sizeHorizontal
  clip: true

  function screenRect() {
    var window = root.hostWindow()
    var point = { x: Number(root.x || 0), y: Number(root.y || 0) }
    try {
      if (window && window.contentItem) point = window.contentItem.mapFromItem(root, 0, 0)
    } catch (error) {
    }
    return { x: Number(point.x || 0), y: Number(point.y || 0), width: width, height: height }
  }

  function holdReveal() {
    collapseDelay.stop()
    revealIntent = true
  }

  function releaseReveal() {
    collapseDelay.restart()
  }

  function isLiveStockBar(candidate) {
    return !!(candidate
      && typeof candidate.moduleWidgets === "function"
      && typeof candidate.targetWindow === "function"
      && typeof candidate.focusedScreenName === "function")
  }

  function liveHostBar() {
    if (isLiveStockBar(bar)) return bar
    var window = root.QsWindow ? root.QsWindow.window : null
    var candidates = [root.parent, window]
    if (window) {
      candidates.push(window.parent)
      if (window.contentItem) candidates.push(window.contentItem)
    }
    for (var i = 0; i < candidates.length; i++) {
      var item = candidates[i]
      var depth = 0
      while (item && depth < 16) {
        if (isLiveStockBar(item)) return item
        item = item.parent
        depth++
      }
    }
    return bar
  }

  function hostWindow() {
    var candidate = root.liveHostBar()
    if (candidate && typeof candidate.targetWindow === "function")
      return candidate.targetWindow(root)
    if (bar && typeof bar.targetWindow === "function")
      return bar.targetWindow(root)
    return root.QsWindow ? root.QsWindow.window : null
  }

  function adapterBar() {
    var live = root.liveHostBar()
    return isLiveStockBar(live) ? live : bar
  }

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
    if ("bar" in adapter) adapter.bar = root.adapterBar()
    if ("settings" in adapter) adapter.settings = {
      id: "omarchy.clock",
      format: island.clockFormat,
      formatAlt: "d MMMM 'W'ww yyyy",
      verticalFormat: island.verticalClockFormat,
      verticalFormatAlt: "dd\nMMM\n'W'ww\n''yy"
    }
  }

  function configureStockAdapter(adapter, pluginId) {
    if (!adapter) return
    if ("manageIpc" in adapter) adapter.manageIpc = false
    if ("bar" in adapter) adapter.bar = root.adapterBar()
    if ("settings" in adapter) adapter.settings = { id: String(pluginId || "") }
    if (island) Qt.callLater(island.refreshStockState)
  }

  function stockAdapter(pluginId) {
    var id = String(pluginId || "")
    if (id === "omarchy.indicators") return indicatorAdapter
    if (id === "omarchy.keyboard-layout") return keyboardAdapter
    if (id === "omarchy.audio") return audioAdapter
    if (id === "omarchy.monitor") return displayAdapter
    if (id === "omarchy.tray") return trayAdapter
    if (id === "omarchy.bluetooth") return bluetoothAdapter
    if (id === "omarchy.network") return networkAdapter
    if (id === "omarchy.power") return powerAdapter
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
        island.setClockFormat(String(adapter.activeFormat || ""), true, root.vertical)
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
      vertical: vertical,
      barPosition: barPosition,
      sideCompactVisible: sideCompactVisible,
      restWidth: Number(restWidth || 0),
      expandedWidth: Number(expandedWidth || 0),
      implicitWidth: Number(implicitWidth || 0),
      implicitHeight: Number(implicitHeight || 0),
      rowImplicitWidth: Number(compactSurface.rowImplicitWidth || 0),
      borderOpacity: Number(expandingBorder.opacity || 0),
      surfaceOpacity: Number(islandSurface.opacity || 0),
      surfaceTargetOpacity: surfaceTargetOpacity,
      barTransparent: bar ? bar.transparent === true : false,
      clockAdapterReady: clockAdapter !== null,
      indicatorAdapterReady: indicatorAdapter !== null,
      keyboardAdapterReady: keyboardAdapter !== null,
      audioAdapterReady: audioAdapter !== null,
      displayAdapterReady: displayAdapter !== null,
      trayAdapterReady: trayAdapter !== null,
      liveHostBar: isLiveStockBar(root.liveHostBar()),
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
  onAudioAdapterChanged: configureStockAdapter(audioAdapter, "omarchy.audio")
  onDisplayAdapterChanged: configureStockAdapter(displayAdapter, "omarchy.monitor")
  onTrayAdapterChanged: configureStockAdapter(trayAdapter, "omarchy.tray")
  onBluetoothAdapterChanged: configureStockAdapter(bluetoothAdapter, "omarchy.bluetooth")
  onNetworkAdapterChanged: configureStockAdapter(networkAdapter, "omarchy.network")
  onPowerAdapterChanged: configureStockAdapter(powerAdapter, "omarchy.power")
  onKeyboardInventoryChanged: {
    if (keyboardInventory) Qt.callLater(ensureKeyboardSelection)
    else keyboardSelectionId = ""
  }
  onVerticalChanged: if (vertical) widthAnimation.complete()
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
    x: root.adapterAnchorX
    y: root.adapterAnchorY
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
    x: root.adapterAnchorX
    y: root.adapterAnchorY
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
    x: root.adapterAnchorX
    y: root.adapterAnchorY
    width: 1
    height: 1
    opacity: 0
    z: -100
    onLoaded: root.configureStockAdapter(item, "omarchy.keyboard-layout")
  }

  Loader {
    id: stockAudioLoader
    active: root.island && !root.island.hasMountedStockWidget("omarchy.audio")
    source: active ? root.island.pluginEntryPointUrl("omarchy.audio", "barWidget") : ""
    x: root.adapterAnchorX
    y: root.adapterAnchorY
    width: 1
    height: 1
    opacity: 0
    z: -100
    onLoaded: root.configureStockAdapter(item, "omarchy.audio")
  }

  Loader {
    id: stockDisplayLoader
    active: root.island && !root.island.hasMountedStockWidget("omarchy.monitor")
    source: active ? root.island.pluginEntryPointUrl("omarchy.monitor", "barWidget") : ""
    x: root.adapterAnchorX
    y: root.adapterAnchorY
    width: 1
    height: 1
    opacity: 0
    z: -100
    onLoaded: root.configureStockAdapter(item, "omarchy.monitor")
  }

  Loader {
    id: stockTrayLoader
    active: root.island && !root.island.hasMountedStockWidget("omarchy.tray")
    source: active ? root.island.pluginEntryPointUrl("omarchy.tray", "barWidget") : ""
    x: root.adapterAnchorX
    y: root.adapterAnchorY
    width: 1
    height: 1
    opacity: 0
    z: -100
    onLoaded: root.configureStockAdapter(item, "omarchy.tray")
  }

  Loader {
    id: stockBluetoothLoader
    active: root.island && !root.island.hasMountedStockWidget("omarchy.bluetooth")
    source: active ? root.island.pluginEntryPointUrl("omarchy.bluetooth", "barWidget") : ""
    x: root.adapterAnchorX
    y: root.adapterAnchorY
    width: 1
    height: 1
    opacity: 0
    z: -100
    onLoaded: root.configureStockAdapter(item, "omarchy.bluetooth")
  }

  Loader {
    id: stockNetworkLoader
    active: root.island && !root.island.hasMountedStockWidget("omarchy.network")
    source: active ? root.island.pluginEntryPointUrl("omarchy.network", "barWidget") : ""
    x: root.adapterAnchorX
    y: root.adapterAnchorY
    width: 1
    height: 1
    opacity: 0
    z: -100
    onLoaded: root.configureStockAdapter(item, "omarchy.network")
  }

  Loader {
    id: stockPowerLoader
    active: root.island && !root.island.hasMountedStockWidget("omarchy.power")
    source: active ? root.island.pluginEntryPointUrl("omarchy.power", "barWidget") : ""
    x: root.adapterAnchorX
    y: root.adapterAnchorY
    width: 1
    height: 1
    opacity: 0
    z: -100
    onLoaded: root.configureStockAdapter(item, "omarchy.power")
  }

  Connections {
    target: root.island
    enabled: root.island !== null
    ignoreUnknownSignals: true
    function onConfiguredClockFormatChanged() {
      if (root.island.clockFormatOverride === "") root.configureClockAdapter()
    }
    function onConfiguredVerticalClockFormatChanged() {
      if (root.island.verticalClockFormatOverride === "") root.configureClockAdapter()
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
    anchors.leftMargin: root.vertical ? 0 : root.horizontalPadding
    anchors.rightMargin: root.vertical ? 0 : root.horizontalPadding
    clip: true

    CompactSurface {
      id: compactSurface
      anchors.centerIn: parent
      width: implicitWidth
      height: implicitHeight
      visible: !root.vertical && (root.inventoryVisible || root.transientVisible)
      enabled: visible
      host: root
      registrationBar: root.bar
    }

    ClockButton {
      id: restClock
      anchors.centerIn: parent
      width: root.vertical ? parent.width : implicitWidth
      height: parent.height
      visible: !root.activityAtRest && !root.companionAtRest
        && (root.vertical || (!root.inventoryVisible && !root.transientVisible))
      enabled: visible
      vertical: root.vertical
      format: root.island
        ? (root.vertical ? root.island.verticalClockFormat : root.island.clockFormat)
        : (root.vertical ? "HH\nmm" : "h:mm AP")
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
      width: root.vertical ? parent.width : implicitWidth
      height: parent.height
      markOnly: root.vertical
      visible: root.activityAtRest
        && (root.vertical || (!root.inventoryVisible && !root.transientVisible))
      enabled: visible
      island: root.island
      activity: root.restActivity
      onActivated: if (root.island) root.island.activateActivity(root.restActivity)
    }

    Row {
      id: companionRest
      anchors.centerIn: parent
      spacing: Style.space(4)
      visible: !root.vertical && root.companionAtRest
        && !root.inventoryVisible && !root.transientVisible
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

    Item {
      id: verticalCompanionRest
      anchors.centerIn: parent
      width: parent.width
      height: parent.height
      visible: root.vertical && root.companionAtRest
      enabled: visible

      ClockButton {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: Math.max(Style.space(16), parent.width - Style.space(10))
        vertical: true
        accessibleName: "Open calendar"
        format: root.island ? root.island.verticalClockFormat : "HH\nmm"
        cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        bar: root.bar
        interactive: verticalCompanionRest.visible
        onActivated: if (root.island) root.island.triggerClockAction("primary")
        onSecondaryActivated: if (root.island) root.island.triggerClockAction("secondary")
        onMiddleActivated: if (root.island) root.island.triggerClockAction("middle")
      }

      Item {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: Style.space(10)

        Ui.OpticalGlyph {
          anchors.centerIn: parent
          width: parent.width
          height: parent.width
          text: root.restActivity ? String(root.restActivity.glyph || "󰐕") : "󰐕"
          color: root.restActivity && root.restActivity.attention === "critical"
            ? Color.urgent : Color.popups.text
          fontFamily: Style.font.family
          fontSize: Style.font.caption
        }

        TapHandler {
          acceptedButtons: Qt.LeftButton
          gesturePolicy: TapHandler.ReleaseWithinBounds
          onTapped: if (root.island) root.island.activateActivity(root.restActivity)
        }
        HoverHandler { cursorShape: Qt.PointingHandCursor }

        Accessible.role: Accessible.Button
        Accessible.name: root.restActivity ? String(root.restActivity.title || "Open activity") : "Open activity"
        Accessible.onPressAction: if (root.island) root.island.activateActivity(root.restActivity)
      }
    }
  }

  MouseArea {
    id: revealPointer
    anchors.fill: parent
    acceptedButtons: Qt.NoButton
    hoverEnabled: true
    propagateComposedEvents: true

    onContainsMouseChanged: {
      if (containsMouse) root.holdReveal()
      else root.releaseReveal()
    }
  }

  Behavior on implicitWidth {
    enabled: !root.vertical && root.island && root.island.motionEnabled
    NumberAnimation {
      id: widthAnimation
      duration: root.island
        ? (root.revealed ? root.island.motionExpandMs : root.island.motionCollapseMs) : 0
      easing.type: Easing.OutCubic
    }
  }
}
