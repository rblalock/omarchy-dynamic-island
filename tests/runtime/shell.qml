import QtQuick
import Quickshell
import "plugin" as IslandPlugin
import "plugin/components" as IslandComponents

ShellRoot {
  id: harness

  property string toggledPlugin: ""
  property string toggledPayload: ""
  property int focusedWorkspace: 0
  property int keyboardCycles: 0
  property int updateRuns: 0
  property string summonedPlugin: ""
  property string lastRunCommand: ""
  property int bluetoothToggles: 0
  property int clockCycles: 0
  property int clockPanelToggles: 0
  property int powerPercentageToggles: 0
  property int weatherRefreshes: 0

  readonly property var hostManifest: ({
    id: "rblalock.omarchy-island",
    __sourceDir: Quickshell.shellDir + "/plugin"
  })

  QtObject {
    id: bluetoothWidget
    property string hostScreenName: "DP-3"
    property string icon: "BT"
    function toggleBluetooth() { harness.bluetoothToggles++ }
  }

  QtObject {
    id: bluetoothWidgetOther
    property string hostScreenName: "HDMI-A-1"
    property string icon: "BT-OTHER"
    function toggleBluetooth() {}
  }

  QtObject {
    id: networkWidget
    property string icon: "NET"
  }

  QtObject {
    id: audioWidget
    property real outputVolume: 0.4
    property bool outputMuted: false
    property var volumeSink: ({ name: "test-output", description: "Harness speakers" })
    function outputIcon() { return "VOL" }
    function setOutputVolume(value) { outputVolume = Math.max(0, Math.min(1, Number(value))) }
    function toggleOutputMute() { outputMuted = !outputMuted }
    function nodeLabel(node) { return node && node.description ? node.description : "Harness speakers" }
  }

  QtObject {
    id: powerWidget
    function batteryIcon() { return "BAT" }
    function togglePercentage() { harness.powerPercentageToggles++ }
  }

  QtObject {
    id: clockWidget
    property string activeFormat: "HH:mm"
    function cycleFormat() {
      harness.clockCycles++
      activeFormat = activeFormat === "HH:mm" ? "h:mm AP" : "HH:mm"
    }
    function togglePanel() { harness.clockPanelToggles++ }
  }

  QtObject {
    id: weatherWidget
    function refresh() { harness.weatherRefreshes++ }
  }

  QtObject {
    id: displayWidget
    property int brightnessPercent: 62
    property bool brightnessAvailable: true
    property string focusedMonitor: "eDP-1"
    property var displays: [{ name: "eDP-1" }]
    function setBrightness(value) { brightnessPercent = Math.round(Number(value)) }
    function previewBrightness(value) { brightnessPercent = Math.round(Number(value)) }
    function refresh() {}
  }

  QtObject {
    id: workspacesWidget
    property var bar: fakeBar
    function workspaceIds() { return [1, 2, 3, 4, 5, 8] }
    function focusWorkspace(workspaceId) { harness.focusedWorkspace = Number(workspaceId) }
  }

  QtObject {
    id: trayWidget
    property var allItems: []
  }

  QtObject {
    id: indicatorsWidget
    property var indicatorActiveStates: ({ Dnd: true, NightLight: false })
  }

  QtObject {
    id: keyboardWidget
    property bool visible: true
    property string layoutLabel: "en"
    function cycleLayout() { harness.keyboardCycles++ }
  }

  QtObject {
    id: updateWidget
    property bool updateAvailable: true
    function runUpdate() { harness.updateRuns++ }
  }

  QtObject {
    id: unknownWidget
    property string icon: "X"
  }

  QtObject {
    id: fakeBar
    property var shell: fakeShell
    property var activePopout: null
    property bool vertical: false
    property bool transparent: false
    property int barSize: 24
    property string focusedName: "DP-3"
    property var moduleSlots: []
    property var clickTargets: []
    function registerModuleSlot(slot) {
      if (slot && moduleSlots.indexOf(slot) === -1) moduleSlots = moduleSlots.concat([slot])
    }
    function unregisterModuleSlot(slot) {
      moduleSlots = moduleSlots.filter(function(candidate) { return candidate !== slot })
    }
    function registerClickTarget(target) {
      if (target && clickTargets.indexOf(target) === -1) clickTargets = clickTargets.concat([target])
    }
    function unregisterClickTarget(target) {
      clickTargets = clickTargets.filter(function(candidate) { return candidate !== target })
    }
    function focusedScreenName() { return focusedName }
    function targetWindow(target) {
      return { screen: { name: target === secondaryIsland ? "HDMI-A-1" : "DP-3" } }
    }
    function moduleWidgets(pluginId) {
      var nested = []
      for (var slotIndex = 0; slotIndex < moduleSlots.length; slotIndex++) {
        var slot = moduleSlots[slotIndex]
        if (slot && slot.moduleName === pluginId && slot.activeItem) nested.push(slot.activeItem)
      }
      if (nested.length > 0) return nested
      if (pluginId === "omarchy.bluetooth") return [bluetoothWidgetOther, bluetoothWidget]
      if (pluginId === "omarchy.network") return [networkWidget]
      if (pluginId === "omarchy.audio") return [audioWidget]
      if (pluginId === "omarchy.monitor") return [displayWidget]
      if (pluginId === "omarchy.power") return [powerWidget]
      // The Island clock adapter must keep calendar/format parity when the
      // visible stock clock is intentionally absent from the bar.
      if (pluginId === "omarchy.clock") return []
      if (pluginId === "omarchy.weather") return [weatherWidget]
      if (pluginId === "omarchy.workspaces") return [workspacesWidget]
      if (pluginId === "omarchy.tray") return [trayWidget]
      if (pluginId === "omarchy.indicators") return []
      if (pluginId === "omarchy.keyboard-layout") return []
      if (pluginId === "omarchy.system-update") return [updateWidget]
      if (pluginId === "test.unknown-widget") return [unknownWidget]
      return []
    }
    function run(command) { harness.lastRunCommand = String(command) }
  }

  QtObject {
    id: fakeShell
    property var bar: fakeBar
    function toggle(pluginId, payloadJson) {
      harness.toggledPlugin = String(pluginId)
      harness.toggledPayload = String(payloadJson)
      return true
    }
    function summon(pluginId, payloadJson) {
      harness.summonedPlugin = String(pluginId)
      return true
    }
    function serviceFor(pluginId) {
      return pluginId === "rblalock.omarchy-island" ? service : null
    }
  }

  QtObject {
    id: fakePluginRegistry
    property var installedPlugins: ({
      "test.island-provider": {
        schemaVersion: 1,
        id: "test.island-provider",
        name: "Test Island provider",
        version: "1.0.0",
        kinds: ["service"],
        entryPoints: {
          omarchyIslandProvider: "Provider.qml",
          omarchyIslandExpanded: "Expanded.qml"
        },
        omarchyIsland: {
          schemaVersion: 1,
          id: "test.activity",
          capabilities: ["activity-provider", "quick-access", "custom-presentation"],
          displayName: "Test activity",
          quickAccess: { id: "test.quick", target: "test.panel", label: "Test panel", glyph: "Q" }
        },
        __sourceDir: Quickshell.shellDir + "/provider"
      },
      "test.unknown-widget": {
        schemaVersion: 1,
        id: "test.unknown-widget",
        name: "Unknown widget",
        version: "1.0.0",
        kinds: ["bar-widget"],
        entryPoints: { barWidget: "Unknown.qml" },
        __sourceDir: Quickshell.shellDir + "/provider"
      }
    })
    function entryPointUrl(candidate, kind) {
      var entry = candidate && candidate.entryPoints ? candidate.entryPoints[kind] : ""
      return entry ? "file://" + candidate.__sourceDir + "/" + entry : ""
    }
    function isEnabled(pluginId) {
      return pluginId === "test.island-provider" || pluginId === "test.unknown-widget"
    }
  }

  IslandPlugin.Service {
    id: service
    shell: fakeShell
    manifest: harness.hostManifest
    pluginRegistry: fakePluginRegistry
    retainedWindowEnabled: false
  }

  IslandPlugin.IslandBarWidget {
    id: hostedIsland
    bar: fakeBar
    clockAdapter: clockWidget
    indicatorAdapter: indicatorsWidget
    keyboardAdapter: keyboardWidget
  }

  IslandPlugin.IslandBarWidget {
    id: secondaryIsland
    bar: fakeBar
    clockAdapter: clockWidget
    indicatorAdapter: indicatorsWidget
    keyboardAdapter: keyboardWidget
  }

  IslandComponents.NavigableSurface {
    id: navigationHarness
    width: 100
    height: 100

    Item {
      id: navigationTopLeft
      x: 0
      y: 0
      width: 40
      height: 40
      activeFocusOnTab: true
    }

    Item {
      id: navigationTopRight
      x: 60
      y: 0
      width: 40
      height: 40
      activeFocusOnTab: true
    }

    Item {
      id: navigationBottomLeft
      x: 0
      y: 60
      width: 40
      height: 40
      activeFocusOnTab: true
    }

    Item {
      id: navigationBottomRight
      x: 60
      y: 60
      width: 40
      height: 40
      activeFocusOnTab: true
    }
  }

  IslandComponents.ActivityShelf {
    id: activityHarness
    width: 400
    height: 240
    visible: false
    island: service
  }

  Timer {
    interval: 1200
    running: true
    onTriggered: {
      var adapterViews = [
        "ControlStateSurface.qml", "NavigableSurface.qml", "ShelfButton.qml", "ProxyButton.qml",
        "ClockButton.qml", "VolumePill.qml", "VolumeShelf.qml", "DisplayPill.qml", "DisplayShelf.qml",
        "OsdPill.qml"
      ]
      for (var viewIndex = 0; viewIndex < adapterViews.length; viewIndex++) {
        var adapterComponent = Qt.createComponent(
          "file://" + Quickshell.shellDir + "/plugin/components/" + adapterViews[viewIndex],
          Component.PreferSynchronous)
        if (adapterComponent.status !== Component.Ready) {
          console.error("HARNESS_FAIL adapter component", adapterViews[viewIndex], adapterComponent.errorString())
          Qt.exit(9)
          return
        }
      }
      var navigationItems = navigationHarness.focusItems()
      if (navigationItems.length !== 4
          || navigationHarness.directionalTarget(navigationTopLeft, 1, 0, navigationItems) !== navigationTopRight
          || navigationHarness.directionalTarget(navigationTopLeft, 0, 1, navigationItems) !== navigationBottomLeft
          || navigationHarness.directionalTarget(navigationBottomRight, -1, 0, navigationItems) !== navigationBottomLeft
          || navigationHarness.directionalTarget(navigationBottomRight, 0, -1, navigationItems) !== navigationTopRight) {
        console.error("HARNESS_FAIL spatial keyboard navigation")
        Qt.exit(21)
        return
      }
      service.refreshStockState()
      if (!service.barHosted || service.barHosts.length !== 2
          || service.activeBarHost() !== hostedIsland
          || !hostedIsland.visible || !secondaryIsland.visible
          || hostedIsland.hostScreenName !== "DP-3"
          || secondaryIsland.hostScreenName !== "HDMI-A-1"
          || service.stockWidget("test.unknown-widget") !== unknownWidget
          || hostedIsland.proxyItems.length === 0
          || hostedIsland.proxyItems.some(function(item) { return item.id === hostedIsland.moduleName })
          || hostedIsland.proxyItems.some(function(item) { return item.id === "test.unknown-widget" })
          || fakeBar.clickTargets.length === 0
          || hostedIsland.inventoryVisible || hostedIsland.borderTargetOpacity !== 0
          || hostedIsland.surfaceTargetOpacity !== 1
          || hostedIsland.implicitWidth <= 8) {
        console.error("HARNESS_FAIL standalone proxy bar widget", service.inspectJson())
        Qt.exit(24)
        return
      }
      fakeBar.transparent = true
      if (hostedIsland.surfaceTargetOpacity !== 0) {
        console.error("HARNESS_FAIL transparent bar rest parity", hostedIsland.debugState())
        Qt.exit(24)
        return
      }
      hostedIsland.triggerPress(Qt.LeftButton)
      if (service.retainedMode !== "focus" || service.activeShelf !== "activity") {
        console.error("HARNESS_FAIL stock bar pointer contract", service.inspectJson())
        Qt.exit(25)
        return
      }
      service.closeRetained()
      hostedIsland.revealIntent = true
      if (!hostedIsland.inventoryVisible || hostedIsland.targetWidth !== hostedIsland.expandedWidth
          || hostedIsland.borderTargetOpacity !== 1 || hostedIsland.surfaceTargetOpacity !== 1) {
        console.error("HARNESS_FAIL standalone inventory reveal", hostedIsland.debugState())
        Qt.exit(27)
        return
      }
      hostedIsland.revealIntent = false
      fakeBar.transparent = false
      if (service.stockWidgetOnScreen("omarchy.bluetooth", "HDMI-A-1") !== bluetoothWidgetOther
          || service.stockWidget("omarchy.bluetooth") !== bluetoothWidget
          || service.bluetoothIcon !== "BT" || service.networkIcon !== "NET" || service.audioIcon !== "VOL") {
        console.error("HARNESS_FAIL icon proxies", service.inspectJson())
        Qt.exit(10)
        return
      }
      var peekIds = service.peekItems.map(function(item) { return item.id })
      var expectedPeek = ["omarchy-island.activities", "test.quick", "omarchy.menu", "omarchy.workspaces", "omarchy.tray", "omarchy.indicators", "omarchy.tailscale", "omarchy.bluetooth", "omarchy.network", "omarchy.audio", "omarchy.monitor", "omarchy.keyboard-layout", "omarchy.power"]
      if (JSON.stringify(peekIds) !== JSON.stringify(expectedPeek)
          || service.peekItems[service.peekItems.length - 1].glyph !== "BAT"
          || service.proxyDefinition("omarchy.indicators").glyph !== "󰘮") {
        console.error("HARNESS_FAIL bar projection", service.inspectJson())
        Qt.exit(10)
        return
      }
      var stableActivityProjection = service.peekItems
      service.update("test.activity", "build", { progress: 0.65 })
      service.refreshStockState()
      if (service.peekItems !== stableActivityProjection
          || Math.abs(service.currentActivity.progress - 0.65) > 0.001) {
        console.error("HARNESS_FAIL stable activity projection", service.inspectJson())
        Qt.exit(28)
        return
      }
      var tailscaleProxy = service.peekItems.filter(function(item) { return item.id === "omarchy.tailscale" })[0]
      if (!tailscaleProxy || tailscaleProxy.iconKind !== "tailscale" || tailscaleProxy.glyph !== "") {
        console.error("HARNESS_FAIL custom stock icon adapter", service.inspectJson())
        Qt.exit(10)
        return
      }
      var audioProxy = service.peekItems.filter(function(item) { return item.id === "omarchy.audio" })[0]
      if (!audioProxy || audioProxy.kind !== "audio" || !service.audioAvailable
          || Math.abs(service.audioVolume - 0.4) > 0.001
          || service.audioOutputLabel !== "Harness speakers") {
        console.error("HARNESS_FAIL audio adapter discovery", service.inspectJson())
        Qt.exit(10)
        return
      }
      var displayProxy = service.peekItems.filter(function(item) { return item.id === "omarchy.monitor" })[0]
      if (!displayProxy || displayProxy.kind !== "display" || !service.displayAvailable
          || Math.abs(service.displayBrightness - 0.62) > 0.001
          || service.displayMonitorLabel !== "eDP-1") {
        console.error("HARNESS_FAIL display adapter discovery", service.inspectJson())
        Qt.exit(10)
        return
      }
      if (service.unsupportedPeekIds.length !== 0
          || service.proxyDefinition("test.unknown-widget") !== null
          || service.workspaceIds.length !== 10
          || service.workspaceIds[0] !== 1 || service.workspaceIds[9] !== 10
          || service.indicatorItems.length !== 6
          || service.indicatorItems[0].id !== "Dictation") {
        console.error("HARNESS_FAIL adapter projection", service.inspectJson())
        Qt.exit(10)
        return
      }
      var reducedMotion = Quickshell.env("OMARCHY_ISLAND_REDUCED_MOTION") === "1"
      if (service.clockFormat !== "HH:mm" || service.collapseDelayMs !== 70
          || service.motionEnabled !== !reducedMotion
          || service.motionExpandMs !== (reducedMotion ? 0 : 111)
          || service.motionCollapseMs !== (reducedMotion ? 0 : 77)
          || service.contentMotionMs !== (reducedMotion ? 0 : 66)
          || service.configuredShelfWidth !== 444
          || service.configuredShelfHeight !== 177 || service.configuredFocusHeight !== 233
          || service.configuredControlsHeight !== 322 || service.restContent !== "activity"
          || !service.autoFocusEvents || service.audioTransientHoldMs !== 1234
          || Math.abs(service.audioScrollStep - 0.07) > 0.001
          || service.displayTransientHoldMs !== 1432
          || Math.abs(service.displayScrollStep - 0.09) > 0.001
          || !service.providerPinned("test.activity")
          || service.providerRestOverride("test.activity") !== "companion") {
        console.error("HARNESS_FAIL TOML overrides", service.inspectJson())
        Qt.exit(10)
        return
      }
      if (!service.scrollProxy(audioProxy, 120) || Math.abs(audioWidget.outputVolume - 0.47) > 0.001
          || !service.transientActive || service.transientKind !== "audio"
          || hostedIsland.borderTargetOpacity !== 1) {
        console.error("HARNESS_FAIL audio scroll transient", service.inspectJson())
        Qt.exit(20)
        return
      }
      if (!service.openAudio() || service.retainedMode !== "focus" || service.activeShelf !== "audio"
          || service.transientActive || !service.toggleAudioMute() || !audioWidget.outputMuted) {
        console.error("HARNESS_FAIL audio focus and mute", service.inspectJson())
        Qt.exit(20)
        return
      }
      if (!service.openStockAudioPanel() || harness.toggledPlugin !== "omarchy.audio"
          || service.retainedMode !== "") {
        console.error("HARNESS_FAIL audio stock fallback", service.inspectJson())
        Qt.exit(20)
        return
      }
      if (!service.scrollProxy(displayProxy, 120) || displayWidget.brightnessPercent !== 71
          || !service.transientActive || service.transientKind !== "display"
          || hostedIsland.borderTargetOpacity !== 1) {
        console.error("HARNESS_FAIL display scroll transient", service.inspectJson())
        Qt.exit(22)
        return
      }
      if (!service.openDisplay(true) || service.retainedMode !== "focus"
          || service.activeShelf !== "display" || !service.keyboardEntryActive
          || service.transientActive || !service.previewDisplayBrightness(0.55)
          || displayWidget.brightnessPercent !== 55
          || !service.setDisplayBrightness(0.56, false)
          || displayWidget.brightnessPercent !== 56) {
        console.error("HARNESS_FAIL display focus and brightness", service.inspectJson())
        Qt.exit(22)
        return
      }
      if (!service.openStockDisplayPanel() || harness.toggledPlugin !== "omarchy.monitor"
          || service.retainedMode !== "") {
        console.error("HARNESS_FAIL display stock fallback", service.inspectJson())
        Qt.exit(22)
        return
      }
      displayWidget.brightnessAvailable = false
      service.sampleDisplayState(false)
      if (service.displayAvailable || !service.triggerProxy(displayProxy)
          || harness.toggledPlugin !== "omarchy.monitor") {
        console.error("HARNESS_FAIL unsupported display delegation", service.inspectJson())
        Qt.exit(22)
        return
      }
      displayWidget.brightnessAvailable = true
      service.sampleDisplayState(false)
      service.openShelf("workspaces")
      if (service.retainedMode !== "shelf" || service.activeShelf !== "workspaces"
          || !service.focusWorkspace(8) || harness.focusedWorkspace !== 8 || service.retainedMode !== "") {
        console.error("HARNESS_FAIL shelf state and workspace routing", service.inspectJson())
        Qt.exit(13)
        return
      }
      service.keyboardToggle()
      if (service.retainedMode !== "peek" || service.activeShelf !== ""
          || service.keyboardTarget !== "peek" || !service.keyboardPeekActive
          || !hostedIsland.keyboardInventory || !hostedIsland.inventoryVisible) {
        console.error("HARNESS_FAIL keyboard peek entry", service.inspectJson())
        Qt.exit(14)
        return
      }
      hostedIsland.ensureKeyboardSelection()
      var firstKeyboardId = hostedIsland.keyboardIds()[0]
      if (!service.keyboardEntryActive || hostedIsland.keyboardSelectionId !== firstKeyboardId
          || !service.handleBarKeyboardKey(Qt.Key_Left, Qt.NoModifier)
          || hostedIsland.keyboardSelectionId !== "omarchy.clock"
          || !service.handleBarKeyboardKey(Qt.Key_Right, Qt.NoModifier)
          || hostedIsland.keyboardSelectionId !== firstKeyboardId) {
        console.error("HARNESS_FAIL keyboard focus intent", service.inspectJson())
        Qt.exit(14)
        return
      }
      if (!service.handleBarKeyboardKey(Qt.Key_2, Qt.NoModifier)
          || harness.summonedPlugin !== "test.panel" || service.retainedMode !== "") {
        console.error("HARNESS_FAIL dynamic keyboard index activation", service.inspectJson())
        Qt.exit(14)
        return
      }
      service.keyboardToggle()
      if (!service.keyboardPeekActive
          || service.handleBarKeyboardKey(Qt.Key_0, Qt.NoModifier) !== true
          || service.retainedMode !== "focus" || service.activeShelf !== "audio"
          || !service.keyboardEntryActive) {
        console.error("HARNESS_FAIL tenth keyboard index activation", service.inspectJson())
        Qt.exit(14)
        return
      }
      service.closeRetained()
      service.keyboardToggle()
      if (!service.keyboardPeekActive
          || service.handleBarKeyboardKey(Qt.Key_0, Qt.NoModifier) !== true) {
        console.error("HARNESS_FAIL keyboard index re-entry", service.inspectJson())
        Qt.exit(14)
        return
      }
      service.keyboardToggle()
      if (service.retainedMode !== "" || service.keyboardEntryActive
          || service.keyboardPeekActive || hostedIsland.keyboardInventory
          || hostedIsland.inventoryVisible) {
        console.error("HARNESS_FAIL keyboard peek toggle close", service.inspectJson())
        Qt.exit(14)
        return
      }
      if (!service.triggerStockAction("keyboard") || harness.keyboardCycles !== 1
          || !service.triggerStockAction("update") || harness.updateRuns !== 1) {
        console.error("HARNESS_FAIL stock action adapters", service.inspectJson())
        Qt.exit(14)
        return
      }
      if (!service.triggerClockAction("secondary") || harness.clockCycles !== 1
          || service.clockFormat !== "h:mm AP"
          || !service.triggerClockAction("middle") || harness.lastRunCommand !== "omarchy-menu-timezone"
          || !service.triggerProxyAction(service.proxyDefinition("omarchy.menu"), "secondary")
          || harness.lastRunCommand !== "xdg-terminal-exec"
          || !service.triggerProxyAction(service.proxyDefinition("omarchy.bluetooth"), "secondary")
          || harness.bluetoothToggles !== 1
          || !service.triggerProxyAction(service.proxyDefinition("omarchy.audio"), "secondary")
          || audioWidget.outputMuted
          || !service.triggerProxyAction(service.proxyDefinition("omarchy.power"), "secondary")
          || harness.powerPercentageToggles !== 1
          || !service.triggerProxyAction(service.proxyDefinition("omarchy.weather"), "secondary")
          || harness.lastRunCommand !== "omarchy-notification-send \"$(omarchy-weather-status)\""
          || !service.triggerProxyAction(service.proxyDefinition("omarchy.weather"), "middle")
          || harness.weatherRefreshes !== 1
          || !service.triggerProxyAction(service.proxyDefinition("omarchy.tailscale"), "secondary")
          || harness.lastRunCommand !== "omarchy-shell omarchy.tailscale toggleTailscale"
          || !service.triggerProxyAction(service.proxyDefinition("omarchy.tailscale"), "middle")
          || harness.lastRunCommand !== "omarchy-shell omarchy.tailscale refresh") {
        console.error("HARNESS_FAIL pointer parity actions", service.inspectJson())
        Qt.exit(23)
        return
      }
      if (service.activities.length !== 1 || service.currentActivity.title !== "Harness activity"
          || service.currentActivity.presentation.rest !== "companion"
          || service.presentationUrl(service.currentActivity, "expanded").indexOf("Expanded.qml") === -1) {
        console.error("HARNESS_FAIL provider discovery", service.inspectJson())
        Qt.exit(15)
        return
      }
      var enabledPresentationConfig = service.userConfig
      var customPresentationConfig = service.copyObject(enabledPresentationConfig)
      customPresentationConfig.appearance = service.copyObject(service.userConfig.appearance)
      customPresentationConfig.appearance.allow_custom_qml = false
      service.userConfig = customPresentationConfig
      if (service.presentationUrl(service.currentActivity, "expanded") !== "") {
        console.error("HARNESS_FAIL declarative provider fallback", service.inspectJson())
        Qt.exit(15)
        return
      }
      service.userConfig = enabledPresentationConfig
      service.update("test.activity", "build", { primaryAction: "run" })
      var primaryActionProxy = service.peekItems.filter(function(item) {
        return item.id === "omarchy-island.activities"
      })[0]
      service.providerObjects["test.activity"].lastAction = ""
      if (service.currentActivity.primaryAction !== "run"
          || !service.triggerProxy(primaryActionProxy)
          || service.providerObjects["test.activity"].lastAction !== "build:run") {
        console.error("HARNESS_FAIL activity primary action", service.inspectJson())
        Qt.exit(37)
        return
      }
      service.update("test.activity", "build", { primaryAction: "missing" })
      if (service.currentActivity.primaryAction !== "") {
        console.error("HARNESS_FAIL invalid activity primary action")
        Qt.exit(37)
        return
      }
      var harnessActivity = service.currentActivity
      service.publish("test.secondary", {
        id: "timer", title: "Secondary timer", glyph: "T", attention: "timely",
        presentation: { rest: "takeover" }, updatedAt: Date.now() + 1
      })
      if (service.rankedActivities.length !== 2 || service.currentActivity !== harnessActivity
          || !activityHarness.selectorVisible || activityHarness.activity !== harnessActivity
          || !service.selectActivity("test.secondary:timer")
          || service.selectedActivity.key !== "test.secondary:timer") {
        console.error("HARNESS_FAIL multi-activity selection", service.inspectJson())
        Qt.exit(36)
        return
      }
      service.openFocus("activity")
      if (service.selectedActivity !== harnessActivity) {
        console.error("HARNESS_FAIL activity focus leading selection")
        Qt.exit(36)
        return
      }
      service.closeRetained()
      var criticalActivity = service.normalizeActivity("test.critical", {
        id: "alarm", title: "Critical alarm", attention: "critical"
      })
      if (service.rankActivities([harnessActivity, criticalActivity])[0] !== criticalActivity) {
        console.error("HARNESS_FAIL critical safety floor")
        Qt.exit(36)
        return
      }
      var invalidPresentation = service.normalizeActivity("test.invalid", {
        id: "invalid", title: "Invalid presentation", presentation: { rest: "somewhere" }
      })
      if (invalidPresentation.presentation.rest !== "takeover") {
        console.error("HARNESS_FAIL rest presentation normalization")
        Qt.exit(29)
        return
      }
      var originalUserConfig = service.userConfig
      var policyConfig = service.copyObject(originalUserConfig)
      policyConfig.providers = service.copyObject(originalUserConfig.providers)
      policyConfig.providers.pinned = []
      policyConfig.providers.rest = service.copyObject(originalUserConfig.providers.rest)
      policyConfig.providers.rest["test.activity"] = "hidden"
      service.userConfig = policyConfig
      if (service.currentActivity.key !== "test.secondary:timer"
          || service.restPresentation(harnessActivity) !== "hidden") {
        console.error("HARNESS_FAIL provider policy overrides", service.inspectJson())
        Qt.exit(36)
        return
      }
      var invalidPolicyConfig = service.copyObject(policyConfig)
      invalidPolicyConfig.providers = service.copyObject(policyConfig.providers)
      invalidPolicyConfig.providers.rest = service.copyObject(policyConfig.providers.rest)
      invalidPolicyConfig.providers.rest["test.activity"] = "invalid"
      service.userConfig = invalidPolicyConfig
      if (service.restPresentation(harnessActivity) !== "companion") {
        console.error("HARNESS_FAIL invalid provider rest override fallback")
        Qt.exit(36)
        return
      }
      service.userConfig = originalUserConfig
      service.selectActivity(harnessActivity.key)
      var companionConfig = service.copyObject(originalUserConfig)
      companionConfig.layout = service.copyObject(originalUserConfig.layout)
      companionConfig.layout.rest_content = "auto"
      service.userConfig = companionConfig
      service.closeRetained()
      service.clearTransient()
      var companionWidth = hostedIsland.restWidth
      if (hostedIsland.restMode !== "companion" || !hostedIsland.companionAtRest
          || hostedIsland.activityAtRest || companionWidth <= 0) {
        console.error("HARNESS_FAIL companion rest", hostedIsland.debugState())
        Qt.exit(29)
        return
      }
      if (!service.presentAudioTransient() || hostedIsland.restMode !== "transient"
          || !hostedIsland.transientVisible) {
        console.error("HARNESS_FAIL companion transient takeover", hostedIsland.debugState())
        Qt.exit(29)
        return
      }
      service.clearTransient()
      if (hostedIsland.restMode !== "companion" || !hostedIsland.companionAtRest
          || Math.abs(hostedIsland.restWidth - companionWidth) > 0.001) {
        console.error("HARNESS_FAIL companion transient restore", hostedIsland.debugState())
        Qt.exit(29)
        return
      }
      hostedIsland.revealIntent = true
      if (!service.showOsd('{"icon":"volume","value":42}')
          || service.transientKind !== "osd" || !service.osdEvent
          || !service.osdEvent.hasProgress || service.osdEvent.message !== "42%"
          || Math.abs(service.osdEvent.progress - 0.42) > 0.001
          || !hostedIsland.transientVisible || secondaryIsland.transientVisible
          || hostedIsland.inventoryVisible || service.osdScreenName !== "DP-3"
          || service.inspectObject().transient.osdScreen !== "DP-3"
          || service.inspectObject().transient.osdArbitration.passiveHover !== "takeover"
          || hostedIsland.borderTargetOpacity !== 1 || hostedIsland.surfaceTargetOpacity !== 1) {
        console.error("HARNESS_FAIL generic OSD progress routing", service.inspectJson())
        Qt.exit(38)
        return
      }
      fakeBar.focusedName = "HDMI-A-1"
      if (service.activeBarHost() !== secondaryIsland
          || !service.showOsd('{"icon":"volume","value":43}')
          || service.osdScreenName !== "DP-3" || !hostedIsland.transientVisible
          || secondaryIsland.transientVisible || service.osdEvent.message !== "43%") {
        console.error("HARNESS_FAIL generic OSD monitor latch", service.inspectJson())
        Qt.exit(38)
        return
      }
      fakeBar.focusedName = "DP-3"
      if (!service.showOsd('{"icon":"microphone-muted","message":"Microphone muted","duration":0}')
          || service.osdEvent.hasProgress || service.osdEvent.message !== "Microphone muted"
          || service.osdEvent.duration !== 0 || service.inspectObject().transient.osd.iconKey !== "microphone-muted"
          || !service.closeOsd() || service.transientActive || service.osdEvent !== null) {
        console.error("HARNESS_FAIL generic OSD message lifecycle", service.inspectJson())
        Qt.exit(38)
        return
      }
      if (!hostedIsland.inventoryVisible) {
        console.error("HARNESS_FAIL passive hover restore", hostedIsland.debugState())
        Qt.exit(38)
        return
      }
      hostedIsland.revealIntent = false
      service.openShelf("workspaces")
      if (service.showOsd('{"icon":"brightness","value":75}')) {
        console.error("HARNESS_FAIL generic OSD retained-surface policy", service.inspectJson())
        Qt.exit(38)
        return
      }
      service.closeRetained()
      service.userConfig = originalUserConfig
      if (!service.routeAction("test.activity", "build", "run")
          || service.providerObjects["test.activity"].lastAction !== "build:run") {
        console.error("HARNESS_FAIL provider action routing", service.inspectJson())
        Qt.exit(16)
        return
      }
      if (!service.openQuickAccess("test.panel") || harness.summonedPlugin !== "test.panel") {
        console.error("HARNESS_FAIL quick access routing", service.inspectJson())
        Qt.exit(17)
        return
      }
      if (!service.togglePlugin("omarchy.bluetooth", "") || harness.toggledPlugin !== "omarchy.bluetooth") {
        console.error("HARNESS_FAIL stock routing", service.inspectJson())
        Qt.exit(11)
        return
      }
      if (!service.openLauncher() || harness.toggledPlugin !== "omarchy.menu"
          || harness.toggledPayload.indexOf("root") === -1) {
        console.error("HARNESS_FAIL launcher routing", service.inspectJson())
        Qt.exit(12)
        return
      }
      if (!service.openClockPanel() || harness.clockPanelToggles !== 1) {
        console.error("HARNESS_FAIL clock panel routing", service.inspectJson())
        Qt.exit(12)
        return
      }
      console.log("HARNESS_OK", service.inspectJson())
      Qt.quit()
    }
  }
}
