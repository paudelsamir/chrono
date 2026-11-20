.pragma library

function pad2(value) {
  var n = Math.floor(Math.abs(Number(value) || 0))
  return (n < 10 ? "0" : "") + n
}

function dayKey(date) {
  return date.getFullYear() + "-" + pad2(date.getMonth() + 1) + "-" + pad2(date.getDate())
}

function parseKey(key) {
  var parts = String(key || "").split("-")
  if (parts.length !== 3) return new Date()
  return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
}

function addDays(date, amount) {
  var next = new Date(date.getFullYear(), date.getMonth(), date.getDate())
  next.setDate(next.getDate() + amount)
  return next
}

function startOfWeek(date) {
  var day = new Date(date.getFullYear(), date.getMonth(), date.getDate())
  var shift = (day.getDay() + 6) % 7
  day.setDate(day.getDate() - shift)
  return day
}

function sameKey(a, b) {
  return String(a) === String(b)
}

function weekday(date, wide) {
  var names = wide
    ? ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  return names[date.getDay()]
}

function monthLetter(index) {
  return ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"][index] || ""
}

function formatHM(ms) {
  var total = Math.max(0, Math.round((Number(ms) || 0) / 60000))
  var hours = Math.floor(total / 60)
  var minutes = total % 60
  if (hours <= 0) return minutes + "m"
  if (minutes === 0) return hours + "h"
  return hours + "h " + minutes + "m"
}

function weekTitle(monday) {
  var end = addDays(monday, 6)
  var nowMonday = startOfWeek(new Date())
  var prefix = dayKey(monday) === dayKey(nowMonday) ? "This week" : "Week"
  var startLabel = monthShort(monday) + " " + monday.getDate()
  var endLabel = monday.getMonth() === end.getMonth()
    ? String(end.getDate())
    : monthShort(end) + " " + end.getDate()
  return prefix + "  ·  " + startLabel + "–" + endLabel
}

function monthShort(date) {
  var names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  return names[date.getMonth()]
}

function prettyDay(key) {
  var date = parseKey(key)
  if (dayKey(date) === dayKey(new Date())) return "Today"
  var yesterday = addDays(new Date(), -1)
  if (dayKey(date) === dayKey(yesterday)) return "Yesterday"
  return weekday(date, false) + " " + monthShort(date) + " " + date.getDate()
}
