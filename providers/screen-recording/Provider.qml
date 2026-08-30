import QtQuick
import Quickshell.Io

Item {
  id: root

  property var island: null
  property var shell: null
  property var manifest: null
  property string providerId: "rblalock.screen-recording"
  property bool started: false
  property bool recording: false
  property bool stopping: false
  property bool completionActive: false
  property int elapsedSeconds: 0
  property string filename: ""
  property string semanticSignature: ""
  property double semanticUpdatedAt: 0
  property var recordingStateOverride: null
  property var actionHandler: null
  property string stopOutput: ""
  property int stopTimeoutMs: 15000

  function basename(path) {
    var value = String(path || "")
    var parts = value.split("/")
    return parts.length > 0 ? parts[parts.length - 1] : value
  }

  function elapsedText(seconds) {
    var value = Math.max(0, Math.floor(Number(seconds) || 0))
    var hours = Math.floor(value / 3600)
    var minutes = Math.floor((value % 3600) / 60)
    var remainder = value % 60
    var shortClock = minutes + ":" + (remainder < 10 ? "0" : "") + remainder
    return hours > 0 ? hours + ":" + (minutes < 10 ? "0" : "") + shortClock : shortClock
  }

  function setSemanticSignature(signature) {
    var next = String(signature || "")
    if (next === semanticSignature && semanticUpdatedAt > 0) return
    semanticSignature = next
    semanticUpdatedAt = Date.now()
  }

  function publishRecording() {
    if (!started || !island) return false
    setSemanticSignature("recording|" + filename + "|" + (stopping ? "stopping" : "active"))
    var state = stopping ? "stopping" : "recording"
    return island.publish(providerId, {
      id: "screen-recording",
      title: stopping ? "Saving recording…" : "Screen recording",
      subtitle: elapsedText(elapsedSeconds),
      glyph: "󰻂",
      attention: "timely",
      presentation: { rest: "companion" },
      updatedAt: semanticUpdatedAt,
      expiresAt: Date.now() + 3000,
      data: {
        state: state,
        elapsedSeconds: elapsedSeconds,
        filename: filename,
        basename: basename(filename)
      },
      primaryAction: stopping ? "" : "stop",
      actions: stopping ? [] : [
        { id: "stop", label: "Stop recording", glyph: "󰓛", destructive: true }
      ]
    })
  }

  function publishCompletion(path) {
    if (!started || !island) return false
    recording = false
    stopping = false
    completionActive = true
    if (String(path || "") !== "") filename = String(path).trim()
    setSemanticSignature("saved|" + filename + "|" + Date.now())
    var now = Date.now()
    completionTimer.restart()
    return island.publish(providerId, {
      id: "screen-recording",
      title: "Recording saved",
      subtitle: basename(filename),
      glyph: "󰄬",
      attention: "timely",
      presentation: { rest: "takeover" },
      updatedAt: semanticUpdatedAt,
      expiresAt: now + completionTimer.interval,
      data: {
        state: "saved",
        elapsedSeconds: elapsedSeconds,
        filename: filename,
        basename: basename(filename)
      },
      actions: [],
      event: {
        id: "saved-" + now,
        title: "Recording saved",
        subtitle: basename(filename),
        glyph: "󰄬",
        attention: "timely"
      }
    })
  }

  function withdraw() {
    recording = false
    stopping = false
    semanticSignature = ""
    semanticUpdatedAt = 0
    if (island) island.withdraw(providerId, "screen-recording")
  }

  function acceptStatus(status) {
    if (!started) return
    var active = !!(status && status.active)
    if (active) {
      completionTimer.stop()
      completionActive = false
      recording = true
      elapsedSeconds = Math.max(0, Math.floor(Number(status.elapsedSeconds) || 0))
      if (String(status.filename || "") !== "") filename = String(status.filename)
      publishRecording()
      return
    }
    recording = false
    if (stopping) publishRecording()
    else if (!completionActive) withdraw()
  }

  function acceptStatusText(text) {
    var line = String(text || "").trim()
    if (line.indexOf("active\t") !== 0) {
      acceptStatus({ active: false })
      return
    }
    var fields = line.split("\t")
    acceptStatus({
      active: true,
      elapsedSeconds: Number(fields[1] || 0),
      filename: fields.slice(2).join("\t")
    })
  }

  function refresh() {
    if (!started) return false
    if (recordingStateOverride !== null) {
      acceptStatus(recordingStateOverride)
      return true
    }
    if (statusProcess.running) return false
    statusProcess.running = true
    return true
  }

  function start() {
    started = true
    refresh()
  }

  function stop() {
    started = false
    statusTimer.stop()
    completionTimer.stop()
    stopTimeout.stop()
    if (statusProcess.running) statusProcess.running = false
    completionActive = false
    withdraw()
  }

  function beginStop() {
    if (!recording || stopping) return false
    stopping = true
    publishRecording()
    if (actionHandler && typeof actionHandler.run === "function") {
      var handled = actionHandler.run("stop") === true
      if (!handled) {
        stopping = false
        publishRecording()
      } else {
        stopTimeout.restart()
      }
      return handled
    }
    stopOutput = ""
    stopTimeout.restart()
    stopProcess.running = true
    return true
  }

  function finishStop(exitCode, output) {
    if (!started || !stopping) return
    stopTimeout.stop()
    stopping = false
    recording = false
    var path = String(output || "").trim().split("\n").filter(function(line) {
      return String(line).trim() !== ""
    }).pop() || ""
    if (Number(exitCode) === 0) publishCompletion(path)
    else {
      completionActive = false
      withdraw()
      delayedRefresh.restart()
    }
  }

  function stopTimedOut() {
    if (!stopping) return false
    stopTimeout.stop()
    if (stopProcess.running) stopProcess.running = false
    completionActive = false
    withdraw()
    delayedRefresh.restart()
    return true
  }

  function onAction(activityId, actionId) {
    if (activityId === "screen-recording" && actionId === "stop") beginStop()
  }

  Process {
    id: statusProcess
    command: ["bash", "-c",
      "pid=$(pgrep -o -f '^gpu-screen-recorder') || { printf 'inactive\\n'; exit 0; }; elapsed=$(ps -o etimes= -p \"$pid\" | tr -d '[:space:]'); file=$(cat /tmp/omarchy-screenrecord-filename 2>/dev/null); printf 'active\\t%s\\t%s\\n' \"${elapsed:-0}\" \"$file\""]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.acceptStatusText(text)
    }
  }

  Process {
    id: stopProcess
    command: ["omarchy", "capture", "screenrecording", "--stop-recording"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.stopOutput = text
    }
    onExited: function(exitCode) {
      Qt.callLater(function() { root.finishStop(exitCode, root.stopOutput) })
    }
  }

  Timer {
    id: statusTimer
    interval: 1000
    repeat: true
    running: root.started && root.recordingStateOverride === null
    onTriggered: root.refresh()
  }

  Timer {
    id: completionTimer
    interval: 5200
    onTriggered: {
      root.completionActive = false
      root.withdraw()
    }
  }

  Timer {
    id: delayedRefresh
    interval: 500
    onTriggered: root.refresh()
  }

  Timer {
    id: stopTimeout
    interval: root.stopTimeoutMs
    onTriggered: root.stopTimedOut()
  }
}
