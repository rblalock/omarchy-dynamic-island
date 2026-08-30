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
        text: root.island ? root.island.audioIcon : "󰕾"
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
          text: root.island && root.island.audioMuted
            ? "Muted" : Math.round((root.island ? root.island.audioVolume : 0) * 100) + "%"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
          font.weight: Font.DemiBold
          renderType: Text.NativeRendering
        }

        Text {
          width: parent.width
          text: root.island ? root.island.audioOutputLabel : "Default output"
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
          root.island.adjustAudioVolume(-1, false)
          event.accepted = true
        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
          root.island.adjustAudioVolume(1, false)
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
        value: root.island ? root.island.audioVolume : 0
        step: root.island ? root.island.audioScrollStep : 0.05
        trackColor: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.16)
        fillColor: Color.accent
        knobColor: Color.popups.text
        tickColor: Color.popups.background
        onMoved: function(value) { if (root.island) root.island.setAudioVolume(value, false) }
        onRightClicked: if (root.island) root.island.toggleAudioMute()
      }

      Accessible.role: Accessible.Slider
      Accessible.name: root.island && root.island.audioMuted
        ? "Output volume, muted"
        : "Output volume, " + Math.round((root.island ? root.island.audioVolume : 0) * 100) + " percent"
    }

    Row {
      width: parent.width
      height: Style.space(58)
      spacing: Style.space(8)

      ShelfButton {
        width: (parent.width - parent.spacing) / 2
        height: parent.height
        glyph: root.island && root.island.audioMuted ? "󰖁" : "󰕾"
        label: root.island && root.island.audioMuted ? "Unmute" : "Mute"
        description: "Output"
        active: root.island && root.island.audioMuted
        cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        accessibleName: label + " output"
        onActivated: if (root.island) root.island.toggleAudioMute()
      }

      ShelfButton {
        width: (parent.width - parent.spacing) / 2
        height: parent.height
        glyph: "󰓃"
        label: "Full mixer"
        description: "Stock audio panel"
        cornerRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        accessibleName: "Open the full stock audio mixer"
        onActivated: if (root.island) root.island.openStockAudioPanel()
      }
    }
  }
}
