import QtQuick
import "."

Canvas {
  id: root

  property var slices: []
  property int hot: -1
  property color track: Qt.rgba(1, 1, 1, 0.1)

  antialiasing: true

  onSlicesChanged: requestPaint()
  onHotChanged: requestPaint()
  onTrackChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()
  Component.onCompleted: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var size = Math.min(width, height)
    var cx = width / 2
    var cy = height / 2
    var outer = size / 2 - 2
    var thickness = Math.max(12, size * 0.17)
    var mid = outer - thickness / 2
    var total = 0
    var i
    for (i = 0; i < root.slices.length; i++) total += Number(root.slices[i].ms) || 0

    ctx.lineCap = "butt"
    ctx.lineWidth = thickness

    if (total <= 0 || root.slices.length === 0) {
      ctx.beginPath()
      ctx.strokeStyle = root.track
      ctx.arc(cx, cy, mid, 0, Math.PI * 2)
      ctx.stroke()
      return
    }

    // clean gaps between topics
    var count = root.slices.length
    var gap = count > 1 ? 0.14 : 0
    var angle = -Math.PI / 2

    for (i = 0; i < count; i++) {
      var sweep = ((Number(root.slices[i].ms) || 0) / total) * Math.PI * 2
      var draw = sweep - gap
      if (draw <= 0.01) draw = 0.01
      // avoid negative/overdraw on very small slices
      if (draw > sweep) draw = Math.max(0.01, sweep - 0.02)

      var start = angle + gap / 2
      var end = start + draw
      var faded = root.hot >= 0 && root.hot !== i

      ctx.beginPath()
      ctx.globalAlpha = faded ? 0.28 : 1
      ctx.strokeStyle = root.slices[i].color
      ctx.lineWidth = root.hot === i ? thickness + 2 : thickness
      ctx.arc(cx, cy, mid, start, end, false)
      ctx.stroke()
      ctx.globalAlpha = 1

      angle += sweep
    }
  }
}
