.pragma library

var schemaVersion = 1
var capabilities = ["activity-provider", "quick-access", "custom-presentation"]
var presentationModes = ["Minimal", "Compact", "Expanded", "Event"]

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
  if (String(metadata.id || pluginId || "") === "") return "provider id is required"
  if (!Array.isArray(metadata.capabilities)) return "capabilities must be an array"

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
  if (access && access.enabled !== false && String(access.target || "") === "")
    return "quickAccess.target is required"

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
