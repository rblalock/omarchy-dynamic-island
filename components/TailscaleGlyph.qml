import QtQuick
import qs.Commons

// Matches Omarchy's stock Tailscale bar mark: a compact 3x3 dot grid with
// the corner/edge dots recessed. The stock widget draws this as QML rather
// than exposing a text glyph, so Island owns this small compatibility view.
Item {
  id: root

  property real iconSize: Style.space(11)
  property color color: Color.popups.text

  implicitWidth: iconSize
  implicitHeight: iconSize
  width: iconSize
  height: iconSize

  readonly property real dotSize: Math.max(2, iconSize * 0.24)
  readonly property real mid: (iconSize - dotSize) / 2
  readonly property real end: iconSize - dotSize

  Dot { x: 0; y: 0; opacity: 0.24 }
  Dot { x: root.mid; y: 0; opacity: 0.24 }
  Dot { x: root.end; y: 0; opacity: 0.24 }
  Dot { x: 0; y: root.mid; opacity: 1 }
  Dot { x: root.mid; y: root.mid; opacity: 1 }
  Dot { x: root.end; y: root.mid; opacity: 1 }
  Dot { x: 0; y: root.end; opacity: 0.24 }
  Dot { x: root.mid; y: root.end; opacity: 1 }
  Dot { x: root.end; y: root.end; opacity: 0.24 }

  component Dot: Rectangle {
    width: root.dotSize
    height: root.dotSize
    radius: width / 2
    color: root.color
  }
}
