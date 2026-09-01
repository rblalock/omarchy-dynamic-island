import QtQuick
import Quickshell
import "plugin" as IslandPlugin
import "plugin/components" as IslandComponents
import "plugin/lib/ProviderContract.js" as ProviderContract

ShellRoot {
  id: harness

  property bool providerEnabled: true
  property bool replacementEnabled: false

  QtObject {
    id: observer
    property int starts: 0
    property int stops: 0
    property int actions: 0
    property bool running: false
    property string lastAction: ""
    property bool throwActions: false
  }

  QtObject {
    id: replacementObserver
    property int starts: 0
    property int stops: 0
    property int actions: 0
    property bool running: false
    property string lastAction: ""
    property bool throwActions: false
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

  readonly property var invalidSchemaManifest: ({
    schemaVersion: 1,
    id: "test.invalid-schema",
    name: "Invalid schema",
    entryPoints: {},
    omarchyIsland: {
      schemaVersion: 2,
      id: "test.invalid-schema",
      capabilities: ["quick-access"],
      quickAccess: { target: "test.invalid-schema" }
    },
    __sourceDir: Quickshell.shellDir + "/provider"
  })

  readonly property var invalidCapabilitiesManifest: ({
    schemaVersion: 1,
    id: "test.invalid-capabilities",
    name: "Invalid capabilities",
    entryPoints: { omarchyIslandProvider: "Provider.qml" },
    omarchyIsland: {
      schemaVersion: 1,
      id: "test.invalid-capabilities",
      capabilities: []
    },
    __sourceDir: Quickshell.shellDir + "/provider"
  })

  readonly property var replacementManifest: ({
    schemaVersion: 1,
    id: "test.system-update-replacement",
    name: "System update replacement",
    entryPoints: { omarchyIslandProvider: "Provider.qml" },
    omarchyIsland: {
      schemaVersion: 1,
      id: "rblalock.system-update",
      capabilities: ["activity-provider"],
      displayName: "System update replacement"
    },
    __sourceDir: Quickshell.shellDir + "/provider",
    __testObserver: replacementObserver
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
      "test.quick-only": harness.quickAccessManifest,
      "test.invalid-schema": harness.invalidSchemaManifest,
      "test.invalid-capabilities": harness.invalidCapabilitiesManifest,
      "test.system-update-replacement": harness.replacementManifest
    })
    function isEnabled(pluginId) {
      return pluginId === "test.broken-provider" || pluginId === "test.quick-only"
        || pluginId === "test.invalid-schema" || pluginId === "test.invalid-capabilities"
        || (pluginId === "test.island-provider" && harness.providerEnabled)
        || (pluginId === "test.system-update-replacement" && harness.replacementEnabled)
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
    retainedWindowEnabled: false
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
      var schemaDiagnostic = harness.diagnostic("test.invalid-schema")
      var capabilitiesDiagnostic = harness.diagnostic("test.invalid-capabilities")
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
          || quickDiagnostic.activities.length !== 0
          || !schemaDiagnostic || schemaDiagnostic.status !== "failed"
          || schemaDiagnostic.error.indexOf("schemaVersion") === -1
          || !capabilitiesDiagnostic || capabilitiesDiagnostic.status !== "failed"
          || capabilitiesDiagnostic.error.indexOf("declared together") === -1)
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
      service.update("test.activity", "build", {
        actions: [
          { id: "run", label: "Run" },
          { id: "", label: "Missing ID" },
          { id: "run", label: "Duplicate" }
        ]
      })
      if (service.currentActivity.actions.length !== 1
          || service.currentActivity.actions[0].label !== "Run")
        return harness.fail("declared action normalization")

      var longDisplay = ""
      for (var displayIndex = 0; displayIndex < ProviderContract.limits.maxSubtitleChars + 20;
           displayIndex++) longDisplay += "x"
      var boundedActions = [{ id: "run", label: longDisplay, glyph: longDisplay }]
      for (var actionIndex = 1;
           actionIndex < ProviderContract.limits.maxActionsPerActivity + 1; actionIndex++)
        boundedActions.push({ id: "action-" + actionIndex, label: "Action " + actionIndex })
      var providerData = { nested: { value: "before" } }
      if (!service.update("test.activity", "build", {
          title: longDisplay,
          subtitle: longDisplay,
          glyph: longDisplay,
          data: providerData,
          actions: boundedActions,
          event: { id: "bounded-event", title: longDisplay, subtitle: longDisplay, glyph: longDisplay },
          unknownField: longDisplay
        })) return harness.fail("bounded activity setup")
      providerData.nested.value = "after"
      var boundedActivity = service.currentActivity
      if (boundedActivity.title.length !== ProviderContract.limits.maxTitleChars
          || boundedActivity.subtitle.length !== ProviderContract.limits.maxSubtitleChars
          || boundedActivity.glyph.length !== ProviderContract.limits.maxGlyphChars
          || boundedActivity.actions.length !== ProviderContract.limits.maxActionsPerActivity
          || boundedActivity.actions[0].label.length !== ProviderContract.limits.maxLabelChars
          || boundedActivity.actions[0].glyph.length !== ProviderContract.limits.maxGlyphChars
          || boundedActivity.event.title.length !== ProviderContract.limits.maxTitleChars
          || boundedActivity.unknownField !== undefined
          || boundedActivity.data.nested.value !== "before")
        return harness.fail("bounded activity normalization")
      service.clearEvent()

      var longIdentifier = ""
      for (var identifierIndex = 0;
           identifierIndex < ProviderContract.limits.maxIdentifierChars + 1; identifierIndex++)
        longIdentifier += "i"
      var retainedActivity = service.currentActivity
      if (service.publish("test.activity", { id: longIdentifier, title: "Rejected" })
          || service.currentActivity !== retainedActivity)
        return harness.fail("overlong activity id rejection")
      var retainedErrors = JSON.stringify(service.providerActivityErrors)
      if (service.publish(longIdentifier, { id: "unknown-provider", title: "Rejected" })
          || JSON.stringify(service.providerActivityErrors) !== retainedErrors)
        return harness.fail("unknown provider diagnostic retention")

      var oversizedData = { value: longDisplay }
      while (JSON.stringify(oversizedData).length <= ProviderContract.limits.maxDataBytes)
        oversizedData.value += longDisplay
      if (service.update("test.activity", "build", { data: oversizedData })
          || service.currentActivity !== retainedActivity
          || harness.diagnostic("test.activity").error.indexOf("data exceeds") === -1)
        return harness.fail("oversized activity data rejection")
      service.discoverProviders()
      if (harness.diagnostic("test.activity").error.indexOf("data exceeds") === -1)
        return harness.fail("provider activity error discovery retention")
      var circularData = ({})
      circularData.self = circularData
      if (service.update("test.activity", "build", { data: circularData })
          || service.currentActivity !== retainedActivity)
        return harness.fail("circular activity data rejection")
      if (!service.update("test.activity", "build", { data: { healthy: true } })
          || harness.diagnostic("test.activity").error !== "")
        return harness.fail("provider activity error recovery")

      var providerSaturation = []
      for (var providerLimitIndex = 0;
           providerLimitIndex < ProviderContract.limits.maxActivitiesPerProvider;
           providerLimitIndex++)
        providerSaturation.push(service.normalizeActivity("limit.provider",
          { id: "activity-" + providerLimitIndex, title: "Bounded" }))
      var originalActivities = service.activities
      service.activities = providerSaturation
      if (service.publish("limit.provider", { id: "overflow", title: "Rejected" })
          || !service.publish("limit.provider", { id: "activity-0", title: "Replacement" }))
        return harness.fail("per-provider activity count boundary")

      var globalSaturation = []
      for (var globalLimitIndex = 0;
           globalLimitIndex < ProviderContract.limits.maxActivitiesTotal; globalLimitIndex++)
        globalSaturation.push(service.normalizeActivity("global-"
          + Math.floor(globalLimitIndex / ProviderContract.limits.maxActivitiesPerProvider),
          { id: "activity-" + globalLimitIndex, title: "Bounded" }))
      service.activities = globalSaturation
      if (service.publish("global-overflow", { id: "overflow", title: "Rejected" })
          || !service.publish("global-0", { id: "activity-0", title: "Replacement" }))
        return harness.fail("global activity count boundary")
      service.activities = originalActivities

      if (!service.routeAction("test.activity", "build", "run")
          || observer.actions !== 1 || observer.lastAction !== "build:run")
        return harness.fail("typed action routing")
      if (service.routeAction("test.activity", "build", "missing"))
        return harness.fail("undeclared action rejection")
      observer.throwActions = true
      if (service.routeAction("test.activity", "build", "run")
          || harness.diagnostic("test.activity").error.indexOf("fixture action failure") === -1)
        return harness.fail("provider action failure isolation")
      observer.throwActions = false

      if (activityShelf.customUrl.indexOf("MissingExpanded.qml") === -1
          || activityShelf.customReady)
        return harness.fail("missing custom view declarative fallback")

      harness.providerEnabled = false
      service.update("test.activity", "build", {
        event: { id: "disable-event", title: "Provider event" }
      })
      if (!service.eventActive) return harness.fail("provider event setup")
      service.discoverProviders()
      var disabledDiagnostic = harness.diagnostic("test.activity")
      if (service.providerObjects["test.activity"] !== undefined
          || service.activities.length !== 0 || service.quickAccessItems.length !== 1
          || observer.stops !== 1 || observer.running || !disabledDiagnostic
          || service.eventActive
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

      var conformanceConfig = service.copyObject(service.userConfig)
      var providerPolicy = service.copyObject(conformanceConfig.providers)
      providerPolicy.disabled = (providerPolicy.disabled || []).filter(function(providerId) {
        return providerId !== "rblalock.system-update"
      })
      conformanceConfig.providers = providerPolicy
      service.userConfig = conformanceConfig
      service.discoverProviders()
      var bundledOwner = service.providerManifests["rblalock.system-update"]
      if (!bundledOwner || !bundledOwner.__isBundledIslandProvider)
        return harness.fail("bundled provider setup")
      harness.replacementEnabled = true
      service.discoverProviders()
      var externalOwner = service.providerManifests["rblalock.system-update"]
      if (!externalOwner || externalOwner.id !== "test.system-update-replacement"
          || replacementObserver.starts !== 1)
        return harness.fail("external provider supersession")
      harness.replacementEnabled = false
      service.discoverProviders()
      var restoredOwner = service.providerManifests["rblalock.system-update"]
      if (!restoredOwner || !restoredOwner.__isBundledIslandProvider
          || replacementObserver.stops !== 1)
        return harness.fail("single-pass bundled provider failback")

      console.log("PROVIDER_CONFORMANCE_OK")
      Qt.quit()
    }
  }
}
