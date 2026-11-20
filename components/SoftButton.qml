import QtQuick
import qs.Commons
import "."

Rectangle {
  id: root

  property string label: ""
  property int iconCode: 0
  property bool primary: false
  property bool accentLabel: false
  property bool enabled: true
  property color ink: Color.foreground
  property string fontFamily: Style.font.family

  signal clicked()

  implicitHeight: Style.space(38)
  radius: Style.space(12)
  opacity: enabled ? 1 : 0.42
  color: {
    if (!root.enabled) return ChronoTheme.alpha(root.ink, 0.04)
    if (root.primary) return area.containsMouse ? Qt.lighter(ChronoTheme.accent, 1.08) : ChronoTheme.accent
    if (area.containsMouse) return ChronoTheme.alpha(root.ink, 0.1)
    return ChronoTheme.alpha(root.ink, 0.055)
  }
  border.width: root.primary ? 0 : 1
  border.color: ChronoTheme.alpha(root.accentLabel ? ChronoTheme.accent : root.ink, root.primary ? 0 : 0.16)

  Row {
    anchors.centerIn: parent
    spacing: Style.space(6)

    Text {
      visible: root.iconCode !== 0
      text: String.fromCodePoint(root.iconCode)
      color: root.primary ? ChronoTheme.onAccent : root.accentLabel ? ChronoTheme.accent : root.ink
      font.family: root.fontFamily
      font.pixelSize: Style.font.body
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: root.label
      textFormat: Text.PlainText
      color: root.primary ? ChronoTheme.onAccent : root.accentLabel ? ChronoTheme.accent : root.ink
      font.family: root.fontFamily
      font.pixelSize: Style.font.bodySmall
      font.bold: root.primary
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: root.enabled
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
