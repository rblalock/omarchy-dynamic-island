import QtQuick
import qs.Commons
import qs.Ui as Ui

Item {
  id: root

  property var island: null
  property var activity: null
  property var bar: null

  readonly property var media: activity && activity.data ? activity.data : ({})
  readonly property var actions: activity && activity.actions ? activity.actions : []
  readonly property bool playing: !!media.playing
  readonly property bool hasProgress: !!media.positionSupported && Number(media.length || 0) > 0

  implicitWidth: Style.space(390)
  implicitHeight: Style.space(188)

  function hasAction(actionId) {
    for (var index = 0; index < actions.length; index++)
      if (String(actions[index].id || "") === actionId) return true
    return false
  }

  function runAction(actionId) {
    if (!island || !activity) return
    island.routeAction(activity.providerId, activity.id, actionId)
  }

  function clockText(seconds) {
    var value = Math.max(0, Math.floor(Number(seconds) || 0))
    var minutes = Math.floor(value / 60)
    var remainder = value % 60
    return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
  }

  Row {
    anchors.fill: parent
    spacing: Style.space(14)

    Ui.BorderSurface {
      id: artworkSurface
      width: Math.min(parent.height, Style.space(104))
      height: width
      anchors.verticalCenter: parent.verticalCenter
      radius: Math.min(root.island ? root.island.cornerRadius : Style.cornerRadius, Style.space(12))
      color: Style.normalFillFor(Color.popups.text, Color.accent)
      borderSpec: Border.none()
      clip: true

      Image {
        id: artwork
        anchors.fill: parent
        source: String(root.media.artUrl || "")
        asynchronous: true
        cache: true
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready
      }

      Text {
        anchors.centerIn: parent
        visible: !artwork.visible
        text: root.playing ? "󰏤" : "󰐊"
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.space(30)
        renderType: Text.NativeRendering
      }
    }

    Column {
      width: Math.max(0, parent.width - artworkSurface.width - parent.spacing)
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(7)

      Text {
        width: parent.width
        text: root.activity ? root.activity.title : "Nothing playing"
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
        text: String(root.media.artist || (root.activity ? root.activity.subtitle : ""))
        color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.72)
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
        renderType: Text.NativeRendering
      }

      Text {
        width: parent.width
        visible: text !== ""
        text: String(root.media.album || root.media.identity || "")
        color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.5)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
        renderType: Text.NativeRendering
      }

      Row {
        width: parent.width
        height: Style.space(24)

        Item {
          width: parent.width
          height: parent.height

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Style.space(3)
            radius: height / 2
            visible: root.hasProgress
            color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.12)

            Rectangle {
              width: parent.width * Math.max(0, Math.min(1,
                Number(root.media.position || 0) / Math.max(1, Number(root.media.length || 1))))
              height: parent.height
              radius: height / 2
              color: Color.accent
              Behavior on width {
                enabled: root.island && root.island.motionEnabled
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
              }
            }
          }
        }
      }

      Row {
        width: parent.width
        height: Style.space(18)
        visible: root.hasProgress

        Text {
          id: elapsedTime
          text: root.clockText(root.media.position)
          color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.5)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          renderType: Text.NativeRendering
        }

        Item { width: Math.max(0, parent.width - elapsedTime.width - totalTime.width) }

        Text {
          id: totalTime
          text: root.clockText(root.media.length)
          color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.5)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          renderType: Text.NativeRendering
        }
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)

        MediaButton {
          glyph: "󰒮"
          label: "Previous track"
          enabled: root.hasAction("previous")
          onActivated: root.runAction("previous")
        }

        MediaButton {
          glyph: root.playing ? "󰏤" : "󰐊"
          label: root.playing ? "Pause" : "Play"
          enabled: root.hasAction("play-pause")
          onActivated: root.runAction("play-pause")
        }

        MediaButton {
          glyph: "󰒭"
          label: "Next track"
          enabled: root.hasAction("next")
          onActivated: root.runAction("next")
        }
      }
    }
  }
}
