import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import "lib/Toml.js" as Toml
import "lib/OsdModel.js" as OsdModel
import "lib/ProviderContract.js" as ProviderContract

Item {
  id: root

  property var shell: null
  property var manifest: null
  property var pluginRegistry: null
  property bool retainedWindowEnabled: true
  property var barHosts: []
  readonly property bool barHosted: barHosts.length > 0
  readonly property bool keyboardPeekActive: barHosted && keyboardEntryActive && retainedMode === "peek"

  readonly property string homePath: Quickshell.env("HOME")
  readonly property string configRoot: Quickshell.env("XDG_CONFIG_HOME") || (homePath + "/.config")
  readonly property string configPath: configRoot + "/omarchy/island.toml"
  property var defaultConfig: ({})
  property var userConfig: ({})
  property var config: Toml.merge(defaultConfig, userConfig)
  property string configError: ""

  // Hover owns Peek locally in the bar. Shelf and Focus are retained
  // service state so IPC, provider events, and every output agree on what is
  // open. The stock bar remains the owner of delegated popups.
  property string retainedMode: ""
  property string activeShelf: ""
  property bool keyboardEntryActive: false
  property string lastAction: ""
  property bool lastActionAccepted: false
  property string bluetoothIcon: "󰂯"
  property string networkIcon: "󰤨"
  property string audioIcon: "󰕾"
  property var audioControl: null
  property bool audioStateReady: false
  property bool audioAvailable: false
  property real audioVolume: 0
  property bool audioMuted: false
  property string audioOutputLabel: "Default output"
  property real audioWheelAccumulator: 0
  property string displayIcon: "󰍹"
  property var displayControl: null
  property bool displayStateReady: false
  property bool displayAvailable: false
  property real displayBrightness: 0
  property string displayMonitorLabel: "Focused display"
  property real displayWheelAccumulator: 0
  property string transientKind: ""
  property bool transientActive: false
  property var osdEvent: null
  property string osdScreenName: ""
  property var peekItems: []
  property var trayItems: []
  property var workspaceIds: []
  readonly property int focusedWorkspaceId: Hyprland.focusedWorkspace
    ? Number(Hyprland.focusedWorkspace.id || 0) : 0
  property var indicatorItems: []
  property var unsupportedPeekIds: []
  property var hiddenPeekIds: []

  // Optional Island-native provider contract.
  property var activities: []
  property var providerObjects: ({})
  property var providerManifests: ({})
  property var providerDiagnostics: []
  property var providerActivityErrors: ({})
  property var quickAccessItems: []
  property var eventActivity: null
  property bool eventActive: false
  property string selectedActivityKey: ""
  property string activityNormalizationError: ""
  readonly property var rankedActivities: rankActivities(activities)
  readonly property var currentActivity: rankedActivities.length > 0 ? rankedActivities[0] : null
  readonly property var displayActivity: eventActive && eventActivity ? eventActivity : currentActivity
  readonly property var restActivity: eventActive && eventActivity ? eventActivity
    : (displayActivity && restPresentation(displayActivity) !== "hidden" ? displayActivity : null)

  readonly property string styleName: String(value("appearance", "style", "pill"))
  property string clockFormatOverride: ""
  property string verticalClockFormatOverride: ""
  readonly property string configuredClockFormat: String(value("appearance", "clock_format", "h:mm AP"))
  readonly property string configuredVerticalClockFormat: String(
    value("appearance", "clock_format_vertical", "HH\nmm"))
  readonly property string clockFormat: clockFormatOverride !== ""
    ? clockFormatOverride : configuredClockFormat
  readonly property string verticalClockFormat: verticalClockFormatOverride !== ""
    ? verticalClockFormatOverride : configuredVerticalClockFormat
  readonly property string clockWidgetUrl: pluginEntryPointUrl("omarchy.clock", "barWidget")
  readonly property real configuredShelfWidth: Math.max(0, Number(value("appearance", "shelf_width", 0)) || 0)
  readonly property real configuredShelfHeight: Math.max(0, Number(value("appearance", "shelf_height", 0)) || 0)
  readonly property real configuredFocusHeight: Math.max(0, Number(value("appearance", "focus_height", 0)) || 0)
  readonly property real configuredControlsHeight: Math.max(0, Number(value("appearance", "controls_height", 0)) || 0)
  readonly property real cornerRadius: {
    var configured = value("appearance", "corner_radius", "system")
    var mode = String(configured === undefined || configured === null ? "system" : configured).toLowerCase()
    if (mode === "" || mode === "system" || mode === "inherit" || mode === "auto")
      return Style.cornerRadius
    var numeric = Number(configured)
    return isFinite(numeric) && numeric >= 0 ? numeric : Style.cornerRadius
  }
  readonly property int workspaceCount: Math.max(1,
    Math.min(20, Math.round(Number(value("workspaces", "count", 10)) || 10)))
  readonly property string backgroundOverride: String(value("appearance", "background", ""))
  readonly property string borderOverride: String(value("appearance", "border", ""))
  readonly property bool customQmlAllowed: Boolean(value("appearance", "allow_custom_qml", true))
  readonly property string restContent: String(value("layout", "rest_content", "clock"))
  readonly property real topOffset: Math.max(0, Number(value("placement", "top_offset", 0)) || 0)
  readonly property int collapseDelayMs: Math.max(0, Math.round(Number(value("behavior", "collapse_delay_ms", 95)) || 0))
  readonly property bool motionEnabled: Boolean(value("motion", "enabled", true))
    && !Boolean(value("motion", "reduced", false))
    && Quickshell.env("OMARCHY_ISLAND_REDUCED_MOTION") !== "1"
  readonly property int motionExpandMs: motionEnabled
    ? Math.max(0, Math.round(Number(value("motion", "expand_ms", 260)) || 0)) : 0
  readonly property int motionCollapseMs: motionEnabled
    ? Math.max(0, Math.round(Number(value("motion", "collapse_ms", 180)) || 0)) : 0
  readonly property int contentMotionMs: motionEnabled
    ? Math.max(0, Math.round(Number(value("motion", "content_ms", 150)) || 0)) : 0
  readonly property bool includeClock: Boolean(value("layout", "include_clock", true))
  readonly property int eventHoldMs: Math.max(250, Math.round(Number(value("behavior", "event_hold_ms", 4500)) || 4500))
  readonly property bool autoFocusEvents: Boolean(value("behavior", "auto_focus_events", false))
  readonly property string keyboardTarget: String(value("behavior", "keyboard_target", "peek"))
  readonly property bool audioAdapterEnabled: Boolean(nestedValue("adapters", "audio", "enabled", true))
  readonly property int audioTransientHoldMs: {
    var configured = Number(nestedValue("adapters", "audio", "transient_hold_ms", 1600))
    return Math.max(250, Math.round(isFinite(configured) ? configured : 1600))
  }
  readonly property real audioScrollStep: {
    var configured = Number(nestedValue("adapters", "audio", "scroll_step_percent", 5))
    return Math.max(0.01, Math.min(0.25, (isFinite(configured) ? configured : 5) / 100))
  }
  readonly property bool displayAdapterEnabled: Boolean(nestedValue("adapters", "display", "enabled", true))
  readonly property int displayTransientHoldMs: {
    var configured = Number(nestedValue("adapters", "display", "transient_hold_ms", 1600))
    return Math.max(250, Math.round(isFinite(configured) ? configured : 1600))
  }
  readonly property real displayScrollStep: {
    var configured = Number(nestedValue("adapters", "display", "scroll_step_percent", 5))
    return Math.max(0.01, Math.min(0.25, (isFinite(configured) ? configured : 5) / 100))
  }
  readonly property var selectedActivity: eventActive && eventActivity
    ? eventActivity : activityForKey(selectedActivityKey)

  function value(section, key, fallback) {
    var group = config && config[section] ? config[section] : null
    var result = group ? group[key] : undefined
    return result === undefined || result === null ? fallback : result
  }

  function nestedValue(section, subsection, key, fallback) {
    var group = config && config[section] ? config[section] : null
    var nested = group && group[subsection] ? group[subsection] : null
    var result = nested ? nested[key] : undefined
    return result === undefined || result === null ? fallback : result
  }

  function pluginEntryPointUrl(pluginId, entryPoint) {
    if (pluginRegistry && pluginRegistry.installedPlugins
        && typeof pluginRegistry.entryPointUrl === "function") {
      var candidate = pluginRegistry.installedPlugins[String(pluginId || "")]
      var fromRegistry = candidate
        ? String(pluginRegistry.entryPointUrl(candidate, String(entryPoint || "")) || "") : ""
      if (fromRegistry) return fromRegistry
    }
    return firstPartyBarWidgetUrl(pluginId, entryPoint)
  }

  function firstPartyBarWidgetUrl(pluginId, entryPoint) {
    if (String(entryPoint || "") !== "barWidget") return ""
    if (!pluginRegistryIsSelfScoped()) return ""
    var paths = {
      "omarchy.clock": "shell/plugins/panels/clock/BarWidget.qml",
      "omarchy.indicators": "shell/plugins/bar/widgets/Indicators.qml",
      "omarchy.keyboard-layout": "shell/plugins/bar/widgets/KeyboardLayout.qml",
      "omarchy.audio": "shell/plugins/panels/audio/Panel.qml",
      "omarchy.monitor": "shell/plugins/panels/monitor/Panel.qml",
      "omarchy.tray": "shell/plugins/bar/widgets/Tray.qml",
      "omarchy.bluetooth": "shell/plugins/panels/bluetooth/Panel.qml",
      "omarchy.network": "shell/plugins/panels/network/Panel.qml",
      "omarchy.power": "shell/plugins/panels/power/Panel.qml"
    }
    var relative = paths[String(pluginId || "")]
    if (!relative) return ""
    var omarchyPath = String((shell && shell.omarchyPath) || Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy")
    return "file://" + omarchyPath.replace(/\/$/, "") + "/" + relative
  }

  function pluginRegistryIsSelfScoped() {
    if (!pluginRegistry || !pluginRegistry.installedPlugins || !manifest) return false
    var installed = pluginRegistry.installedPlugins
    var keys = []
    for (var id in installed) keys.push(id)
    return keys.length === 1 && keys[0] === String(manifest.id || "")
  }

  function isLiveStockBar(candidate) {
    return !!(candidate
      && typeof candidate.moduleWidgets === "function"
      && typeof candidate.targetWindow === "function"
      && typeof candidate.focusedScreenName === "function")
  }

  function liveStockBar() {
    if (isLiveStockBar(shell && shell.bar)) return shell.bar
    for (var i = 0; i < barHosts.length; i++) {
      var host = barHosts[i]
      if (!host) continue
      if (isLiveStockBar(host.bar)) return host.bar
      if (typeof host.liveHostBar === "function") {
        var hosted = host.liveHostBar()
        if (isLiveStockBar(hosted)) return hosted
      }
      var item = host.parent
      while (item) {
        if (isLiveStockBar(item)) return item
        item = item.parent
      }
    }
    return null
  }

  function runnableBar() {
    var stock = stockBar()
    if (stock && typeof stock.run === "function") return stock
    var live = liveStockBar()
    if (live && typeof live.run === "function") return live
    for (var i = 0; i < barHosts.length; i++) {
      var bar = barHosts[i] && barHosts[i].bar
      if (bar && typeof bar.run === "function") return bar
    }
    return null
  }

  function focusedOutputName() {
    var live = liveStockBar()
    if (live && typeof live.focusedScreenName === "function") {
      var fromBar = String(live.focusedScreenName() || "")
      if (fromBar) return fromBar
    }
    if (shell && shell.bar && typeof shell.bar.focusedScreenName === "function") {
      var fromShell = String(shell.bar.focusedScreenName() || "")
      if (fromShell) return fromShell
    }
    var monitor = Hyprland.focusedMonitor
    return monitor ? String(monitor.name || "") : ""
  }

  function shellQuote(value) {
    return typeof Util.shellQuote === "function"
      ? Util.shellQuote(value) : ("'" + String(value || "").replace(/'/g, "'\\''") + "'")
  }

  function hostShellCommand(method, pluginId, payload) {
    var command = "omarchy-shell shell " + String(method || "toggle") + " " + shellQuote(pluginId)
    if (payload !== undefined && payload !== null && String(payload) !== "")
      command += " " + shellQuote(String(payload))
    return command
  }

  function persistClockFormat(format, vertical) {
    var value = String(format || "")
    if (value === "") return false
    var raw = String(userConfigFile.text() || "")
    var lines = raw.split("\n")
    var section = -1
    var nextSection = lines.length
    for (var i = 0; i < lines.length; i++) {
      var heading = lines[i].match(/^\s*\[([^\]]+)\]\s*$/)
      if (!heading) continue
      if (section >= 0) {
        nextSection = i
        break
      }
      if (heading[1] === "appearance") section = i
    }
    var encoded = value.replace(/\\/g, "\\\\").replace(/\"/g, "\\\"")
      .replace(/\n/g, "\\n")
    var key = vertical === true ? "clock_format_vertical" : "clock_format"
    var entry = key + " = \"" + encoded + "\""
    if (section < 0) {
      if (raw.trim() !== "") lines.push("")
      lines.push("[appearance]", entry, "")
    } else {
      var replaced = false
      for (var line = section + 1; line < nextSection; line++) {
        var setting = lines[line].match(/^\s*([A-Za-z0-9_-]+)\s*=/)
        if (!setting || setting[1] !== key) continue
        lines[line] = entry
        replaced = true
        break
      }
      if (!replaced) lines.splice(section + 1, 0, entry)
    }
    userConfigFile.setText(lines.join("\n"))
    return true
  }

  function setClockFormat(format, persist, vertical) {
    var value = String(format || "")
    if (value === "") return false
    if (vertical === true) verticalClockFormatOverride = value
    else clockFormatOverride = value
    return persist === true ? persistClockFormat(value, vertical === true) : true
  }

  function widgetScreenName(widget) {
    if (!widget) return ""
    if (widget.hostScreenName) return String(widget.hostScreenName)
    var bar = liveStockBar()
    var window = bar && typeof bar.targetWindow === "function"
      ? bar.targetWindow(widget)
      : (widget.QsWindow ? widget.QsWindow.window : null)
    return window && window.screen ? String(window.screen.name || "") : ""
  }

  function stockWidgets(pluginId) {
    var bar = liveStockBar()
    if (bar && typeof bar.moduleWidgets === "function") {
      var widgets = bar.moduleWidgets(String(pluginId || ""))
      if (widgets && widgets.length > 0) return widgets
    }
    if (shell && shell.bar && typeof shell.bar.moduleWidgets === "function") {
      var scoped = shell.bar.moduleWidgets(String(pluginId || ""))
      if (scoped && scoped.length > 0) return scoped
    }
    return []
  }

  function stockWidgetOnScreen(pluginId, screenName) {
    var widgets = stockWidgets(pluginId)
    var targetScreen = String(screenName || "")
    if (widgets && widgets.length > 0 && targetScreen !== "") {
      for (var i = 0; i < widgets.length; i++)
        if (widgetScreenName(widgets[i]) === targetScreen) return widgets[i]
    }
    if (widgets && widgets.length > 0) return widgets[0]
    for (var hostIndex = 0; hostIndex < barHosts.length; hostIndex++) {
      var host = barHosts[hostIndex]
      if (!host || typeof host.stockAdapter !== "function") continue
      if (targetScreen !== "" && barHostScreenName(host) !== targetScreen) continue
      var adapter = host.stockAdapter(String(pluginId || ""))
      if (adapter) return adapter
    }
    return null
  }

  function hasMountedStockWidget(pluginId) {
    var widgets = stockWidgets(String(pluginId || ""))
    return !!(widgets && widgets.length > 0)
  }

  function activeIslandScreenName() {
    var hostScreen = barHostScreenName(activeBarHost())
    if (hostScreen !== "") return hostScreen
    return focusedOutputName()
  }

  function stockWidget(pluginId) {
    return stockWidgetOnScreen(pluginId, activeIslandScreenName())
  }

  function barHostScreenName(host) {
    if (host && host.hostScreenName) return String(host.hostScreenName)
    var window = host && host.QsWindow ? host.QsWindow.window : null
    return window && window.screen ? String(window.screen.name || "") : ""
  }

  function activeBarHost() {
    if (barHosts.length === 0) return null
    var focused = focusedOutputName()
    if (focused !== "") {
      for (var i = 0; i < barHosts.length; i++)
        if (barHostScreenName(barHosts[i]) === focused) return barHosts[i]
    }
    return barHosts[0]
  }

  function barHostOnScreen(screenName) {
    var target = String(screenName || "")
    if (target === "") return null
    for (var i = 0; i < barHosts.length; i++)
      if (barHostScreenName(barHosts[i]) === target) return barHosts[i]
    return null
  }

  function registerBarHost(host) {
    if (!host || barHosts.indexOf(host) !== -1) return false
    var next = barHosts.slice()
    next.push(host)
    barHosts = next
    Qt.callLater(refreshStockState)
    return true
  }

  function unregisterBarHost(host) {
    var removedScreen = barHostScreenName(host)
    var next = barHosts.filter(function(candidate) { return candidate !== host })
    if (next.length === barHosts.length) return false
    barHosts = next
    if (transientKind === "osd" && osdScreenName === removedScreen) clearTransient()
    Qt.callLater(refreshStockState)
    return true
  }

  function handleBarKeyboardKey(key, modifiers) {
    var host = activeBarHost()
    return !!(host && typeof host.handleKeyboardKey === "function"
      && host.handleKeyboardKey(Number(key), Number(modifiers || 0)))
  }

  function stockIcon(pluginId, fallback) {
    var widget = stockWidget(pluginId)
    if (!widget) return fallback
    if (widget.icon) return String(widget.icon)
    if (typeof widget.outputIcon === "function") return String(widget.outputIcon())
    if (typeof widget.batteryIcon === "function") return String(widget.batteryIcon())
    return fallback
  }

  function audioWidgetSupported(widget) {
    return !!(widget && "outputVolume" in widget && typeof widget.setOutputVolume === "function")
  }

  function audioLabel(widget) {
    if (!widget) return "Default output"
    var sink = "volumeSink" in widget ? widget.volumeSink : ("sink" in widget ? widget.sink : null)
    if (!sink) return "Default output"
    if (typeof widget.nodeLabel === "function") return String(widget.nodeLabel(sink) || "Default output")
    if (sink.description) return String(sink.description)
    if (sink.nickname) return String(sink.nickname)
    if (sink.name) return String(sink.name)
    return "Default output"
  }

  function sampleAudioState(presentChange) {
    var widget = audioControl
    var supported = audioAdapterEnabled && audioWidgetSupported(widget)
    if (!supported) {
      audioAvailable = false
      audioStateReady = false
      audioOutputLabel = "Default output"
      return false
    }

    var nextVolume = Math.max(0, Math.min(1, Number(widget.outputVolume) || 0))
    var nextMuted = "outputMuted" in widget ? Boolean(widget.outputMuted) : false
    var changed = audioStateReady
      && (Math.abs(nextVolume - audioVolume) >= 0.005 || nextMuted !== audioMuted)
    audioAvailable = true
    audioVolume = nextVolume
    audioMuted = nextMuted
    audioOutputLabel = audioLabel(widget)
    if (typeof widget.outputIcon === "function") audioIcon = String(widget.outputIcon())
    audioStateReady = true
    if (changed && presentChange) presentAudioTransient()
    return true
  }

  function presentAudioTransient() {
    if (!audioAvailable || retainedMode !== "" || eventActive) return false
    transientKind = "audio"
    transientActive = true
    transientTimer.restart()
    return true
  }

  function clearTransient() {
    transientTimer.stop()
    transientActive = false
    transientKind = ""
    osdEvent = null
    osdScreenName = ""
  }

  // Accept the stock `omarchy osd` payload contract. The optional OSD
  // companion calls this directly and falls back to its own stock-style card
  // whenever the Island is unavailable or a user-owned surface is open.
  function showOsd(payloadJson) {
    var continuing = transientActive && transientKind === "osd"
      && osdEvent !== null && osdScreenName !== ""
    var host = continuing ? barHostOnScreen(osdScreenName) : activeBarHost()
    if (!barHosted || !host || retainedMode !== "" || eventActive) return false
    var event = OsdModel.parse(payloadJson)
    if (!event) return false
    if (!continuing) osdScreenName = barHostScreenName(host)
    osdEvent = event
    transientKind = "osd"
    transientActive = true
    if (event.duration > 0) transientTimer.restart()
    else transientTimer.stop()
    return true
  }

  function closeOsd() {
    if (transientKind !== "osd") return false
    clearTransient()
    return true
  }

  function setAudioVolume(volume, showTransient) {
    var widget = audioControl
    if (!audioWidgetSupported(widget)) return false
    widget.setOutputVolume(Math.max(0, Math.min(1, Number(volume) || 0)))
    sampleAudioState(false)
    if (showTransient !== false) presentAudioTransient()
    return true
  }

  function adjustAudioVolume(steps, showTransient) {
    if (!audioAvailable) sampleAudioState(false)
    return setAudioVolume(audioVolume + Number(steps || 0) * audioScrollStep, showTransient)
  }

  function toggleAudioMute() {
    var widget = audioControl
    if (!audioWidgetSupported(widget)) return false
    if (typeof widget.toggleOutputMute === "function") widget.toggleOutputMute()
    else if ("volumeSink" in widget && widget.volumeSink && widget.volumeSink.audio)
      widget.volumeSink.audio.muted = !widget.volumeSink.audio.muted
    else return false
    sampleAudioState(false)
    return true
  }

  function openAudio(keyboardEntry) {
    clearTransient()
    if (audioAvailable || sampleAudioState(false)) {
      openFocus("audio", keyboardEntry === true)
      return true
    }
    return togglePlugin("omarchy.audio", "")
  }

  function openStockAudioPanel() {
    clearTransient()
    closeRetained()
    return togglePlugin("omarchy.audio", "")
  }

  function displayWidgetSupported(widget) {
    return !!(widget && "brightnessPercent" in widget && "brightnessAvailable" in widget
      && typeof widget.setBrightness === "function")
  }

  function sampleDisplayState(presentChange) {
    var widget = displayControl
    var supported = displayAdapterEnabled && displayWidgetSupported(widget)
      && Boolean(widget.brightnessAvailable)
    if (!supported) {
      displayAvailable = false
      displayStateReady = false
      displayMonitorLabel = "Focused display"
      return false
    }

    var nextBrightness = Math.max(0.01, Math.min(1, Number(widget.brightnessPercent) / 100 || 0.01))
    var changed = displayStateReady && Math.abs(nextBrightness - displayBrightness) >= 0.005
    displayAvailable = true
    displayBrightness = nextBrightness
    displayMonitorLabel = String(widget.focusedMonitor || "Focused display")
    displayIcon = Quickshell.screens.length > 1 ? "󰍺" : "󰍹"
    displayStateReady = true
    if (changed && presentChange) presentDisplayTransient()
    return true
  }

  function presentDisplayTransient() {
    if (!displayAvailable || retainedMode !== "" || eventActive) return false
    transientKind = "display"
    transientActive = true
    transientTimer.restart()
    return true
  }

  function previewDisplayBrightness(value) {
    var widget = displayControl
    if (!displayWidgetSupported(widget) || !Boolean(widget.brightnessAvailable)) return false
    var normalized = Math.max(0.01, Math.min(1, Number(value) || 0.01))
    displayBrightness = normalized
    if (typeof widget.previewBrightness === "function") widget.previewBrightness(normalized * 100)
    else widget.setBrightness(normalized * 100)
    return true
  }

  function setDisplayBrightness(value, showTransient) {
    var widget = displayControl
    if (!displayWidgetSupported(widget) || !Boolean(widget.brightnessAvailable)) return false
    var normalized = Math.max(0.01, Math.min(1, Number(value) || 0.01))
    widget.setBrightness(normalized * 100)
    displayBrightness = normalized
    if (showTransient !== false) presentDisplayTransient()
    return true
  }

  function adjustDisplayBrightness(steps, showTransient) {
    if (!displayAvailable) sampleDisplayState(false)
    return setDisplayBrightness(displayBrightness + Number(steps || 0) * displayScrollStep, showTransient)
  }

  function openDisplay(keyboardEntry) {
    clearTransient()
    if (displayAvailable || sampleDisplayState(false)) {
      openFocus("display", keyboardEntry === true)
      return true
    }
    return togglePlugin("omarchy.monitor", "")
  }

  function openStockDisplayPanel() {
    clearTransient()
    closeRetained()
    return togglePlugin("omarchy.monitor", "")
  }

  function scrollProxy(proxy, delta) {
    if (!proxy) return false
    var kind = String(proxy.kind || "")
    if (kind === "audio") {
      var audioWheel = Util.wheelSteps(audioWheelAccumulator, Number(delta || 0))
      audioWheelAccumulator = audioWheel.remainder
      if (audioWheel.steps === 0) return true
      return adjustAudioVolume(audioWheel.steps, true)
    }
    if (kind === "display") {
      var displayWheel = Util.wheelSteps(displayWheelAccumulator, Number(delta || 0))
      displayWheelAccumulator = displayWheel.remainder
      if (displayWheel.steps === 0) return true
      return adjustDisplayBrightness(displayWheel.steps, true)
    }
    return false
  }

  function workspaceLabel(workspaceId) {
    var id = Number(workspaceId || 0)
    if (id <= 0) return "1"
    return id === 10 ? "0" : String(id)
  }

  function indicatorCatalog() {
    return ({
      Dictation: { id: "Dictation", label: "Dictation", glyph: "󰍬" },
      ScreenRecording: { id: "ScreenRecording", label: "Screen recording", glyph: "󰻂" },
      Reminder: { id: "Reminder", label: "Reminders", glyph: "󰢌" },
      NightLight: { id: "NightLight", label: "Night light", glyph: "󰔎" },
      Dnd: { id: "Dnd", label: "Do not disturb", glyph: "󰂛" },
      StayAwake: { id: "StayAwake", label: "Stay awake", glyph: "󰅶" }
    })
  }

  function indicatorEntryId(entry) {
    if (typeof entry === "string") return entry
    return entry && entry.id !== undefined ? String(entry.id) : ""
  }

  function stockIndicatorDefinitions(widget, activeStates) {
    var catalog = indicatorCatalog()
    var entries = widget && widget.indicatorEntries && widget.indicatorEntries.length > 0
      ? widget.indicatorEntries
      : ["Dictation", "ScreenRecording", "Reminder", "NightLight", "Dnd", "StayAwake"]
    var result = []
    for (var i = 0; i < entries.length; i++) {
      var id = indicatorEntryId(entries[i])
      var definition = catalog[id]
      if (!definition) continue
      result.push({
        id: definition.id,
        label: definition.label,
        glyph: definition.glyph,
        active: activeStates && activeStates[id] === true
      })
    }
    return result
  }

  function stockBar() {
    var widget = stockWidget("omarchy.workspaces") || stockWidget("omarchy.tray")
      || stockWidget("omarchy.audio")
    return widget && widget.bar ? widget.bar : null
  }

  function stockRun(command) {
    var value = String(command || "")
    if (!value) return false
    var bar = runnableBar()
    if (bar && typeof bar.run === "function") {
      bar.run(value)
      return true
    }
    if (typeof Util.execDetached === "function") {
      Util.execDetached(value)
      return true
    }
    Quickshell.execDetached(["bash", "-lc", value])
    return true
  }

  function proxyDefinition(pluginId) {
    var id = String(pluginId || "")
    if (id === "omarchy.workspaces")
      return { id: id, kind: "shelf", shelf: "workspaces", label: "Open workspaces",
        glyph: workspaceLabel(focusedWorkspaceId), fontFamily: "", payload: "" }
    if (id === "omarchy.tray")
      return { id: id, kind: "shelf", shelf: "tray", label: "Open system tray", glyph: "󰇙", fontFamily: "", payload: "" }
    if (id === "omarchy.indicators")
      return { id: id, kind: "shelf", shelf: "status", label: "Open status controls", glyph: "󰘮", fontFamily: "", payload: "" }
    if (id === "omarchy.keyboard-layout") {
      var keyboard = stockWidget(id)
      return { id: id, kind: "action", action: "keyboard", label: "Switch keyboard layout",
        glyph: keyboard && keyboard.layoutLabel ? String(keyboard.layoutLabel) : "󰌌", fontFamily: "", payload: "" }
    }
    if (id === "omarchy.system-update")
      return { id: id, kind: "action", action: "update", label: "Install Omarchy updates", glyph: "\uf021", fontFamily: "", payload: "" }
    if (id === "omarchy.menu")
      return { id: id, kind: "proxy", label: "Open launcher", glyph: "\ue900", fontFamily: "omarchy", payload: "{\"menu\":\"root\"}" }
    if (id === "omarchy.tailscale")
      return { id: id, label: "Open Tailscale", glyph: "", iconKind: "tailscale", fontFamily: "", payload: "" }
    if (id === "omarchy.bluetooth")
      return { id: id, label: "Open Bluetooth", glyph: stockIcon(id, "󰂯"), fontFamily: "", payload: "" }
    if (id === "omarchy.network")
      return { id: id, label: "Open network", glyph: stockIcon(id, "󰤨"), fontFamily: "", payload: "" }
    if (id === "omarchy.audio")
      return { id: id, kind: "audio", label: "Open audio", glyph: stockIcon(id, "󰕾"), fontFamily: "", payload: "" }
    if (id === "omarchy.monitor")
      return { id: id, kind: "display", label: "Open display controls",
        glyph: Quickshell.screens.length > 1 ? "󰍺" : "󰍹", fontFamily: "", payload: "" }
    if (id === "omarchy.power")
      return { id: id, label: "Open power controls", glyph: stockIcon(id, "󰁹"), fontFamily: "", payload: "" }
    if (id === "omarchy.weather")
      return { id: id, label: "Open weather", glyph: "󰖐", fontFamily: "", payload: "" }
    return null
  }

  function proxyVisible(pluginId) {
    var widget = stockWidget(pluginId)
    if (String(pluginId) === "omarchy.power" && widget
        && "batteryPresent" in widget && widget.batteryPresent === false) return false
    if (String(pluginId) === "omarchy.keyboard-layout")
      return !!widget && widget.visible !== false
    if (String(pluginId) === "omarchy.system-update")
      return !!widget && widget.updateAvailable === true
    return true
  }

  function desiredPeekIds() {
    var configured = value("layout", "peek", [
      "omarchy.menu", "omarchy.workspaces", "omarchy.indicators", "omarchy.tray",
      "omarchy.tailscale", "omarchy.bluetooth", "omarchy.network", "omarchy.audio",
      "omarchy.monitor", "omarchy.keyboard-layout", "omarchy.power"
    ])
    return Array.isArray(configured) ? configured.slice() : []
  }

  function refreshStockState() {
    var bluetooth = stockWidget("omarchy.bluetooth")
    var network = stockWidget("omarchy.network")
    var audio = stockWidget("omarchy.audio")
    var display = stockWidget("omarchy.monitor")

    if (audioControl !== audio) {
      audioControl = audio
      audioStateReady = false
    }
    sampleAudioState(false)

    if (displayControl !== display) {
      displayControl = display
      displayStateReady = false
      if (display && typeof display.refresh === "function") display.refresh()
    }
    sampleDisplayState(false)

    if (bluetooth && bluetooth.icon) bluetoothIcon = String(bluetooth.icon)
    if (network && network.icon) networkIcon = String(network.icon)
    if (audio && typeof audio.outputIcon === "function") audioIcon = String(audio.outputIcon())
    displayIcon = Quickshell.screens.length > 1 ? "󰍺" : "󰍹"

    var items = []
    var unsupported = []
    var hidden = []
    var ids = desiredPeekIds()
    for (var i = 0; i < ids.length; i++) {
      var definition = proxyDefinition(ids[i])
      if (definition && proxyVisible(ids[i])) {
        items.push(definition)
      }
      else if (definition) hidden.push(String(ids[i]))
      else if (String(ids[i]) !== "omarchy.clock") unsupported.push(String(ids[i]))
    }

    for (var q = quickAccessItems.length - 1; q >= 0; q--) {
      var accessItem = quickAccessItems[q]
      var duplicate = items.some(function(item) {
        return item.id === accessItem.id || item.id === accessItem.target
      })
      if (!duplicate) items.unshift(accessItem)
    }

    if (displayActivity) items.unshift({
      id: "omarchy-island.activities", kind: "focus", shelf: "activity",
      label: "Activity", glyph: "󰐕",
      fontFamily: "", payload: "",
      customUrl: presentationUrl(displayActivity, eventActive ? "event" : "compact")
    })

    var tray = stockWidget("omarchy.tray")
    var nextTray = tray && tray.allItems ? tray.allItems : []
    trayItems = nextTray && typeof nextTray.length === "number" ? nextTray : []

    var nextWorkspaceIds = []
    for (var workspaceId = 1; workspaceId <= workspaceCount; workspaceId++)
      nextWorkspaceIds.push(workspaceId)
    if (JSON.stringify(nextWorkspaceIds) !== JSON.stringify(workspaceIds)) workspaceIds = nextWorkspaceIds

    var indicators = stockWidget("omarchy.indicators")
    var activeStates = indicators && indicators.indicatorActiveStates ? indicators.indicatorActiveStates : ({})
    var definitions = stockIndicatorDefinitions(indicators, activeStates)
    if (JSON.stringify(definitions) !== JSON.stringify(indicatorItems)) indicatorItems = definitions

    if (JSON.stringify(items) !== JSON.stringify(peekItems)) peekItems = items
    if (JSON.stringify(unsupported) !== JSON.stringify(unsupportedPeekIds)) unsupportedPeekIds = unsupported
    if (JSON.stringify(hidden) !== JSON.stringify(hiddenPeekIds)) hiddenPeekIds = hidden
  }

  function toggleStockPanel(pluginId) {
    var widget = stockWidget(pluginId)
    if (!widget) return false
    if (typeof widget.toggle === "function") {
      widget.toggle()
      return true
    }
    if (typeof widget.togglePanel === "function") {
      widget.togglePanel()
      return true
    }
    if ("opened" in widget && typeof widget.open === "function" && typeof widget.close === "function") {
      if (widget.opened === true) widget.close()
      else widget.open()
      return true
    }
    return false
  }

  function togglePlugin(pluginId, payloadJson) {
    lastAction = String(pluginId || "")
    var payload = String(payloadJson || "")
    // Prefer in-process shell.toggle when the host still exposes it. Omarchy
    // 4.0.3 scoped third-party facades refuse other plugins, so fall back to
    // the public `omarchy-shell shell toggle` IPC and then a live widget.
    lastActionAccepted = !!(shell && typeof shell.toggle === "function"
      && shell.toggle(lastAction, payload))
    if (!lastActionAccepted)
      lastActionAccepted = stockRun(hostShellCommand("toggle", lastAction, payload))
    if (!lastActionAccepted && payload === "")
      lastActionAccepted = toggleStockPanel(lastAction)
    actionFeedback.restart()
    return lastActionAccepted
  }

  function openLauncher() {
    if (retainedMode !== "") closeRetained()
    return togglePlugin("omarchy.menu", "{\"menu\":\"root\"}")
  }

  function openClockPanel() {
    if (retainedMode !== "") closeRetained()
    if (stockWidget("omarchy.clock") && togglePlugin("omarchy.clock", "")) return true
    return invokeClockAdapter("primary")
  }

  function invokeStockMethod(pluginId, methodName) {
    var widget = stockWidget(pluginId)
    lastAction = String(pluginId || "") + "." + String(methodName || "")
    lastActionAccepted = !!(widget && typeof widget[methodName] === "function")
    if (lastActionAccepted) widget[methodName]()
    actionFeedback.restart()
    return lastActionAccepted
  }

  function triggerClockAction(action) {
    action = String(action || "primary")
    if (action === "primary") return openClockPanel()
    if (action === "secondary") {
      if (stockWidget("omarchy.clock")) return invokeStockMethod("omarchy.clock", "cycleFormat")
      return invokeClockAdapter("secondary")
    }
    if (action === "middle") {
      if (retainedMode !== "") closeRetained()
      return stockRun("omarchy-menu-timezone")
    }
    return false
  }

  function invokeClockAdapter(action) {
    var host = activeBarHost()
    lastAction = "omarchy.clock"
    lastActionAccepted = !!(host && typeof host.triggerClockAdapterAction === "function"
      && host.triggerClockAdapterAction(String(action || "primary")))
    actionFeedback.restart()
    return lastActionAccepted
  }

  function triggerProxyAction(proxy, action, keyboardEntry) {
    if (!proxy || !proxy.id) return false
    action = String(action || "primary")
    if (action === "primary") return triggerProxy(proxy, keyboardEntry)

    var id = String(proxy.id)
    if (action === "secondary") {
      if (id === "omarchy.menu") {
        if (retainedMode !== "") closeRetained()
        return stockRun("xdg-terminal-exec")
      }
      if (id === "omarchy.bluetooth") return invokeStockMethod(id, "toggleBluetooth")
      if (id === "omarchy.tailscale") return stockRun("omarchy-shell omarchy.tailscale toggleTailscale")
      if (id === "omarchy.audio") {
        var muted = toggleAudioMute()
        if (muted) presentAudioTransient()
        return muted
      }
      if (id === "omarchy.power") return invokeStockMethod(id, "togglePercentage")
      if (id === "omarchy.weather") {
        if (retainedMode !== "") closeRetained()
        return stockRun("omarchy-notification-send \"$(omarchy-weather-status)\"")
      }
    }

    if (action === "middle") {
      if (id === "omarchy.audio") return openStockAudioPanel()
      if (id === "omarchy.tailscale") return stockRun("omarchy-shell omarchy.tailscale refresh")
      if (id === "omarchy.weather") return invokeStockMethod(id, "refresh")
    }
    return false
  }

  function triggerProxy(proxy, keyboardEntry) {
    if (!proxy || !proxy.id) return false
    var fromKeyboard = keyboardEntry === true
    if (proxy.kind === "shelf") { openShelf(String(proxy.shelf || ""), fromKeyboard); return true }
    if (proxy.kind === "focus") {
      if (String(proxy.shelf || "activity") === "activity")
        return activateActivity(displayActivity, fromKeyboard)
      openFocus(String(proxy.shelf || "activity"), fromKeyboard)
      return true
    }
    if (proxy.kind === "quick-access") return openQuickAccess(String(proxy.target || proxy.id || ""))
    if (proxy.kind === "audio") return openAudio(fromKeyboard)
    if (proxy.kind === "display") return openDisplay(fromKeyboard)
    if (proxy.kind === "action") {
      var actionResult = triggerStockAction(String(proxy.action || ""))
      if (actionResult) closeRetained()
      return actionResult
    }
    if (retainedMode !== "") closeRetained()
    return togglePlugin(String(proxy.id), String(proxy.payload || ""))
  }

  function openShelf(shelfId, keyboardEntry) {
    clearTransient()
    keyboardEntryActive = keyboardEntry === true
    activeShelf = String(shelfId || "")
    retainedMode = "shelf"
  }

  function openFocus(shelfId, keyboardEntry) {
    clearTransient()
    keyboardEntryActive = keyboardEntry === true
    activeShelf = String(shelfId || "activity")
    if (activeShelf === "activity" && !eventActive && currentActivity)
      selectedActivityKey = currentActivity.key
    retainedMode = "focus"
  }

  function openControls(keyboardEntry) {
    clearTransient()
    keyboardEntryActive = keyboardEntry === true
    activeShelf = "controls"
    retainedMode = "controls"
  }

  function openKeyboardPeek() {
    var host = activeBarHost()
    if (!host || typeof host.keyboardItemCount !== "function" || host.keyboardItemCount() <= 0)
      return false
    clearTransient()
    keyboardEntryActive = true
    activeShelf = ""
    retainedMode = "peek"
    return true
  }

  function closeRetained() {
    retainedMode = ""
    activeShelf = ""
    keyboardEntryActive = false
  }

  function keyboardToggle() {
    if (retainedMode !== "") closeRetained()
    else if (keyboardTarget === "peek") openKeyboardPeek()
    else if (keyboardTarget === "controls") openControls(true)
    else openShelf(keyboardTarget, true)
    return retainedMode !== ""
  }

  function focusWorkspace(workspaceId) {
    var workspaces = stockWidget("omarchy.workspaces")
    if (workspaces && typeof workspaces.focusWorkspace === "function") {
      workspaces.focusWorkspace(Number(workspaceId))
      closeRetained()
      return true
    }
    return stockRun("hyprctl dispatch workspace " + Number(workspaceId))
  }

  function triggerStockAction(actionId) {
    if (actionId === "keyboard") {
      var keyboard = stockWidget("omarchy.keyboard-layout")
      if (keyboard && typeof keyboard.cycleLayout === "function") {
        keyboard.cycleLayout()
        return true
      }
    }
    if (actionId === "update") {
      var updater = stockWidget("omarchy.system-update")
      if (updater && typeof updater.runUpdate === "function") {
        updater.runUpdate()
        return true
      }
    }
    return false
  }

  function activateTrayItem(item, action, anchor) {
    if (!item) return false
    action = String(action || "activate")
    var tray = stockWidget("omarchy.tray")
    if ((action === "menu" || item.onlyMenu) && tray && typeof tray.openTrayMenu === "function" && anchor) {
      var host = activeBarHost()
      var edge = host ? String(host.barPosition || "top") : "top"
      var point = { x: anchor.width / 2, y: anchor.height }
      if (edge === "bottom") point.y = 0
      else if (edge === "left") point = { x: anchor.width, y: anchor.height / 2 }
      else if (edge === "right") point = { x: 0, y: anchor.height / 2 }
      tray.openTrayMenu(item, anchor, point)
      return true
    }
    if (action === "secondary" && typeof item.secondaryActivate === "function") item.secondaryActivate()
    else if (typeof item.activate === "function") item.activate()
    else return false
    closeRetained()
    return true
  }

  function serviceFor(pluginId) {
    return shell && typeof shell.firstPartyServiceFor === "function"
      ? shell.firstPartyServiceFor(String(pluginId)) : null
  }

  function openQuickAccess(targetId) {
    closeRetained()
    var id = String(targetId || "")
    if (!id) return false
    if (shell && typeof shell.summon === "function" && shell.summon(id, "{}") === true)
      return true
    if (shell && typeof shell.toggle === "function" && Boolean(shell.toggle(id, "{}")))
      return true
    return stockRun(hostShellCommand("summon", id, "{}"))
  }

  function triggerIndicator(indicatorId) {
    var id = String(indicatorId || "")
    var states = ({})
    for (var i = 0; i < indicatorItems.length; i++) states[indicatorItems[i].id] = indicatorItems[i].active
    if (id === "Dnd") {
      var notifications = serviceFor("omarchy.notifications")
      if (notifications && typeof notifications.setDoNotDisturb === "function") {
        notifications.setDoNotDisturb(!notifications.doNotDisturb)
        return true
      }
    } else if (id === "NightLight") {
      var nightlight = serviceFor("omarchy.nightlight")
      if (nightlight && typeof nightlight.setNightlight === "function") {
        nightlight.setNightlight(!nightlight.enabled)
        return true
      }
    } else if (id === "StayAwake") {
      var idle = serviceFor("omarchy.idle")
      if (idle && typeof idle.setIdleEnabled === "function") {
        idle.setIdleEnabled(Boolean(states.StayAwake))
        return true
      }
    } else if (id === "ScreenRecording") {
      return stockRun(Boolean(states.ScreenRecording)
        ? "omarchy-capture-screenrecording --stop-recording"
        : "omarchy-menu toggle trigger.capture.screenrecord")
    } else if (id === "Dictation") {
      return stockRun("omarchy-voxtype-config")
    } else if (id === "Reminder") {
      Quickshell.execDetached(["omarchy-reminder", Boolean(states.Reminder) ? "show" : "-i"])
      return true
    }
    return false
  }

  function copyObject(source) {
    var target = ({})
    source = source || ({})
    for (var key in source) target[key] = source[key]
    return target
  }

  function providerDisabled(providerId) {
    var disabled = value("providers", "disabled", [])
    return Array.isArray(disabled) && disabled.indexOf(String(providerId)) !== -1
  }

  function customQmlDisabled(providerId) {
    var disabled = value("providers", "custom_qml_disabled", [])
    return !customQmlAllowed || (Array.isArray(disabled) && disabled.indexOf(String(providerId)) !== -1)
  }

  function presentationEntryPoints(candidate) {
    return ProviderContract.presentationEntryPoints(candidate)
  }

  function islandRegistrationError(candidate, pluginId) {
    return ProviderContract.registrationError(candidate, pluginId)
  }

  function providerEntryPointUrl(candidate, key) {
    var entryPoints = candidate && candidate.entryPoints ? candidate.entryPoints : ({})
    var entryPoint = String(entryPoints[String(key || "")] || "")
    if (!entryPoint) return ""
    var baseUrl = String(candidate.__entryPointBaseUrl || "").replace(/\/$/, "")
    if (baseUrl) return baseUrl + "/" + entryPoint
    if (!pluginRegistry || typeof pluginRegistry.entryPointUrl !== "function") return ""
    return String(pluginRegistry.entryPointUrl(candidate, String(key || "")) || "")
  }

  function bundledProviderDefinitions() {
    var hostId = String(manifest && manifest.id ? manifest.id : "rblalock.omarchy-island")
    function definition(providerId, displayName, fallbackGlyph, directory, entryPoints) {
      var baseUrl = Qt.resolvedUrl("providers/" + directory).toString().replace(/\/$/, "")
      return {
        pluginId: hostId,
        providerId: providerId,
        manifest: {
          id: hostId,
          name: "Omarchy Island",
          entryPoints: entryPoints,
          omarchyIsland: {
            schemaVersion: 1,
            id: providerId,
            capabilities: entryPoints.omarchyIslandExpanded
              || entryPoints.omarchyIslandCompact || entryPoints.omarchyIslandMinimal
              || entryPoints.omarchyIslandEvent
              ? ["activity-provider", "custom-presentation"] : ["activity-provider"],
            displayName: displayName,
            fallbackGlyph: fallbackGlyph
          },
          __entryPointBaseUrl: baseUrl,
          __isBundledIslandProvider: true
        }
      }
    }
    return [
      definition("rblalock.now-playing", "Now Playing", "󰝚", "now-playing", {
          omarchyIslandProvider: "Provider.qml",
          omarchyIslandMinimal: "Minimal.qml",
          omarchyIslandCompact: "Compact.qml",
          omarchyIslandExpanded: "Expanded.qml"
        }),
      definition("rblalock.reminders", "Reminders", "󰢌", "reminders", {
          omarchyIslandProvider: "Provider.qml",
          omarchyIslandMinimal: "Minimal.qml",
          omarchyIslandCompact: "Compact.qml",
          omarchyIslandExpanded: "Expanded.qml"
        }),
      definition("rblalock.screen-recording", "Screen Recording", "󰻂", "screen-recording", {
          omarchyIslandProvider: "Provider.qml",
          omarchyIslandMinimal: "Minimal.qml",
          omarchyIslandCompact: "Compact.qml",
          omarchyIslandEvent: "Event.qml"
        }),
      definition("rblalock.system-update", "System Update", "", "system-update", {
          omarchyIslandProvider: "Provider.qml"
        })
    ]
  }

  function providerDiagnosticList() {
    return providerDiagnostics.map(function(diagnostic) {
      var result = copyObject(diagnostic)
      if (providerActivityErrors[result.providerId])
        result.error = providerActivityErrors[result.providerId]
      result.activities = rankedActivities.filter(function(activity) {
        return activity.providerId === diagnostic.providerId
      }).map(function(activity) { return activity.key })
      return result
    })
  }

  function recordProviderActivityError(providerId, message) {
    var key = String(providerId || "")
    var error = ProviderContract.boundedString(message, ProviderContract.limits.maxSubtitleChars,
      "activity rejected")
    if (!providerObjects[key] && !providerManifests[key]) {
      console.warn("Omarchy Island: provider activity rejected: " + error)
      return false
    }
    if (providerActivityErrors[key] === error) return false
    var errors = copyObject(providerActivityErrors)
    errors[key] = error
    providerActivityErrors = errors
    console.warn("Omarchy Island: provider activity rejected: " + error)
    return true
  }

  function clearProviderActivityError(providerId) {
    var key = String(providerId || "")
    if (providerActivityErrors[key] === undefined) return false
    var errors = copyObject(providerActivityErrors)
    delete errors[key]
    providerActivityErrors = errors
    return true
  }

  function unloadProvider(providerId) {
    var key = String(providerId || "")
    var provider = providerObjects[key]
    if (!provider) return false
    try {
      if (typeof provider.stop === "function") provider.stop()
    } catch (error) {
      console.warn("Omarchy Island: provider cleanup failed for " + key + ": " + error)
    }
    withdrawProvider(key)
    var objects = copyObject(providerObjects)
    var manifests = copyObject(providerManifests)
    delete objects[key]
    delete manifests[key]
    providerObjects = objects
    providerManifests = manifests
    clearProviderActivityError(key)
    if (typeof provider.destroy === "function") provider.destroy()
    return true
  }

  function loadProvider(candidate, providerId, providerUrl, diagnostic, sourceLabel) {
    var key = String(providerId || "")
    var label = String(sourceLabel || "provider")
    if (!key || !providerUrl) return false
    var component = Qt.createComponent(providerUrl, Component.PreferSynchronous)
    if (component.status !== Component.Ready) {
      diagnostic.status = "failed"
      diagnostic.error = ProviderContract.boundedString(
        component.errorString() || label + " component is not ready",
        ProviderContract.limits.maxSubtitleChars, "provider component is not ready")
      console.warn("Omarchy Island: " + label + " load failed for " + key
        + ": " + diagnostic.error)
      return false
    }
    var provider = component.createObject(providerHost, {
      island: root,
      manifest: candidate,
      providerId: key
    })
    if (!provider) {
      diagnostic.status = "failed"
      diagnostic.error = ProviderContract.boundedString(
        component.errorString() || label + " object could not be created",
        ProviderContract.limits.maxSubtitleChars, "provider object could not be created")
      console.warn("Omarchy Island: " + label + " creation failed for " + key
        + ": " + diagnostic.error)
      return false
    }
    if ("shell" in provider) provider.shell = root.shell
    if ("pluginRegistry" in provider) provider.pluginRegistry = root.pluginRegistry
    var objects = copyObject(providerObjects)
    var manifests = copyObject(providerManifests)
    objects[key] = provider
    manifests[key] = candidate
    providerObjects = objects
    providerManifests = manifests
    try {
      if (typeof provider.start === "function") provider.start()
      diagnostic.status = "loaded"
      return true
    } catch (error) {
      diagnostic.status = "failed"
      diagnostic.error = ProviderContract.boundedString(error,
        ProviderContract.limits.maxSubtitleChars, "provider failed to start")
      console.warn("Omarchy Island: " + label + " start failed for " + key
        + ": " + diagnostic.error)
      unloadProvider(key)
      return false
    }
  }

  function providerOrder(providerId) {
    var order = value("providers", "order", [])
    var index = Array.isArray(order) ? order.indexOf(String(providerId)) : -1
    return index < 0 ? 10000 : index
  }

  function providerPinned(providerId) {
    var pinned = value("providers", "pinned", [])
    return Array.isArray(pinned) && pinned.indexOf(String(providerId)) !== -1
  }

  function normalizedRestPresentation(value) {
    var requested = String(value || "takeover")
    return ["hidden", "companion", "takeover"].indexOf(requested) !== -1
      ? requested : "takeover"
  }

  function providerRestOverride(providerId) {
    var providers = config && config.providers ? config.providers : null
    var overrides = providers && providers.rest && typeof providers.rest === "object"
      ? providers.rest : null
    if (!overrides || overrides[String(providerId)] === undefined) return ""
    var requested = String(overrides[String(providerId)] || "")
    return ["hidden", "companion", "takeover"].indexOf(requested) !== -1
      ? requested : ""
  }

  function restPresentation(activity) {
    var override = providerRestOverride(activity ? activity.providerId : "")
    if (override !== "") return override
    var presentation = activity && activity.presentation ? activity.presentation : null
    return normalizedRestPresentation(presentation && presentation.rest)
  }

  function activityKey(providerId, activityId) {
    return String(providerId) + ":" + String(activityId)
  }

  function normalizeActivity(providerId, input) {
    activityNormalizationError = ""
    var source = input && typeof input === "object" ? input : ({})
    var providerKey = String(providerId || "")
    var providerError = ProviderContract.identifierError(providerKey, "provider id")
    if (providerError !== "") {
      activityNormalizationError = providerError
      return null
    }
    var activityId = String(source.id || "default")
    var activityIdError = ProviderContract.identifierError(activityId, "activity id")
    if (activityIdError !== "") {
      activityNormalizationError = activityIdError
      return null
    }
    var normalizedData = ProviderContract.normalizedData(source.data)
    if (!normalizedData.ok) {
      activityNormalizationError = normalizedData.error
      return null
    }

    var activity = ({})
    activity.providerId = providerKey
    activity.id = activityId
    activity.key = activityKey(activity.providerId, activity.id)
    activity.title = ProviderContract.boundedString(source.title,
      ProviderContract.limits.maxTitleChars, activity.providerId)
    activity.subtitle = ProviderContract.boundedString(source.subtitle,
      ProviderContract.limits.maxSubtitleChars, "")
    activity.glyph = ProviderContract.boundedString(source.glyph,
      ProviderContract.limits.maxGlyphChars, "󰐕")
    activity.attention = ["routine", "timely", "critical"].indexOf(String(source.attention)) !== -1
      ? String(source.attention) : "routine"
    var updatedAt = Number(source.updatedAt)
    activity.updatedAt = isFinite(updatedAt) && updatedAt > 0 ? updatedAt : Date.now()
    var expiresAt = Number(source.expiresAt)
    expiresAt = isFinite(expiresAt) && expiresAt > 0 ? expiresAt : 0
    if (expiresAt > 0 && expiresAt < 100000000000) expiresAt *= 1000
    var leaseValue = Number(source.leaseMs)
    var leaseMs = isFinite(leaseValue) ? Math.max(0, leaseValue) : 0
    activity.leaseMs = leaseMs
    activity.expiresAt = expiresAt > 0 ? expiresAt : (leaseMs > 0 ? activity.updatedAt + leaseMs : 0)
    var deadline = Number(source.deadline)
    if (isFinite(deadline) && deadline > 0) activity.deadline = deadline
    var progress = Number(source.progress)
    if (source.progress !== undefined && isFinite(progress))
      activity.progress = Math.max(0, Math.min(1, progress))
    activity.data = normalizedData.value

    var sourceActions = Array.isArray(source.actions) ? source.actions : []
    var normalizedActions = []
    var seenActions = ({})
    var inspectedActions = Math.min(sourceActions.length,
      ProviderContract.limits.maxActionsPerActivity)
    for (var actionIndex = 0; actionIndex < inspectedActions; actionIndex++) {
      var sourceAction = sourceActions[actionIndex]
      if (!sourceAction || typeof sourceAction !== "object") continue
      var actionId = String(sourceAction.id || "")
      if (ProviderContract.identifierError(actionId, "action id") !== ""
          || seenActions[actionId]) continue
      var normalizedAction = {
        id: actionId,
        label: ProviderContract.boundedString(sourceAction.label,
          ProviderContract.limits.maxLabelChars, actionId),
        glyph: ProviderContract.boundedString(sourceAction.glyph,
          ProviderContract.limits.maxGlyphChars, ""),
        destructive: Boolean(sourceAction.destructive)
      }
      normalizedActions.push(normalizedAction)
      seenActions[actionId] = true
    }
    activity.actions = normalizedActions
    var primaryAction = String(source.primaryAction || "")
    activity.primaryAction = activity.actions.some(function(action) {
      return action && String(action.id || "") === primaryAction
    }) ? primaryAction : ""
    activity.event = null
    if (source.event && typeof source.event === "object") {
      var eventId = String(source.event.id || "")
      var eventIdError = ProviderContract.identifierError(eventId, "event id")
      if (eventIdError !== "") {
        activityNormalizationError = eventIdError
        return null
      }
      activity.event = {
        id: eventId,
        title: ProviderContract.boundedString(source.event.title,
          ProviderContract.limits.maxTitleChars, activity.title),
        subtitle: ProviderContract.boundedString(source.event.subtitle,
          ProviderContract.limits.maxSubtitleChars, activity.subtitle),
        glyph: ProviderContract.boundedString(source.event.glyph,
          ProviderContract.limits.maxGlyphChars, activity.glyph),
        attention: ["routine", "timely", "critical"].indexOf(String(source.event.attention)) !== -1
          ? String(source.event.attention) : activity.attention
      }
    }
    var sourcePresentation = source.presentation && typeof source.presentation === "object"
      ? source.presentation : ({})
    activity.presentation = { rest: normalizedRestPresentation(sourcePresentation.rest) }
    var providerManifest = providerManifests[activity.providerId]
    if (providerManifest && providerManifest.entryPoints) {
      activity.views = ({
        minimal: providerEntryPointUrl(providerManifest, "omarchyIslandMinimal"),
        compact: providerEntryPointUrl(providerManifest, "omarchyIslandCompact"),
        expanded: providerEntryPointUrl(providerManifest, "omarchyIslandExpanded"),
        event: providerEntryPointUrl(providerManifest, "omarchyIslandEvent")
      })
    }
    return activity
  }

  function publish(providerId, activity) {
    if (!providerId || !activity || providerDisabled(providerId)) return false
    var requestedProviderId = String(providerId || "")
    var requestedActivityId = String(activity.id || "default")
    var providerError = ProviderContract.identifierError(requestedProviderId, "provider id")
    var activityIdError = ProviderContract.identifierError(requestedActivityId, "activity id")
    if (providerError !== "" || activityIdError !== "") {
      recordProviderActivityError(requestedProviderId, providerError || activityIdError)
      return false
    }
    var requestedKey = activityKey(requestedProviderId, requestedActivityId)
    var replacing = false
    var providerActivityCount = 0
    for (var countIndex = 0; countIndex < activities.length; countIndex++) {
      if (activities[countIndex].providerId === requestedProviderId) providerActivityCount++
      if (activities[countIndex].key === requestedKey) replacing = true
    }
    if (!replacing && providerActivityCount >= ProviderContract.limits.maxActivitiesPerProvider) {
      recordProviderActivityError(requestedProviderId, "activity count exceeds "
        + ProviderContract.limits.maxActivitiesPerProvider + " per provider")
      return false
    }
    if (!replacing && activities.length >= ProviderContract.limits.maxActivitiesTotal) {
      recordProviderActivityError(requestedProviderId, "activity count exceeds "
        + ProviderContract.limits.maxActivitiesTotal + " globally")
      return false
    }
    var normalized = normalizeActivity(providerId, activity)
    if (!normalized) {
      recordProviderActivityError(requestedProviderId,
        activityNormalizationError || "activity could not be normalized")
      return false
    }
    var next = []
    var previous = null
    for (var i = 0; i < activities.length; i++) {
      if (activities[i].key === normalized.key) previous = activities[i]
      else next.push(activities[i])
    }
    next.push(normalized)
    activities = next
    var eventId = normalized.event ? String(normalized.event.id || "") : ""
    var previousEventId = previous && previous.event ? String(previous.event.id || "") : ""
    if (eventId && eventId !== previousEventId) presentEvent(normalized)
    clearProviderActivityError(requestedProviderId)
    Qt.callLater(refreshStockState)
    return true
  }

  function update(providerId, activityId, patch) {
    var key = activityKey(providerId, activityId)
    for (var i = 0; i < activities.length; i++) {
      if (activities[i].key !== key) continue
      var merged = copyObject(activities[i])
      patch = patch || ({})
      for (var name in patch) merged[name] = patch[name]
      return publish(providerId, merged)
    }
    return false
  }

  function withdraw(providerId, activityId) {
    var key = activityKey(providerId, activityId)
    var next = activities.filter(function(activity) { return activity.key !== key })
    if (next.length === activities.length) return false
    activities = next
    if (selectedActivityKey === key) selectedActivityKey = ""
    if (eventActivity && eventActivity.key === key) clearEvent()
    Qt.callLater(refreshStockState)
    return true
  }

  function withdrawProvider(providerId) {
    var requestedProviderId = String(providerId)
    var selectedBelongsToProvider = false
    for (var index = 0; index < activities.length; index++)
      if (activities[index].key === selectedActivityKey
          && activities[index].providerId === requestedProviderId) selectedBelongsToProvider = true
    activities = activities.filter(function(activity) {
      return activity.providerId !== requestedProviderId
    })
    if (selectedBelongsToProvider) selectedActivityKey = ""
    if (eventActivity && eventActivity.providerId === requestedProviderId) clearEvent()
    Qt.callLater(refreshStockState)
  }

  function expireActivities() {
    var now = Date.now()
    var next = activities.filter(function(activity) {
      return Number(activity.expiresAt || 0) === 0 || Number(activity.expiresAt) > now
    })
    if (next.length === activities.length) return false
    activities = next
    var selectedStillActive = next.some(function(activity) { return activity.key === selectedActivityKey })
    if (!selectedStillActive) selectedActivityKey = ""
    if (eventActivity && !next.some(function(activity) {
      return activity.key === eventActivity.key
    })) clearEvent()
    Qt.callLater(refreshStockState)
    return true
  }

  function attentionRank(attention) {
    if (attention === "critical") return 0
    if (attention === "timely") return 1
    return 2
  }

  function rankActivities(source) {
    var visible = (source || []).filter(function(activity) {
      return activity && !providerDisabled(activity.providerId)
        && (Number(activity.expiresAt || 0) === 0 || Number(activity.expiresAt) > Date.now())
    })
    visible.sort(function(a, b) {
      var critical = (a.attention === "critical" ? 0 : 1) - (b.attention === "critical" ? 0 : 1)
      if (critical !== 0) return critical
      var pinned = (providerPinned(a.providerId) ? 0 : 1) - (providerPinned(b.providerId) ? 0 : 1)
      if (pinned !== 0) return pinned
      var provider = providerOrder(a.providerId) - providerOrder(b.providerId)
      if (provider !== 0) return provider
      var attention = attentionRank(a.attention) - attentionRank(b.attention)
      if (attention !== 0) return attention
      return Number(b.updatedAt) - Number(a.updatedAt)
    })
    return visible
  }

  function activityForKey(key) {
    var requested = String(key || "")
    for (var index = 0; index < rankedActivities.length; index++)
      if (rankedActivities[index].key === requested) return rankedActivities[index]
    return currentActivity
  }

  function selectActivity(key) {
    var requested = String(key || "")
    for (var index = 0; index < rankedActivities.length; index++) {
      if (rankedActivities[index].key !== requested) continue
      selectedActivityKey = requested
      return true
    }
    return false
  }

  function presentationUrl(activity, mode) {
    if (!activity || customQmlDisabled(activity.providerId) || !activity.views) return ""
    return String(activity.views[String(mode || "expanded")] || "")
  }

  function routeAction(providerId, activityId, actionId) {
    var requestedProviderId = String(providerId || "")
    var requestedActivityId = String(activityId || "")
    var requestedActionId = String(actionId || "")
    var key = activityKey(requestedProviderId, requestedActivityId)
    var activity = null
    for (var index = 0; index < activities.length; index++) {
      if (activities[index].key !== key) continue
      activity = activities[index]
      break
    }
    if (!activity || requestedActionId === "" || !activity.actions.some(function(action) {
      return action && String(action.id || "") === requestedActionId
    })) return false

    var provider = providerObjects[requestedProviderId]
    if (!provider || typeof provider.onAction !== "function") return false
    try {
      return provider.onAction(requestedActivityId, requestedActionId) !== false
    } catch (error) {
      console.warn("Omarchy Island: provider action failed for " + key + ":" + requestedActionId
        + ": " + error)
      for (var diagnosticIndex = 0;
           diagnosticIndex < providerDiagnostics.length;
           diagnosticIndex++) {
        if (providerDiagnostics[diagnosticIndex].providerId !== requestedProviderId) continue
        var diagnostics = providerDiagnostics.slice()
        var diagnostic = copyObject(diagnostics[diagnosticIndex])
        diagnostic.error = ProviderContract.boundedString(
          "action " + requestedActionId + " failed: " + String(error),
          ProviderContract.limits.maxSubtitleChars, "provider action failed")
        diagnostics[diagnosticIndex] = diagnostic
        providerDiagnostics = diagnostics
        break
      }
      return false
    }
  }

  function activateActivity(activity, keyboardEntry) {
    var target = activity || displayActivity || currentActivity
    if (!target) return false
    var primaryAction = String(target.primaryAction || "")
    if (primaryAction !== "") {
      if (retainedMode !== "") closeRetained()
      return routeAction(target.providerId, target.id, primaryAction)
    }
    openFocus("activity", keyboardEntry === true)
    if (!eventActive) selectedActivityKey = target.key
    return true
  }

  function presentEvent(activity) {
    if (!activity) return false
    var shown = copyObject(activity)
    var event = activity.event || ({})
    if (event.title !== undefined) shown.title = String(event.title)
    if (event.subtitle !== undefined) shown.subtitle = String(event.subtitle)
    if (event.glyph !== undefined) shown.glyph = String(event.glyph)
    shown.event = copyObject(event)
    eventActivity = shown
    eventActive = true
    eventTimer.restart()
    if (autoFocusEvents) openFocus("activity")
    return true
  }

  function clearEvent() {
    eventTimer.stop()
    eventActive = false
    eventActivity = null
  }

  function discoverProviders() {
    if (!pluginRegistry || !pluginRegistry.installedPlugins) return
    var installed = pluginRegistry.installedPlugins
    var accessItems = []
    var diagnostics = []
    var enabledExternalProviders = ({})
    for (var installedId in installed) {
      var installedCandidate = installed[installedId]
      var installedMetadata = installedCandidate ? installedCandidate.omarchyIsland : null
      var installedEnabled = typeof pluginRegistry.isEnabled !== "function"
        || pluginRegistry.isEnabled(installedId)
      var installedProviderEntryPoint = installedCandidate && installedCandidate.entryPoints
        ? String(installedCandidate.entryPoints.omarchyIslandProvider || "") : ""
      if (installedMetadata && installedEnabled && installedProviderEntryPoint
          && islandRegistrationError(installedCandidate, installedId) === "")
        enabledExternalProviders[String(installedMetadata.id || installedId)] = true
    }

    var bundled = bundledProviderDefinitions()
    for (var bundledIndex = 0; bundledIndex < bundled.length; bundledIndex++) {
      var bundledDefinition = bundled[bundledIndex]
      var bundledId = bundledDefinition.providerId
      var bundledOwner = providerManifests[bundledId]
      if (!enabledExternalProviders[bundledId] || !bundledOwner
          || !bundledOwner.__isBundledIslandProvider) continue
      unloadProvider(bundledId)
    }

    // Remove stale external ownership before loading a bundled fallback. This
    // keeps failback within the same registry reconciliation pass.
    for (var existingId in providerObjects) {
      var existingManifest = providerManifests[existingId]
      if (existingManifest && existingManifest.__isBundledIslandProvider) continue
      var existingPluginId = existingManifest ? String(existingManifest.id || "") : ""
      var existingCandidate = existingPluginId ? installed[existingPluginId] : null
      var existingEnabled = existingCandidate
        && (typeof pluginRegistry.isEnabled !== "function"
          || pluginRegistry.isEnabled(existingPluginId))
      var existingValid = existingCandidate
        && islandRegistrationError(existingCandidate, existingPluginId) === ""
      if (existingEnabled && existingValid && !providerDisabled(existingId)) continue
      unloadProvider(existingId)
    }

    for (var pluginId in installed) {
      var candidate = installed[pluginId]
      var metadata = candidate ? candidate.omarchyIsland : null
      var enabled = typeof pluginRegistry.isEnabled !== "function" || pluginRegistry.isEnabled(pluginId)
      if (!metadata) continue
      var providerId = String(metadata.id || pluginId)
      var providerEntryPoint = candidate.entryPoints
        ? String(candidate.entryPoints.omarchyIslandProvider || "") : ""
      var providerUrl = providerEntryPoint
        ? providerEntryPointUrl(candidate, "omarchyIslandProvider") : ""
      var access = metadata.quickAccess && metadata.quickAccess.enabled !== false
        ? metadata.quickAccess : null
      var diagnostic = {
        pluginId: ProviderContract.boundedString(pluginId,
          ProviderContract.limits.maxIdentifierChars, ""),
        providerId: ProviderContract.boundedString(providerId,
          ProviderContract.limits.maxIdentifierChars, ""),
        displayName: ProviderContract.boundedString(
          metadata.displayName || candidate.name || providerId,
          ProviderContract.limits.maxLabelChars, providerId),
        status: enabled ? "discovered" : "disabled",
        reason: enabled ? "" : "plugin-disabled",
        sourceDir: ProviderContract.boundedString(candidate.__sourceDir,
          ProviderContract.limits.maxSubtitleChars, ""),
        providerEntryPoint: ProviderContract.boundedString(providerEntryPoint,
          ProviderContract.limits.maxSubtitleChars, ""),
        providerUrl: ProviderContract.boundedString(providerUrl,
          ProviderContract.limits.maxSubtitleChars, ""),
        capabilities: Array.isArray(metadata.capabilities)
          ? metadata.capabilities.slice(0, ProviderContract.capabilities.length).map(function(value) {
              return ProviderContract.boundedString(value,
                ProviderContract.limits.maxIdentifierChars, "")
            }) : [],
        presentations: presentationEntryPoints(candidate),
        quickAccessId: access ? ProviderContract.boundedString(access.id || pluginId,
          ProviderContract.limits.maxIdentifierChars, "") : "",
        error: ""
      }
      diagnostics.push(diagnostic)
      if (!enabled) continue
      var registrationError = islandRegistrationError(candidate, pluginId)
      if (registrationError !== "") {
        diagnostic.status = "failed"
        diagnostic.error = registrationError
        continue
      }
      if (access) {
        accessItems.push({
          id: String(access.id || pluginId),
          kind: "quick-access",
          target: String(access.target || pluginId),
          label: ProviderContract.boundedString(
            access.label || metadata.displayName || candidate.name || pluginId,
            ProviderContract.limits.maxLabelChars, pluginId),
          glyph: ProviderContract.boundedString(access.glyph || metadata.fallbackGlyph,
            ProviderContract.limits.maxGlyphChars, "󰐕"),
          fontFamily: "",
          payload: ""
        })
      }
      if (!providerEntryPoint) continue
      if (providerDisabled(providerId)) {
        diagnostic.status = "disabled"
        diagnostic.reason = "island-config"
        continue
      }
      if (providerObjects[providerId]) {
        var owner = providerManifests[providerId]
        var ownerId = owner ? String(owner.id || "") : ""
        if (ownerId && ownerId !== String(pluginId)) {
          diagnostic.status = "failed"
          diagnostic.error = ProviderContract.boundedString(
            "provider id is already owned by plugin " + ownerId,
            ProviderContract.limits.maxSubtitleChars, "provider id is already owned")
        } else {
          diagnostic.status = "loaded"
        }
        continue
      }
      if (!providerUrl) {
        diagnostic.status = "failed"
        diagnostic.error = "provider entry point could not be resolved"
        continue
      }
      loadProvider(candidate, providerId, providerUrl, diagnostic, "provider")
    }

    for (var defaultIndex = 0; defaultIndex < bundled.length; defaultIndex++) {
      var defaultDefinition = bundled[defaultIndex]
      var defaultId = defaultDefinition.providerId
      var defaultManifest = defaultDefinition.manifest
      var defaultDiagnostic = {
        pluginId: defaultDefinition.pluginId,
        providerId: defaultId,
        displayName: ProviderContract.boundedString(
          defaultManifest.omarchyIsland.displayName || defaultId,
          ProviderContract.limits.maxLabelChars, defaultId),
        status: "discovered",
        reason: "bundled",
        sourceDir: String(defaultManifest.__entryPointBaseUrl || ""),
        providerEntryPoint: String(defaultManifest.entryPoints.omarchyIslandProvider || ""),
        providerUrl: providerEntryPointUrl(defaultManifest, "omarchyIslandProvider"),
        capabilities: defaultManifest.omarchyIsland.capabilities.slice(),
        presentations: presentationEntryPoints(defaultManifest),
        quickAccessId: "",
        bundled: true,
        error: ""
      }
      diagnostics.push(defaultDiagnostic)
      if (providerDisabled(defaultId)) {
        defaultDiagnostic.status = "disabled"
        defaultDiagnostic.reason = "island-config"
        continue
      }
      if (providerObjects[defaultId]) {
        var defaultOwner = providerManifests[defaultId]
        defaultDiagnostic.status = defaultOwner && defaultOwner.__isBundledIslandProvider
          ? "loaded" : "superseded"
        defaultDiagnostic.reason = defaultDiagnostic.status === "loaded" ? "bundled" : "external-provider"
        continue
      }
      var defaultProviderUrl = providerEntryPointUrl(defaultManifest, "omarchyIslandProvider")
      loadProvider(defaultManifest, defaultId, defaultProviderUrl,
        defaultDiagnostic, "bundled provider")
    }

    if (JSON.stringify(accessItems) !== JSON.stringify(quickAccessItems)) quickAccessItems = accessItems
    diagnostics.sort(function(a, b) { return a.pluginId.localeCompare(b.pluginId) })
    if (JSON.stringify(diagnostics) !== JSON.stringify(providerDiagnostics))
      providerDiagnostics = diagnostics
    Qt.callLater(refreshStockState)
  }

  function applyConfig(text, isDefault) {
    try {
      var parsed = Toml.parse(text)
      if (isDefault) defaultConfig = parsed
      else userConfig = parsed
      configError = ""
    } catch (error) {
      configError = String(error)
      console.warn("Omarchy Island: config parse failed: " + error)
    }
  }

  function reloadConfig() {
    defaultsFile.reload()
    userConfigFile.reload()
  }

  function inspectObject() {
    return {
      plugin: manifest && manifest.id ? String(manifest.id) : "rblalock.omarchy-island",
      retainedMode: retainedMode,
      activeShelf: activeShelf,
      keyboardEntryActive: keyboardEntryActive,
      keyboardPeekActive: keyboardPeekActive,
      lastAction: lastAction,
      lastActionAccepted: lastActionAccepted,
      liveStockBar: liveStockBar() !== null,
      retainedWindow: {
        enabled: retainedWindowEnabled,
        ready: retainedWindowLoader.item !== null,
        status: Number(retainedWindowLoader.status),
        barHosted: barHosted,
        barHostCount: barHosts.length,
        hostStates: barHosts.map(function(host) {
          return host && typeof host.debugState === "function" ? host.debugState() : null
        }),
        hostState: activeBarHost() && typeof activeBarHost().debugState === "function"
          ? activeBarHost().debugState() : null
      },
      configPath: configPath,
      configError: configError,
      style: styleName,
      resolved: {
        shelfWidth: configuredShelfWidth,
        shelfHeight: configuredShelfHeight,
        focusHeight: configuredFocusHeight,
        controlsHeight: configuredControlsHeight,
        cornerRadius: cornerRadius,
        workspaceCount: workspaceCount,
        background: backgroundOverride,
        border: borderOverride,
        topOffset: topOffset,
        collapseDelayMs: collapseDelayMs,
        motionEnabled: motionEnabled,
        motionExpandMs: motionExpandMs,
        motionCollapseMs: motionCollapseMs,
        contentMotionMs: contentMotionMs,
        clockFormat: clockFormat,
        verticalClockFormat: verticalClockFormat,
        restContent: restContent,
        keyboardTarget: keyboardTarget,
        customQmlAllowed: customQmlAllowed
      },
      peek: peekItems.map(function(item) { return item.id }),
      shelf: {
        trayCount: trayItems.length,
        workspaces: workspaceIds,
        indicatorCount: indicatorItems.length
      },
      transient: {
        active: transientActive,
        kind: transientKind,
        osd: osdEvent,
        osdScreen: osdScreenName,
        osdArbitration: {
          passiveHover: "takeover",
          retainedSurface: "companion-fallback",
          providerEvent: "companion-fallback"
        }
      },
      audio: {
        enabled: audioAdapterEnabled,
        available: audioAvailable,
        volume: Math.round(audioVolume * 100),
        muted: audioMuted,
        output: audioOutputLabel,
        transientHoldMs: audioTransientHoldMs,
        scrollStepPercent: Math.round(audioScrollStep * 100)
      },
      display: {
        enabled: displayAdapterEnabled,
        available: displayAvailable,
        brightness: Math.round(displayBrightness * 100),
        monitor: displayMonitorLabel,
        transientHoldMs: displayTransientHoldMs,
        scrollStepPercent: Math.round(displayScrollStep * 100)
      },
      providers: Object.keys(providerObjects),
      providerDiagnostics: providerDiagnosticList(),
      quickAccess: quickAccessItems.map(function(item) { return item.id }),
      activities: rankedActivities.map(function(activity) { return activity.key }),
      unsupportedPeek: unsupportedPeekIds,
      hiddenPeek: hiddenPeekIds,
      icons: {
        bluetooth: bluetoothIcon,
        network: networkIcon,
        audio: audioIcon,
        display: displayIcon
      }
    }
  }

  function inspectJson() {
    return JSON.stringify(inspectObject())
  }

  onConfigChanged: {
    Qt.callLater(refreshStockState)
    Qt.callLater(discoverProviders)
  }
  onShellChanged: {
    Qt.callLater(refreshStockState)
    Qt.callLater(discoverProviders)
  }
  onPluginRegistryChanged: Qt.callLater(discoverProviders)
  Component.onCompleted: {
    Qt.callLater(refreshStockState)
    Qt.callLater(discoverProviders)
  }

  Item { id: providerHost; visible: false }

  Connections {
    target: root.pluginRegistry
    ignoreUnknownSignals: true
    function onPluginsChanged() { root.discoverProviders() }
    function onScanFinished() { root.discoverProviders() }
  }

  Connections {
    target: root.audioControl
    ignoreUnknownSignals: true
    // Hardware and system-script changes are presented by Omarchy's OSD (or
    // the optional Island companion). Island-authored wheel/slider changes
    // call presentAudioTransient explicitly, avoiding two competing sources.
    function onOutputVolumeChanged() { root.sampleAudioState(false) }
    function onOutputMutedChanged() { root.sampleAudioState(false) }
    function onVolumeSinkChanged() { root.sampleAudioState(false) }
  }

  Connections {
    target: root.displayControl
    ignoreUnknownSignals: true
    function onBrightnessPercentChanged() { root.sampleDisplayState(false) }
    function onBrightnessAvailableChanged() { root.sampleDisplayState(false) }
    function onFocusedMonitorChanged() { root.sampleDisplayState(false) }
    function onDisplaysChanged() { root.sampleDisplayState(false) }
  }

  Timer {
    interval: 800
    repeat: true
    running: true
    onTriggered: root.refreshStockState()
  }

  Timer {
    interval: 15000
    repeat: true
    running: true
    onTriggered: root.expireActivities()
  }

  Timer {
    id: eventTimer
    interval: root.eventHoldMs
    onTriggered: root.clearEvent()
  }

  Timer {
    id: transientTimer
    interval: root.transientKind === "osd" && root.osdEvent
      ? Math.max(1, Number(root.osdEvent.duration || 1))
      : (root.transientKind === "display"
        ? root.displayTransientHoldMs : root.audioTransientHoldMs)
    onTriggered: root.clearTransient()
  }

  FileView {
    id: defaultsFile
    path: Qt.resolvedUrl("config/default.toml")
    watchChanges: true
    printErrors: true
    onLoaded: root.applyConfig(text(), true)
    onFileChanged: reload()
  }

  FileView {
    id: userConfigFile
    path: root.configPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.applyConfig(text(), false)
    onLoadFailed: root.userConfig = ({})
    onFileChanged: reload()
  }

  Timer {
    id: actionFeedback
    interval: 900
    onTriggered: {
      root.lastAction = ""
      root.lastActionAccepted = false
    }
  }

  IpcHandler {
    target: "omarchy-island"

    function peek() : string { return root.openKeyboardPeek() ? "peek" : "unavailable" }
    function shelf(shelfId: string) : string { root.openShelf(shelfId); return "shelf" }
    function focus(shelfId: string) : string { root.openFocus(shelfId); return "focus" }
    function close() : string { root.closeRetained(); return "closed" }
    function keyboard() : string { root.keyboardToggle(); return root.retainedMode !== "" ? "opened" : "closed" }
    function controls() : string { root.openControls(); return "controls" }
    function launcher() : string { return root.openLauncher() ? "ok" : "unavailable" }
    function bluetooth() : string { return root.togglePlugin("omarchy.bluetooth", "") ? "ok" : "unavailable" }
    function network() : string { return root.togglePlugin("omarchy.network", "") ? "ok" : "unavailable" }
    function audio() : string { return root.openAudio() ? "ok" : "unavailable" }
    function volume(stepDelta: int) : string {
      return root.adjustAudioVolume(stepDelta, true) ? "ok" : "unavailable"
    }
    function display() : string { return root.openDisplay() ? "ok" : "unavailable" }
    function brightness(stepDelta: int) : string {
      return root.adjustDisplayBrightness(stepDelta, true) ? "ok" : "unavailable"
    }
    function osdShow(payloadJson: string) : string {
      return root.showOsd(payloadJson) ? "ok" : "unavailable"
    }
    function osdClose() : string { return root.closeOsd() ? "ok" : "closed" }
    function open(pluginId: string) : string {
      var proxy = root.proxyDefinition(pluginId)
      return proxy && root.triggerProxy(proxy) ? "ok" : "unsupported"
    }
    function action(providerId: string, activityId: string, actionId: string) : string {
      return root.routeAction(providerId, activityId, actionId) ? "ok" : "unhandled"
    }
    function reloadConfig() : string { root.reloadConfig(); return "reloading" }
    function inspect() : string { return root.inspectJson() }
  }

  Loader {
    id: retainedWindowLoader
    active: root.retainedWindowEnabled
    source: Qt.resolvedUrl("RetainedWindow.qml")
    onLoaded: {
      if (!item) return
      item.island = root
      item.shell = root.shell
    }
  }
}
