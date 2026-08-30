import QtQuick
import Quickshell.Hyprland
import qs.Commons

NavigableSurface {
  id: root
  property var island: null
  implicitHeight: workspaceFlow.implicitHeight

  Flow {
    id: workspaceFlow
    width: parent.width
    spacing: Style.space(8)

    Repeater {
      model: root.island ? root.island.workspaceIds : []

      ShelfButton {
        required property int modelData
        readonly property var workspace: {
          var values = Hyprland.workspaces.values
          for (var i = 0; i < values.length; i++) if (values[i].id === modelData) return values[i]
          return null
        }
        readonly property bool occupied: workspace && workspace.toplevels
          ? workspace.toplevels.values.length > 0 : false
        readonly property bool focused: Hyprland.focusedWorkspace
          ? Hyprland.focusedWorkspace.id === modelData : false

        compact: true
        cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        glyph: modelData === 10 ? "0" : String(modelData)
        active: focused
        opacity: occupied || focused ? 1 : 0.5
        accessibleName: "Switch to workspace " + modelData
        onActivated: root.island.focusWorkspace(modelData)
      }
    }
  }
}
