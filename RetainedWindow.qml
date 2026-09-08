import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "components"

// Retained companion window for detail panels and keyboard focus only. The
// visible Rest and Inventory states live exclusively in IslandBarWidget.qml.
Item {
  id: root

  property var island: null
  property var shell: null

  function outputMatches(screenName) {
    var focused = Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name || "") : ""
    if (focused === "" && root.island && typeof root.island.focusedOutputName === "function")
      focused = String(root.island.focusedOutputName() || "")
    if (focused === "" && shell && shell.bar && typeof shell.bar.focusedScreenName === "function")
      focused = String(shell.bar.focusedScreenName() || "")
    if (focused === "" && Quickshell.screens.length > 0)
      focused = String(Quickshell.screens[0].name || "")
    return focused === String(screenName || "")
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: window

      required property var modelData
      readonly property bool retained: root.island && root.island.retainedMode !== ""
      readonly property bool keyboardPeek: retained && root.island.retainedMode === "peek"
      readonly property bool companionVisible: root.island && root.island.barHosted && retained
      readonly property string mode: retained ? root.island.retainedMode : ""

      screen: modelData
      visible: companionVisible && root.outputMatches(modelData ? modelData.name : "")
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      anchors { top: true; right: true; bottom: true; left: true }

      WlrLayershell.namespace: "omarchy-island"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: window.retained ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      function activeRetainedSurface() {
        if (!root.island) return null
        if (root.island.activeShelf === "workspaces") return workspaceShelf
        if (root.island.activeShelf === "tray") return trayShelf
        if (root.island.activeShelf === "status") return statusShelf
        if (root.island.activeShelf === "activity") return activityShelf
        if (root.island.activeShelf === "audio") return volumeShelf
        if (root.island.activeShelf === "display") return displayShelf
        if (root.island.activeShelf === "controls") return controlsShelf
        return null
      }

      function focusCurrentSurface() {
        if (!retained) return
        Qt.callLater(function() {
          if (!window.retained) return
          if (window.keyboardPeek) {
            keyboardFocusCatcher.forceActiveFocus(Qt.TabFocusReason)
            return
          }
          var reason = root.island && root.island.keyboardEntryActive
            ? Qt.TabFocusReason : Qt.MouseFocusReason
          retainedContent.forceActiveFocus(reason)
          if (root.island && root.island.keyboardEntryActive) Qt.callLater(function() {
            if (!window.retained || window.keyboardPeek) return
            var surface = window.activeRetainedSurface()
            if (surface) surface.focusBoundary(false, Qt.TabFocusReason)
          })
        })
      }

      onRetainedChanged: focusCurrentSurface()
      onModeChanged: if (retained) focusCurrentSurface()

      mask: Region {
        x: window.keyboardPeek ? 0 : (window.retained ? 0 : islandCard.x)
        y: window.keyboardPeek ? 0 : (window.retained ? 0 : islandCard.y)
        width: window.keyboardPeek ? 0 : (window.retained ? window.width : islandCard.width)
        height: window.keyboardPeek ? 0 : (window.retained ? window.height : islandCard.height)
      }

      Shortcut {
        enabled: window.retained && !window.keyboardPeek
        sequence: "Escape"
        onActivated: root.island.closeRetained()
      }

      MouseArea {
        anchors.fill: parent
        z: 0
        enabled: window.retained
        acceptedButtons: Qt.AllButtons
        onClicked: root.island.closeRetained()
      }

      FocusScope {
        id: keyboardFocusCatcher
        anchors.fill: parent
        z: 2
        visible: window.keyboardPeek
        focus: visible

        Keys.onPressed: function(event) {
          if (!window.keyboardPeek || !root.island) return
          event.accepted = root.island.handleBarKeyboardKey(event.key, event.modifiers)
        }
      }

      BorderSurface {
        id: islandCard
        z: 1
        visible: window.retained && !window.keyboardPeek

        readonly property real shelfWidth: root.island && root.island.configuredShelfWidth > 0
          ? Style.space(root.island.configuredShelfWidth) : Style.space(430)
        readonly property real retainedWidth: Math.min(shelfWidth, window.width - Style.space(24))
        readonly property real retainedContentWidth: Math.max(0, retainedWidth - Style.space(28))
        readonly property real shelfHeight: root.island && root.island.configuredShelfHeight > 0
          ? Math.max(Style.space(root.island.configuredShelfHeight), automaticShelfHeight)
          : automaticShelfHeight
        readonly property real baseFocusHeight: root.island && root.island.configuredFocusHeight > 0
          ? Style.space(root.island.configuredFocusHeight) : Style.space(224)
        readonly property real focusHeight: baseFocusHeight
          + (root.island && root.island.activeShelf === "activity"
            && !root.island.eventActive && root.island.rankedActivities.length > 1
            ? Style.space(52) : 0)
        readonly property real controlsHeight: root.island && root.island.configuredControlsHeight > 0
          ? Style.space(root.island.configuredControlsHeight) : Style.space(318)
        readonly property real retainedChromeHeight: Style.space(28)
        readonly property real activeShelfContentHeight: {
          if (!root.island) return Style.space(44)
          if (root.island.activeShelf === "workspaces") return workspaceShelf.implicitHeight
          if (root.island.activeShelf === "tray") return trayShelf.implicitHeight
          if (root.island.activeShelf === "status") return statusShelf.implicitHeight
          return Style.space(44)
        }
        readonly property real automaticShelfHeight: Math.min(
          retainedChromeHeight + activeShelfContentHeight,
          window.height - y - Style.space(24))
        width: retainedWidth
        height: window.mode === "focus" ? focusHeight
          : (window.mode === "controls" ? controlsHeight : shelfHeight)
        x: (window.width - width) / 2
        y: root.island ? Style.space(root.island.topOffset) : 0
        radius: {
          var inherited = root.island ? root.island.cornerRadius : Style.cornerRadius
          return Math.min(inherited, height / 2)
        }
        clip: true
        color: root.island && root.island.backgroundOverride !== ""
          ? root.island.backgroundOverride
          : (root.island && root.island.styleName === "outline"
            ? Qt.rgba(Color.popups.background.r, Color.popups.background.g, Color.popups.background.b, 0.88)
            : Color.popups.background)
        borderSpec: Border.none()

        Behavior on width {
          enabled: root.island && root.island.motionEnabled
          NumberAnimation {
            duration: root.island
              ? root.island.motionExpandMs : 0
            easing.type: Easing.OutCubic
          }
        }
        Behavior on height {
          enabled: root.island && root.island.motionEnabled
          NumberAnimation {
            duration: root.island
              ? root.island.motionExpandMs : 0
            easing.type: Easing.OutCubic
          }
        }
        Behavior on radius {
          enabled: root.island && root.island.motionEnabled
          NumberAnimation {
            duration: root.island ? root.island.contentMotionMs : 0
            easing.type: Easing.OutCubic
          }
        }

        MouseArea {
          anchors.fill: parent
          z: 0
          acceptedButtons: Qt.AllButtons
          onClicked: function(event) { event.accepted = true }
        }

        // Rest is borderless. Fade the retained boundary in with destination
        // content instead of flashing a fully drawn frame.
        BorderSurface {
          anchors.fill: parent
          z: 2
          radius: parent.radius
          color: "transparent"
          opacity: window.retained && !window.keyboardPeek ? 1 : 0
          borderSpec: Border.surfaceSpec("popups", "border",
            root.island && root.island.borderOverride !== "" ? root.island.borderOverride : Color.popups.border,
            root.island && root.island.styleName === "outline" ? 2 : 1)

          Behavior on opacity {
            enabled: root.island && root.island.motionEnabled
            NumberAnimation {
              duration: root.island ? root.island.contentMotionMs : 0
              easing.type: Easing.OutCubic
            }
          }
        }

        Item {
          id: retainedContent
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: Style.space(14)
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(14)
          width: islandCard.retainedContentWidth
          z: 1
          opacity: window.retained && !window.keyboardPeek ? 1 : 0
          enabled: window.retained && !window.keyboardPeek

          Keys.onPressed: function(event) {
            if (!window.retained || window.keyboardPeek) return
            var surface = window.activeRetainedSurface()
            if (!surface) return
            var moved = false
            if (event.key === Qt.Key_Left || event.key === Qt.Key_H)
              moved = surface.moveFocus(-1, 0)
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_L)
              moved = surface.moveFocus(1, 0)
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_K)
              moved = surface.moveFocus(0, -1)
            else if (event.key === Qt.Key_Down || event.key === Qt.Key_J)
              moved = surface.moveFocus(0, 1)
            else if (event.key === Qt.Key_Home)
              moved = surface.focusBoundary(false, Qt.TabFocusReason)
            else if (event.key === Qt.Key_End)
              moved = surface.focusBoundary(true, Qt.TabFocusReason)
            event.accepted = moved
          }

          Behavior on opacity {
            enabled: root.island && root.island.motionEnabled
            NumberAnimation {
              duration: root.island ? root.island.contentMotionMs : 0
              easing.type: Easing.OutCubic
            }
          }

          Flickable {
            id: shelfViewport
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            clip: true
            contentWidth: width
            contentHeight: Math.max(height, islandCard.activeShelfContentHeight)
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            WorkspaceShelf {
              id: workspaceShelf
              width: shelfViewport.width
              height: Math.max(shelfViewport.height, implicitHeight)
              island: root.island
              navigationViewport: shelfViewport
              navigationMargin: Style.space(4)
              visible: root.island && root.island.activeShelf === "workspaces"
            }

            TrayShelf {
              id: trayShelf
              width: shelfViewport.width
              height: Math.max(shelfViewport.height, implicitHeight)
              island: root.island
              navigationViewport: shelfViewport
              navigationMargin: Style.space(4)
              visible: root.island && root.island.activeShelf === "tray"
            }

            StatusShelf {
              id: statusShelf
              width: shelfViewport.width
              height: Math.max(shelfViewport.height, implicitHeight)
              island: root.island
              navigationViewport: shelfViewport
              navigationMargin: Style.space(4)
              visible: root.island && root.island.activeShelf === "status"
            }

            ActivityShelf {
              id: activityShelf
              width: shelfViewport.width
              height: shelfViewport.height
              island: root.island
              navigationViewport: shelfViewport
              navigationMargin: Style.space(4)
              visible: root.island && root.island.activeShelf === "activity"
            }

            VolumeShelf {
              id: volumeShelf
              width: shelfViewport.width
              height: shelfViewport.height
              island: root.island
              navigationViewport: shelfViewport
              navigationMargin: Style.space(4)
              visible: root.island && root.island.activeShelf === "audio"
            }

            DisplayShelf {
              id: displayShelf
              width: shelfViewport.width
              height: shelfViewport.height
              island: root.island
              navigationViewport: shelfViewport
              navigationMargin: Style.space(4)
              visible: root.island && root.island.activeShelf === "display"
            }

            ControlsShelf {
              id: controlsShelf
              width: shelfViewport.width
              height: shelfViewport.height
              island: root.island
              navigationViewport: shelfViewport
              navigationMargin: Style.space(4)
              visible: root.island && root.island.activeShelf === "controls"
            }
          }
        }
      }
    }
  }
}
