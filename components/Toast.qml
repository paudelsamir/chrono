import QtQuick
import qs.Commons

// Full-width confirmation banner at the top of the timers page. Chrono's
// "Logged 25m · 1h 30m today" needs to be readable while the pointer stays
// where it is, so it appears in-panel rather than as a desktop notification
// that can be missed. `show()` restarts the hold timer instead of stacking.
Rectangle {
  id: root

  property string text: ""
  property color ink: Color.foreground
  property string fontFamily: Style.font.family
  property int holdTime: 2400
  property int phase: 0 // 0 hidden, 1 shown

  function show(message) {
    var next = String(message || "")
    if (next === "") return
    root.text = next
    root.phase = 1
    hideTimer.restart()
  }

  visible: root.phase === 1 || opacity > 0
  implicitHeight: root.phase === 1 ? Style.space(34) : 0
  radius: Style.space(10)
  color: ChronoTheme.alpha(root.ink, 0.1)
  border.width: 1
  border.color: ChronoTheme.alpha(ChronoTheme.accent, 0.55)
  opacity: root.phase === 1 ? 1 : 0
  Behavior on implicitHeight { NumberAnimation { duration: Style.duration(140) } }
  Behavior on opacity { NumberAnimation { duration: Style.duration(140) } }

  Text {
    text: root.text
    textFormat: Text.PlainText
    color: root.ink
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    anchors.centerIn:parent
    width: parent.width - Style.space(28)
    elide: Text.ElideRight
  }

  Timer {
    id: hideTimer
    interval: root.holdTime
    onTriggered: root.phase = 0
  }
}
