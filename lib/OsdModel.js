function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value))
}

var limits = ({
  maxPayloadBytes: 4096,
  maxIconChars: 64,
  maxMessageChars: 256,
  maxNumericValue: 1000000000,
  maxDurationMs: 60000
})

function boundedString(value, maxChars) {
  var text = value === undefined || value === null ? "" : String(value)
  return text.length > maxChars ? text.slice(0, maxChars) : text
}

function utf8ByteLength(text, stopAfter) {
  var value = String(text || "")
  var bytes = 0
  for (var index = 0; index < value.length; index++) {
    var code = value.charCodeAt(index)
    if (code <= 0x7f) bytes += 1
    else if (code <= 0x7ff) bytes += 2
    else if (code >= 0xd800 && code <= 0xdbff && index + 1 < value.length
        && value.charCodeAt(index + 1) >= 0xdc00 && value.charCodeAt(index + 1) <= 0xdfff) {
      bytes += 4
      index++
    } else bytes += 3
    if (bytes > stopAfter) return bytes
  }
  return bytes
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

function stateForPayload(payload) {
  var p = payload || {}
  var sourceIcon = boundedString(p.icon, limits.maxIconChars)
  var rawMessage = boundedString(p.message, limits.maxMessageChars)
  var rawValue = p.value === undefined ? "" : String(p.value)
  var rawMax = p.max === undefined ? "100" : String(p.max)
  var rawDuration = p.duration === undefined ? "1200" : String(p.duration)
  var parsedMax = parseInt(rawMax || "100", 10)
  var maxValue = isNaN(parsedMax) ? 100
    : clamp(parsedMax, 1, limits.maxNumericValue)
  var parsedValue = parseInt(rawValue || "0", 10)
  var hasProgress = rawValue !== "" && !isNaN(parsedValue) && rawMessage === ""
  var value = hasProgress ? clamp(parsedValue, 0, maxValue) : 0
  var percent = hasProgress ? Math.round(value * 100 / maxValue) : -1
  var parsedDuration = parseInt(rawDuration || "1200", 10)
  var progressText = boundedString(p.progressText, limits.maxMessageChars)
  var message = rawMessage || (hasProgress ? (progressText || percent + "%") : "")

  return {
    sourceIcon: sourceIcon,
    iconKey: sourceIcon.toLowerCase(),
    glyph: iconFor(sourceIcon, percent),
    icon: iconFor(sourceIcon, percent),
    message: message,
    value: value,
    maxValue: maxValue,
    progress: hasProgress ? value / maxValue : 0,
    hasProgress: hasProgress,
    duration: isNaN(parsedDuration) ? 1200
      : clamp(parsedDuration, 0, limits.maxDurationMs),
    accessibleName: message !== "" ? message : "System status"
  }
}

function parse(payloadJson) {
  try {
    var serialized = typeof payloadJson === "string"
      ? payloadJson : JSON.stringify(payloadJson === undefined ? {} : payloadJson)
    if (serialized === undefined
        || utf8ByteLength(serialized, limits.maxPayloadBytes) > limits.maxPayloadBytes) return null
    var payload = typeof payloadJson === "string" ? JSON.parse(payloadJson || "{}") : payloadJson
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) return null
    return stateForPayload(payload)
  } catch (error) {
    return null
  }
}

function forwardJson(state) {
  if (!state || typeof state !== "object") return ""
  var payload = {
    icon: boundedString(state.sourceIcon, limits.maxIconChars),
    duration: clamp(Number(state.duration) || 0, 0, limits.maxDurationMs)
  }
  if (state.hasProgress) {
    payload.value = clamp(Number(state.value) || 0, 0, limits.maxNumericValue)
    payload.max = clamp(Number(state.maxValue) || 100, 1, limits.maxNumericValue)
    payload.progressText = boundedString(state.message, limits.maxMessageChars)
  } else payload.message = boundedString(state.message, limits.maxMessageChars)
  return JSON.stringify(payload)
}

if (typeof module !== "undefined") {
  module.exports = {
    limits: limits,
    iconFor: iconFor,
    stateForPayload: stateForPayload,
    parse: parse,
    forwardJson: forwardJson
  }
}
