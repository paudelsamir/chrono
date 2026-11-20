import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import ".." as Chrono
import "../components"

Column {
  id: root

  property color ink: Color.foreground
  property string fontFamily: Style.font.family
  property string themeKey: "auto"
  property bool frosted: true
  property string logoBehavior: "separate"
  property string capsuleTone: "adaptive"
  property string barDensity: "regular"
  property bool syncEnabled: true
  property string syncActivityId: ""
  property bool logIntervals: true
  property bool logBreaks: false
  property bool barSeconds: true
  property int dailyGoalMinutes: 0
  property bool showRounds: true
  property bool showAlarm: true
  property bool menuOpen: false
  property bool confirmClear: false
  property int editors: 0

  readonly property bool editing: newName.activeFocus || root.editors > 0
  readonly property var activities: {
    var revision = Chrono.Tracker.revision
    return Chrono.Tracker.activeActivities()
  }
  readonly property string syncName: {
    var act = Chrono.Tracker.activityById(root.syncActivityId)
    if (act && !act.archived) return act.name
    return root.activities.length > 0 ? root.activities[0].name : "Deep Coding"
  }

  signal changed(string key, var value)

  spacing: Style.space(10)
  width: parent.width

  function caption(text) {
    return text
  }

  Sheet {
    width: parent.width
    ink: root.ink

    Row {
      width: parent.width
      Text {
        id: themeLabel
        text: "Omarchy Theme"
        color: root.ink
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
      }
      Item {
        width: Math.max(Style.space(8), parent.width - themeLabel.implicitWidth - frostRow.width)
        height: 1
      }
      Item {
        id: frostRow
        width: frostContent.width
        height: frostContent.height
        anchors.verticalCenter: parent.verticalCenter

        Row {
          id: frostContent
          spacing: Style.space(6)

          Rectangle {
            width: Style.space(16)
            height: width
            radius: Style.space(4)
            color: root.frosted ? ChronoTheme.accent : "transparent"
            border.width: 1
            border.color: root.frosted ? ChronoTheme.accent : ChronoTheme.alpha(root.ink, 0.4)
            anchors.verticalCenter: parent.verticalCenter
            Text {
              anchors.centerIn: parent
              visible: root.frosted
              text: String.fromCodePoint(ChronoTheme.glyphCheck)
              color: ChronoTheme.onAccent
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
          Text {
            text: "Frosted Sheet"
            color: root.ink
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.changed("frosted", !root.frosted)
        }
      }
    }

    Text {
      width: parent.width
      text: "Auto matches your Omarchy accent. Rosé, Catppuccin, Tokyo, Nord and Paper are fixed palettes."
      wrapMode: Text.WordWrap
      color: ChronoTheme.alpha(root.ink, 0.46)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    Row {
      width: parent.width
      spacing: Style.space(4)
      Repeater {
        model: ChronoTheme.swatches
        Item {
          required property var modelData
          width: (parent.width - parent.spacing * 5) / 6
          implicitHeight: swatchCol.implicitHeight

          Column {
            id: swatchCol
            width: parent.width
            spacing: Style.space(4)
            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: Style.space(26)
              height: width
              radius: width / 2
              color: modelData.color
              border.width: root.themeKey === modelData.key ? Style.space(2) : 1
              border.color: root.themeKey === modelData.key ? root.ink : ChronoTheme.alpha(root.ink, 0.2)
            }
            Text {
              width: parent.width
              text: modelData.label
              color: root.themeKey === modelData.key ? root.ink : ChronoTheme.alpha(root.ink, 0.55)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: root.themeKey === modelData.key
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.changed("themeKey", modelData.key)
          }
        }
      }
    }
  }

  Sheet {
    width: parent.width
    ink: root.ink

    Text {
      text: "Widget Logo Behavior"
      color: root.ink
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }
    Segment {
      width: parent.width
      ink: root.ink
      fontFamily: root.fontFamily
      current: root.logoBehavior
      options: [
        { key: "separate", label: "Separate Logos" },
        { key: "dual", label: "Dual Capsule" }
      ]
      onPicked: function(key) { root.changed("logoBehavior", key) }
    }

    Text {
      text: "Bar Capsule Tone"
      color: root.ink
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }
    Segment {
      width: parent.width
      ink: root.ink
      fontFamily: root.fontFamily
      current: root.capsuleTone
      options: [
        { key: "adaptive", label: "Adaptive" },
        { key: "accent", label: "Accent" },
        { key: "light", label: "Light" }
      ]
      onPicked: function(key) { root.changed("capsuleTone", key) }
    }

    Text {
      text: "Bar Density"
      color: root.ink
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }
    Segment {
      width: parent.width
      ink: root.ink
      fontFamily: root.fontFamily
      compact: true
      current: root.barDensity
      options: [
        { key: "regular", label: "Regular" },
        { key: "compact", label: "Compact" }
      ]
      onPicked: function(key) { root.changed("barDensity", key) }
    }

    Text {
      width: parent.width
      wrapMode: Text.WordWrap
      text: "Separate logos swaps the bar glyph with the mode. Dual capsule adds today's total beside it."
      color: ChronoTheme.alpha(root.ink, 0.46)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  Sheet {
    width: parent.width
    ink: root.ink

    Text {
      text: "Visible Timer Modes"
      color: root.ink
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    Toggle {
      width: parent.width
      label: "Rounds"
      description: "Show the interval timer in the Timers tab"
      checked: root.showRounds
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      onClicked: root.changed("showRounds", !root.showRounds)
    }

    Toggle {
      width: parent.width
      label: "Alarm"
      description: "Show the clock alarm in the Timers tab"
      checked: root.showAlarm
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      onClicked: root.changed("showAlarm", !root.showAlarm)
    }
  }

  Sheet {
    width: parent.width
    ink: root.ink

    Row {
      width: parent.width
      Text {
        id: syncLabel
        text: "Timer & Tracker Sync"
        color: root.ink
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
      }
      Item {
        width: Math.max(Style.space(8), parent.width - syncLabel.implicitWidth - syncToggle.width)
        height: 1
      }
      Rectangle {
        id: syncToggle
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(36)
        height: Style.space(20)
        radius: height / 2
        color: root.syncEnabled ? ChronoTheme.accent : ChronoTheme.alpha(root.ink, 0.16)
        Rectangle {
          width: Style.space(16)
          height: width
          radius: width / 2
          y: Style.space(2)
          x: root.syncEnabled ? parent.width - width - Style.space(2) : Style.space(2)
          color: root.syncEnabled ? ChronoTheme.onAccent : root.ink
          Behavior on x { NumberAnimation { duration: 120 } }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.changed("syncEnabled", !root.syncEnabled)
        }
      }
    }

    Text {
      width: parent.width
      wrapMode: Text.WordWrap
      text: "Log completed Pomodoro and countdown blocks to:"
      color: ChronoTheme.alpha(root.ink, 0.62)
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
    }

    Rectangle {
      width: parent.width
      implicitHeight: menuColumn.implicitHeight + Style.space(16)
      radius: Style.space(12)
      color: ChronoTheme.alpha(root.ink, 0.05)
      border.width: 1
      border.color: ChronoTheme.alpha(root.ink, 0.1)

      Column {
        id: menuColumn
        x: Style.space(12)
        y: Style.space(8)
        width: parent.width - Style.space(24)
        spacing: Style.space(4)

        Item {
          width: parent.width
          height: Style.space(26)

          Row {
            anchors.fill: parent
            Text {
              width: parent.width - Style.space(16)
              text: root.syncName
              color: root.ink
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: "▾"
              color: ChronoTheme.alpha(root.ink, 0.6)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.menuOpen = !root.menuOpen
          }
        }

        Repeater {
          model: root.menuOpen ? root.activities : []
          Rectangle {
            required property var modelData
            width: parent.width
            height: Style.space(28)
            radius: Style.space(8)
            color: modelData.id === root.syncActivityId ? ChronoTheme.alpha(ChronoTheme.accent, 0.28) : "transparent"
            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.space(4)
              spacing: Style.space(8)
              Rectangle {
                width: Style.space(8)
                height: width
                radius: width / 2
                color: modelData.color
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                text: modelData.name
                color: root.ink
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                anchors.verticalCenter: parent.verticalCenter
              }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.changed("syncActivityId", modelData.id)
                root.menuOpen = false
              }
            }
          }
        }
      }
    }

    Toggle {
      width: parent.width
      label: "Also log rounds"
      description: "Each finished interval round lands in the tracker"
      checked: root.logIntervals
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      onClicked: root.changed("logIntervals", !root.logIntervals)
    }

    Toggle {
      width: parent.width
      label: "Also log breaks"
      description: "Pomodoro breaks count too. Off keeps the log to focus time"
      checked: root.logBreaks
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      onClicked: root.changed("logBreaks", !root.logBreaks)
    }

    Toggle {
      width: parent.width
      label: "Seconds on the bar"
      description: "Show the running clock with seconds. Compact density ignores this"
      checked: root.barSeconds
      foreground: root.ink
      accent: ChronoTheme.accent
      fontFamily: root.fontFamily
      onClicked: root.changed("barSeconds", !root.barSeconds)
    }
  }

  Sheet {
    width: parent.width
    ink: root.ink

    Text {
      text: "Activities"
      color: root.ink
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
    }

    Repeater {
      model: root.activities
      Row {
        required property var modelData
        width: parent.width
        spacing: Style.space(8)

        Rectangle {
          width: Style.space(10)
          height: width
          radius: width / 2
          color: modelData.color
          anchors.verticalCenter: parent.verticalCenter
        }

        TextField {
          id: nameField
          width: parent.width - Style.space(52)
          text: modelData.name
          foreground: root.ink
          accent: ChronoTheme.accent
          font.family: root.fontFamily
          onActiveFocusChanged: root.editors = Math.max(0, root.editors + (activeFocus ? 1 : -1))
          onEditingFinished: Chrono.Tracker.renameActivity(modelData.id, text)
        }

        Rectangle {
          width: Style.space(28)
          height: width
          radius: height / 2
          color: closeArea.containsMouse ? ChronoTheme.alpha(root.ink, 0.1) : "transparent"
          anchors.verticalCenter: parent.verticalCenter
          Text {
            anchors.centerIn: parent
            text: "×"
            color: ChronoTheme.alpha(root.ink, 0.7)
            font.pixelSize: Style.font.body
          }
          MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Chrono.Tracker.archiveActivity(modelData.id)
          }
        }
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(8)
      TextField {
        id: newName
        width: parent.width - addButton.width - parent.spacing
        placeholderText: "New activity"
        foreground: root.ink
        accent: ChronoTheme.accent
        font.family: root.fontFamily
        Keys.onReturnPressed: root.addNamed()
        Keys.onEnterPressed: root.addNamed()
      }
      SoftButton {
        id: addButton
        width: Style.space(72)
        label: "Add"
        primary: true
        ink: root.ink
        fontFamily: root.fontFamily
        onClicked: root.addNamed()
      }
    }

    Text {
      width: parent.width
      wrapMode: Text.WordWrap
      text: "Archiving hides an activity from the list. Time already logged stays in the charts."
      color: ChronoTheme.alpha(root.ink, 0.46)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  Sheet {
    width: parent.width
    ink: root.ink

    Row {
      width: parent.width
      Text {
        id: goalLabel
        text: "Daily goal"
        color: root.ink
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
      }
      Item {
        width: Math.max(Style.space(8), parent.width - goalLabel.implicitWidth - goalControls.width)
        height: 1
      }
      Row {
        id: goalControls
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(8)
        SoftButton {
          width: Style.space(36)
          label: "–"
          ink: root.ink
          fontFamily: root.fontFamily
          onClicked: root.changed("dailyGoalMinutes", Math.max(0, root.dailyGoalMinutes - 30))
        }
        Text {
          text: root.dailyGoalMinutes <= 0 ? "Off" : (root.dailyGoalMinutes / 60) + "h"
          color: root.ink
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          width: Style.space(42)
          horizontalAlignment: Text.AlignHCenter
          anchors.verticalCenter: parent.verticalCenter
        }
        SoftButton {
          width: Style.space(36)
          label: "+"
          ink: root.ink
          fontFamily: root.fontFamily
          onClicked: root.changed("dailyGoalMinutes", Math.min(16 * 60, root.dailyGoalMinutes + 30))
        }
      }
    }

    SoftButton {
      width: parent.width
      label: Chrono.Tracker.revision >= 0 && Chrono.Tracker.hasSample() ? "Remove the sample week" : "Load a sample week"
      ink: root.ink
      fontFamily: root.fontFamily
      onClicked: Chrono.Tracker.hasSample() ? Chrono.Tracker.clearSample() : Chrono.Tracker.loadSample()
    }

    SoftButton {
      width: parent.width
      label: root.confirmClear ? "Click again to erase history" : "Clear tracker history"
      accentLabel: root.confirmClear
      ink: root.ink
      fontFamily: root.fontFamily
      onClicked: {
        if (!root.confirmClear) root.confirmClear = true
        else {
          Chrono.Tracker.clearAll()
          root.confirmClear = false
        }
      }
    }

    Text {
      width: parent.width
      wrapMode: Text.WordWrap
      text: "History stays in ~/.local/state/omarchy/chrono-tracker.json. The timer itself is chrono-state.json."
      color: ChronoTheme.alpha(root.ink, 0.46)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  function addNamed() {
    var created = Chrono.Tracker.addActivity(newName.text)
    if (created && !root.syncActivityId) root.changed("syncActivityId", created.id)
    newName.text = ""
  }
}
