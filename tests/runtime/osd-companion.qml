import QtQuick
import Quickshell
import "osd_companion" as Companion

ShellRoot {
  id: harness

  property int phase: 0
  property int coalescedSettles: 0
  readonly property var successCommand: ["/usr/bin/printf", "ok\n"]
  readonly property var unavailableCommand: ["/usr/bin/printf", "unavailable\n"]

  function fail(message) {
    console.error("OSD_COMPANION_FAIL " + message)
    Qt.exit(2)
  }

  function repeated(character, count) {
    var result = ""
    for (var index = 0; index < count; index++) result += character
    return result
  }

  function begin() {
    phase = 1
    bridge.ipcCommandPrefix = successCommand
    if (!bridge.open('{"icon":"volume","value":55}')) fail("start Island forwarding")
  }

  Companion.OsdBridge {
    id: bridge
    fallbackWindowEnabled: false
    cleanupCommandEnabled: false
  }

  Connections {
    target: bridge

    function onRequestSettled(kind, accepted) {
      if (harness.phase === 1) {
        if (kind !== "show" || !accepted || !bridge.islandAccepted
            || bridge.fallbackOpened || !bridge.acceptedEvent
            || bridge.acceptedEvent.message !== "55%" || bridge.state() !== "open") {
          harness.fail("Island forwarding")
          return
        }
        harness.phase = 2
        bridge.close()
        return
      }

      if (harness.phase === 2) {
        if (kind !== "close" || bridge.fallbackOpened || bridge.islandAccepted
            || bridge.state() !== "closed") {
          harness.fail("accepted close lifecycle")
          return
        }
        harness.phase = 3
        bridge.ipcCommandPrefix = harness.unavailableCommand
        if (!bridge.open('{"icon":"brightness","value":12,"max":20,'
            + '"progressText":"Level 12","duration":0}')) {
          harness.fail("start fallback parity")
        }
        return
      }

      if (harness.phase === 3) {
        if (kind !== "show" || accepted || bridge.islandAccepted
            || !bridge.fallbackOpened || !bridge.fallbackEvent
            || !bridge.fallbackEvent.hasProgress || bridge.fallbackEvent.value !== 12
            || bridge.fallbackEvent.maxValue !== 20
            || bridge.fallbackEvent.message !== "Level 12"
            || bridge.fallbackEvent.duration !== 0 || bridge.state() !== "open") {
          harness.fail("fallback parity")
          return
        }
        harness.phase = 4
        bridge.close()
        return
      }

      if (harness.phase === 4) {
        harness.phase = 5
        if (!bridge.open('{"icon":"volume","value":25,"max":"not-a-number"}'))
          harness.fail("start invalid maximum normalization")
        return
      }

      if (harness.phase === 5) {
        if (!bridge.fallbackEvent || bridge.fallbackEvent.maxValue !== 100
            || Math.abs(bridge.fallbackEvent.progress - 0.25) > 0.001) {
          harness.fail("invalid maximum normalization")
          return
        }
        harness.phase = 6
        bridge.close()
        return
      }

      if (harness.phase === 6) {
        var oversized = '{"message":"' + harness.repeated("x", 5000) + '"}'
        if (bridge.open(oversized)) {
          harness.fail("oversized payload accepted")
          return
        }
        harness.phase = 7
        var bounded = JSON.stringify({
          icon: harness.repeated("i", 100),
          message: harness.repeated("m", 500),
          duration: 999999
        })
        if (!bridge.open(bounded)) harness.fail("start bounded fields")
        return
      }

      if (harness.phase === 7) {
        if (!bridge.fallbackEvent || bridge.fallbackEvent.sourceIcon.length !== 64
            || bridge.fallbackEvent.message.length !== 256
            || bridge.fallbackEvent.duration !== 60000) {
          harness.fail("bounded fields")
          return
        }
        harness.phase = 8
        bridge.close()
        return
      }

      if (harness.phase === 8) {
        harness.phase = 9
        harness.coalescedSettles = 0
        bridge.ipcCommandPrefix = harness.successCommand
        if (!bridge.open('{"icon":"volume","value":10,"duration":0}')
            || !bridge.open('{"icon":"volume","value":20,"duration":0}')) {
          harness.fail("start coalesced forwarding")
        }
        return
      }

      if (harness.phase === 9) {
        harness.coalescedSettles++
        if (harness.coalescedSettles < 2) return
        if (!accepted || !bridge.islandAccepted || !bridge.acceptedEvent
            || bridge.acceptedEvent.value !== 20 || bridge.fallbackOpened) {
          harness.fail("latest coalesced forwarding")
          return
        }
        harness.phase = 10
        bridge.close()
        return
      }

      if (harness.phase === 10) {
        if (bridge.fallbackOpened || bridge.islandAccepted || bridge.state() !== "closed") {
          harness.fail("final close lifecycle")
          return
        }
        console.log("OSD_COMPANION_OK")
        Qt.quit()
      }
    }
  }

  Timer {
    interval: 250
    running: true
    onTriggered: harness.begin()
  }
}
