import QtQuick
import Quickshell
import "osd_companion" as Companion

ShellRoot {
  id: harness

  property bool acceptIsland: true
  property int forwardedCount: 0
  property int closedCount: 0

  QtObject {
    id: islandService
    property var osdEvent: null
    property string transientKind: ""
    function showOsd(payloadJson) {
      harness.forwardedCount++
      if (!harness.acceptIsland) return false
      osdEvent = JSON.parse(payloadJson)
      transientKind = "osd"
      return true
    }
    function closeOsd() {
      harness.closedCount++
      osdEvent = null
      transientKind = ""
      return true
    }
  }

  QtObject {
    id: fakeShell
    function serviceFor(pluginId) {
      return pluginId === "rblalock.omarchy-island" ? islandService : null
    }
  }

  Companion.OsdBridge { id: bridge; shell: fakeShell; fallbackWindowEnabled: false }

  Timer {
    interval: 250
    running: true
    onTriggered: {
      if (!bridge.open('{"icon":"volume","value":55}')
          || !bridge.islandAccepted || bridge.fallbackOpened
          || harness.forwardedCount !== 1 || bridge.state() !== "open") {
        console.error("OSD_COMPANION_FAIL Island forwarding")
        Qt.exit(2)
        return
      }
      bridge.close()
      harness.acceptIsland = false
      if (!bridge.open('{"icon":"brightness","value":12,"max":20,"progressText":"Level 12","duration":0}')
          || bridge.islandAccepted || !bridge.fallbackOpened || !bridge.fallbackEvent
          || !bridge.fallbackEvent.hasProgress || bridge.fallbackEvent.value !== 12
          || bridge.fallbackEvent.maxValue !== 20 || bridge.fallbackEvent.message !== "Level 12"
          || bridge.fallbackEvent.duration !== 0 || bridge.state() !== "open") {
        console.error("OSD_COMPANION_FAIL fallback parity")
        Qt.exit(3)
        return
      }
      bridge.close()
      if (bridge.fallbackOpened || bridge.state() !== "closed" || harness.closedCount < 2) {
        console.error("OSD_COMPANION_FAIL close lifecycle")
        Qt.exit(4)
        return
      }
      console.log("OSD_COMPANION_OK")
      Qt.quit()
    }
  }
}
