import QtQuick
import QtTest
import "../../components"

Item {
  width: 180
  height: 120

  Flickable {
    anchors.fill: parent
    contentWidth: width
    contentHeight: height

    NavigableSurface {
      id: surface
      width: 180
      height: 120

      Item {
        id: topLeft
        x: 0
        y: 0
        width: 40
        height: 40
        activeFocusOnTab: true
      }

      Item {
        id: topRight
        x: 60
        y: 0
        width: 40
        height: 40
        activeFocusOnTab: true
      }

      Item {
        id: bottomRight
        x: 60
        y: 60
        width: 40
        height: 40
        activeFocusOnTab: true
      }
    }
  }

  TestCase {
    name: "RetainedPanelKeyboardNavigation"
    when: windowShown

    function init() {
      topLeft.forceActiveFocus(Qt.TabFocusReason)
      verify(topLeft.activeFocus)
    }

    function test_arrow_crosses_flickable() {
      keyClick(Qt.Key_Right)
      tryVerify(function() { return topRight.activeFocus })
    }

    function test_vim_key_crosses_flickable() {
      keyClick(Qt.Key_L)
      tryVerify(function() { return topRight.activeFocus })
      keyClick(Qt.Key_J)
      tryVerify(function() { return bottomRight.activeFocus })
    }
  }
}
