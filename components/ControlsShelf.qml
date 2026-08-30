import QtQuick
import qs.Commons

NavigableSurface {
  id: root
  property var island: null
  readonly property var items: island ? island.peekItems : []
  readonly property real gap: Style.space(8)
  readonly property int columnCount: Math.max(1, Math.min(3,
    Math.floor((width + gap) / (Style.space(118) + gap))))
  readonly property real columnWidth: (width - gap * (columnCount - 1)) / columnCount
  implicitHeight: controlsRows.implicitHeight

  Column {
    id: controlsRows
    width: parent.width
    spacing: root.gap

    Repeater {
      model: Math.ceil(root.items.length / root.columnCount)

      Row {
        id: controlsRow
        required property int index
        readonly property int firstItem: index * root.columnCount
        readonly property int itemCount: Math.min(root.columnCount, root.items.length - firstItem)
        anchors.horizontalCenter: parent.horizontalCenter
        width: itemCount * root.columnWidth + Math.max(0, itemCount - 1) * spacing
        height: Style.space(58)
        spacing: root.gap

        Repeater {
          model: controlsRow.itemCount

          ShelfButton {
            required property int index
            readonly property var itemData: root.items[controlsRow.firstItem + index]
            readonly property bool activityProxy: String(itemData.id || "") === "omarchy-island.activities"
            readonly property var liveActivity: activityProxy && root.island
              ? root.island.displayActivity : null
            width: root.columnWidth
            glyph: String(liveActivity ? (liveActivity.glyph || "󰐕") : (itemData.glyph || "󰘔"))
            iconKind: String(itemData.iconKind || "")
            label: String(liveActivity
              ? liveActivity.title : (itemData.label || itemData.id || "Control"))
            description: {
              if (itemData.kind === "shelf") return "Open shelf"
              if (itemData.kind === "focus") return "Open focus"
              if (itemData.kind === "quick-access") return "Quick access"
              if (itemData.kind === "fallback") return "Plugin surface"
              return "System panel"
            }
            cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
            accessibleName: label
            onActivated: root.island.triggerProxy(itemData, Boolean(root.island.keyboardEntryActive))
          }
        }
      }
    }
  }
}
