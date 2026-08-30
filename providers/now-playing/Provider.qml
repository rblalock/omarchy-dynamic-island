import QtQuick
import Quickshell.Services.Mpris

Item {
  id: root

  property var island: null
  property var shell: null
  property var manifest: null
  property string providerId: "rblalock.now-playing"
  property var playersOverride: null
  property bool started: false
  property string semanticSignature: ""
  property double semanticUpdatedAt: 0

  readonly property var stockMediaService: shell && typeof shell.firstPartyServiceFor === "function"
    ? shell.firstPartyServiceFor("omarchy.media") : null
  readonly property var players: playersOverride !== null
    ? playersOverride
    : (Mpris.players ? Mpris.players.values : [])
  readonly property var player: selectPlayer()

  function isProxyPlayer(candidate) {
    if (!candidate) return false
    var dbusName = String(candidate.dbusName || "").toLowerCase()
    var desktopEntry = String(candidate.desktopEntry || "").toLowerCase()
    return dbusName.indexOf("playerctld") !== -1 || desktopEntry === "playerctld"
  }

  function hasMetadata(candidate) {
    return !!candidate && (String(candidate.trackTitle || "") !== ""
      || String(candidate.trackArtist || "") !== ""
      || String(candidate.identity || candidate.desktopEntry || "") !== "")
  }

  function isOngoing(candidate) {
    return hasMetadata(candidate)
      && candidate.playbackState !== MprisPlaybackState.Stopped
  }

  function playerKey(candidate) {
    if (!candidate) return ""
    if (stockMediaService && typeof stockMediaService.playerKey === "function")
      return String(stockMediaService.playerKey(candidate) || "")
    return String(candidate.dbusName || candidate.desktopEntry || candidate.identity || candidate.uniqueId || "")
  }

  function selectPlayer() {
    var stockPlayer = stockMediaService ? stockMediaService.activePlayer : null
    if (isOngoing(stockPlayer)) return stockPlayer

    var playing = null
    var playingProxy = null
    var idle = null
    var idleProxy = null
    var source = players && typeof players.length === "number" ? players : []
    for (var index = 0; index < source.length; index++) {
      var candidate = source[index]
      if (!isOngoing(candidate)) continue
      var proxy = isProxyPlayer(candidate)
      if (candidate.isPlaying && !proxy && !playing) playing = candidate
      else if (candidate.isPlaying && proxy && !playingProxy) playingProxy = candidate
      else if (!proxy && !idle) idle = candidate
      else if (proxy && !idleProxy) idleProxy = candidate
    }
    return playing || playingProxy || idle || idleProxy || null
  }

  function supportsPlayPause(candidate) {
    return !!candidate && (!!candidate.canTogglePlaying
      || (!!candidate.isPlaying && !!candidate.canPause)
      || (!candidate.isPlaying && !!candidate.canPlay))
  }

  function signatureFor(candidate) {
    if (!candidate) return ""
    return [
      playerKey(candidate),
      String(candidate.trackTitle || ""),
      String(candidate.trackArtist || ""),
      String(candidate.trackAlbum || ""),
      String(candidate.trackArtUrl || ""),
      candidate.isPlaying ? "playing" : "paused",
      candidate.canGoPrevious ? "previous" : "",
      supportsPlayPause(candidate) ? "play-pause" : "",
      candidate.canGoNext ? "next" : ""
    ].join("|")
  }

  function actionsFor(candidate) {
    var actions = []
    if (candidate && candidate.canGoPrevious)
      actions.push({ id: "previous", label: "Previous", glyph: "󰒮" })
    if (supportsPlayPause(candidate)) actions.push({
      id: "play-pause",
      label: candidate.isPlaying ? "Pause" : "Play",
      glyph: candidate.isPlaying ? "󰏤" : "󰐊"
    })
    if (candidate && candidate.canGoNext)
      actions.push({ id: "next", label: "Next", glyph: "󰒭" })
    return actions
  }

  function publish() {
    if (!started || !island) return false
    var active = player
    if (!isOngoing(active)) {
      semanticSignature = ""
      island.withdraw(providerId, "now-playing")
      return false
    }

    var nextSignature = signatureFor(active)
    if (nextSignature !== semanticSignature || semanticUpdatedAt <= 0) {
      semanticSignature = nextSignature
      semanticUpdatedAt = Date.now()
    }

    var title = String(active.trackTitle || active.identity || active.desktopEntry || "Media")
    var artist = String(active.trackArtist || "")
    var album = String(active.trackAlbum || "")
    var identity = String(active.identity || active.desktopEntry || "")
    var position = active.positionSupported ? Math.max(0, Number(active.position) || 0) : 0
    var length = active.lengthSupported ? Math.max(0, Number(active.length) || 0) : 0
    var activity = {
      id: "now-playing",
      title: title,
      subtitle: artist || album || identity,
      glyph: active.isPlaying ? "󰏤" : "󰐊",
      attention: "routine",
      presentation: { rest: "companion" },
      updatedAt: semanticUpdatedAt,
      data: {
        playing: !!active.isPlaying,
        artist: artist,
        album: album,
        identity: identity,
        artUrl: String(active.trackArtUrl || ""),
        position: position,
        length: length,
        positionSupported: !!active.positionSupported && !!active.lengthSupported && length > 0,
        signalKind: "playback-progress"
      },
      actions: actionsFor(active)
    }
    if (activity.data.positionSupported)
      activity.progress = Math.max(0, Math.min(1, position / length))
    return island.publish(providerId, activity)
  }

  function start() {
    started = true
    publish()
  }

  function stop() {
    started = false
    semanticSignature = ""
    if (island) island.withdraw(providerId, "now-playing")
  }

  function runDirect(candidate, actionId) {
    if (!candidate) return false
    if (actionId === "previous" && candidate.canGoPrevious) {
      candidate.previous()
      return true
    }
    if (actionId === "next" && candidate.canGoNext) {
      candidate.next()
      return true
    }
    if (actionId !== "play-pause") return false
    if (candidate.isPlaying && candidate.canPause) {
      candidate.pause()
      return true
    }
    if (!candidate.isPlaying && candidate.canPlay) {
      candidate.play()
      return true
    }
    if (candidate.canTogglePlaying) {
      candidate.togglePlaying()
      return true
    }
    return false
  }

  function onAction(activityId, actionId) {
    if (activityId !== "now-playing") return
    var active = player
    var handled = false
    if (stockMediaService && typeof stockMediaService.runAction === "function") {
      var stockAction = actionId === "play-pause" ? "playPause" : actionId
      handled = stockMediaService.runAction(stockAction, false, playerKey(active)) === true
    }
    if (!handled) handled = runDirect(active, actionId)
    if (handled) Qt.callLater(publish)
  }

  onPlayerChanged: publish()
  onPlayersChanged: publish()

  Connections {
    target: root.player
    enabled: root.started
    ignoreUnknownSignals: true
    function onIsPlayingChanged() { root.publish() }
    function onPlaybackStateChanged() { root.publish() }
    function onTrackTitleChanged() { root.publish() }
    function onTrackArtistChanged() { root.publish() }
    function onTrackAlbumChanged() { root.publish() }
    function onTrackArtUrlChanged() { root.publish() }
    function onPositionChanged() { if (!positionTimer.running) root.publish() }
    function onLengthChanged() { root.publish() }
    function onCanGoPreviousChanged() { root.publish() }
    function onCanGoNextChanged() { root.publish() }
    function onCanTogglePlayingChanged() { root.publish() }
    function onCanPlayChanged() { root.publish() }
    function onCanPauseChanged() { root.publish() }
  }

  Instantiator {
    model: root.players
    active: root.started
    delegate: Connections {
      required property var modelData
      target: modelData
      ignoreUnknownSignals: true
      function onIsPlayingChanged() {
        if (modelData !== root.player) root.publish()
      }
      function onPlaybackStateChanged() {
        if (modelData !== root.player) root.publish()
      }
    }
  }

  Timer {
    id: positionTimer
    interval: 1000
    repeat: true
    running: root.started && root.player && root.player.isPlaying
    onTriggered: root.publish()
  }
}
