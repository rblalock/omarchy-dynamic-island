import QtQuick
import Quickshell
import Quickshell.Io
import "plugin" as IslandPlugin

ShellRoot {
  id: harness

  readonly property var providerManifest: ({
    schemaVersion: 1,
    id: "test.island-provider",
    name: "Test Island provider",
    version: "1.0.0",
    kinds: ["service"],
    entryPoints: {
      omarchyIslandProvider: "Provider.qml",
      omarchyIslandMinimal: "Minimal.qml",
      omarchyIslandCompact: "Compact.qml",
      omarchyIslandExpanded: "Expanded.qml"
    },
    omarchyIsland: { id: "test.activity", displayName: "Test activity" },
    __sourceDir: Quickshell.shellDir + "/provider"
  })

  QtObject {
    id: fakeBar
    function focusedScreenName() { return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "" }
    function moduleWidgets(pluginId) { return [] }
  }

  QtObject {
    id: fakeShell
    property var bar: fakeBar
    property var barConfig: ({ layout: { left: [], center: [{ id: "omarchy.clock" }], right: [] } })
    function toggle(pluginId, payload) { return true }
    function summon(pluginId, payload) { return true }
  }

  QtObject {
    id: fakePluginRegistry
    property var installedPlugins: ({ "test.island-provider": harness.providerManifest })
    function isEnabled(pluginId) { return pluginId === "test.island-provider" }
    function entryPointUrl(candidate, kind) {
      return "file://" + candidate.__sourceDir + "/" + candidate.entryPoints[kind]
    }
  }

  IslandPlugin.Service {
    id: service
    shell: fakeShell
    manifest: ({ id: "rblalock.omarchy-island" })
    pluginRegistry: fakePluginRegistry
  }

  QtObject {
    id: dummyBarHost
    property string hostScreenName: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    function handleKeyboardKey(key, modifiers) { return false }
  }

  Component.onCompleted: service.registerBarHost(dummyBarHost)

  function configure() {
    service.userConfig = ({
      placement: { top_offset: 72 },
      appearance: { shelf_width: 430, focus_height: 224, allow_custom_qml: true },
      behavior: { collapse_delay_ms: 95 },
      motion: { enabled: true, expand_ms: 260, collapse_ms: 180, content_ms: 150 },
      layout: { rest_content: "auto", peek: [], include_clock: true }
    })
  }

  function restoreActivity() {
    service.activities = []
    var provider = service.providerObjects["test.activity"]
    if (provider && typeof provider.start === "function") provider.start()
  }

  Timer {
    interval: 700
    running: true
    onTriggered: {
      harness.configure()
      harness.restoreActivity()
      service.openFocus("activity")
    }
  }

  IpcHandler {
    target: "omarchy-island-visual"
    function customFocus(): string {
      harness.configure(); harness.restoreActivity(); service.openFocus("activity"); return "custom-focus"
    }
    function broken(): string {
      harness.configure(); harness.restoreActivity()
      var broken = service.copyObject(service.currentActivity)
      broken.views = service.copyObject(broken.views)
      broken.views.expanded = "file:///definitely-missing-omarchy-island-view.qml"
      service.activities = [broken]
      service.openFocus("activity")
      return "broken-fallback"
    }
    function inspect(): string { return service.inspectJson() }
  }
}
