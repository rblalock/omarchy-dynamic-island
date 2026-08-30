import QtQuick
import qs.Commons

NavigableSurface {
  id: root
  property var island: null
  readonly property var activity: island ? island.selectedActivity : null
  readonly property var activities: island ? island.rankedActivities : []
  readonly property bool selectorVisible: island && !island.eventActive && activities.length > 1
  readonly property real selectorHeight: selectorVisible ? Style.space(52) : 0
  readonly property string customUrl: island && activity
    ? island.presentationUrl(activity, "expanded") : ""
  readonly property bool customReady: customView.active && customView.status === Loader.Ready && customView.item

  function injectCustom() {
    if (!customView.item) return
    if ("island" in customView.item) customView.item.island = root.island
    if ("activity" in customView.item) customView.item.activity = root.activity
    if ("bar" in customView.item) customView.item.bar = root.island ? root.island.stockBar() : null
  }

  onActivityChanged: injectCustom()
  onIslandChanged: injectCustom()

  function ensureSelectorVisible(item) {
    if (!item || selector.contentWidth <= selector.width) return
    var position = item.mapToItem(selector.contentItem, 0, 0)
    var margin = Style.space(4)
    if (position.x < selector.contentX + margin)
      selector.contentX = Math.max(0, position.x - margin)
    else if (position.x + item.width > selector.contentX + selector.width - margin)
      selector.contentX = Math.min(selector.contentWidth - selector.width,
        position.x + item.width - selector.width + margin)
  }

  Flickable {
    id: selector
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: root.selectorVisible ? Style.space(44) : 0
    visible: root.selectorVisible
    clip: true
    contentWidth: selectorRow.implicitWidth
    contentHeight: height
    interactive: contentWidth > width
    boundsBehavior: Flickable.StopAtBounds

    Row {
      id: selectorRow
      height: parent.height
      spacing: Style.space(4)

      Repeater {
        model: root.activities

        ShelfButton {
          required property var modelData
          width: Style.space(44)
          height: Style.space(44)
          compact: true
          glyph: String(modelData.glyph || "󰐕")
          active: root.activity && root.activity.key === modelData.key
          cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
          accessibleName: String(modelData.title || modelData.providerId || "Activity")
          onActiveFocusChanged: if (activeFocus) root.ensureSelectorVisible(this)
          onActivated: if (root.island) root.island.selectActivity(modelData.key)
        }
      }
    }
  }

  Item {
    id: detail
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.topMargin: root.selectorHeight
    anchors.bottom: parent.bottom

  Loader {
    id: customView
    anchors.fill: parent
    active: root.customUrl !== ""
    source: active ? root.customUrl : ""
    onLoaded: root.injectCustom()
  }

  Column {
    id: fallback
    anchors.fill: parent
    visible: !root.customReady
    spacing: Style.space(10)

    Row {
      width: parent.width
      spacing: Style.space(10)

      Text {
        text: root.activity ? root.activity.glyph : "󰐕"
        color: root.activity && root.activity.attention === "critical" ? Color.urgent : Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        renderType: Text.NativeRendering
      }

      Column {
        width: parent.width - x
        spacing: Style.space(2)

        Text {
          width: parent.width
          text: root.activity ? root.activity.title : "Nothing needs your attention"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
          font.weight: Font.DemiBold
          elide: Text.ElideRight
          renderType: Text.NativeRendering
        }

        Text {
          width: parent.width
          visible: text !== ""
          text: root.activity ? root.activity.subtitle : "Island-native plugins will appear here."
          color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.64)
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
          renderType: Text.NativeRendering
        }
      }
    }

    Rectangle {
      width: parent.width
      height: Style.space(4)
      radius: height / 2
      visible: root.activity && typeof root.activity.progress === "number"
        && root.activity.progress >= 0 && root.activity.progress <= 1
      color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.12)

      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, Number(root.activity ? root.activity.progress : 0)))
        height: parent.height
        radius: height / 2
        color: Color.accent
      }
    }

    Flow {
      width: parent.width
      spacing: Style.space(8)
      visible: root.activity && root.activity.actions && root.activity.actions.length > 0

      Repeater {
        model: root.activity && root.activity.actions ? root.activity.actions : []

        ShelfButton {
          required property var modelData
          width: Style.space(118)
          height: Style.space(44)
          glyph: String(modelData.glyph || "")
          label: String(modelData.label || modelData.id || "Action")
          cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
          accessibleName: label
          onActivated: if (root.activity) root.island.routeAction(
            root.activity.providerId, root.activity.id, String(modelData.id || ""))
        }
      }
    }
  }
  }
}
