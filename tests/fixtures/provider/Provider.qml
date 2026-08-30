import QtQuick

QtObject {
  required property var island
  required property var manifest
  required property string providerId
  property string lastAction: ""
  property bool started: false

  function notifyObserver(name, value) {
    var observer = manifest ? manifest.__testObserver : null
    if (observer && name in observer) observer[name] = value
  }

  function incrementObserver(name) {
    var observer = manifest ? manifest.__testObserver : null
    if (observer && name in observer) observer[name] = Number(observer[name] || 0) + 1
  }

  function publishActivity() {
    if (!started) return false
    return island.publish(providerId, {
      id: "build",
      title: "Harness activity",
      subtitle: "Provider discovery is live",
      glyph: "H",
      attention: "timely",
      presentation: { rest: "companion" },
      progress: 0.64,
      actions: [{ id: "run", label: "Run" }]
    })
  }

  function start() {
    if (started) return
    started = true
    incrementObserver("starts")
    notifyObserver("running", true)
    publishActivity()
  }

  function stop() {
    if (!started) return
    started = false
    incrementObserver("stops")
    notifyObserver("running", false)
    island.withdrawProvider(providerId)
  }

  function onAction(activityId, actionId) {
    var observer = manifest ? manifest.__testObserver : null
    if (observer && observer.throwActions === true) throw new Error("fixture action failure")
    lastAction = activityId + ":" + actionId
    incrementObserver("actions")
    notifyObserver("lastAction", lastAction)
  }
}
