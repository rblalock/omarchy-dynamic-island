import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "OsdModel.js" as OsdModel

Item {
  id: root

  property var ipcCommandPrefix: ["timeout", "1s", "omarchy-shell"]
  property bool cleanupCommandEnabled: true
  property bool fallbackOpened: false
  property bool fallbackWindowEnabled: true
  property bool islandAccepted: false
  property var fallbackEvent: null
  property var acceptedEvent: null
  property var pendingRequest: null
  property var activeRequest: null
  property bool activeRequestAccepted: false
  property int requestSerial: 0
  readonly property bool forwarding: forwardProcess.running || pendingRequest !== null
  signal requestSettled(string kind, bool accepted)

  function startEventTimer(timer, event) {
    if (event && event.duration > 0) timer.restart()
    else timer.stop()
  }

  function showFallback(event) {
    fallbackEvent = event
    fallbackOpened = true
    startEventTimer(fallbackTimer, event)
  }

  function settleRequest(request, accepted) {
    if (!request) return
    var current = request.serial === requestSerial
    if (current && request.kind === "show") {
      islandAccepted = accepted
      if (accepted) {
        acceptedEvent = request.event
        fallbackOpened = false
        fallbackTimer.stop()
        startEventTimer(acceptedTimer, request.event)
      } else {
        acceptedEvent = null
        acceptedTimer.stop()
        showFallback(request.event)
      }
    }
    requestSettled(request.kind, accepted)
  }

  function startPendingRequest() {
    if (forwardProcess.running || !pendingRequest) return
    var request = pendingRequest
    pendingRequest = null
    activeRequest = request
    var prefix = Array.isArray(ipcCommandPrefix) ? ipcCommandPrefix.slice() : []
    if (prefix.length === 0) {
      activeRequest = null
      settleRequest(request, false)
      Qt.callLater(startPendingRequest)
      return
    }
    var args = request.kind === "show"
      ? ["omarchy-island", "osdShow", request.payloadJson]
      : ["omarchy-island", "osdClose"]
    forwardProcess.command = prefix.concat(args)
    forwardProcess.running = true
  }

  function finishActiveRequest() {
    var request = activeRequest
    activeRequest = null
    settleRequest(request, activeRequestAccepted)
    startPendingRequest()
  }

  function open(payloadJson) {
    var next = OsdModel.parse(payloadJson)
    if (!next) return false
    var normalized = OsdModel.forwardJson(next)
    if (normalized === "") return false
    requestSerial++
    islandAccepted = false
    acceptedTimer.stop()
    if (fallbackOpened) showFallback(next)
    pendingRequest = {
      kind: "show",
      serial: requestSerial,
      event: next,
      payloadJson: normalized
    }
    startPendingRequest()
    return true
  }

  function close() {
    requestSerial++
    fallbackTimer.stop()
    acceptedTimer.stop()
    fallbackOpened = false
    islandAccepted = false
    fallbackEvent = null
    acceptedEvent = null
    pendingRequest = { kind: "close", serial: requestSerial }
    startPendingRequest()
    return true
  }

  function state() {
    return forwarding || fallbackOpened || islandAccepted
      ? "open" : "closed"
  }

  Component.onDestruction: {
    if (!cleanupCommandEnabled || requestSerial === 0) return
    Quickshell.execDetached(["timeout", "1s", "omarchy-shell", "-q",
      "omarchy-island", "osdClose"])
  }

  Process {
    id: forwardProcess
    stdout: StdioCollector { id: forwardStdout; waitForEnd: true }
    onExited: function(exitCode) {
      var output = String(forwardStdout.text || "").slice(0, 32).trim()
      root.activeRequestAccepted = exitCode === 0 && output === "ok"
      Qt.callLater(root.finishActiveRequest)
    }
  }

  Timer {
    id: acceptedTimer
    interval: root.acceptedEvent ? Math.max(1, Number(root.acceptedEvent.duration || 1)) : 1200
    onTriggered: {
      root.islandAccepted = false
      root.acceptedEvent = null
    }
  }

  Timer {
    id: fallbackTimer
    interval: root.fallbackEvent ? Math.max(1, Number(root.fallbackEvent.duration || 1)) : 1200
    onTriggered: root.fallbackOpened = false
  }

  IpcHandler {
    target: "osd"
    function show(payloadJson: string): string { return root.open(payloadJson) ? "ok" : "invalid" }
    function close(): string { root.close(); return "ok" }
    function state(): string { return root.state() }
    function ping(): string { return "ok" }
  }

  Loader {
    active: root.fallbackWindowEnabled
    source: active ? Qt.resolvedUrl("OsdFallback.qml") : ""
    onLoaded: if (item) item.bridge = root
  }
}
