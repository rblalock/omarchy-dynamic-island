import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property string glyph: ""
  property string iconKind: ""
  property string label: ""
  property string description: ""
  property bool active: false
  property bool compact: false
  property bool focusOnHover: true
  property real cornerRadius: Style.cornerRadius
  property string accessibleName: label
  readonly property bool hovered: mouse.containsMouse
  signal activated()
  signal secondaryActivated()
  signal menuRequested(var anchor)

  implicitWidth: compact ? Style.space(44) : Style.space(118)
  implicitHeight: compact ? Style.space(44) : Style.space(58)
  activeFocusOnTab: true
  Keys.onReturnPressed: root.activated()
  Keys.onEnterPressed: root.activated()
  Keys.onSpacePressed: root.activated()

  ControlStateSurface {
    anchors.fill: parent
    cornerRadius: root.cornerRadius
    hovered: mouse.containsMouse
    pressed: mouse.pressed
    focused: root.activeFocus
    selected: root.active
    normalColor: Style.normalFillFor(Color.popups.text, Color.accent)
  }

  Column {
    anchors.centerIn: parent
    width: parent.width - Style.space(12)
    spacing: root.compact ? 0 : Style.space(3)

    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: Style.bar.iconCanvas
      height: Style.bar.iconCanvas

      OpticalGlyph {
        anchors.fill: parent
        text: root.glyph
        visible: root.iconKind === ""
        color: Color.popups.text
        fontFamily: Style.font.family
        fontSize: Style.font.icon
      }

      TailscaleGlyph {
        anchors.centerIn: parent
        visible: root.iconKind === "tailscale"
        iconSize: Style.space(11)
        color: Color.popups.text
      }
    }

    Text {
      visible: !root.compact && text !== ""
      width: parent.width
      text: root.label
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.weight: Font.Medium
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      renderType: Text.NativeRendering
    }

    Text {
      visible: !root.compact && text !== ""
      width: parent.width
      text: root.description
      color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.58)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
      elide: Text.ElideRight
      renderType: Text.NativeRendering
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onContainsMouseChanged: if (containsMouse && root.focusOnHover)
      root.forceActiveFocus(Qt.MouseFocusReason)
    onClicked: function(event) {
      if (event.button === Qt.RightButton) root.menuRequested(root)
      else if (event.button === Qt.MiddleButton) root.secondaryActivated()
      else root.activated()
    }
  }

  Accessible.role: Accessible.Button
  Accessible.name: root.accessibleName || root.label
  Accessible.onPressAction: root.activated()
}
