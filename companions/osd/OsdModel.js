function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value))
}

function iconFor(name, percent) {
  var n = String(name || "").toLowerCase()
  if (n === "volume-muted" || n === "volume-mute" || n === "muted" || n === "mute") return ""
  if (n === "volume-low") return ""
  if (n === "volume-medium") return ""
  if (n === "volume-high" || n === "volume") return ""
  if (n === "microphone-muted" || n === "microphone-off" || n === "mic-muted" || n === "mic-off") return "󰍭"
  if (n === "microphone" || n === "mic") return "󰍬"
  if (n === "keyboard") return "󰌌"
  if (n === "brightness" || n === "display") return "󰍹"
  if (n === "touchpad") return "󰟸"
  if (n === "touch" || n === "touchscreen") return "󰝁"
  if (n === "reboot" || n === "restart") return "󰜉"
  if (n === "shutdown" || n === "power" || n === "poweroff") return "󰐥"
  if (n === "logout" || n === "sign-out" || n === "leave") return "󰍃"
  if (n === "media" || n === "player" || n === "media-source" || n === "player-source") return "󰝚"
  if (n === "media-play" || n === "player-play") return "󰐊"
  if (n === "media-pause" || n === "player-pause") return "󰏤"
  if (n === "media-next" || n === "player-next") return "󰒭"
  if (n === "media-previous" || n === "player-previous") return "󰒮"
  if (n.length > 0) return String(name)
  if (percent <= 0) return ""
  if (percent <= 33) return ""
  if (percent <= 66) return ""
  return ""
}

function parse(payloadJson) {
  try {
    var p = JSON.parse(payloadJson || "{}")
    var rawMessage = String(p.message || "")
    var rawValue = p.value === undefined ? "" : String(p.value)
    var maxValue = Math.max(1, parseInt(p.max === undefined ? "100" : String(p.max), 10) || 100)
    var parsedValue = parseInt(rawValue || "0", 10)
    var hasProgress = rawValue !== "" && !isNaN(parsedValue) && rawMessage === ""
    var value = hasProgress ? clamp(parsedValue, 0, maxValue) : 0
    var percent = hasProgress ? Math.round(value * 100 / maxValue) : -1
    var parsedDuration = parseInt(p.duration === undefined ? "1200" : String(p.duration), 10)
    return {
      iconKey: String(p.icon || "").toLowerCase(),
      icon: iconFor(p.icon || "", percent),
      message: String(rawMessage || (hasProgress ? (p.progressText || percent + "%") : "")),
      value: value,
      maxValue: maxValue,
      hasProgress: hasProgress,
      duration: isNaN(parsedDuration) ? 1200 : Math.max(0, parsedDuration)
    }
  } catch (error) {
    return null
  }
}
