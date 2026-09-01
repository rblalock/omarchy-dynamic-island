.pragma library

var schemaVersion = 1
var capabilities = ["activity-provider", "quick-access", "custom-presentation"]
var presentationModes = ["Minimal", "Compact", "Expanded", "Event"]
var limits = ({
  maxActivitiesPerProvider: 32,
  maxActivitiesTotal: 128,
  maxActionsPerActivity: 8,
  maxIdentifierChars: 128,
  maxTitleChars: 256,
  maxSubtitleChars: 512,
  maxLabelChars: 256,
  maxGlyphChars: 16,
  maxDataBytes: 65536
})

function boundedString(value, maxChars, fallback) {
  var text = value === undefined || value === null || String(value) === ""
    ? String(fallback || "") : String(value)
  var limit = Math.max(0, Number(maxChars) || 0)
  return limit > 0 && text.length > limit ? text.slice(0, limit) : text
}

function identifierError(value, label) {
  var text = String(value || "")
  var name = String(label || "identifier")
  if (text === "") return name + " is required"
  if (text.length > limits.maxIdentifierChars)
    return name + " exceeds " + limits.maxIdentifierChars + " characters"
  return ""
}

function utf8ByteLength(text, stopAfter) {
  var value = String(text || "")
  var stop = Math.max(0, Number(stopAfter) || 0)
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
    if (stop > 0 && bytes > stop) return bytes
  }
  return bytes
}

function normalizedData(value) {
  if (value === undefined || value === null) return { ok: true, value: ({}) }
  if (typeof value !== "object") return { ok: false, error: "activity data must be an object" }
  try {
    var serialized = JSON.stringify(value)
    if (serialized === undefined)
      return { ok: false, error: "activity data must be JSON-serializable" }
    if (utf8ByteLength(serialized, limits.maxDataBytes) > limits.maxDataBytes)
      return { ok: false, error: "activity data exceeds " + limits.maxDataBytes + " bytes" }
    return { ok: true, value: JSON.parse(serialized) }
  } catch (error) {
    return { ok: false, error: "activity data must be JSON-serializable" }
  }
}

function presentationEntryPoints(candidate) {
  var entryPoints = candidate && candidate.entryPoints ? candidate.entryPoints : ({})
  var presentations = []
  for (var index = 0; index < presentationModes.length; index++) {
    var key = "omarchyIsland" + presentationModes[index]
    if (entryPoints[key]) presentations.push(presentationModes[index].toLowerCase())
  }
  return presentations
}

function registrationError(candidate, pluginId) {
  var metadata = candidate ? candidate.omarchyIsland : null
  if (!metadata || typeof metadata !== "object") return "missing omarchyIsland metadata"
  if (Number(metadata.schemaVersion) !== schemaVersion)
    return "unsupported omarchyIsland schemaVersion"
  var providerError = identifierError(metadata.id || pluginId, "provider id")
  if (providerError !== "") return providerError
  if (!Array.isArray(metadata.capabilities)) return "capabilities must be an array"
  if (metadata.capabilities.length > capabilities.length)
    return "capabilities exceeds " + capabilities.length + " entries"

  var declared = metadata.capabilities.map(function(value) { return String(value || "") })
  for (var index = 0; index < declared.length; index++) {
    if (capabilities.indexOf(declared[index]) === -1)
      return "unsupported capability: " + declared[index]
    if (declared.indexOf(declared[index]) !== index)
      return "duplicate capability: " + declared[index]
  }

  var entryPoints = candidate && candidate.entryPoints ? candidate.entryPoints : ({})
  var providerEntryPoint = String(entryPoints.omarchyIslandProvider || "")
  var hasProviderCapability = declared.indexOf("activity-provider") !== -1
  if (hasProviderCapability !== (providerEntryPoint !== ""))
    return "activity-provider capability and entry point must be declared together"

  var access = metadata.quickAccess
  var hasQuickAccessCapability = declared.indexOf("quick-access") !== -1
  if (hasQuickAccessCapability !== !!(access && typeof access === "object"))
    return "quick-access capability and metadata must be declared together"
  if (access && access.enabled !== false) {
    var accessIdError = identifierError(access.id || pluginId, "quickAccess.id")
    if (accessIdError !== "") return accessIdError
    var accessTargetError = identifierError(access.target, "quickAccess.target")
    if (accessTargetError !== "") return accessTargetError
  }

  var presentations = presentationEntryPoints(candidate)
  var hasCustomCapability = declared.indexOf("custom-presentation") !== -1
  if (presentations.length > 0 && !hasCustomCapability)
    return "custom presentation entry points require the custom-presentation capability"
  if (hasCustomCapability && presentations.length === 0)
    return "custom-presentation capability requires a presentation entry point"
  if (presentations.length > 0 && !hasProviderCapability)
    return "custom presentations require an activity provider"
  return ""
}
