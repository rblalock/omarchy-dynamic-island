import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var island: null
  property var shell: null
  property var manifest: null
  property string providerId: "rblalock.reminders"
  property bool started: false
  property var reminders: []
  property var reminderDataOverride: null
  property var actionHandler: null
  property string semanticSignature: ""
  property double semanticUpdatedAt: 0

  function sortedReminders(values) {
    var result = Array.isArray(values) ? values.slice() : []
    result.sort(function(a, b) { return Number(a.at || 0) - Number(b.at || 0) })
    return result
  }

  function remainingText(seconds) {
    var value = Math.max(0, Math.round(Number(seconds) || 0))
    var hours = Math.floor(value / 3600)
    var minutes = Math.floor((value % 3600) / 60)
    var remainder = value % 60
    if (hours > 0) return hours + "h " + minutes + "m"
    if (minutes > 0) return minutes + "m" + (remainder > 0 ? " " + remainder + "s" : "")
    return remainder + "s"
  }

  function signatureFor(values) {
    return values.map(function(reminder) {
      return [String(reminder.unit || reminder.timer || ""), String(reminder.label || ""),
        Number(reminder.at || 0)].join("|")
    }).join(";")
  }

  function acceptData(data) {
    if (!started) return
    var nextReminders = sortedReminders(data && data.reminders)
    reminders = nextReminders
    publish()
  }

  function publish() {
    if (!started || !island) return false
    if (reminders.length === 0) {
      semanticSignature = ""
      island.withdraw(providerId, "reminders")
      return false
    }

    var next = reminders[0]
    var nextSignature = signatureFor(reminders)
    if (nextSignature !== semanticSignature || semanticUpdatedAt <= 0) {
      semanticSignature = nextSignature
      semanticUpdatedAt = Date.now()
    }

    var nowSeconds = Math.floor(Date.now() / 1000)
    var remainingSeconds = Math.max(0, Number(next.at || 0) - nowSeconds)
    var totalSeconds = Math.max(0, Number(next.minutes || 0) * 60)
    var count = reminders.length
    var subtitle = remainingText(remainingSeconds)
      + (count > 1 ? " · " + count + " reminders" : " · " + String(next.atTime || ""))
    var activity = {
      id: "reminders",
      title: String(next.label || "Reminder"),
      subtitle: subtitle,
      glyph: "󰢌",
      attention: remainingSeconds <= 60 ? "timely" : "routine",
      presentation: { rest: "companion" },
      updatedAt: semanticUpdatedAt,
      deadline: Number(next.at || 0),
      expiresAt: Number(next.at || 0) > 0 ? Number(next.at) * 1000 + 15000 : 0,
      data: {
        count: count,
        reminders: reminders,
        remainingSeconds: remainingSeconds
      },
      actions: [
        { id: "new", label: "New reminder", glyph: "󰐕" },
        { id: "show", label: "Show reminders", glyph: "󰍉" },
        { id: "clear", label: "Clear all", glyph: "󰆴", destructive: true }
      ]
    }
    if (totalSeconds > 0)
      activity.progress = Math.max(0, Math.min(1, 1 - remainingSeconds / totalSeconds))
    return island.publish(providerId, activity)
  }

  function refresh() {
    if (!started) return false
    if (reminderDataOverride !== null) {
      acceptData(reminderDataOverride)
      return true
    }
    if (jsonProcess.running) return false
    jsonProcess.running = true
    return true
  }

  function start() {
    started = true
    refresh()
  }

  function stop() {
    started = false
    refreshTimer.stop()
    if (jsonProcess.running) jsonProcess.running = false
    reminders = []
    semanticSignature = ""
    if (island) island.withdraw(providerId, "reminders")
  }

  function runAction(actionId) {
    if (actionHandler && typeof actionHandler.run === "function"
        && actionHandler.run(actionId) === true) return true
    if (actionId === "new") return island && island.openQuickAccess("omarchy.reminders")
    if (actionId === "show") {
      Quickshell.execDetached(["omarchy-reminder", "show"])
      return true
    }
    if (actionId === "clear") {
      Quickshell.execDetached(["omarchy-reminder", "clear"])
      actionRefresh.restart()
      return true
    }
    return false
  }

  function onAction(activityId, actionId) {
    if (activityId !== "reminders") return
    runAction(String(actionId || ""))
  }

  Process {
    id: jsonProcess
    command: ["omarchy-reminder", "show", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { root.acceptData(JSON.parse(text || "{}")) }
        catch (error) { console.warn("Omarchy Island reminders: invalid reminder data: " + error) }
      }
    }
  }

  Timer {
    id: refreshTimer
    interval: 5000
    repeat: true
    running: root.started && root.reminderDataOverride === null
    onTriggered: root.refresh()
  }

  Timer {
    id: actionRefresh
    interval: 500
    onTriggered: root.refresh()
  }
}
