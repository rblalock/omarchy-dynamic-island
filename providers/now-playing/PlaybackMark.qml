import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Ui as Ui

Item {
  id: root

  property var activity: null
  property color foreground: Color.popups.text

  readonly property var media: activity && activity.data ? activity.data : ({})
  readonly property bool playing: !!media.playing
  readonly property bool hasProgress: !!media.positionSupported
    && Number(media.length || 0) > 0
  readonly property real progress: hasProgress
    ? Math.max(0, Math.min(1, Number(media.position || 0) / Number(media.length))) : 0
  readonly property real diameter: Style.bar.iconCanvas
  readonly property real ringWidth: Math.max(1, diameter / 12)
  readonly property real ringRadius: diameter / 2 - ringWidth / 2
  readonly property color quietTrack: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.18)

  implicitWidth: diameter
  implicitHeight: diameter

  Shape {
    anchors.fill: parent
    visible: root.hasProgress
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.quietTrack
      strokeWidth: root.ringWidth
      capStyle: ShapePath.RoundCap

      PathAngleArc {
        centerX: root.diameter / 2
        centerY: root.diameter / 2
        radiusX: root.ringRadius
        radiusY: root.ringRadius
        startAngle: -90
        sweepAngle: 359.9
      }
    }

    ShapePath {
      fillColor: "transparent"
      strokeColor: Color.accent
      strokeWidth: root.ringWidth
      capStyle: ShapePath.RoundCap

      PathAngleArc {
        centerX: root.diameter / 2
        centerY: root.diameter / 2
        radiusX: root.ringRadius
        radiusY: root.ringRadius
        startAngle: -90
        sweepAngle: Math.max(0.1, root.progress * 360)
      }
    }
  }

  Ui.OpticalGlyph {
    anchors.centerIn: parent
    width: root.diameter - root.ringWidth * 4
    height: width
    text: "󰝚"
    fontFamily: Style.font.family
    fontSize: Math.max(8, root.diameter - Style.space(6))
    color: root.foreground
    opacity: root.playing ? 1 : 0.48
  }
}
