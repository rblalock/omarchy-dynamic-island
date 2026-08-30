import QtQuick
import qs.Commons

NavigableSurface {
  id: root
  property var island: null
  implicitHeight: root.island && root.island.trayItems.length > 0
    ? trayFlow.implicitHeight : Style.space(44)

  Text {
    visible: !root.island || root.island.trayItems.length === 0
    anchors.centerIn: parent
    text: "No tray applications are reporting."
    color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.62)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
  }

  Flow {
    id: trayFlow
    width: parent.width
    spacing: Style.space(8)

    Repeater {
      model: root.island ? root.island.trayItems : []

      ShelfButton {
        id: trayButton
        required property var modelData
        compact: true
        cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        glyph: ""
        accessibleName: String(modelData.tooltipTitle || modelData.title || modelData.id || "Tray application")
        onActivated: root.island.activateTrayItem(modelData, "activate", trayButton)
        onSecondaryActivated: root.island.activateTrayItem(modelData, "secondary", trayButton)
        onMenuRequested: function(anchor) { root.island.activateTrayItem(modelData, "menu", anchor) }

        Image {
          anchors.centerIn: parent
          width: Style.space(18)
          height: Style.space(18)
          fillMode: Image.PreserveAspectFit
          source: String(trayButton.modelData.icon || "")
          sourceSize.width: Math.round(width * Screen.devicePixelRatio)
          sourceSize.height: Math.round(height * Screen.devicePixelRatio)
        }

        WheelHandler {
          onWheel: function(event) {
            if (trayButton.modelData && typeof trayButton.modelData.scroll === "function")
              trayButton.modelData.scroll(event.angleDelta.y, false)
          }
        }
      }
    }
  }
}
