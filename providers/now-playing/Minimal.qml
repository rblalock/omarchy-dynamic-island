import QtQuick
import qs.Commons

Item {
  id: root
  property var island: null
  property var activity: null
  property var bar: null

  implicitWidth: mark.implicitWidth
  implicitHeight: mark.implicitHeight

  PlaybackMark {
    id: mark
    anchors.centerIn: parent
    activity: root.activity
    foreground: root.bar ? root.bar.foreground : Color.popups.text
  }
}
