import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var island: null
  property var shell: null
  property var manifest: null
  property string providerId: "rblalock.system-update"
  property bool started: false
  property string checkOutput: ""
  property string semanticSignature: ""
  property double semanticUpdatedAt: 0
  property var updateStateOverride: null
  property var actionHandler: null

  readonly property var stockUpdateWidget: {
    if (!shell || !shell.bar || typeof shell.bar.moduleWidgets !== "function") return null
    var widgets = shell.bar.moduleWidgets("omarchy.system-update")
    return widgets && widgets.length > 0 ? widgets[0] : null
  }

  function updateLines(text) {
    return String(text || "").split("\n").map(function(line) {
      return String(line).trim()
    }).filter(function(line) { return line !== "" })
  }

  function publishAvailable(lines) {
    if (!started || !island) return false
    var updates = Array.isArray(lines) ? lines : []
    var detail = updates.length > 0 ? updates[0] : "Ready to install"
    var signature = updates.join("|")
    if (signature !== semanticSignature || semanticUpdatedAt <= 0) {
      semanticSignature = signature
      semanticUpdatedAt = Date.now()
    }
    return island.publish(providerId, {
      id: "system-update",
      title: "Omarchy update available",
      subtitle: updates.length > 1 ? detail + " · " + updates.length + " updates" : detail,
      glyph: "",
      attention: "routine",
      presentation: { rest: "companion" },
      updatedAt: semanticUpdatedAt,
      expiresAt: Date.now() + checkTimer.interval + 600000,
      data: { updates: updates },
      primaryAction: "update",
      actions: [
        { id: "update", label: "Open Omarchy update", glyph: "" }
      ]
    })
  }

  function withdraw() {
    semanticSignature = ""
    semanticUpdatedAt = 0
    if (island) island.withdraw(providerId, "system-update")
  }

  function acceptResult(exitCode, text) {
    if (!started) return
    if (Number(exitCode) === 0) publishAvailable(updateLines(text))
    else if (Number(exitCode) === 1) withdraw()
    else console.warn("Omarchy Island system update: availability check failed with exit " + exitCode)
  }

  function acceptOverride(value) {
    var state = value || ({})
    if (state.available) {
      var lines = Array.isArray(state.updates) ? state.updates
        : updateLines(String(state.detail || "Ready to install"))
      publishAvailable(lines)
    } else withdraw()
  }

  function refresh() {
    if (!started) return false
    if (updateStateOverride !== null) {
      acceptOverride(updateStateOverride)
      return true
    }
    if (checkProcess.running) return false
    checkOutput = ""
    checkProcess.running = true
    return true
  }

  function start() {
    started = true
    refresh()
  }

  function stop() {
    started = false
    checkTimer.stop()
    if (checkProcess.running) checkProcess.running = false
    withdraw()
  }

  function runUpdate() {
    if (actionHandler && typeof actionHandler.run === "function")
      return actionHandler.run("update") === true
    if (shell && shell.bar && typeof shell.bar.run === "function") {
      shell.bar.run("omarchy-launch-floating-terminal-with-presentation omarchy-update")
      return true
    }
    Quickshell.execDetached([
      "omarchy-launch-floating-terminal-with-presentation", "omarchy-update"
    ])
    return true
  }

  function onAction(activityId, actionId) {
    if (activityId === "system-update" && actionId === "update") runUpdate()
  }

  onStockUpdateWidgetChanged: {
    if (!started || !stockUpdateWidget) return
    if (stockUpdateWidget.updateAvailable) refresh()
    else withdraw()
  }

  Connections {
    target: root.stockUpdateWidget
    enabled: root.started && root.stockUpdateWidget !== null
    ignoreUnknownSignals: true
    function onUpdateAvailableChanged() {
      if (root.stockUpdateWidget.updateAvailable) root.refresh()
      else root.withdraw()
    }
  }

  Process {
    id: checkProcess
    command: ["timeout", "20s", "omarchy", "update", "available"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.checkOutput = text
    }
    onExited: function(exitCode) {
      Qt.callLater(function() { root.acceptResult(exitCode, root.checkOutput) })
    }
  }

  Timer {
    id: checkTimer
    interval: 21600000
    repeat: true
    running: root.started && root.updateStateOverride === null
    onTriggered: root.refresh()
  }
}
