import QtQuick
import Quickshell
import "plugin" as IslandPlugin

ShellRoot {
  id: harness

  readonly property var expectedProviders: [
    "rblalock.now-playing",
    "rblalock.reminders",
    "rblalock.screen-recording",
    "rblalock.system-update"
  ]

  QtObject {
    id: fakeBar
    function focusedScreenName() { return "" }
    function moduleWidgets(pluginId) { return [] }
    function run(command) { return true }
  }

  QtObject {
    id: fakeShell
    property var bar: fakeBar
    function toggle(pluginId, payload) { return true }
    function summon(pluginId, payload) { return true }
    function firstPartyServiceFor(pluginId) { return null }
  }

  QtObject {
    id: registry
    property var installedPlugins: ({})
    function isEnabled(pluginId) { return false }
    function entryPointUrl(candidate, kind) { return "" }
  }

  IslandPlugin.Service {
    id: service
    shell: fakeShell
    manifest: ({
      id: "rblalock.omarchy-island",
      __sourceDir: Quickshell.shellDir + "/plugin"
    })
    pluginRegistry: registry
    retainedWindowEnabled: false
  }

  function fail(message) {
    console.error("BUNDLED_PROVIDERS_FAIL", message, service.inspectJson())
    Qt.exit(51)
  }

  Timer {
    interval: 350
    running: true
    onTriggered: {
      service.userConfig = ({ providers: { disabled: [] } })
      service.discoverProviders()
      verifyTimer.start()
    }
  }

  Timer {
    id: verifyTimer
    interval: 500
    onTriggered: {
      var inspection = service.inspectObject()
      for (var index = 0; index < harness.expectedProviders.length; index++) {
        var providerId = harness.expectedProviders[index]
        var provider = service.providerObjects[providerId]
        var diagnostic = null
        for (var diagnosticIndex = 0;
             diagnosticIndex < inspection.providerDiagnostics.length;
             diagnosticIndex++) {
          var candidate = inspection.providerDiagnostics[diagnosticIndex]
          if (candidate.providerId === providerId && candidate.bundled === true) {
            diagnostic = candidate
            break
          }
        }
        if (!provider || !provider.started || !diagnostic || diagnostic.status !== "loaded"
            || diagnostic.pluginId !== "rblalock.omarchy-island"
            || diagnostic.providerUrl.indexOf("/providers/") === -1)
          return harness.fail("missing bundled provider " + providerId)
      }
      if (inspection.providers.length !== harness.expectedProviders.length)
        return harness.fail("unexpected provider count")
      console.log("BUNDLED_PROVIDERS_OK")
      Qt.quit()
    }
  }
}
