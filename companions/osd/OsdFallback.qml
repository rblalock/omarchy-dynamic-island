import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Adapted from Omarchy's MIT-licensed stock OSD presentation. See LICENSE.
PanelWindow {
  id: panel

  property var bridge: null
  readonly property var event: bridge ? bridge.fallbackEvent : null
  readonly property int pad: Style.space(16)
  readonly property int gap: Style.space(16)
  readonly property int messageGap: Math.round(gap * 2 / 3)
  readonly property int barWidth: Style.space(142)
  readonly property int maxMessageWidth: event
    && (String(event.iconKey || "").indexOf("media") === 0
      || String(event.iconKey || "").indexOf("player") === 0)
    ? Style.space(325) : Style.space(190)
  readonly property int iconInkWidth: Math.ceil(iconMetrics.tightBoundingRect.width)
  readonly property int iconWidth: event && event.hasProgress
    ? Math.max(iconInkWidth, Math.ceil(widestIconMetrics.tightBoundingRect.width)) : iconInkWidth
  readonly property int valueWidth: Math.ceil(Math.max(valueMetrics.advanceWidth, messageMetrics.advanceWidth))
  readonly property int messageWidth: Math.min(Math.ceil(messageMetrics.advanceWidth), maxMessageWidth)
  readonly property int contentWidth: event && event.hasProgress
    ? iconWidth + gap + barWidth + gap + valueWidth
    : (event && event.message !== "" ? iconWidth + messageGap + messageWidth : iconWidth)

  visible: bridge && bridge.fallbackOpened
  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  WlrLayershell.namespace: "omarchy-island-osd-fallback"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  mask: Region {}

  TextMetrics {
    id: messageMetrics
    font.family: Style.font.family
    font.bold: true
    font.pixelSize: Style.font.title
    text: panel.event ? String(panel.event.message || "") : ""
  }
  TextMetrics { id: valueMetrics; font: messageMetrics.font; text: "100%" }
  TextMetrics {
    id: iconMetrics
    font.family: Style.font.family
    font.pixelSize: Style.font.displayLarge
    text: panel.event ? String(panel.event.icon || "") : ""
  }
  TextMetrics { id: widestIconMetrics; font: iconMetrics.font; text: "" }

  BorderSurface {
    id: card
    width: card.borderLeft + panel.pad + panel.contentWidth + panel.pad + card.borderRight
    height: card.borderTop + panel.pad + Style.font.displayLarge + panel.pad + card.borderBottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Style.space(67)
    color: Util.alpha(Color.background, 0.97)
    borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
    radius: Style.cornerRadius

    Row {
      anchors.fill: parent
      anchors.topMargin: card.borderTop + panel.pad
      anchors.rightMargin: card.borderRight + panel.pad
      anchors.bottomMargin: card.borderBottom + panel.pad
      anchors.leftMargin: card.borderLeft + panel.pad
      spacing: panel.event && panel.event.hasProgress ? panel.gap : panel.messageGap

      Item {
        width: panel.iconWidth
        height: parent.height
        Text {
          x: Math.round((panel.iconWidth - panel.iconInkWidth) / 2 - iconMetrics.tightBoundingRect.x)
          anchors.verticalCenter: parent.verticalCenter
          text: panel.event ? String(panel.event.icon || "") : ""
          font: iconMetrics.font
          color: Color.popups.text
        }
      }

      Rectangle {
        visible: panel.event && panel.event.hasProgress
        width: panel.barWidth
        height: Math.max(Style.space(6), Style.spacing.sm)
        anchors.verticalCenter: parent.verticalCenter
        color: Util.alpha(Color.popups.text, 0.45)
        Rectangle {
          height: parent.height
          width: parent.width * (panel.event ? panel.event.value / panel.event.maxValue : 0)
          color: Color.accent
          Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
      }

      Text {
        visible: panel.event && panel.event.message !== ""
        width: panel.event && panel.event.hasProgress ? panel.valueWidth : panel.messageWidth
        horizontalAlignment: panel.event && panel.event.hasProgress ? Text.AlignRight : Text.AlignLeft
        anchors.verticalCenter: parent.verticalCenter
        text: panel.event ? String(panel.event.message || "") : ""
        font: messageMetrics.font
        color: Color.popups.text
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }
  }
}
