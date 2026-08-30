import QtQuick
import Quickshell
import "plugin" as IslandPlugin
import "plugin/components" as IslandComponents

ShellRoot {
  id: harness

  property bool providerEnabled: true

  QtObject {
    id: observer
    property int starts: 0
    property int stops: 0
    property int actions: 0
    property bool running: false
    property string lastAction: ""
  }

  readonly property var healthyManifest: ({
    schemaVersion: 1,
    id: "test.island-provider",
    name: "Hello Island conformance provider",
    version: "1.0.0",
    kinds: ["service"],
    entryPoints: {
      omarchyIslandProvider: "Provider.qml",
      omarchyIslandExpanded: "MissingExpanded.qml"
    },
    omarchyIsland: {
      schemaVersion: 1,
      id: "test.activity",
      capabilities: ["activity-provider", "quick-access", "custom-presentation"],
      displayName: "Test activity",
      quickAccess: {
        id: "test.quick",
        target: "test.panel",
        label: "Test panel",
        glyph: "Q"
      }
    },
    __sourceDir: Quickshell.shellDir + "/provider",
    __testObserver: observer
  })

  readonly property var brokenManifest: ({
    schemaVersion: 1,
    id: "test.broken-provider",
    name: "Broken Island provider",
    version: "1.0.0",
    kinds: ["service"],
    entryPoints: { omarchyIslandProvider: "MissingProvider.qml" },
    omarchyIsland: {
      schemaVersion: 1,
      id: "test.broken",
      capabilities: ["activity-provider"],
      displayName: "Broken provider"
    },
    __sourceDir: Quickshell.shellDir + "/provider"
  })

  readonly property var quickAccessManifest: ({
    schemaVersion: 1,
    id: "test.quick-only",
    name: "Quick access only",
    version: "1.0.0",
    kinds: ["service"],
    entryPoints: {},
    omarchyIsland: {
      schemaVersion: 1,
      id: "test.quick-registration",
      capabilities: ["quick-access"],
      displayName: "Quick access only",
      quickAccess: {
        id: "test.quick-only",
        target: "test.quick-only",
        label: "Quick access only",
        glyph: "Q"
      }
    },
    __sourceDir: Quickshell.shellDir + "/provider"
  })

  QtObject {
    id: fakeBar
    function focusedScreenName() { return "" }
    function moduleWidgets(pluginId) { return [] }
  }

  QtObject {
    id: fakeShell
    property var bar: fakeBar
    function toggle(pluginId, payload) { return true }
    function summon(pluginId, payload) { return true }
  }

  QtObject {
    id: registry
    property var installedPlugins: ({
      "test.island-provider": harness.healthyManifest,
      "test.broken-provider": harness.brokenManifest,
      "test.quick-only": harness.quickAccessManifest
    })
    function isEnabled(pluginId) {
      return pluginId === "test.broken-provider" || pluginId === "test.quick-only"
        || (pluginId === "test.island-provider" && harness.providerEnabled)
    }
    function entryPointUrl(candidate, kind) {
      var entry = candidate && candidate.entryPoints ? candidate.entryPoints[kind] : ""
      return entry ? "file://" + candidate.__sourceDir + "/" + entry : ""
    }
  }

  IslandPlugin.Service {
    id: service
    shell: fakeShell
    manifest: ({ id: "rblalock.omarchy-island" })
    pluginRegistry: registry
    overlayEnabled: false
  }

  IslandComponents.ActivityShelf {
    id: activityShelf
    width: 360
    height: 220
    visible: false
    island: service
  }

  function fail(message) {
    console.error("PROVIDER_CONFORMANCE_FAIL", message, service.inspectJson())
    Qt.exit(41)
  }

  function diagnostic(providerId) {
    var diagnostics = service.inspectObject().providerDiagnostics
    for (var index = 0; index < diagnostics.length; index++)
      if (diagnostics[index].providerId === providerId) return diagnostics[index]
    return null
  }

  Timer {
    interval: 900
    running: true
    onTriggered: {
      var provider = service.providerObjects["test.activity"]
      if (!provider || observer.starts !== 1 || observer.stops !== 0 || !observer.running
          || service.activities.length !== 1 || service.quickAccessItems.length !== 2
          || service.providerObjects["test.broken"] !== undefined)
        return harness.fail("healthy discovery and broken-provider isolation")

      var loadedDiagnostic = harness.diagnostic("test.activity")
      var brokenDiagnostic = harness.diagnostic("test.broken")
      var quickDiagnostic = harness.diagnostic("test.quick-registration")
      if (!loadedDiagnostic || loadedDiagnostic.status !== "loaded"
          || loadedDiagnostic.pluginId !== "test.island-provider"
          || loadedDiagnostic.providerUrl.indexOf("Provider.qml") === -1
          || loadedDiagnostic.quickAccessId !== "test.quick"
          || loadedDiagnostic.activities.length !== 1
          || loadedDiagnostic.activities[0] !== "test.activity:build"
          || loadedDiagnostic.presentations.indexOf("expanded") === -1
          || !brokenDiagnostic || brokenDiagnostic.status !== "failed"
          || brokenDiagnostic.pluginId !== "test.broken-provider"
          || brokenDiagnostic.error === "" || !quickDiagnostic
          || quickDiagnostic.status !== "discovered"
          || quickDiagnostic.quickAccessId !== "test.quick-only"
          || quickDiagnostic.activities.length !== 0)
        return harness.fail("structured provider diagnostics")

      provider.start()
      if (observer.starts !== 1 || service.activities.length !== 1)
        return harness.fail("idempotent start")

      if (!service.update("test.activity", "build", { progress: 0.75 })
          || Math.abs(service.currentActivity.progress - 0.75) > 0.001)
        return harness.fail("semantic update")

      if (!service.withdraw("test.activity", "build") || service.activities.length !== 0
          || !provider.publishActivity() || service.activities.length !== 1)
        return harness.fail("withdraw and republish")

      service.update("test.activity", "build", { primaryAction: "missing" })
      if (service.currentActivity.primaryAction !== "")
        return harness.fail("invalid primary action normalization")

      if (!service.routeAction("test.activity", "build", "run")
          || observer.actions !== 1 || observer.lastAction !== "build:run")
        return harness.fail("typed action routing")

      if (activityShelf.customUrl.indexOf("MissingExpanded.qml") === -1
          || activityShelf.customReady)
        return harness.fail("missing custom view declarative fallback")

      harness.providerEnabled = false
      service.discoverProviders()
      var disabledDiagnostic = harness.diagnostic("test.activity")
      if (service.providerObjects["test.activity"] !== undefined
          || service.activities.length !== 0 || service.quickAccessItems.length !== 1
          || observer.stops !== 1 || observer.running || !disabledDiagnostic
          || disabledDiagnostic.status !== "disabled"
          || disabledDiagnostic.reason !== "plugin-disabled"
          || disabledDiagnostic.activities.length !== 0)
        return harness.fail("disable cleanup")

      harness.providerEnabled = true
      service.discoverProviders()
      var reenabledDiagnostic = harness.diagnostic("test.activity")
      if (!service.providerObjects["test.activity"] || service.activities.length !== 1
          || service.quickAccessItems.length !== 2 || observer.starts !== 2
          || observer.stops !== 1 || !observer.running || !reenabledDiagnostic
          || reenabledDiagnostic.status !== "loaded"
          || reenabledDiagnostic.activities.length !== 1)
        return harness.fail("re-enable lifecycle")

      service.discoverProviders()
      if (observer.starts !== 2 || service.activities.length !== 1)
        return harness.fail("stable rediscovery")

      console.log("PROVIDER_CONFORMANCE_OK")
      Qt.quit()
    }
  }
}
