import QtQuick

Item {
  id: root

  property var navigationViewport: null
  property bool navigationEnabled: true
  property real navigationMargin: 4

  function collectFocusItems(item, result) {
    var children = item && item.children ? item.children : []
    for (var index = 0; index < children.length; index++) {
      var child = children[index]
      if (!child.visible || !child.enabled) continue
      if (child.activeFocusOnTab) result.push(child)
      collectFocusItems(child, result)
    }
  }

  function focusItems() {
    var result = []
    collectFocusItems(root, result)
    return result
  }

  function focusedItem(items) {
    for (var index = 0; index < items.length; index++)
      if (items[index].activeFocus) return items[index]
    return null
  }

  function directionalTarget(current, horizontal, vertical, items) {
    if (!current) return null
    var origin = current.mapToItem(root, current.width / 2, current.height / 2)
    var best = null
    var bestScore = Number.POSITIVE_INFINITY
    for (var index = 0; index < items.length; index++) {
      var candidate = items[index]
      if (candidate === current) continue
      var center = candidate.mapToItem(root, candidate.width / 2, candidate.height / 2)
      var deltaX = center.x - origin.x
      var deltaY = center.y - origin.y
      var primary = horizontal !== 0 ? deltaX * horizontal : deltaY * vertical
      if (primary <= 0.5) continue
      var orthogonal = horizontal !== 0 ? Math.abs(deltaY) : Math.abs(deltaX)
      var score = primary + orthogonal * 2.5
      if (score < bestScore) {
        best = candidate
        bestScore = score
      }
    }
    return best
  }

  function ensureVisible(item) {
    var viewport = root.navigationViewport
    if (!item || !viewport || viewport.contentHeight <= viewport.height) return
    var position = item.mapToItem(viewport, 0, 0)
    var margin = root.navigationMargin
    if (position.y < margin)
      viewport.contentY = Math.max(0, viewport.contentY + position.y - margin)
    else if (position.y + item.height > viewport.height - margin)
      viewport.contentY = Math.min(viewport.contentHeight - viewport.height,
        viewport.contentY + position.y + item.height - viewport.height + margin)
  }

  function focusBoundary(last, reason) {
    var items = focusItems()
    if (items.length === 0) return false
    var target = items[last ? items.length - 1 : 0]
    target.forceActiveFocus(reason === undefined ? Qt.TabFocusReason : reason)
    ensureVisible(target)
    return true
  }

  function moveFocus(horizontal, vertical) {
    if (!root.navigationEnabled) return false
    var items = focusItems()
    if (items.length === 0) return false
    var current = focusedItem(items)
    if (!current) {
      var reverse = horizontal < 0 || vertical < 0
      return focusBoundary(reverse, Qt.TabFocusReason)
    }
    var target = directionalTarget(current, horizontal, vertical, items)
    if (!target) return false
    target.forceActiveFocus(Qt.TabFocusReason)
    ensureVisible(target)
    return true
  }

  Keys.onPressed: function(event) {
    if (!root.navigationEnabled) {
      event.accepted = false
      return
    }
    var moved = false
    if (event.key === Qt.Key_Left || event.key === Qt.Key_H)
      moved = root.moveFocus(-1, 0)
    else if (event.key === Qt.Key_Right || event.key === Qt.Key_L)
      moved = root.moveFocus(1, 0)
    else if (event.key === Qt.Key_Up || event.key === Qt.Key_K)
      moved = root.moveFocus(0, -1)
    else if (event.key === Qt.Key_Down || event.key === Qt.Key_J)
      moved = root.moveFocus(0, 1)
    else if (event.key === Qt.Key_Home)
      moved = root.focusBoundary(false, Qt.TabFocusReason)
    else if (event.key === Qt.Key_End)
      moved = root.focusBoundary(true, Qt.TabFocusReason)
    event.accepted = moved
  }
}
