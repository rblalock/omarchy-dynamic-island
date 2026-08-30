.pragma library

function _stripComment(line) {
  var quote = ""
  for (var i = 0; i < line.length; i++) {
    var ch = line.charAt(i)
    if ((ch === "\"" || ch === "'") && (i === 0 || line.charAt(i - 1) !== "\\")) {
      if (quote === ch) quote = ""
      else if (quote === "") quote = ch
    }
    if (ch === "#" && quote === "") return line.slice(0, i)
  }
  return line
}

function _splitArray(body) {
  var parts = []
  var quote = ""
  var start = 0
  for (var i = 0; i < body.length; i++) {
    var ch = body.charAt(i)
    if ((ch === "\"" || ch === "'") && (i === 0 || body.charAt(i - 1) !== "\\")) {
      if (quote === ch) quote = ""
      else if (quote === "") quote = ch
    } else if (ch === "," && quote === "") {
      parts.push(body.slice(start, i).trim())
      start = i + 1
    }
  }
  if (body.slice(start).trim() !== "") parts.push(body.slice(start).trim())
  return parts
}

function _value(raw) {
  var value = raw.trim()
  if (value === "true") return true
  if (value === "false") return false
  if (/^[+-]?[0-9]+(?:\.[0-9]+)?$/.test(value)) return Number(value)
  if (value.length >= 2 && value.charAt(0) === "[" && value.charAt(value.length - 1) === "]") {
    var inner = value.slice(1, -1).trim()
    if (inner === "") return []
    return _splitArray(inner).map(_value)
  }
  if (value.length >= 2 && ((value.charAt(0) === "\"" && value.charAt(value.length - 1) === "\"")
      || (value.charAt(0) === "'" && value.charAt(value.length - 1) === "'"))) {
    if (value.charAt(0) === "'") return value.slice(1, -1)
    try { return JSON.parse(value) } catch (e) { return value.slice(1, -1) }
  }
  return value
}

function _key(raw, lineNumber) {
  var key = raw.trim()
  if (key.length >= 2 && ((key.charAt(0) === "\"" && key.charAt(key.length - 1) === "\"")
      || (key.charAt(0) === "'" && key.charAt(key.length - 1) === "'"))) {
    var decoded = _value(key)
    if (typeof decoded !== "string" || decoded === "")
      throw new Error("unsupported key on line " + lineNumber)
    return decoded
  }
  if (!/^[A-Za-z0-9_-]+$/.test(key))
    throw new Error("unsupported key on line " + lineNumber)
  return key
}

function parse(text) {
  var result = {}
  var section = result
  var lines = String(text || "").split(/\r?\n/)
  for (var lineNumber = 0; lineNumber < lines.length; lineNumber++) {
    var line = _stripComment(lines[lineNumber]).trim()
    if (line === "") continue
    if (line.charAt(0) === "[" && line.charAt(line.length - 1) === "]") {
      var path = line.slice(1, -1).trim().split(".")
      section = result
      for (var p = 0; p < path.length; p++) {
        var name = path[p].trim()
        if (!name) throw new Error("empty table name on line " + (lineNumber + 1))
        if (section[name] === undefined) section[name] = {}
        if (typeof section[name] !== "object" || Array.isArray(section[name]))
          throw new Error("table conflicts with value on line " + (lineNumber + 1))
        section = section[name]
      }
      continue
    }
    var equals = line.indexOf("=")
    if (equals <= 0) throw new Error("expected key = value on line " + (lineNumber + 1))
    var key = _key(line.slice(0, equals), lineNumber + 1)
    section[key] = _value(line.slice(equals + 1))
  }
  return result
}

function merge(base, override) {
  var out = {}
  var key
  base = base || {}
  override = override || {}
  for (key in base) {
    if (base[key] && typeof base[key] === "object" && !Array.isArray(base[key]))
      out[key] = merge(base[key], {})
    else if (Array.isArray(base[key])) out[key] = base[key].slice()
    else out[key] = base[key]
  }
  for (key in override) {
    if (override[key] && typeof override[key] === "object" && !Array.isArray(override[key])
        && out[key] && typeof out[key] === "object" && !Array.isArray(out[key]))
      out[key] = merge(out[key], override[key])
    else if (Array.isArray(override[key])) out[key] = override[key].slice()
    else out[key] = override[key]
  }
  return out
}
