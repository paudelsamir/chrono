import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import ".." as Chrono
import "../components"
import "../components/Format.js" as Format

Column {
  id: root

  property color ink: Color.foreground
  property string fontFamily: Style.font.family
  property string syncActivityId: ""
  property bool showRounds: true
  property bool showAlarm: true
  property int cursorIndex: 0

  signal logged()

  function ensureVisibleMode() {
    var state = Chrono.TimerState
    if (!root.showRounds && state.mode === state.intervalsMode)
      state.selectMode(state.stopwatchMode)
    if (!root.showAlarm && state.mode === state.alarmMode)
      state.selectMode(state.stopwatchMode)
  }

  onShowRoundsChanged: root.ensureVisibleMode()
  onShowAlarmChanged: root.ensureVisibleMode()

  readonly property bool idleMajor: !Chrono.TimerState.running
    && Chrono.TimerState.storedElapsedMs === 0
    && !Chrono.TimerState.completed
  readonly property bool canEditMajorTime: root.idleMajor
    && (Chrono.TimerState.mode === Chrono.TimerState.countdownMode
      || Chrono.TimerState.mode === Chrono.TimerState.alarmMode)
  readonly property bool editing: sessionField.activeFocus
    || majorLeft.field.activeFocus
    || majorRight.field.activeFocus
    || alarmMessage.activeFocus
    || roundsField.field.activeFocus
    || minutesField.field.activeFocus
    || secondsField.field.activeFocus
    || workField.field.activeFocus
    || shortField.field.activeFocus
    || cyclesField.field.activeFocus
    || longField.field.activeFocus

  readonly property var cursorTargets: {
    if (Chrono.TimerState.running) return []
    var mode = Chrono.TimerState.mode
    if (mode === Chrono.TimerState.countdownMode) {
      var countdown = []
      if (root.canEditMajorTime) {
        countdown.push({ key: "major-left", kind: "time" })
        countdown.push({ key: "major-right", kind: "time" })
      }
      countdown.push({ key: "session", kind: "text" })
      return countdown
    }
    if (mode === Chrono.TimerState.alarmMode) {
      var alarm = []
      if (root.canEditMajorTime) {
        alarm.push({ key: "major-left", kind: "time" })
        alarm.push({ key: "major-right", kind: "time" })
        if (Chrono.TimerState.alarmUses12Hour) {
          alarm.push({ key: "alarm-am", kind: "button" })
          alarm.push({ key: "alarm-pm", kind: "button" })
        }
      }
      alarm.push({ key: "alarm-format", kind: "toggle" })
      alarm.push({ key: "alarm-sound", kind: "button" })
      alarm.push({ key: "alarm-message", kind: "text" })
      return alarm
    }
    if (mode === Chrono.TimerState.intervalsMode) {
      return [
        { key: "rounds", kind: "number" },
        { key: "minutes", kind: "number" },
        { key: "seconds", kind: "number" },
        { key: "session", kind: "text" }
      ]
    }
    if (mode === Chrono.TimerState.pomodoroMode) {
      if (Chrono.TimerState.pomodoroSessionStarted || Chrono.TimerState.completed) return []
      return [
        { key: "work", kind: "number" },
        { key: "short", kind: "number" },
        { key: "cycles", kind: "number" },
        { key: "long", kind: "number" },
        { key: "sound", kind: "toggle" },
        { key: "session", kind: "text" }
      ]
    }
    return [{ key: "session", kind: "text" }]
  }
  readonly property string cursorKey: cursorTargets.length > 0
    ? cursorTargets[Math.max(0, Math.min(cursorIndex, cursorTargets.length - 1))].key
    : ""

  function clampCursor() {
    if (root.cursorTargets.length === 0) root.cursorIndex = 0
    else root.cursorIndex = Math.max(0, Math.min(root.cursorIndex, root.cursorTargets.length - 1))
  }

  function moveCursor(direction) {
    var count = root.cursorTargets.length
    if (count === 0) return false
    root.cursorIndex = (root.cursorIndex + direction + count) % count
    return true
  }

  function beginField(key) {
    if (key === "major-left") majorLeft.beginEditing()
    else if (key === "major-right") majorRight.beginEditing()
    else if (key === "rounds") roundsField.beginEditing()
    else if (key === "minutes") minutesField.beginEditing()
    else if (key === "seconds") secondsField.beginEditing()
    else if (key === "work") workField.beginEditing()
    else if (key === "short") shortField.beginEditing()
    else if (key === "cycles") cyclesField.beginEditing()
    else if (key === "long") longField.beginEditing()
    else if (key === "session") sessionField.forceActiveFocus()
    else if (key === "alarm-message") alarmMessage.forceActiveFocus()
  }

  function activate() {
    if (root.cursorTargets.length === 0) return false
    var key = root.cursorKey
    var kind = root.cursorTargets[root.cursorIndex].kind
    if (kind === "time" || kind === "number" || kind === "text") root.beginField(key)
    else if (key === "alarm-format") Chrono.TimerState.setAlarmUses12Hour(!Chrono.TimerState.alarmUses12Hour)
    else if (key === "alarm-am") Chrono.TimerState.setAlarmMeridiem("AM")
    else if (key === "alarm-pm") Chrono.TimerState.setAlarmMeridiem("PM")
    else if (key === "alarm-sound") Chrono.TimerState.cycleAlarmSound(1)
    else if (key === "sound") Chrono.TimerState.setPomodoroSoundEnabled(!Chrono.TimerState.pomodoroSoundEnabled)
    return true
  }

  function adjust(direction) {
    var key = root.cursorKey
    var state = Chrono.TimerState
    if (key === "rounds") state.setIntervalRounds(state.intervalRounds + direction)
    else if (key === "minutes") state.setIntervalMinutes(state.intervalMinutes + direction)
    else if (key === "seconds") state.setIntervalSeconds(state.intervalSeconds + direction)
    else if (key === "work") state.setPomodoroWorkMinutes(state.pomodoroWorkMinutes + direction)
    else if (key === "short") state.setPomodoroShortBreakMinutes(state.pomodoroShortBreakMinutes + direction)
    else if (key === "cycles") state.setPomodoroCycles(state.pomodoroCycles + direction)
    else if (key === "long") state.setPomodoroLongBreakMinutes(state.pomodoroLongBreakMinutes + direction)
    else if (key === "sound") state.setPomodoroSoundEnabled(direction > 0)
    else if (key === "alarm-format") state.setAlarmUses12Hour(direction > 0)
    else if (key === "alarm-am" || key === "alarm-pm")
      state.setAlarmMeridiem(direction > 0 ? "PM" : "AM")
    else if (key === "alarm-sound") state.cycleAlarmSound(direction)
  }

  function moveHorizontal(direction) {
    if (root.cursorKey === "major-left" && direction > 0) root.selectKey("major-right")
    else if (root.cursorKey === "major-right" && direction < 0) root.selectKey("major-left")
    else root.adjust(direction)
  }

  function selectKey(key) {
    for (var i = 0; i < root.cursorTargets.length; i++) {
      if (root.cursorTargets[i].key === key) {
        root.cursorIndex = i
        return
      }
    }
  }

  function commitSession() {
    Chrono.TimerState.sessionName = sessionField.text
  }

  readonly property int logMs: {
    var state = Chrono.TimerState
    if (state.mode === state.alarmMode) return 0
    if (state.elapsedMs >= 1000) return state.elapsedMs
    if (state.mode === state.stopwatchMode) return 0
    return state.targetMs
  }

  readonly property string todayLabel: {
    var total = Chrono.Tracker.totalOn(Format.dayKey(new Date()))
    if (total <= 0) return ""
    var minutes = Math.round(total / 60000)
    var hours = Math.floor(minutes / 60)
    if (hours > 0) return hours + "h " + (minutes % 60) + "m today"
    return minutes + "m today"
  }

  function manualLog() {
    var state = Chrono.TimerState
    if (root.logMs < 1000) return
    // A finished block that the panel already wrote to the tracker must not be
    // logged a second time by this button.
    if (state.completed && state.lastBlockLogged) {
      toast.show("Already logged · " + root.todayLabel)
      return
    }
    var amount = root.logMs
    var elapsed = state.elapsedMs >= 1000
    var who = String(state.sessionName || "").trim()
    var activity = Chrono.Tracker.logNamed(who, root.syncActivityId, amount, "manual", state.modeName)
    if (!activity) {
      toast.show("Nothing to log yet")
      return
    }
    var name = who !== "" ? who : activity
    toast.show("Logged " + Format.formatHM(amount) + " · " + name
      + (root.todayLabel !== "" ? " · " + root.todayLabel : ""))
    if (elapsed) state.reset()
    root.logged()
  }

  spacing: Style.space(12)
  width: parent.width

  Toast {
    id: toast
    z: 10
    width: parent.width
    ink: root.ink
    fontFamily: root.fontFamily
  }

  Connections {
    target: Chrono.TimerState
    function onModeChanged() { root.cursorIndex = 0 }
    function onRunningChanged() { root.clampCursor() }
    function onPomodoroSessionStartedChanged() { root.clampCursor() }
  }

  Row {
    id: modeRow
    width: parent.width
    spacing: Style.space(6)
    readonly property var modes: {
      var list = [
        { label: "Watch", value: Chrono.TimerState.stopwatchMode },
        { label: "Timer", value: Chrono.TimerState.countdownMode }
      ]
      if (root.showRounds) list.push({ label: "Rounds", value: Chrono.TimerState.intervalsMode })
      if (root.showAlarm) list.push({ label: "Alarm", value: Chrono.TimerState.alarmMode })
      list.push({ label: "Pomo", value: Chrono.TimerState.pomodoroMode })
      return list
    }
    readonly property real cellWidth: (width - spacing * (modes.length - 1)) / modes.length

    Repeater {
      model: modeRow.modes

      Rectangle {
        required property var modelData
        readonly property bool selected: Chrono.TimerState.mode === modelData.value
        readonly property bool active: Chrono.TimerState.running || Chrono.TimerState.completed
        width: modeRow.cellWidth
        height: Style.space(34)
        radius: Style.space(10)
        color: selected
          ? (active ? ChronoTheme.accent : ChronoTheme.alpha(root.ink, 0.12))
          : ChronoTheme.alpha(root.ink, 0.05)
        border.width: 1
        border.color: selected
          ? (active ? ChronoTheme.accent : ChronoTheme.alpha(root.ink, 0.22))
          : ChronoTheme.alpha(root.ink, 0.1)
        opacity: !Chrono.TimerState.running || selected ? 1 : 0.45

        Row {
          anchors.centerIn: parent
          spacing: Style.space(4)
          Text {
            text: String.fromCodePoint(ChronoTheme.modeGlyph(modelData.value, false, false))
            color: selected && active ? ChronoTheme.onAccent : root.ink
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            anchors.verticalCenter: parent.verticalCenter
          }
          Text {
            text: modelData.label
            color: selected && active ? ChronoTheme.onAccent : root.ink
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: selected
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          enabled: !Chrono.TimerState.running
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: Chrono.TimerState.selectMode(modelData.value)
        }
      }
    }
  }

  Item {
    width: parent.width
    implicitHeight: statusRow.implicitHeight

    Row {
      id: statusRow
      spacing: Style.space(6)
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      Text {
        text: String.fromCodePoint(ChronoTheme.modeGlyph(
          Chrono.TimerState.mode,
          Chrono.TimerState.pomodoroPhaseKind !== "focus",
          Chrono.TimerState.mode === Chrono.TimerState.alarmMode && Chrono.TimerState.completed))
        color: (Chrono.TimerState.running || Chrono.TimerState.completed)
          ? ChronoTheme.modeInk(Chrono.TimerState.mode, root.ink)
          : ChronoTheme.alpha(root.ink, 0.72)
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: {
          var state = Chrono.TimerState
          if (state.completed) return state.statusText
          if (!state.running && state.storedElapsedMs === 0 && !state.pomodoroSessionStarted) return "Ready"
          if (!state.running) return "Paused"
          return state.statusText
        }
        textFormat: Text.PlainText
        color: root.ink
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: {
        var state = Chrono.TimerState
        if (state.mode === state.intervalsMode) return state.currentRound + "/" + state.intervalRounds
        if (state.mode === state.pomodoroMode) return state.pomodoroCurrentCycle + "/" + state.pomodoroCycles
        return ""
      }
      color: ChronoTheme.alpha(root.ink, 0.55)
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }

  Text {
    visible: !root.canEditMajorTime
    width: parent.width
    text: Chrono.TimerState.displayText
    textFormat: Text.PlainText
    color: root.ink
    font.family: root.fontFamily
    font.pixelSize: Style.font.displayLarge * 2
    font.bold: true
    horizontalAlignment: Text.AlignHCenter
  }

  Row {
    id: majorRow
    visible: root.canEditMajorTime
    width: parent.width
    spacing: Style.space(8)
    readonly property bool hasMeridiem: Chrono.TimerState.mode === Chrono.TimerState.alarmMode
      && Chrono.TimerState.alarmUses12Hour
    readonly property real timeFieldWidth: Math.max(Style.space(88),
      (width - Style.space(18) - (hasMeridiem ? Style.space(58) + spacing : 0) - spacing * (hasMeridiem ? 3 : 2)) / 2)

    Chrono.TimeField {
      id: majorLeft
      width: majorRow.timeFieldWidth
      fieldWidth: width
      label: Chrono.TimerState.mode === Chrono.TimerState.alarmMode ? "Hour" : "Minutes"
      from: Chrono.TimerState.mode === Chrono.TimerState.alarmMode && Chrono.TimerState.alarmUses12Hour ? 1 : 0
      to: Chrono.TimerState.mode === Chrono.TimerState.alarmMode
        ? Chrono.TimerState.alarmUses12Hour ? 12 : 23 : 999
      value: Chrono.TimerState.mode === Chrono.TimerState.alarmMode
        ? Chrono.TimerState.alarmDisplayHour : Chrono.TimerState.countdownMinutes
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      hasCursor: root.cursorKey === "major-left"
      onModified: function(value) {
        if (Chrono.TimerState.mode === Chrono.TimerState.alarmMode)
          Chrono.TimerState.alarmUses12Hour
            ? Chrono.TimerState.setAlarmDisplayHour(value)
            : Chrono.TimerState.setAlarmHour(value)
        else Chrono.TimerState.setCountdownMinutes(value)
      }
      onHoveredChangedByPointer: function(hovered) { if (hovered) root.selectKey("major-left") }
    }

    Text {
      width: Style.space(18)
      text: ":"
      color: root.ink
      font.family: root.fontFamily
      font.pixelSize: Style.font.displayLarge * 2
      font.bold: true
      horizontalAlignment: Text.AlignHCenter
      anchors.top: majorLeft.top
    }

    Chrono.TimeField {
      id: majorRight
      width: majorRow.timeFieldWidth
      fieldWidth: width
      label: Chrono.TimerState.mode === Chrono.TimerState.alarmMode ? "Minute" : "Seconds"
      from: 0
      to: 59
      value: Chrono.TimerState.mode === Chrono.TimerState.alarmMode
        ? Chrono.TimerState.alarmMinute : Chrono.TimerState.countdownSeconds
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      hasCursor: root.cursorKey === "major-right"
      onModified: function(value) {
        if (Chrono.TimerState.mode === Chrono.TimerState.alarmMode) Chrono.TimerState.setAlarmMinute(value)
        else Chrono.TimerState.setCountdownSeconds(value)
      }
      onHoveredChangedByPointer: function(hovered) { if (hovered) root.selectKey("major-right") }
    }

    Column {
      visible: majorRow.hasMeridiem
      width: Style.space(58)
      spacing: Style.space(4)

      Rectangle {
        width: parent.width
        height: Style.space(28)
        radius: Style.space(8)
        color: Chrono.TimerState.alarmMeridiem === "AM" ? ChronoTheme.accent : ChronoTheme.alpha(root.ink, 0.06)
        border.width: 1
        border.color: root.cursorKey === "alarm-am" ? ChronoTheme.accent : ChronoTheme.alpha(root.ink, 0.12)
        Text {
          anchors.centerIn: parent
          text: "AM"
          color: Chrono.TimerState.alarmMeridiem === "AM" ? ChronoTheme.onAccent : root.ink
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Chrono.TimerState.setAlarmMeridiem("AM")
          onContainsMouseChanged: if (containsMouse) root.selectKey("alarm-am")
          hoverEnabled: true
        }
      }

      Rectangle {
        width: parent.width
        height: Style.space(28)
        radius: Style.space(8)
        color: Chrono.TimerState.alarmMeridiem === "PM" ? ChronoTheme.accent : ChronoTheme.alpha(root.ink, 0.06)
        border.width: 1
        border.color: root.cursorKey === "alarm-pm" ? ChronoTheme.accent : ChronoTheme.alpha(root.ink, 0.12)
        Text {
          anchors.centerIn: parent
          text: "PM"
          color: Chrono.TimerState.alarmMeridiem === "PM" ? ChronoTheme.onAccent : root.ink
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Chrono.TimerState.setAlarmMeridiem("PM")
          hoverEnabled: true
          onContainsMouseChanged: if (containsMouse) root.selectKey("alarm-pm")
        }
      }
    }
  }

  Item {
    visible: Chrono.TimerState.mode !== Chrono.TimerState.stopwatchMode
    width: parent.width
    implicitHeight: Style.space(6)

    Rectangle {
      anchors.fill: parent
      radius: Style.space(4)
      color: ChronoTheme.alpha(root.ink, 0.1)
    }

    Rectangle {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: Chrono.TimerState.progress <= 0 ? 0 : Math.max(height, parent.width * Chrono.TimerState.progress)
      height: parent.height
      radius: Style.space(4)
      color: ChronoTheme.accent
      Behavior on width { NumberAnimation { duration: 90 } }
    }
  }

  TextField {
    id: sessionField
    visible: Chrono.TimerState.mode !== Chrono.TimerState.alarmMode
    width: parent.width
    text: Chrono.TimerState.sessionName
    placeholderText: "Session name (same name logs together)…"
    foreground: root.ink
    accent: ChronoTheme.accent
    font.family: root.fontFamily
    hasCursor: root.cursorKey === "session"
    onEditingFinished: root.commitSession()
    onHoveredChanged: if (hovered) root.selectKey("session")
    Keys.onEscapePressed: focus = false
    Keys.onReturnPressed: { root.commitSession(); focus = false }
    Keys.onEnterPressed: { root.commitSession(); focus = false }
  }

  Row {
    visible: Chrono.TimerState.mode === Chrono.TimerState.intervalsMode
    width: parent.width
    spacing: Style.space(8)

    Chrono.CompactField {
      id: roundsField
      width: (parent.width - parent.spacing * 2) / 3
      fieldWidth: width
      label: "Rounds"
      from: 1
      to: 999
      value: Chrono.TimerState.intervalRounds
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      hasCursor: root.cursorKey === "rounds"
      enabled: !Chrono.TimerState.running
      onModified: function(value) { Chrono.TimerState.setIntervalRounds(value) }
      onHoveredChangedByPointer: function(hovered) { if (hovered) root.selectKey("rounds") }
    }

    Chrono.CompactField {
      id: minutesField
      width: (parent.width - parent.spacing * 2) / 3
      fieldWidth: width
      label: "Min"
      from: 0
      to: 999
      value: Chrono.TimerState.intervalMinutes
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      hasCursor: root.cursorKey === "minutes"
      enabled: !Chrono.TimerState.running
      onModified: function(value) { Chrono.TimerState.setIntervalMinutes(value) }
      onHoveredChangedByPointer: function(hovered) { if (hovered) root.selectKey("minutes") }
    }

    Chrono.CompactField {
      id: secondsField
      width: (parent.width - parent.spacing * 2) / 3
      fieldWidth: width
      label: "Sec"
      from: 0
      to: 59
      value: Chrono.TimerState.intervalSeconds
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      hasCursor: root.cursorKey === "seconds"
      enabled: !Chrono.TimerState.running
      onModified: function(value) { Chrono.TimerState.setIntervalSeconds(value) }
      onHoveredChangedByPointer: function(hovered) { if (hovered) root.selectKey("seconds") }
    }
  }

  Column {
    visible: Chrono.TimerState.mode === Chrono.TimerState.alarmMode
    width: parent.width
    spacing: Style.space(8)

    Toggle {
      id: alarmFormatToggle
      width: parent.width
      label: "12-hour time"
      description: "Enter the alarm with AM or PM"
      checked: Chrono.TimerState.alarmUses12Hour
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      hasCursor: root.cursorKey === "alarm-format"
      enabled: !Chrono.TimerState.running
      onClicked: if (enabled) Chrono.TimerState.setAlarmUses12Hour(!Chrono.TimerState.alarmUses12Hour)
      onHovered: function(hovered) { if (hovered) root.selectKey("alarm-format") }
    }

    SoftButton {
      id: alarmSoundButton
      width: parent.width
      label: "Sound  ·  " + Chrono.TimerState.alarmSoundName
      ink: root.ink
      fontFamily: root.fontFamily
      enabled: !Chrono.TimerState.running
      onClicked: Chrono.TimerState.cycleAlarmSound(1)
    }

    TextField {
      id: alarmMessage
      width: parent.width
      text: Chrono.TimerState.alarmMessage
      placeholderText: "Alarm"
      foreground: root.ink
      accent: ChronoTheme.accent
      font.family: root.fontFamily
      hasCursor: root.cursorKey === "alarm-message"
      enabled: !Chrono.TimerState.running
      onEditingFinished: Chrono.TimerState.setAlarmMessage(text)
      onHoveredChanged: if (hovered) root.selectKey("alarm-message")
    }
  }

  Column {
    visible: Chrono.TimerState.mode === Chrono.TimerState.pomodoroMode
    width: parent.width
    spacing: Style.space(8)

    Row {
      width: parent.width
      spacing: Style.space(8)
      Chrono.CompactField {
        id: workField
        width: (parent.width - parent.spacing) / 2
        fieldWidth: width
        label: "Focus"
        from: 1
        to: 999
        value: Chrono.TimerState.pomodoroWorkMinutes
        foreground: root.ink
        accent: ChronoTheme.accent
        fontFamily: root.fontFamily
        hasCursor: root.cursorKey === "work"
        enabled: !Chrono.TimerState.pomodoroSessionStarted && !Chrono.TimerState.completed
        onModified: function(value) { Chrono.TimerState.setPomodoroWorkMinutes(value) }
        onHoveredChangedByPointer: function(hovered) { if (hovered) root.selectKey("work") }
      }
      Chrono.CompactField {
        id: shortField
        width: (parent.width - parent.spacing) / 2
        fieldWidth: width
        label: "Short"
        from: 1
        to: 999
        value: Chrono.TimerState.pomodoroShortBreakMinutes
        foreground: root.ink
        accent: ChronoTheme.accent
        fontFamily: root.fontFamily
        hasCursor: root.cursorKey === "short"
        enabled: !Chrono.TimerState.pomodoroSessionStarted && !Chrono.TimerState.completed
        onModified: function(value) { Chrono.TimerState.setPomodoroShortBreakMinutes(value) }
        onHoveredChangedByPointer: function(hovered) { if (hovered) root.selectKey("short") }
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(8)
      Chrono.CompactField {
        id: cyclesField
        width: (parent.width - parent.spacing) / 2
        fieldWidth: width
        label: "Cycles"
        from: 1
        to: 99
        value: Chrono.TimerState.pomodoroCycles
        foreground: root.ink
        accent: ChronoTheme.accent
        fontFamily: root.fontFamily
        hasCursor: root.cursorKey === "cycles"
        enabled: !Chrono.TimerState.pomodoroSessionStarted && !Chrono.TimerState.completed
        onModified: function(value) { Chrono.TimerState.setPomodoroCycles(value) }
        onHoveredChangedByPointer: function(hovered) { if (hovered) root.selectKey("cycles") }
      }
      Chrono.CompactField {
        id: longField
        width: (parent.width - parent.spacing) / 2
        fieldWidth: width
        label: "Long"
        from: 1
        to: 999
        value: Chrono.TimerState.pomodoroLongBreakMinutes
        foreground: root.ink
        accent: ChronoTheme.accent
        fontFamily: root.fontFamily
        hasCursor: root.cursorKey === "long"
        enabled: !Chrono.TimerState.pomodoroSessionStarted && !Chrono.TimerState.completed
        onModified: function(value) { Chrono.TimerState.setPomodoroLongBreakMinutes(value) }
        onHoveredChangedByPointer: function(hovered) { if (hovered) root.selectKey("long") }
      }
    }

    Toggle {
      id: soundToggle
      width: parent.width
      label: "Sounds"
      description: "Bell between phases, three on finish"
      checked: Chrono.TimerState.pomodoroSoundEnabled
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      hasCursor: root.cursorKey === "sound"
      enabled: !Chrono.TimerState.pomodoroSessionStarted && !Chrono.TimerState.completed
      onClicked: if (enabled) Chrono.TimerState.setPomodoroSoundEnabled(!Chrono.TimerState.pomodoroSoundEnabled)
      onHovered: function(hovered) { if (hovered) root.selectKey("sound") }
    }
  }

  Row {
    width: parent.width
    spacing: Style.space(8)

    SoftButton {
      width: Math.max(Style.space(96), (parent.width - parent.spacing * (logButton.visible ? 2 : 1)) * 0.42)
      label: Chrono.TimerState.mode === Chrono.TimerState.alarmMode
        ? Chrono.TimerState.running ? "Unset" : "Set"
        : Chrono.TimerState.running ? "Pause" : Chrono.TimerState.completed ? "Again" : "Start"
      iconCode: Chrono.TimerState.running ? 0xF03E4 : 0xF040A
      primary: !Chrono.TimerState.running
      ink: root.ink
      fontFamily: root.fontFamily
      enabled: Chrono.TimerState.mode === Chrono.TimerState.stopwatchMode
        || Chrono.TimerState.mode === Chrono.TimerState.alarmMode
        || Chrono.TimerState.targetMs > 0
      onClicked: Chrono.TimerState.startPause()
    }

    SoftButton {
      width: Math.max(Style.space(84), (parent.width - parent.spacing * (logButton.visible ? 2 : 1)) * 0.28)
      label: "Reset"
      iconCode: 0xF0450
      ink: root.ink
      fontFamily: root.fontFamily
      enabled: Chrono.TimerState.running || Chrono.TimerState.storedElapsedMs > 0
        || Chrono.TimerState.completed || Chrono.TimerState.pomodoroSessionStarted
      onClicked: Chrono.TimerState.reset()
    }

    SoftButton {
      id: logButton
      visible: Chrono.TimerState.mode !== Chrono.TimerState.alarmMode
      width: Math.max(Style.space(96), (parent.width - parent.spacing * 2) * 0.3)
      label: Chrono.TimerState.completed && Chrono.TimerState.lastBlockLogged
        ? "Logged"
        : root.logMs >= 1000 ? "Log " + Format.formatHM(root.logMs) : "Log"
      iconCode: ChronoTheme.glyphCheck
      accentLabel: true
      ink: root.ink
      fontFamily: root.fontFamily
      enabled: root.logMs >= 1000
        && !(Chrono.TimerState.completed && Chrono.TimerState.lastBlockLogged)
      onClicked: root.manualLog()
    }
  }
}
