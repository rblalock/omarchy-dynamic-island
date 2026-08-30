import QtQuick
import Quickshell
import "system_update" as SystemUpdate

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
    function publish(providerId, activity) {
      harness.publishedActivity = activity
      return true
    }
    function withdraw(providerId, activityId) {
      harness.withdrawnActivity = providerId + ":" + activityId
      return true
    }
  }

  SystemUpdate.Provider {
    id: provider
    island: fakeIsland
    providerId: "rblalock.system-update"
    actionHandler: fakeActions
    updateStateOverride: ({
      available: true,
      updates: ["omarchy 4.0.1 -> 4.0.2", "omarchy-dev-checkout 2 new commits"]
    })
  }

  Timer {
    interval: 120
    running: true
    onTriggered: {
      provider.start()
      var activity = harness.publishedActivity
      if (!activity || activity.id !== "system-update"
          || activity.title !== "Omarchy update available"
          || activity.subtitle.indexOf("2 updates") === -1
          || activity.attention !== "routine" || activity.presentation.rest !== "companion"
          || activity.primaryAction !== "update"
          || activity.actions.length !== 1 || activity.actions[0].id !== "update"
          || activity.data.updates.length !== 2 || activity.expiresAt <= Date.now()) {
        console.error("SYSTEM_UPDATE_FAIL publish", JSON.stringify(activity || {}))
        Qt.exit(61)
        return
      }

      provider.onAction("system-update", "update")
      if (fakeActions.lastAction !== "update") {
        console.error("SYSTEM_UPDATE_FAIL action")
        Qt.exit(62)
        return
      }

      harness.withdrawnActivity = ""
      provider.updateStateOverride = { available: false }
      provider.refresh()
      if (harness.withdrawnActivity !== "rblalock.system-update:system-update") {
        console.error("SYSTEM_UPDATE_FAIL withdrawal", harness.withdrawnActivity)
        Qt.exit(63)
        return
      }

      console.log("SYSTEM_UPDATE_OK")
      Qt.quit()
    }
  }
}
