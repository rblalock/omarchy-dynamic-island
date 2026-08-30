import QtQuick
import Quickshell
import "reminders" as Reminders

ShellRoot {
  id: harness

  property var publishedActivity: null
  property string withdrawnActivity: ""
  property string quickAccessTarget: ""

  QtObject {
    id: fakeActions
    property string lastAction: ""
    function run(actionId) {
      if (actionId === "new") return false
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
    function openQuickAccess(targetId) {
      harness.quickAccessTarget = String(targetId)
      return true
    }
    function routeAction(providerId, activityId, actionId) {
      provider.onAction(activityId, actionId)
      return true
    }
  }

  Reminders.Provider {
    id: provider
    island: fakeIsland
    providerId: "rblalock.reminders"
    actionHandler: fakeActions
  }

  Reminders.Minimal {
    id: minimal
    visible: false
    island: fakeIsland
    activity: harness.publishedActivity
  }

  Reminders.Compact {
    id: compact
    visible: false
    island: fakeIsland
    activity: harness.publishedActivity
  }

  Reminders.Expanded {
    id: expanded
    visible: false
    island: fakeIsland
    activity: harness.publishedActivity
  }

  Timer {
    interval: 120
    running: true
    onTriggered: {
      var now = Math.floor(Date.now() / 1000)
      provider.reminderDataOverride = {
        count: 2,
        reminders: [
          { unit: "later", label: "Later reminder", minutes: 10, at: now + 300, atTime: "12:05" },
          { unit: "next", label: "Check the oven", minutes: 2, at: now + 60, atTime: "12:01" }
        ]
      }
      provider.start()
      var activity = harness.publishedActivity
      if (!activity || activity.id !== "reminders" || activity.title !== "Check the oven"
          || activity.deadline !== now + 60 || activity.data.count !== 2
          || activity.data.reminders[0].unit !== "next"
          || !activity.presentation || activity.presentation.rest !== "companion"
          || activity.actions.length !== 3
          || Math.abs(activity.progress - 0.5) > 0.02
          || minimal.implicitWidth <= 16 || compact.implicitWidth !== minimal.implicitWidth
          || expanded.implicitHeight <= 0) {
        console.error("REMINDERS_FAIL publish", JSON.stringify(activity || {}))
        Qt.exit(41)
        return
      }
      provider.onAction("reminders", "new")
      if (harness.quickAccessTarget !== "omarchy.reminders") {
        console.error("REMINDERS_FAIL new action")
        Qt.exit(42)
        return
      }
      provider.onAction("reminders", "show")
      if (fakeActions.lastAction !== "show") {
        console.error("REMINDERS_FAIL show action")
        Qt.exit(43)
        return
      }
      provider.onAction("reminders", "clear")
      if (fakeActions.lastAction !== "clear") {
        console.error("REMINDERS_FAIL clear action")
        Qt.exit(44)
        return
      }
      harness.withdrawnActivity = ""
      provider.reminderDataOverride = { count: 0, reminders: [] }
      provider.refresh()
      if (harness.withdrawnActivity !== "rblalock.reminders:reminders") {
        console.error("REMINDERS_FAIL withdrawal", harness.withdrawnActivity)
        Qt.exit(45)
        return
      }
      console.log("REMINDERS_OK")
      Qt.quit()
    }
  }
}
