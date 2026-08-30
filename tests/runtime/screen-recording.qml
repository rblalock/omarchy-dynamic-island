import QtQuick
import Quickshell
import "screen_recording" as Recording

ShellRoot {
  id: harness

  property var publishedActivity: null
  property string withdrawnActivity: ""

  QtObject {
    id: fakeActions
    property string lastAction: ""
    function run(actionId) {
      lastAction = String(actionId)
      return true
    }
  }

  QtObject {
    id: fakeIsland
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
      provider.onAction(activityId, actionId)
      return true
    }
  }

  Recording.Provider {
    id: provider
    island: fakeIsland
    providerId: "rblalock.screen-recording"
    actionHandler: fakeActions
    recordingStateOverride: ({
      active: true,
      elapsedSeconds: 65,
      filename: "/tmp/screenrecording-test.mp4"
    })
  }

  Recording.Minimal {
    id: minimal
    visible: false
    activity: harness.publishedActivity
  }

  Recording.Compact {
    id: compact
    visible: false
    activity: harness.publishedActivity
  }

  Recording.Event {
    id: eventView
    visible: false
    activity: harness.publishedActivity
  }

  Timer {
    interval: 120
    running: true
    onTriggered: {
      provider.start()
      var activity = harness.publishedActivity
      if (!activity || activity.id !== "screen-recording"
          || activity.title !== "Screen recording" || activity.subtitle !== "1:05"
          || activity.attention !== "timely" || activity.presentation.rest !== "companion"
          || activity.data.state !== "recording" || activity.data.elapsedSeconds !== 65
          || activity.primaryAction !== "stop"
          || activity.actions.length !== 1 || activity.actions[0].id !== "stop"
          || minimal.implicitWidth <= 16 || compact.implicitWidth <= 0
          || compact.implicitWidth >= minimal.implicitWidth) {
        console.error("SCREEN_RECORDING_FAIL publish", JSON.stringify(activity || {}))
        Qt.exit(51)
        return
      }

      provider.onAction("screen-recording", "stop")
      if (fakeActions.lastAction !== "stop" || !provider.stopping
          || harness.publishedActivity.data.state !== "stopping"
          || harness.publishedActivity.primaryAction !== ""
          || harness.publishedActivity.actions.length !== 0) {
        console.error("SCREEN_RECORDING_FAIL stop action")
        Qt.exit(52)
        return
      }

      provider.finishStop(0, "/tmp/screenrecording-test.mp4\n")
      activity = harness.publishedActivity
      if (!provider.completionActive || activity.title !== "Recording saved"
          || activity.presentation.rest !== "takeover" || activity.data.state !== "saved"
          || activity.data.basename !== "screenrecording-test.mp4"
          || !activity.event || String(activity.event.id).indexOf("saved-") !== 0
          || activity.expiresAt <= Date.now() || eventView.implicitWidth <= 16) {
        console.error("SCREEN_RECORDING_FAIL completion", JSON.stringify(activity || {}))
        Qt.exit(53)
        return
      }

      provider.recordingStateOverride = {
        active: true,
        elapsedSeconds: 2,
        filename: "/tmp/screenrecording-second.mp4"
      }
      provider.refresh()
      harness.withdrawnActivity = ""
      provider.recordingStateOverride = { active: false }
      provider.refresh()
      if (harness.withdrawnActivity !== "rblalock.screen-recording:screen-recording") {
        console.error("SCREEN_RECORDING_FAIL external withdrawal", harness.withdrawnActivity)
        Qt.exit(54)
        return
      }

      console.log("SCREEN_RECORDING_OK")
      Qt.quit()
    }
  }
}
