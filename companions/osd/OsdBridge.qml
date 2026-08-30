import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "OsdModel.js" as OsdModel

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool fallbackOpened: false
  property bool fallbackWindowEnabled: true
  property bool islandAccepted: false
  property var fallbackEvent: null

  function islandService() {
    return shell && typeof shell.serviceFor === "function"
      ? shell.serviceFor("rblalock.omarchy-island") : null
  }

  function open(payloadJson) {
    var island = islandService()
    islandAccepted = false
    if (island && typeof island.showOsd === "function") {
      try { islandAccepted = island.showOsd(payloadJson) === true }
      catch (error) { islandAccepted = false }
    }
    if (islandAccepted) {
      fallbackOpened = false
      fallbackTimer.stop()
      return true
    }

    var next = OsdModel.parse(payloadJson)
    if (!next) return false
    fallbackEvent = next
    fallbackOpened = true
    if (next.duration > 0) fallbackTimer.restart()
    else fallbackTimer.stop()
    return true
  }

  function close() {
    var island = islandService()
    if (island && typeof island.closeOsd === "function") {
      try { island.closeOsd() } catch (error) {}
    }
    fallbackTimer.stop()
    fallbackOpened = false
    islandAccepted = false
  }

  function state() {
    var island = islandService()
    return fallbackOpened || (island && island.osdEvent && island.transientKind === "osd")
      ? "open" : "closed"
  }

  Component.onDestruction: close()

  Timer {
    id: fallbackTimer
    interval: root.fallbackEvent ? Math.max(1, Number(root.fallbackEvent.duration || 1)) : 1200
    onTriggered: root.fallbackOpened = false
  }

  IpcHandler {
    target: "osd"
    function show(payloadJson: string): string { root.open(payloadJson); return "ok" }
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
