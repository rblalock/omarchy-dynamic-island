import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property var island: null
  property var activity: null
  property var bar: null
  property double nowSeconds: Date.now() / 1000

  readonly property var reminders: activity && activity.data && activity.data.reminders
    ? activity.data.reminders : []

  implicitWidth: Style.space(390)
  implicitHeight: Style.space(188)

  function remainingText(deadline) {
    var value = Math.max(0, Math.ceil(Number(deadline || 0) - nowSeconds))
    var hours = Math.floor(value / 3600)
    var minutes = Math.floor((value % 3600) / 60)
    var seconds = value % 60
    if (hours > 0) return hours + "h " + minutes + "m"
    if (minutes > 0) return minutes + "m " + seconds + "s"
    return seconds + "s"
  }

  function runAction(actionId) {
    if (island && activity)
      island.routeAction(activity.providerId, activity.id, actionId)
  }

  Column {
    anchors.fill: parent
    spacing: Style.space(8)

    ListView {
      id: reminderList
      width: parent.width
      height: Math.max(0, parent.height - actions.height - parent.spacing)
      model: root.reminders
      spacing: Style.space(4)
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      delegate: BorderSurface {
        required property var modelData
        width: reminderList.width
        height: Style.space(44)
        radius: Math.min(root.island ? root.island.cornerRadius : Style.cornerRadius, height / 2)
        color: Style.normalFillFor(Color.popups.text, Color.accent)
        borderSpec: Border.none()

        Row {
          anchors.fill: parent
          anchors.leftMargin: Style.space(10)
          anchors.rightMargin: Style.space(10)
          spacing: Style.space(8)

          Item {
            width: Style.bar.iconCanvas
            height: parent.height

            OpticalGlyph {
              anchors.centerIn: parent
              width: Style.bar.iconCanvas
              height: Style.bar.iconCanvas
              text: "󰢌"
              color: Color.popups.text
              fontFamily: Style.font.family
              fontSize: Style.font.icon
            }
          }

          Column {
            width: Math.max(0, parent.width - x - countdown.width)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(1)

            Text {
              width: parent.width
              text: String(modelData.label || "Reminder")
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              renderType: Text.NativeRendering
            }

            Text {
              width: parent.width
              text: String(modelData.atTime || "")
              color: Qt.rgba(Color.popups.text.r, Color.popups.text.g, Color.popups.text.b, 0.55)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              renderType: Text.NativeRendering
            }
          }

          Text {
            id: countdown
            anchors.verticalCenter: parent.verticalCenter
            text: root.remainingText(modelData.at)
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
          }
        }
      }
    }

    Row {
      id: actions
      anchors.horizontalCenter: parent.horizontalCenter
      height: Style.space(42)
      spacing: Style.space(6)

      ActionButton {
        glyph: "󰐕"
        label: "New"
        islandRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        onActivated: root.runAction("new")
      }

      ActionButton {
        glyph: "󰍉"
        label: "Show"
        islandRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        onActivated: root.runAction("show")
      }

      ActionButton {
        glyph: "󰆴"
        label: "Clear"
        destructive: true
        islandRadius: root.island ? root.island.cornerRadius : Style.cornerRadius
        onActivated: root.runAction("clear")
      }
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: root.visible && root.reminders.length > 0
    onTriggered: root.nowSeconds = Date.now() / 1000
  }
}
