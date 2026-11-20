import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "." as TimerCore

BarWidget {
  id: root
  moduleName: "paudelsamir.chrono"

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false
  readonly property bool pomodoroSessionVisible: TimerCore.TimerState.mode === TimerCore.TimerState.pomodoroMode
    && TimerCore.TimerState.pomodoroSessionStarted
  readonly property bool pomodoroBreak: root.pomodoroSessionVisible
    && TimerCore.TimerState.pomodoroPhase.kind !== "focus"
  readonly property bool alarmRinging: TimerCore.TimerState.mode === TimerCore.TimerState.alarmMode
    && TimerCore.TimerState.completed
  readonly property color pomodoroPhaseColor: root.pomodoroBreak
    ? TimerCore.TimerState.pomodoroBreakColor
    : Color.accent
  readonly property color alarmCueColor: root.bar ? root.bar.urgent : Color.urgent

  
  
  readonly property string barDensity: String(root.setting("barDensity", "regular"))
  readonly property string logoBehavior: String(root.setting("logoBehavior", "separate"))
  readonly property string capsuleTone: String(root.setting("capsuleTone", "adaptive"))
  readonly property bool barSeconds: root.setting("barSeconds", true) !== false
  readonly property bool compactBar: root.barDensity === "compact"
  readonly property bool timerActive: TimerCore.TimerState.running
    || root.pomodoroSessionVisible
    || root.alarmRinging

  
  readonly property int todayMs: {
    var revision = TimerCore.Tracker.revision
    return TimerCore.Tracker.totalOn(root.dayKey(new Date()))
  }
  readonly property string todayLabel: {
    if (root.todayMs <= 0) return ""
    var minutes = Math.floor(root.todayMs / 60000)
    var hours = Math.floor(minutes / 60)
    if (hours > 0) return hours + "h " + (minutes % 60) + "m"
    return minutes + "m"
  }

  function dayKey(date) {
    var month = date.getMonth() + 1
    var day = date.getDate()
    return date.getFullYear() + "-" + (month < 10 ? "0" + month : month)
      + "-" + (day < 10 ? "0" + day : day)
  }

  
  
  function shortDuration(milliseconds) {
    var countingUp = TimerCore.TimerState.mode === TimerCore.TimerState.stopwatchMode
    var minutes = countingUp
      ? Math.floor(Math.max(0, milliseconds) / 60000)
      : Math.ceil(Math.max(0, milliseconds) / 60000)
    var hours = Math.floor(minutes / 60)
    if (hours > 0) return hours + "h " + (minutes % 60) + "m"
    if (minutes <= 0) return "<1m"
    return minutes + "m"
  }

  readonly property string barClockText: {
    var raw = TimerCore.TimerState.barTimeText
    if (raw === "") return ""
    
    if (root.compactBar) return root.shortDuration(TimerCore.TimerState.displayMs)
    if (!root.barSeconds) return root.shortDuration(TimerCore.TimerState.displayMs)
    return raw
  }

  
  
  
  readonly property int glyphCanvas: root.compactBar
    ? Math.max(10, Math.round(Style.bar.iconCanvas * 0.9))
    : Style.bar.iconCanvas
  readonly property int glyphPainted: root.compactBar
    ? Math.max(8, Math.round(Style.bar.iconSize * 0.9))
    : Style.bar.iconSize
  readonly property int clockSize: root.compactBar ? Math.max(8, button.fontSize - 1) : button.fontSize
  readonly property int rowSpacing: Style.space(root.compactBar ? 3 : 5)

  readonly property color iconColor: root.alarmRinging
    ? root.alarmCueColor
    : root.pomodoroSessionVisible
      ? root.pomodoroPhaseColor
      : button.active ? button.activeColor : button.foreground

  readonly property string barIconGlyph: {
    if (root.alarmRinging) return String.fromCodePoint(0xF0020)
    if (root.pomodoroSessionVisible) {
      if (TimerCore.TimerState.completed && TimerCore.TimerState.mode === TimerCore.TimerState.pomodoroMode)
        return String.fromCodePoint(0xE001)
      return root.pomodoroBreak
        ? String.fromCodePoint(0xF0176)
        : String.fromCodePoint(0xE003)
    }
    switch (TimerCore.TimerState.mode) {
      case TimerCore.TimerState.stopwatchMode:
        return String.fromCodePoint(0xF2F2)
      case TimerCore.TimerState.countdownMode:
        return String.fromCodePoint(0xF051B)
      case TimerCore.TimerState.intervalsMode:
        return String.fromCodePoint(0xF006B)
      case TimerCore.TimerState.alarmMode:
        return String.fromCodePoint(0xF0020)
      case TimerCore.TimerState.pomodoroMode:
        return String.fromCodePoint(0xE003)
    }
    return String.fromCodePoint(0xF13AB)
  }

  function hasSetting(key) {
    return root.settings !== null && root.settings !== undefined
      && Object.prototype.hasOwnProperty.call(root.settings, key)
  }

  function configuredInt(primary, alias, fallback, minimum, maximum) {
    var value = root.hasSetting(primary)
      ? root.settings[primary]
      : root.hasSetting(alias)
        ? root.settings[alias]
        : fallback
    var parsed = Number(value)
    if (!isFinite(parsed)) parsed = fallback
    return Math.max(minimum, Math.min(maximum, Math.round(parsed)))
  }

  function applyPomodoroSettings() {
    
    
    var sound = root.hasSetting("pomodoroSound")
      ? root.setting("pomodoroSound", true)
      : root.hasSetting("sound")
        ? root.setting("sound", true)
        : TimerCore.TimerState.pomodoroSoundEnabled
    var breakColor = root.hasSetting("pomodoroBreakColor")
      ? root.setting("pomodoroBreakColor", "#a6e3a1")
      : root.hasSetting("breakColor")
        ? root.setting("breakColor", "#a6e3a1")
        : TimerCore.TimerState.pomodoroBreakColor
    TimerCore.TimerState.configurePomodoro(
      root.configuredInt("pomodoroWorkMinutes", "workMinutes", TimerCore.TimerState.pomodoroWorkMinutes, 1, 999),
      root.configuredInt("pomodoroShortBreakMinutes", "shortBreakMinutes", TimerCore.TimerState.pomodoroShortBreakMinutes, 1, 999),
      root.configuredInt("pomodoroCycles", "pomodorosPerCycle", TimerCore.TimerState.pomodoroCycles, 1, 99),
      root.configuredInt("pomodoroLongBreakMinutes", "longBreakMinutes", TimerCore.TimerState.pomodoroLongBreakMinutes, 1, 999),
      sound !== false,
      breakColor
    )
  }

  function applyAlarmSettings() {
    TimerCore.TimerState.setAlarmUses12Hour(root.hasSetting("alarmUses12Hour")
      ? root.setting("alarmUses12Hour", false) === true
      : TimerCore.TimerState.alarmUses12Hour)
    TimerCore.TimerState.setAlarmSound(root.hasSetting("alarmSound")
      ? root.setting("alarmSound", "alarm-clock-elapsed.oga")
      : TimerCore.TimerState.alarmSound)
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: {
    root.applyPomodoroSettings()
    root.applyAlarmSettings()
    root.injectPanel()
  }
  Component.onCompleted: {
    root.applyPomodoroSettings()
    root.applyAlarmSettings()
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    
    
    target: "paudelsamir.chrono"

    function start(): string {
      if (!TimerCore.TimerState.running) TimerCore.TimerState.startPause()
      return TimerCore.TimerState.statusText
    }

    function pause(): string {
      TimerCore.TimerState.pause()
      return TimerCore.TimerState.statusText
    }

    function toggleTimer(): string {
      TimerCore.TimerState.startPause()
      return TimerCore.TimerState.statusText
    }

    function reset(): string {
      TimerCore.TimerState.reset()
      return TimerCore.TimerState.statusText
    }

    function skip(): string {
      TimerCore.TimerState.skipPomodoroPhase()
      return TimerCore.TimerState.statusText
    }

    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.toggle() }

    function page(name: string): string {
      if (panelLoader.item) panelLoader.item.showPage(name)
      return String(name || "")
    }

    function log(): string {
      if (panelLoader.item && typeof panelLoader.item.logManual === "function")
        panelLoader.item.logManual()
      return TimerCore.TimerState.statusText
    }

    function undoLog(): string {
      TimerCore.Tracker.undo()
      return "Undid last log"
    }

    function stopwatch(): string {
      TimerCore.TimerState.selectMode(TimerCore.TimerState.stopwatchMode)
      return TimerCore.TimerState.statusText
    }

    function countdown(minutes: string, seconds: string): string {
      TimerCore.TimerState.selectMode(TimerCore.TimerState.countdownMode)
      TimerCore.TimerState.setCountdownMinutes(parseInt(minutes, 10) || 0)
      TimerCore.TimerState.setCountdownSeconds(parseInt(seconds, 10) || 0)
      return TimerCore.TimerState.statusText
    }

    function intervals(rounds: string, minutes: string, seconds: string): string {
      TimerCore.TimerState.selectMode(TimerCore.TimerState.intervalsMode)
      TimerCore.TimerState.setIntervalRounds(parseInt(rounds, 10) || 1)
      var legacyUnit = String(seconds).toLowerCase()
      var duration = parseInt(minutes, 10) || 0
      if (legacyUnit.indexOf("sec") === 0) {
        TimerCore.TimerState.setIntervalMinutes(Math.floor(duration / 60))
        TimerCore.TimerState.setIntervalSeconds(duration % 60)
      } else if (legacyUnit.indexOf("min") === 0) {
        TimerCore.TimerState.setIntervalMinutes(duration)
        TimerCore.TimerState.setIntervalSeconds(0)
      } else {
        TimerCore.TimerState.setIntervalMinutes(duration)
        TimerCore.TimerState.setIntervalSeconds(parseInt(seconds, 10) || 0)
      }
      return TimerCore.TimerState.statusText
    }

    function alarm(hour: string, minute: string, message: string): string {
      TimerCore.TimerState.selectMode(TimerCore.TimerState.alarmMode)
      TimerCore.TimerState.setAlarmHour(parseInt(hour, 10) || 0)
      TimerCore.TimerState.setAlarmMinute(parseInt(minute, 10) || 0)
      TimerCore.TimerState.setAlarmMessage(message)
      return TimerCore.TimerState.statusText
    }

    function pomodoro(workMinutes: string, shortBreakMinutes: string, cycles: string, longBreakMinutes: string): string {
      TimerCore.TimerState.selectMode(TimerCore.TimerState.pomodoroMode)
      TimerCore.TimerState.setPomodoroWorkMinutes(parseInt(workMinutes, 10) || 25)
      TimerCore.TimerState.setPomodoroShortBreakMinutes(parseInt(shortBreakMinutes, 10) || 5)
      TimerCore.TimerState.setPomodoroCycles(parseInt(cycles, 10) || 4)
      TimerCore.TimerState.setPomodoroLongBreakMinutes(parseInt(longBreakMinutes, 10) || 15)
      return TimerCore.TimerState.statusText
    }

    function status(): string {
      return JSON.stringify({
        mode: TimerCore.TimerState.modeName,
        running: TimerCore.TimerState.running,
        completed: TimerCore.TimerState.completed,
        display: TimerCore.TimerState.displayText,
        status: TimerCore.TimerState.statusText,
        phase: TimerCore.TimerState.mode === TimerCore.TimerState.pomodoroMode
          ? TimerCore.TimerState.pomodoroPhase.label
          : "",
        completedPomodoros: TimerCore.TimerState.mode === TimerCore.TimerState.pomodoroMode
          ? TimerCore.TimerState.pomodoroCompletedCycles
          : 0,
        sound: TimerCore.TimerState.pomodoroSoundEnabled
      })
    }

    function presentation(): string {
      return JSON.stringify({
        height: root.height,
        text: root.barClockText,
        raw: TimerCore.TimerState.barTimeText,
        density: root.barDensity,
        logo: root.logoBehavior,
        tone: root.capsuleTone,
        seconds: root.barSeconds,
        active: root.timerActive
      })
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.vertical
      ? -1
      : timerRow.implicitWidth + button.scaledHorizontalMargin * 2
    active: TimerCore.TimerState.running
    tooltipText: TimerCore.TimerState.modeName + " · " + TimerCore.TimerState.statusText
    onPressed: function(b) {
      if (b === Qt.MiddleButton) TimerCore.TimerState.startPause()
      else if (b === Qt.RightButton) TimerCore.TimerState.reset()
      else root.toggle()
    }

    
    
    Rectangle {
      id: capsule
      anchors.centerIn: parent
      width: parent.width
      height: Math.max(10, Style.space(22))
      radius: Style.space(7)
      color: root.capsuleTone === "accent"
        ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.16)
        : root.capsuleTone === "light"
          ? Qt.rgba(1, 1, 1, 0.12)
          : root.timerActive
            ? Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.06)
            : "transparent"
      border.width: root.capsuleTone === "accent" ? 1 : 0
      border.color: Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.35)

      Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: Style.space(8)
        visible: root.alarmRinging
        color: root.alarmCueColor

        SequentialAnimation on opacity {
          running: root.alarmRinging
          loops: Animation.Infinite
          NumberAnimation { from: 0.12; to: 0.44; duration: 700; easing.type: Easing.InOutSine }
          NumberAnimation { from: 0.44; to: 0.12; duration: 700; easing.type: Easing.InOutSine }
        }
      }

      Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: Style.space(8)
        visible: root.pomodoroSessionVisible
        color: Qt.rgba(
          root.pomodoroPhaseColor.r,
          root.pomodoroPhaseColor.g,
          root.pomodoroPhaseColor.b,
          TimerCore.TimerState.running ? 0.18 : 0.10
        )
      }

      Row {
        id: timerRow
        anchors.centerIn: parent
        spacing: root.rowSpacing

        Item {
          width: root.glyphCanvas
          height: root.glyphCanvas
          anchors.verticalCenter: parent.verticalCenter

          OpticalGlyph {
            anchors.fill: parent
            text: root.barIconGlyph
            fontFamily: button.fontFamily
            fontSize: Style.bar.iconFont
            paintedSize: root.glyphPainted
            color: root.iconColor
          }
        }

        Text {
          visible: !root.vertical && root.barClockText !== ""
          text: root.barClockText
          textFormat: Text.PlainText
          color: root.alarmRinging
            ? root.alarmCueColor
            : root.pomodoroSessionVisible
            ? root.pomodoroPhaseColor
            : button.active ? button.activeColor : button.foreground
          font.family: button.fontFamily
          font.pixelSize: root.clockSize
          renderType: Text.NativeRendering
          anchors.verticalCenter: parent.verticalCenter
        }

      Text {
        
        visible: !root.vertical && root.logoBehavior === "dual" && root.todayLabel !== ""
        text: root.todayLabel
        textFormat: Text.PlainText
        color: Qt.rgba(button.foreground.r, button.foreground.g, button.foreground.b, 0.55)
        font.family: button.fontFamily
        font.pixelSize: Math.max(8, root.clockSize - 1)
        renderType: Text.NativeRendering
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
}
