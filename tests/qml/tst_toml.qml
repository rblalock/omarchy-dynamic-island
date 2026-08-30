import QtQuick
import QtTest
import "../../lib/Toml.js" as Toml

TestCase {
  name: "Toml"

  function test_multilineArrays() {
    var parsed = Toml.parse([
      "[layout]",
      "peek = [",
      "  \"omarchy.menu\",",
      "  \"omarchy.audio\", # trailing comments are allowed",
      "]",
      "",
      "[providers]",
      "disabled = []"
    ].join("\n"))

    compare(parsed.layout.peek.length, 2)
    compare(parsed.layout.peek[0], "omarchy.menu")
    compare(parsed.layout.peek[1], "omarchy.audio")
    compare(parsed.providers.disabled.length, 0)
  }

  function test_unterminatedArray() {
    var failed = false
    try {
      Toml.parse("[layout]\npeek = [\n  \"omarchy.menu\"")
    } catch (error) {
      failed = String(error).indexOf("unterminated array") !== -1
    }
    verify(failed)
  }
}
