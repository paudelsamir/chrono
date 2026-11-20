import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "." as Chrono
import "components" as C
import "pages" as Pages

Panel {
  id: root
  moduleName: "paudelsamir.chrono"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  property string page: "timers" // timers | insights | settings
  property string themeKey: "auto"
  property bool frosted: C.ChronoTheme.frosted
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

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() { if (root.opened) close(); else open() }
  function closeForPopoutSwitch() { close() }
  function showPage(next) {
    var wanted = String(next || "")
    if (wanted === "timers" || wanted === "insights" || wanted === "settings") root.page = wanted
    root.open()
  }

  // The Log button lives in the timers page; this lets `omarchy-shell
  // paudelsamir.chrono log` exercise the same path (and show the same toast).
  function logManual() {
    var item = loader ? loader.item : null
    if (item && typeof item.manualLog === "function") item.manualLog()
  }

  function hasSetting(key) {
    return root.settings !== null && root.settings !== undefined
      && Object.prototype.hasOwnProperty.call(root.settings, key)
  }

  // shell.json values arrive as whatever `omarchy bar set` stored: a
  // `--json` write is typed, a plain write is a string. Normalize both.
  function boolValue(value, fallback) {
    if (typeof value === "boolean") return value
    if (typeof value === "number") return value !== 0
    if (typeof value === "string") {
      var low = value.trim().toLowerCase()
      if (low === "false" || low === "0" || low === "") return false
      if (low === "true" || low === "1") return true
    }
    return fallback
  }

  function pickValue(value, allowed, fallback) {
    var key = String(value === undefined || value === null ? "" : value).trim()
    return allowed.indexOf(key) !== -1 ? key : fallback
  }

  readonly property var themeKeys: ["auto", "rose", "catppuccin", "tokyo", "nord", "paper"]
  readonly property var logoBehaviors: ["separate", "dual"]
  readonly property var capsuleTones: ["adaptive", "accent", "light"]
  readonly property var barDensities: ["regular", "compact"]

  // Pull the persisted widget settings (shell.json) into the panel. Runs when
  // the bar injects or updates `settings`, and when we write a key back.
  function loadSettings() {
    if (!root.settings) return
    if (root.hasSetting("themeKey"))
      root.themeKey = root.pickValue(root.settings.themeKey, root.themeKeys, "auto")
    if (root.hasSetting("frosted"))
      root.frosted = root.boolValue(root.settings.frosted, true)
    if (root.hasSetting("logoBehavior"))
      root.logoBehavior = root.pickValue(root.settings.logoBehavior, root.logoBehaviors, "separate")
    if (root.hasSetting("capsuleTone"))
      root.capsuleTone = root.pickValue(root.settings.capsuleTone, root.capsuleTones, "adaptive")
    if (root.hasSetting("barDensity"))
      root.barDensity = root.pickValue(root.settings.barDensity, root.barDensities, "regular")
    if (root.hasSetting("syncEnabled"))
      root.syncEnabled = root.boolValue(root.settings.syncEnabled, true)
    if (root.hasSetting("syncActivityId")) root.syncActivityId = String(root.settings.syncActivityId || "")
    if (root.hasSetting("logIntervals"))
      root.logIntervals = root.boolValue(root.settings.logIntervals, true)
    if (root.hasSetting("logBreaks"))
      root.logBreaks = root.boolValue(root.settings.logBreaks, false)
    if (root.hasSetting("barSeconds"))
      root.barSeconds = root.boolValue(root.settings.barSeconds, true)
    if (root.hasSetting("dailyGoalMinutes"))
      root.dailyGoalMinutes = Math.max(0, Math.round(Number(root.settings.dailyGoalMinutes) || 0))
    if (root.hasSetting("showRounds"))
      root.showRounds = root.boolValue(root.settings.showRounds, true)
    if (root.hasSetting("showAlarm"))
      root.showAlarm = root.boolValue(root.settings.showAlarm, true)
    C.ChronoTheme.themeKey = root.themeKey
    C.ChronoTheme.frosted = root.frosted
    root.pushTrackingSettings()
    // Settings can change from outside the open page (`omarchy bar set`), so
    // refresh whatever page is loaded instead of only the new values.
    root.pushAllSettings()
  }

  // The tracker write happens inside the TimerState singleton (one instance),
  // so it needs the same switches the panel shows.
  function pushTrackingSettings() {
    Chrono.TimerState.syncEnabled = root.syncEnabled
    Chrono.TimerState.syncActivityId = root.syncActivityId
    Chrono.TimerState.logIntervals = root.logIntervals
    Chrono.TimerState.logBreaks = root.logBreaks
  }

  function pushAllSettings() {
    var keys = ["themeKey", "frosted", "logoBehavior", "capsuleTone", "barDensity",
      "syncEnabled", "syncActivityId", "logIntervals", "logBreaks", "barSeconds",
      "dailyGoalMinutes", "showRounds", "showAlarm"]
    for (var i = 0; i < keys.length; i++) root.pushSetting(keys[i], root[keys[i]])
  }

  // Settings live in shell.json (omarchy bar set), so they survive shell
  // reloads and are shared with BarWidget.
  function persistSetting(key, value) {
    Quickshell.execDetached([
      "omarchy", "bar", "set", root.moduleName, key,
      JSON.stringify(value), "--json"
    ])
  }

  // Keep the page that is currently loaded in sync with a changed setting.
  function pushSetting(key, value) {
    var item = loader ? loader.item : null
    if (!item) return
    if (key in item) item[key] = value
    if (key === "syncActivityId" && ("extraFallback" in item)) item.extraFallback = value
  }

  function applySetting(key, value) {
    if (key === "themeKey") {
      root.themeKey = root.pickValue(value, root.themeKeys, "auto")
      C.ChronoTheme.themeKey = root.themeKey
    } else if (key === "frosted") {
      root.frosted = root.boolValue(value, true)
      C.ChronoTheme.frosted = root.frosted
    } else if (key === "logoBehavior") {
      root.logoBehavior = root.pickValue(value, root.logoBehaviors, "separate")
    } else if (key === "capsuleTone") {
      root.capsuleTone = root.pickValue(value, root.capsuleTones, "adaptive")
    } else if (key === "barDensity") {
      root.barDensity = root.pickValue(value, root.barDensities, "regular")
    } else if (key === "syncEnabled") {
      root.syncEnabled = root.boolValue(value, true)
    } else if (key === "logIntervals") {
      root.logIntervals = root.boolValue(value, true)
    } else if (key === "logBreaks") {
      root.logBreaks = root.boolValue(value, false)
    } else if (key === "barSeconds") {
      root.barSeconds = root.boolValue(value, true)
    } else if (key === "syncActivityId") {
      root.syncActivityId = String(value || "")
    } else if (key === "dailyGoalMinutes") {
      root.dailyGoalMinutes = Math.max(0, Math.round(Number(value) || 0))
    } else if (key === "showRounds") {
      root.showRounds = root.boolValue(value, true)
    } else if (key === "showAlarm") {
      root.showAlarm = root.boolValue(value, true)
    }
    // Persist and mirror the normalized value, not the raw payload, so a
    // malformed choice never reaches shell.json.
    root.pushSetting(key, root[key])
    root.pushTrackingSettings()
    // shell.json is the live source of truth; a setting that comes back from
    // it (a `omarchy bar set` from another client, or a write we just made)
    // is re-applied without persisting, so the UI cannot loop.
    root.persistSetting(key, root[key])
  }

  Component.onCompleted: root.loadSettings()
  onSettingsChanged: root.loadSettings()

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    padding: Style.space(10)
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(Style.space(500), Style.space(600))

    Item {
      anchors.fill: parent

      Column {
        id: rootCol
        anchors.fill: parent
        spacing: Style.space(8)

        Item {
          id: bodyWrap
          width: parent.width
          height: Math.max(0, rootCol.height - tabs.height - rootCol.spacing)

          Flickable {
            id: body
            anchors.fill: parent
            contentWidth: width
            contentHeight: pageCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Column {
              id: pageCol
              width: body.width

              Loader {
                id: loader
                width: pageCol.width
                source: root.page === "timers" ? "pages/TimersPage.qml"
                      : root.page === "insights" ? "pages/InsightsPage.qml"
                      : "pages/SettingsPage.qml"
                onLoaded: {
                  if (!item) return
                  if ("ink" in item) item.ink = Color.foreground
                  if ("fontFamily" in item) item.fontFamily = Style.font.family
                  if (root.page === "settings") {
                    var keys = ["themeKey","frosted","logoBehavior","capsuleTone","barDensity","syncEnabled","syncActivityId","logIntervals","logBreaks","barSeconds","dailyGoalMinutes","showRounds","showAlarm"]
                    for (var i = 0; i < keys.length; i++) {
                      var k = keys[i]
                      if (k in item) item[k] = root[k]
                    }
                    try { item.changed.connect(function(k,v){ root.applySetting(k,v) }) } catch(e) {}
                  }
                  if (root.page === "timers") {
                    if ("syncActivityId" in item) item.syncActivityId = root.syncActivityId
                    root.pushAllSettings()
                  }
                  if (root.page === "insights") {
                    if ("dailyGoalMinutes" in item) item.dailyGoalMinutes = root.dailyGoalMinutes
                    if ("extraFallback" in item) item.extraFallback = root.syncActivityId
                  }
                }
              }
            }
          }
        }

        Row {
          id: tabs
          width: parent.width
          height: Style.space(30)
          spacing: Style.space(6)

          Repeater {
            model: [
              { key: "timers", label: "Timers", icon: C.ChronoTheme.glyphClock },
              { key: "insights", label: "Insights", icon: C.ChronoTheme.glyphChart },
              { key: "settings", label: "Settings", icon: C.ChronoTheme.glyphCog }
            ]
            delegate: Rectangle {
              required property var modelData
              width: Math.floor((tabs.width - Style.space(12)) / 3)
              height: tabs.height
              radius: Style.space(8)
              color: root.page === modelData.key ? C.ChronoTheme.accent : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.06)
              border.width: 1
              border.color: root.page === modelData.key ? C.ChronoTheme.accent : Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.08)

              Row {
                anchors.centerIn: parent
                spacing: Style.space(5)
                Text {
                  text: String.fromCodePoint(modelData.icon)
                  color: root.page === modelData.key ? C.ChronoTheme.onAccent : Color.foreground
                  font.family: Style.font.family
                  font.pixelSize: Style.font.bodySmall
                  anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                  text: modelData.label
                  textFormat: Text.PlainText
                  color: root.page === modelData.key ? C.ChronoTheme.onAccent : Color.foreground
                  font.family: Style.font.family
                  font.pixelSize: Style.font.bodySmall
                  font.bold: root.page === modelData.key
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: root.page = modelData.key
              }
            }
          }
        }
      }
    }
  }
}
