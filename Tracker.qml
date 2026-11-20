pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "components/Format.js" as Format

// Activity log. One JSON file, no network, no daemon.
// Entries with the same activity on the same day are folded together.
Item {
  id: root

  readonly property string statePath: (Quickshell.env("XDG_STATE_HOME")
    || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy/chrono-tracker.json"

  property bool persistenceReady: false
  property bool restoring: false
  property int revision: 0
  property var activities: []
  property var entries: []
  property var queue: []
  property var logger: null
  property string lastUndoId: ""

  readonly property var palette: [
    "#7eb6ff", "#5fd0ea", "#e0b15a", "#e7b4a8", "#cba6f7",
    "#a6e3a1", "#f38ba8", "#fab387", "#89dceb", "#b4befe"
  ]

  function touch() {
    root.activities = root.activities.slice()
    root.entries = root.entries.slice()
    root.revision += 1
    root.scheduleSave()
  }

  function scheduleSave() {
    if (!root.persistenceReady || root.restoring) return
    saveTimer.restart()
  }

  function snapshot() {
    return {
      version: 1,
      savedAt: Date.now(),
      activities: root.activities,
      entries: root.entries
    }
  }

  function saveState() {
    if (!root.persistenceReady) return
    stateFile.setText(JSON.stringify(root.snapshot(), null, 2) + "\n")
  }

  function seedActivities() {
    if (root.activities.length > 0) return
    root.activities = [
      { id: "deep", name: "Deep Coding", color: "#7eb6ff", archived: false, createdAt: Date.now() },
      { id: "linux", name: "Linux & Notes", color: "#5fd0ea", archived: false, createdAt: Date.now() },
      { id: "coffee", name: "Coffee Break", color: "#e0b15a", archived: false, createdAt: Date.now() }
    ]
  }

  function restoreState(raw) {
    if (root.persistenceReady) return
    var data = null
    try {
      data = JSON.parse(raw)
    } catch (error) {
      data = null
    }
    root.restoring = true
    if (data && typeof data === "object") {
      root.activities = Array.isArray(data.activities) ? data.activities : []
      root.entries = Array.isArray(data.entries) ? data.entries : []
    }
    root.seedActivities()
    root.restoring = false
    root.persistenceReady = true
    root.revision += 1
    root.flush()
  }

  function flush() {
    var pending = root.queue
    root.queue = []
    for (var i = 0; i < pending.length; i++) {
      var item = pending[i]
      root.logNamed(item.name, item.fallbackId, item.ms, item.source, item.detail)
    }
  }

  function activityById(id) {
    for (var i = 0; i < root.activities.length; i++) {
      if (root.activities[i].id === id) return root.activities[i]
    }
    return null
  }

  function activeActivities() {
    var out = []
    for (var i = 0; i < root.activities.length; i++) {
      if (!root.activities[i].archived) out.push(root.activities[i])
    }
    return out
  }

  function nextColor() {
    return root.palette[root.activities.length % root.palette.length]
  }

  function findByName(name) {
    var wanted = String(name || "").trim().toLowerCase()
    if (!wanted) return null
    for (var i = 0; i < root.activities.length; i++) {
      if (!root.activities[i].archived && String(root.activities[i].name).toLowerCase() === wanted)
        return root.activities[i]
    }
    return null
  }

  function findAny(name) {
    var wanted = String(name || "").trim().toLowerCase()
    if (!wanted) return null
    for (var i = 0; i < root.activities.length; i++) {
      if (String(root.activities[i].name).toLowerCase() === wanted) return root.activities[i]
    }
    return null
  }

  // The bucket for logs with no name at all: it shows up as its own "Misc"
  // section in Insights, instead of the first sync activity or "Deep Coding".
  function miscActivity() {
    var found = root.activityById("misc")
    if (found) {
      if (!found.archived) return found
      found.archived = false
      root.touch()
      return found
    }
    var byName = root.findAny("Misc")
    if (byName) {
      byName.archived = false
      root.touch()
      return byName
    }
    var created = {
      id: "misc",
      name: "Misc",
      color: root.palette[0],
      archived: false,
      createdAt: Date.now()
    }
    root.activities = root.activities.concat([created])
    root.touch()
    return created
  }

  function peekId(name, fallbackId) {
    var found = root.findByName(name)
    if (found) return found.id
    if (String(name || "").trim() !== "") return ""
    return root.miscActivity().id
  }

  function ensureActivity(name, fallbackId) {
    var trimmed = String(name || "").trim()
    if (trimmed === "") return root.miscActivity()
    var found = root.findByName(trimmed)
    if (found) return found
    var hidden = root.findAny(trimmed)
    if (hidden) {
      hidden.archived = false
      root.touch()
      return hidden
    }
    return root.addActivity(trimmed)
  }

  function addActivity(name) {
    var trimmed = String(name || "").trim()
    if (trimmed === "") return null
    var existing = root.findByName(trimmed)
    if (existing) return existing
    var hidden = root.findAny(trimmed)
    if (hidden) {
      hidden.archived = false
      root.touch()
      return hidden
    }
    var created = {
      id: "a" + Date.now().toString(36) + root.activities.length,
      name: trimmed,
      color: root.nextColor(),
      archived: false,
      createdAt: Date.now()
    }
    root.activities = root.activities.concat([created])
    root.touch()
    return created
  }

  function renameActivity(id, name) {
    var trimmed = String(name || "").trim()
    if (trimmed === "") return
    var act = root.activityById(id)
    if (!act || act.name === trimmed) return
    act.name = trimmed
    root.touch()
  }

  function archiveActivity(id) {
    var act = root.activityById(id)
    if (!act) return
    act.archived = true
    root.touch()
  }

  function logNamed(name, fallbackId, ms, source, detail) {
    var amount = Math.round(Number(ms) || 0)
    if (amount < 1000) return ""
    if (!root.persistenceReady) {
      root.queue = root.queue.concat([{
        name: name, fallbackId: fallbackId, ms: amount, source: source, detail: detail
      }])
      return ""
    }
    var activity = root.ensureActivity(name, fallbackId)
    if (!activity) return ""
    var day = Format.dayKey(new Date())
    var stamp = Date.now()
    for (var i = 0; i < root.entries.length; i++) {
      var entry = root.entries[i]
      if (entry.day === day && entry.activityId === activity.id && entry.sample !== true) {
        entry.ms += amount
        entry.endedAt = stamp
        entry.detail = detail || entry.detail || ""
        root.lastUndoId = entry.id
        root.touch()
        return entry.id
      }
    }
    var created = {
      id: "e" + stamp.toString(36),
      activityId: activity.id,
      name: activity.name,
      color: activity.color,
      day: day,
      ms: amount,
      source: source || "manual",
      detail: detail || "",
      startedAt: stamp - amount,
      endedAt: stamp,
      sample: false
    }
    root.entries = root.entries.concat([created])
    root.lastUndoId = created.id
    root.touch()
    return created.id
  }

  function undo() {
    // lastUndoId is runtime-only, so after a shell restart fall back to the
    // newest real entry. Undo must still work for a log made in a previous
    // session.
    var id = root.lastUndoId
    if (!id) {
      for (var j = root.entries.length - 1; j >= 0; j--) {
        if (root.entries[j].sample !== true) {
          id = root.entries[j].id
          break
        }
      }
    }
    if (!id) return
    var kept = []
    for (var i = 0; i < root.entries.length; i++) {
      if (root.entries[i].id !== id) kept.push(root.entries[i])
    }
    root.entries = kept
    root.lastUndoId = ""
    root.touch()
  }

  function totalOn(day) {
    var total = 0
    for (var i = 0; i < root.entries.length; i++) {
      if (root.entries[i].day === day) total += Number(root.entries[i].ms) || 0
    }
    return total
  }

  function slices(day) {
    var map = {}
    var order = []
    for (var i = 0; i < root.entries.length; i++) {
      var entry = root.entries[i]
      if (entry.day !== day) continue
      var ms = Number(entry.ms) || 0
      if (ms <= 0) continue
      if (!map[entry.activityId]) {
        var act = root.activityById(entry.activityId)
        map[entry.activityId] = {
          id: entry.activityId,
          name: act ? act.name : entry.name,
          color: act ? act.color : entry.color,
          ms: 0
        }
        order.push(entry.activityId)
      }
      map[entry.activityId].ms += ms
    }
    var out = []
    for (var j = 0; j < order.length; j++) out.push(map[order[j]])
    out.sort(function(a, b) { return b.ms - a.ms })
    return out
  }

  function weekDays(mondayKey) {
    var start = Format.parseKey(mondayKey)
    var out = []
    var total = 0
    for (var i = 0; i < 7; i++) {
      var date = Format.addDays(start, i)
      var key = Format.dayKey(date)
      var ms = root.totalOn(key)
      total += ms
      out.push({ key: key, label: Format.weekday(date, false), ms: ms })
    }
    return { days: out, total: total }
  }

  function yearOf(dayKey) {
    var year = Number(String(dayKey || Format.dayKey(new Date())).slice(0, 4))
    var months = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var perDay = {}
    var yearMs = 0
    for (var i = 0; i < root.entries.length; i++) {
      var entry = root.entries[i]
      if (String(entry.day).slice(0, 4) !== String(year)) continue
      var ms = Number(entry.ms) || 0
      yearMs += ms
      var month = Number(String(entry.day).slice(5, 7)) - 1
      if (month >= 0 && month < 12) months[month] += ms
      perDay[entry.day] = (perDay[entry.day] || 0) + ms
    }
    var peakMs = 0
    var peakKey = ""
    for (var key in perDay) {
      if (perDay[key] > peakMs) {
        peakMs = perDay[key]
        peakKey = key
      }
    }
    return { year: year, yearMs: yearMs, months: months, peakMs: peakMs, peakKey: peakKey }
  }

  function streak() {
    var days = {}
    for (var i = 0; i < root.entries.length; i++) {
      if ((Number(root.entries[i].ms) || 0) > 0) days[root.entries[i].day] = true
    }
    var cursor = new Date()
    if (!days[Format.dayKey(cursor)]) cursor = Format.addDays(cursor, -1)
    var count = 0
    while (days[Format.dayKey(cursor)] && count < 5000) {
      count += 1
      cursor = Format.addDays(cursor, -1)
    }
    return count
  }

  function leader(mondayKey) {
    var start = Format.parseKey(mondayKey)
    var end = Format.dayKey(Format.addDays(start, 6))
    var begin = Format.dayKey(start)
    var map = {}
    for (var i = 0; i < root.entries.length; i++) {
      var entry = root.entries[i]
      if (entry.day < begin || entry.day > end) continue
      var act = root.activityById(entry.activityId)
      var name = act ? act.name : entry.name
      map[name] = (map[name] || 0) + (Number(entry.ms) || 0)
    }
    var bestName = ""
    var bestMs = 0
    for (var key in map) {
      if (map[key] > bestMs) {
        bestMs = map[key]
        bestName = key
      }
    }
    return { name: bestName, ms: bestMs }
  }

  function loadSample() {
    root.clearSample(false)
    root.seedActivities()
    var deep = root.activityById("deep") || root.ensureActivity("Deep Coding", "")
    var linux = root.activityById("linux") || root.ensureActivity("Linux & Notes", "")
    var coffee = root.activityById("coffee") || root.ensureActivity("Coffee Break", "")
    var today = new Date()
    var monday = Format.startOfWeek(today)
    var pattern = [
      [{ id: deep.id, name: deep.name, color: deep.color, minutes: 70 },
        { id: linux.id, name: linux.name, color: linux.color, minutes: 40 }],
      [{ id: deep.id, name: deep.name, color: deep.color, minutes: 100 },
        { id: linux.id, name: linux.name, color: linux.color, minutes: 35 },
        { id: coffee.id, name: coffee.name, color: coffee.color, minutes: 15 }],
      [{ id: deep.id, name: deep.name, color: deep.color, minutes: 80 },
        { id: linux.id, name: linux.name, color: linux.color, minutes: 50 }],
      [{ id: deep.id, name: deep.name, color: deep.color, minutes: 110 },
        { id: coffee.id, name: coffee.name, color: coffee.color, minutes: 15 },
        { id: linux.id, name: linux.name, color: linux.color, minutes: 75 }],
      [{ id: linux.id, name: linux.name, color: linux.color, minutes: 45 }],
      [],
      []
    ]
    var stamped = Date.now()
    var extra = []
    var d
    for (d = 0; d < 7; d++) {
      var date = Format.addDays(monday, d)
      if (date > today) continue
      var blocks = pattern[d]
      for (var b = 0; b < blocks.length; b++) {
        extra.push({
          id: "sample-" + d + "-" + b,
          activityId: blocks[b].id,
          name: blocks[b].name,
          color: blocks[b].color,
          day: Format.dayKey(date),
          ms: blocks[b].minutes * 60000,
          source: "sample",
          detail: "Sample",
          startedAt: stamped,
          endedAt: stamped,
          sample: true
        })
      }
    }
    for (var monthBack = 1; monthBack <= 3; monthBack++) {
      var past = new Date(today.getFullYear(), today.getMonth() - monthBack, 12)
      extra.push({
        id: "sample-m-" + monthBack,
        activityId: deep.id,
        name: deep.name,
        color: deep.color,
        day: Format.dayKey(past),
        ms: (40 + monthBack * 25) * 60000,
        source: "sample",
        detail: "Sample",
        startedAt: stamped,
        endedAt: stamped,
        sample: true
      })
    }
    root.entries = root.entries.concat(extra)
    root.touch()
  }

  function clearSample(commit) {
    var kept = []
    for (var i = 0; i < root.entries.length; i++) {
      if (root.entries[i].sample !== true) kept.push(root.entries[i])
    }
    root.entries = kept
    if (commit !== false) root.touch()
  }

  function hasSample() {
    for (var i = 0; i < root.entries.length; i++) {
      if (root.entries[i].sample === true) return true
    }
    return false
  }

  function clearAll() {
    root.entries = []
    root.lastUndoId = ""
    root.touch()
  }

  Timer {
    id: saveTimer
    interval: 180
    repeat: false
    onTriggered: root.saveState()
  }

  FileView {
    id: stateFile
    path: root.statePath
    atomicWrites: true
    printErrors: false
    onLoaded: Qt.callLater(function() { root.restoreState(stateFile.text()) })
    onLoadFailed: Qt.callLater(function() {
      if (root.persistenceReady) return
      root.seedActivities()
      root.persistenceReady = true
      root.revision += 1
      root.flush()
    })
  }
}
