pragma Singleton

import QtQuick
import qs.Commons
import qs.Commons as Commons

// Chrono accent. Text and surfaces stay on the shell palette; these swatches
// only recolor the bits the panel owns (pills, the selected day, the ring).
QtObject {
  id: root

  property string themeKey: "auto"
  property bool frosted: true

  function alpha(color, amount) {
    return Qt.rgba(color.r, color.g, color.b, amount)
  }

  readonly property var swatches: [
    { key: "auto", label: "Auto", color: Commons.Color.accent },
    { key: "rose", label: "Rosé", color: "#e7b4a8" },
    { key: "catppuccin", label: "Catppuccin", color: "#cba6f7" },
    { key: "tokyo", label: "Tokyo", color: "#7aa2f7" },
    { key: "nord", label: "Nord", color: "#88c0d0" },
    { key: "paper", label: "Paper", color: "#d9d0c1" }
  ]

  readonly property color accent: {
    if (root.themeKey === "auto") return Commons.Color.accent
    if (root.themeKey === "catppuccin") return "#cba6f7"
    if (root.themeKey === "tokyo") return "#7aa2f7"
    if (root.themeKey === "nord") return "#88c0d0"
    if (root.themeKey === "paper") return "#d9d0c1"
    return "#e7b4a8"
  }
  readonly property color onAccent: {
    if (root.themeKey === "auto") {
      // pick readable text on the system accent
      var c = Commons.Color.accent
      var lum = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
      return lum > 0.6 ? "#1a1a1a" : "#ffffff"
    }
    return root.themeKey === "paper" ? "#241c16" : "#2a1620"
  }
  readonly property color chart: root.themeKey === "auto" ? Qt.lighter(Commons.Color.accent, 1.15) : "#8eb6f2"

  function modeInk(mode, foreground) {
    if (mode === 1) return "#7eb6ff"
    if (mode === 2) return "#e0b15a"
    if (mode === 3) return "#f2a0b5"
    if (mode === 4) return "#ef6f5e"
    return foreground
  }

  function modeGlyph(mode, onBreak, ringing) {
    if (ringing) return 0xF0020
    if (mode === 4 && onBreak) return 0xF0176
    if (mode === 1) return 0xF051F
    if (mode === 2) return 0xF140B
    if (mode === 3) return 0xF009C
    if (mode === 4) return 0xE003
    return 0xF0150
  }

  readonly property int glyphClock: 0xF0150
  readonly property int glyphChart: 0xF07A1
  readonly property int glyphCog: 0xF08BB
  readonly property int glyphCheck: 0xF012C
  readonly property int glyphClose: 0xF0156
  readonly property int glyphPlus: 0xF0415
  readonly property int glyphChevronLeft: 0xF0141
  readonly property int glyphChevronRight: 0xF0142
  readonly property int glyphUndo: 0xF054C
}