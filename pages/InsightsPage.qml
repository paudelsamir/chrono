import QtQuick
import qs.Commons
import ".." as Chrono
import "../components"
import "../components/Format.js" as Format

Column {
  id: root

  property color ink: Color.foreground
  property string fontFamily: Style.font.family
  // A running (or paused) stopwatch is unlogged time, so include it live in
  // today's breakdown. It carries the session name so the slice lines up with
  // the activity it will be logged to.
  property int extraMs: Chrono.TimerState.mode === Chrono.TimerState.stopwatchMode
    ? Chrono.TimerState.elapsedMs
    : 0
  property string extraName: Chrono.TimerState.sessionName
  property string extraFallback: ""
  property int dailyGoalMinutes: 0
  property date weekStart: Format.startOfWeek(new Date())
  property string selectedDay: Format.dayKey(new Date())
  property int hot: -1

  function shiftWeek(direction) {
    root.weekStart = Format.addDays(root.weekStart, direction * 7)
    root.selectedDay = Format.dayKey(root.weekStart)
    root.hot = -1
  }

  readonly property var baked: {
    var revision = Chrono.Tracker.revision
    var slices = Chrono.Tracker.slices(root.selectedDay).slice()
    // Older logs may have no name anywhere; label them Misc.
    for (var s = 0; s < slices.length; s++)
      if (String(slices[s].name || "").trim() === "") slices[s].name = "Misc"
    var extra = root.selectedDay === Format.dayKey(new Date()) ? root.extraMs : 0
    if (extra >= 1000) {
      var peeked = Chrono.Tracker.peekId(root.extraName, root.extraFallback)
      var label = String(root.extraName || "").trim()
      var placed = false
      for (var i = 0; i < slices.length; i++) {
        if (peeked && slices[i].id === peeked) {
          slices[i].ms += extra
          placed = true
        }
      }
      if (!placed) {
        var act = peeked ? Chrono.Tracker.activityById(peeked) : null
        slices.push({
          id: peeked || "live",
          name: act ? act.name : (label || "Tracking"),
          color: act ? act.color : "#e7b4a8",
          ms: extra
        })
      }
      slices.sort(function(a, b) { return b.ms - a.ms })
    }
    var total = 0
    for (var s = 0; s < slices.length; s++) total += slices[s].ms
    var week = Chrono.Tracker.weekDays(Format.dayKey(root.weekStart))
    var year = Chrono.Tracker.yearOf(root.selectedDay)
    var lead = Chrono.Tracker.leader(Format.dayKey(root.weekStart))
    return {
      revision: revision,
      slices: slices,
      total: total,
      week: week,
      year: year,
      streak: Chrono.Tracker.streak(),
      lead: lead
    }
  }

  spacing: Style.space(10)
  width: parent.width

  Sheet {
    width: parent.width
    ink: root.ink
    gap: Style.space(12)

    Text {
      text: "Activity Breakdown  ·  " + Format.prettyDay(root.selectedDay)
      color: root.ink
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    Row {
      width: parent.width
      spacing: Style.space(12)

      Item {
        width: Style.space(132)
        height: Style.space(132)

        Donut {
          anchors.fill: parent
          slices: root.baked.slices
          hot: root.hot
          track: ChronoTheme.alpha(root.ink, 0.1)
        }

        Column {
          anchors.centerIn: parent
          spacing: 0
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Format.prettyDay(root.selectedDay) === "Today" ? "Today" : Format.weekday(Format.parseKey(root.selectedDay), false)
            color: ChronoTheme.alpha(root.ink, 0.5)
            font.family: root.fontFamily
            font.pixelSize: Math.max(9, Style.font.caption - 1)
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Format.formatHM(root.baked.total)
            color: root.ink
            font.family: root.fontFamily
            font.pixelSize: Math.max(12, Style.font.body + 1)
            font.bold: true
          }
        }
      }

      Column {
        width: parent.width - Style.space(144)
        spacing: Style.space(7)

        Text {
          visible: root.baked.slices.length === 0
          width: parent.width
          wrapMode: Text.WordWrap
          text: "Nothing here yet. Name a session and log it, or let a timer finish."
          color: ChronoTheme.alpha(root.ink, 0.55)
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Repeater {
          model: root.baked.slices

          Item {
            required property var modelData
            required property int index
            width: parent.width
            implicitHeight: Style.space(22)

            Row {
              anchors.fill: parent
              spacing: Style.space(8)
              opacity: root.hot >= 0 && root.hot !== index ? 0.4 : 1

              Rectangle {
                width: Style.space(8)
                height: width
                radius: width / 2
                color: modelData.color
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                width: parent.width - Style.space(92)
                text: modelData.name
                textFormat: Text.PlainText
                color: root.ink
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: Format.formatHM(modelData.ms) + " · " + (root.baked.total > 0 ? Math.round(modelData.ms / root.baked.total * 100) : 0) + "%"
                color: ChronoTheme.alpha(root.ink, 0.62)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onContainsMouseChanged: root.hot = containsMouse ? index : -1
            }
          }
        }
      }
    }

    // Daily goal (set in Settings) reads against the same live total as the
    // donut, so a running stopwatch counts toward it as it ticks.
    Item {
      id: goalBox
      width: parent.width
      height: root.dailyGoalMinutes > 0 ? Style.space(30) : 0
      visible: root.dailyGoalMinutes > 0

      readonly property real goalMs: Math.max(0, root.dailyGoalMinutes) * 60000
      readonly property real ratio: goalMs > 0 ? Math.min(1, root.baked.total / goalMs) : 0

      Text {
        id: goalLabel
        anchors.left: parent.left
        anchors.top: parent.top
        text: "Daily goal"
        color: ChronoTheme.alpha(root.ink, 0.62)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        anchors.right: parent.right
        anchors.top: parent.top
        text: Math.round(goalBox.ratio * 100) + "%  ·  " + Format.formatHM(root.baked.total)
          + " / " + Format.formatHM(goalBox.goalMs)
        color: goalBox.ratio >= 1 ? ChronoTheme.accent : ChronoTheme.alpha(root.ink, 0.62)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Style.space(5)
        radius: height / 2
        color: ChronoTheme.alpha(root.ink, 0.10)

        Rectangle {
          width: parent.width * goalBox.ratio
          height: parent.height
          radius: parent.radius
          color: goalBox.ratio >= 1 ? ChronoTheme.accent : ChronoTheme.alpha(ChronoTheme.accent, 0.8)
        }
      }
    }
  }

  Sheet {
    width: parent.width
    ink: root.ink

    Row {
      width: parent.width

      Rectangle {
        width: Style.space(28)
        height: Style.space(28)
        radius: height / 2
        color: areaPrev.containsMouse ? ChronoTheme.alpha(root.ink, 0.08) : "transparent"
        Text {
          anchors.centerIn: parent
          text: "‹"
          color: root.ink
          font.family: root.fontFamily
          font.pixelSize: Style.font.display
        }
        MouseArea {
          id: areaPrev
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.shiftWeek(-1)
        }
      }

      Text {
        width: parent.width - Style.space(56) - weekTotal.implicitWidth
        text: Format.weekTitle(root.weekStart)
        color: root.ink
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
      }

      Text {
        id: weekTotal
        text: Format.formatHM(root.baked.week.total)
        color: ChronoTheme.alpha(root.ink, 0.66)
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        anchors.verticalCenter: parent.verticalCenter
      }

      Rectangle {
        width: Style.space(28)
        height: Style.space(28)
        radius: height / 2
        color: areaNext.containsMouse ? ChronoTheme.alpha(root.ink, 0.08) : "transparent"
        Text {
          anchors.centerIn: parent
          text: "›"
          color: root.ink
          font.family: root.fontFamily
          font.pixelSize: Style.font.display
        }
        MouseArea {
          id: areaNext
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.shiftWeek(1)
        }
      }
    }

    Item {
      width: parent.width
      implicitHeight: Style.space(108)

      Row {
        anchors.fill: parent
        spacing: Style.space(6)

        Repeater {
          model: root.baked.week.days

          Item {
            required property var modelData
            width: (parent.width - parent.spacing * 6) / 7
            height: Style.space(100)

            Column {
              anchors.fill: parent
              spacing: Style.space(6)

              Item {
                width: parent.width
                height: Style.space(78)

                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.bottom: parent.bottom
                  width: parent.width * 0.62
                  height: {
                    if (modelData.ms <= 0) return Style.space(3)
                    var maxMs = 1
                    var days = root.baked.week.days
                    for (var i = 0; i < days.length; i++) maxMs = Math.max(maxMs, days[i].ms)
                    return Math.max(Style.space(8), parent.height * (modelData.ms / maxMs))
                  }
                  radius: modelData.ms <= 0 ? 1 : Style.space(6)
                  color: modelData.key === root.selectedDay
                    ? ChronoTheme.accent
                    : modelData.ms <= 0
                      ? ChronoTheme.alpha(root.ink, 0.16)
                      : ChronoTheme.chart
                }
              }

              Text {
                width: parent.width
                text: modelData.label
                color: modelData.key === root.selectedDay ? ChronoTheme.accent : ChronoTheme.alpha(root.ink, 0.5)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: modelData.key === root.selectedDay
                horizontalAlignment: Text.AlignHCenter
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (root.selectedDay === modelData.key && modelData.key !== Format.dayKey(new Date()))
                  root.selectedDay = Format.dayKey(new Date())
                else root.selectedDay = modelData.key
                root.hot = -1
              }
            }
          }
        }
      }
    }

    Text {
      visible: root.baked.lead.ms > 0
      width: parent.width
      text: root.baked.lead.name + " leads  ·  " + Format.formatHM(root.baked.lead.ms)
      color: ChronoTheme.alpha(root.ink, 0.5)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
    }
  }

  Sheet {
    width: parent.width
    ink: root.ink
    gap: Style.space(12)

    Row {
      width: parent.width
      spacing: Style.space(8)

      Column {
        width: (parent.width - parent.spacing * 2) / 3
        spacing: Style.space(2)
        Text {
          text: "Active Streak"
          color: ChronoTheme.alpha(root.ink, 0.48)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        Text {
          text: root.baked.streak + "d"
          color: root.ink
          font.family: root.fontFamily
          font.pixelSize: Style.font.display
          font.bold: true
        }
      }

      Column {
        width: (parent.width - parent.spacing * 2) / 3
        spacing: Style.space(2)
        Text {
          text: "Peak Day"
          color: ChronoTheme.alpha(root.ink, 0.48)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        Text {
          text: root.baked.year.peakMs > 0 ? Format.formatHM(root.baked.year.peakMs) : "—"
          color: root.ink
          font.family: root.fontFamily
          font.pixelSize: Style.font.display
          font.bold: true
        }
        Text {
          visible: root.baked.year.peakKey !== ""
          text: Format.prettyDay(root.baked.year.peakKey)
          color: ChronoTheme.alpha(root.ink, 0.45)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      Column {
        width: (parent.width - parent.spacing * 2) / 3
        spacing: Style.space(2)
        Text {
          text: "Year Total"
          color: ChronoTheme.alpha(root.ink, 0.48)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
        Text {
          text: Format.formatHM(root.baked.year.yearMs)
          color: root.ink
          font.family: root.fontFamily
          font.pixelSize: Style.font.display
          font.bold: true
        }
      }
    }

    Column {
      width: parent.width
      spacing: Style.space(4)

      Row {
        width: parent.width
        spacing: Style.space(3)
        Repeater {
          model: 12
          Item {
            required property int index
            width: (parent.width - parent.spacing * 11) / 12
            height: Style.space(36)

            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              width: parent.width * 0.7
              height: {
                var months = root.baked.year.months
                var maxMs = 1
                for (var i = 0; i < months.length; i++) maxMs = Math.max(maxMs, months[i])
                if (months[index] <= 0) return Style.space(2)
                return Math.max(Style.space(4), parent.height * (months[index] / maxMs))
              }
              radius: Style.space(2)
              color: index === Format.parseKey(root.selectedDay).getMonth()
                ? ChronoTheme.accent
                : ChronoTheme.alpha(ChronoTheme.accent, 0.45)
            }
          }
        }
      }

      Row {
        width: parent.width
        spacing: Style.space(3)
        Repeater {
          model: 12
          Text {
            required property int index
            width: (parent.width - parent.spacing * 11) / 12
            text: Format.monthLetter(index)
            color: ChronoTheme.alpha(root.ink, 0.4)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }
    }
  }

  Text {
    visible: root.extraMs >= 1000 && root.selectedDay === Format.dayKey(new Date())
    width: parent.width
    text: "Watch is still running, so today includes it before you log."
    color: ChronoTheme.alpha(root.ink, 0.45)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
  }
}
