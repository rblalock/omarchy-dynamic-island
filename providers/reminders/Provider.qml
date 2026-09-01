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
  property string responseText: ""
  property int responseBytes: 0

  readonly property int maxResponseBytes: 65536
  readonly property int maxReminderCount: 64
  readonly property int maxReminderLabelChars: 256
  readonly property int maxReminderFieldChars: 64

  function boundedText(value, maxChars) {
    var text = String(value || "")
    return text.length > maxChars ? text.slice(0, maxChars) : text
  }

  function utf8ByteLength(value) {
    var text = String(value || "")
    var bytes = 0
    for (var index = 0; index < text.length; index++) {
      var code = text.charCodeAt(index)
      if (code <= 0x7f) bytes += 1
      else if (code <= 0x7ff) bytes += 2
      else if (code >= 0xd800 && code <= 0xdbff && index + 1 < text.length
          && text.charCodeAt(index + 1) >= 0xdc00 && text.charCodeAt(index + 1) <= 0xdfff) {
        bytes += 4
        index++
      } else bytes += 3
      if (bytes > maxResponseBytes) return bytes
    }
    return bytes
  }

  function finiteNonNegative(value) {
    var number = Number(value)
    return isFinite(number) && number >= 0 ? number : 0
  }

  function normalizedReminder(value) {
    if (!value || typeof value !== "object") return null
    return {
      unit: boundedText(value.unit, maxReminderFieldChars),
      timer: boundedText(value.timer, maxReminderFieldChars),
      label: boundedText(value.label || "Reminder", maxReminderLabelChars),
      minutes: finiteNonNegative(value.minutes),
      at: finiteNonNegative(value.at),
      atTime: boundedText(value.atTime, maxReminderFieldChars)
    }
  }

  function sortedReminders(values) {
    var source = Array.isArray(values) ? values : []
    var result = []
    var inspected = Math.min(source.length, maxReminderCount)
    for (var index = 0; index < inspected; index++) {
      var reminder = normalizedReminder(source[index])
      if (reminder) result.push(reminder)
    }
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

  function rejectData(reason) {
    console.warn("Omarchy Island reminders: " + String(reason || "invalid reminder data"))
    reminders = []
    semanticSignature = ""
    if (island) island.withdraw(providerId, "reminders")
    return false
  }

  function acceptJsonResponse(exitCode, text, byteCount) {
    if (!started) return false
    if (Number(exitCode) !== 0) return rejectData("reminder command failed")
    if (Number(byteCount) > maxResponseBytes) return rejectData("reminder response exceeds "
      + maxResponseBytes + " bytes")
    try {
      var data = JSON.parse(String(text || ""))
      if (!data || typeof data !== "object" || !Array.isArray(data.reminders))
        return rejectData("invalid reminder data")
      acceptData(data)
      return true
    } catch (error) {
      return rejectData("invalid reminder data")
    }
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
    responseText = ""
    responseBytes = 0
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
    command: [
      "bash", "-c",
      "set -o pipefail; timeout 10s omarchy-reminder show --json | head -c "
        + (root.maxResponseBytes + 1)
    ]
    onStarted: {
      root.responseText = ""
      root.responseBytes = 0
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.responseText = text
        root.responseBytes = data && data.byteLength !== undefined
          ? Number(data.byteLength) : root.utf8ByteLength(text)
      }
    }
    onExited: function(exitCode) {
      Qt.callLater(function() {
        root.acceptJsonResponse(exitCode, root.responseText, root.responseBytes)
      })
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
