import QtQuick
import qs.Commons

NavigableSurface {
  id: root
  property var island: null
  implicitHeight: statusFlow.implicitHeight

  Flow {
    id: statusFlow
    width: parent.width
    spacing: Style.space(8)
    readonly property int columnCount: Math.max(1, Math.min(3,
      Math.floor((width + spacing) / (Style.space(118) + spacing))))
    readonly property real columnWidth: (width - spacing * (columnCount - 1)) / columnCount

    Repeater {
      model: root.island ? root.island.indicatorItems : []

      ShelfButton {
        required property var modelData
        width: statusFlow.columnWidth
        glyph: String(modelData.glyph || "")
        label: String(modelData.label || modelData.id)
        description: modelData.active ? "On" : "Off"
        active: Boolean(modelData.active)
        cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        accessibleName: "Toggle " + label
        onActivated: root.island.triggerIndicator(String(modelData.id || ""))
      }
    }
  }
}
