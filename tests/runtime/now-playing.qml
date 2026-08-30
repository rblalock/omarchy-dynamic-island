import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "now_playing" as NowPlaying

ShellRoot {
  id: harness

  property var publishedActivity: null
  property string withdrawnActivity: ""
  property string routedAction: ""

  QtObject {
    id: player
    property string dbusName: "org.mpris.MediaPlayer2.harness"
    property string desktopEntry: "harness"
    property string identity: "Harness player"
    property string trackTitle: "Reference track"
    property string trackArtist: "Island artist"
    property string trackAlbum: "Provider proof"
    property string trackArtUrl: ""
    property bool isPlaying: true
    property int playbackState: MprisPlaybackState.Playing
    property bool canGoPrevious: true
    property bool canGoNext: true
    property bool canTogglePlaying: true
    property bool canPlay: true
    property bool canPause: true
    property bool positionSupported: true
    property bool lengthSupported: true
    property real position: 30
    property real length: 120
    property int uniqueId: 1
    function previous() {}
    function next() {}
    function play() { isPlaying = true; playbackState = MprisPlaybackState.Playing }
    function pause() { isPlaying = false; playbackState = MprisPlaybackState.Paused }
    function togglePlaying() {
      if (isPlaying) pause()
      else play()
    }
  }

  QtObject {
    id: mediaService
    property var activePlayer: player
    property string lastAction: ""
    function playerKey(candidate) { return candidate ? candidate.dbusName : "" }
    function runAction(action, showFeedback, targetKey) {
      lastAction = String(action)
      if (action === "playPause") player.togglePlaying()
      return true
    }
  }

  QtObject {
    id: fakeShell
    function firstPartyServiceFor(pluginId) {
      return pluginId === "omarchy.media" ? mediaService : null
    }
  }

  QtObject {
    id: fakeIsland
    property bool motionEnabled: false
    property real cornerRadius: 6
    function publish(providerId, activity) {
      harness.publishedActivity = activity
      return true
    }
    function withdraw(providerId, activityId) {
      harness.withdrawnActivity = providerId + ":" + activityId
      return true
    }
    function routeAction(providerId, activityId, actionId) {
      harness.routedAction = providerId + ":" + activityId + ":" + actionId
      return true
    }
  }

  NowPlaying.Provider {
    id: provider
    island: fakeIsland
    shell: fakeShell
    providerId: "rblalock.now-playing"
    playersOverride: []
  }

  NowPlaying.Minimal {
    id: minimal
    visible: false
    island: fakeIsland
    activity: harness.publishedActivity
  }

  NowPlaying.Compact {
    id: compact
    visible: false
    island: fakeIsland
    activity: harness.publishedActivity
  }

  NowPlaying.Expanded {
    id: expanded
    visible: false
    island: fakeIsland
    activity: harness.publishedActivity
  }

  NowPlaying.PlaybackMark {
    id: hiddenPlaybackMark
    visible: false
    activity: harness.publishedActivity
  }

  Timer {
    interval: 120
    running: true
    onTriggered: {
      provider.start()
      var activity = harness.publishedActivity
      if (!activity || activity.id !== "now-playing" || activity.title !== "Reference track"
          || activity.subtitle !== "Island artist" || Math.abs(activity.progress - 0.25) > 0.001
          || !activity.data.playing || activity.data.signalKind !== "playback-progress"
          || !activity.presentation || activity.presentation.rest !== "companion"
          || activity.actions.length !== 3 || minimal.implicitWidth <= 0
          || compact.implicitWidth <= 0 || expanded.implicitHeight <= 0
          || !hiddenPlaybackMark.playing || !hiddenPlaybackMark.hasProgress
          || Math.abs(hiddenPlaybackMark.progress - 0.25) > 0.001) {
        console.error("NOW_PLAYING_FAIL publish", JSON.stringify(activity || {}))
        Qt.exit(31)
        return
      }
      provider.onAction("now-playing", "play-pause")
      if (mediaService.lastAction !== "playPause" || player.isPlaying) {
        console.error("NOW_PLAYING_FAIL action")
        Qt.exit(32)
        return
      }
      harness.withdrawnActivity = ""
      player.playbackState = MprisPlaybackState.Stopped
      if (provider.isOngoing(player)) {
        console.error("NOW_PLAYING_FAIL stopped classification", player.playbackState,
          MprisPlaybackState.Stopped)
        Qt.exit(35)
        return
      }
      provider.publish()
      if (harness.withdrawnActivity !== "rblalock.now-playing:now-playing") {
        console.error("NOW_PLAYING_FAIL stopped withdrawal", harness.withdrawnActivity)
        Qt.exit(34)
        return
      }
      harness.withdrawnActivity = ""
      provider.stop()
      if (harness.withdrawnActivity !== "rblalock.now-playing:now-playing") {
        console.error("NOW_PLAYING_FAIL stop", harness.withdrawnActivity)
        Qt.exit(33)
        return
      }
      console.log("NOW_PLAYING_OK")
      Qt.quit()
    }
  }
}
