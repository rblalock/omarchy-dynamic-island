import QtQuick
import qs.Commons
import qs.Ui

NavigableSurface {
  id: root

  property var island: null

  Column {
    anchors.fill: parent
    spacing: Style.space(12)

    Row {
      width: parent.width
      height: Style.space(42)
      spacing: Style.space(10)

      OpticalGlyph {
        width: Style.space(30)
        height: parent.height
        text: root.island ? root.island.displayIcon : "󰍹"
        color: Color.popups.text
        fontFamily: Style.font.family
        fontSize: Style.font.title
      }

      Column {
        width: parent.width - x
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(1)

        Text {
          width: parent.width
          text: Math.round((root.island ? root.island.displayBrightness : 0) * 100) + "%"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }

        Text {
          width: parent.width
          text: root.island ? root.island.displayMonitorLabel : "Focused display"
          color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.62)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          renderType: Text.NativeRendering
        }
      }
    }

    Item {
      id: sliderControl
      width: parent.width
      height: Style.space(44)
      activeFocusOnTab: true
      Keys.onPressed: function(event) {
        if (!root.island) {
          event.accepted = false
          return
        }
        if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
          root.island.adjustDisplayBrightness(-1, false)
          event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
          root.island.adjustDisplayBrightness(1, false)
          event.accepted = true
        } else event.accepted = false
      }

      HoverHandler {
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: if (hovered) sliderControl.forceActiveFocus(Qt.MouseFocusReason)
      }

      ControlStateSurface {
        anchors.fill: parent
        cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        focused: sliderControl.activeFocus
      }

      PanelSlider {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Style.space(10)
        anchors.rightMargin: Style.space(10)
        anchors.verticalCenter: parent.verticalCenter
        minimum: 0.01
        maximum: 1
        value: root.island ? root.island.displayBrightness : 0
        step: root.island ? root.island.displayScrollStep : 0.05
        trackColor: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.16)
        fillColor: Color.accent
        knobColor: Color.popups.text
        tickColor: Color.popups.background
        onMoved: function(value) {
          if (root.island) root.island.previewDisplayBrightness(value)
        }
        onReleased: function(value) {
          if (root.island) root.island.setDisplayBrightness(value, false)
        }
      }

      Accessible.role: Accessible.Slider
      Accessible.name: "Display brightness, "
        + Math.round((root.island ? root.island.displayBrightness : 0) * 100) + " percent"
    }

    ShelfButton {
      width: parent.width
      height: Style.space(58)
      glyph: "󰍹"
      label: "Full display controls"
      description: "Stock display panel"
      cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
      accessibleName: "Open the full stock display panel"
      onActivated: if (root.island) root.island.openStockDisplayPanel()
    }
  }
}
