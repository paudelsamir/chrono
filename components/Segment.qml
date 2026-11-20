import QtQuick
import qs.Commons
import "."

Rectangle {
  id: root

  property var options: []
  property string current: ""
  property color ink: Color.foreground
  property string fontFamily: Style.font.family
  property bool compact: false

  signal picked(string key)

  implicitHeight: root.compact ? Style.space(32) : Style.space(36)
  radius: Style.space(10)
  color: ChronoTheme.alpha(ink, 0.05)
  border.width: 1
  border.color: ChronoTheme.alpha(ink, 0.08)

  Row {
    anchors.fill: parent
    anchors.margins: Style.space(3)
    spacing: 0

    Repeater {
      model: root.options

      Rectangle {
        required property var modelData
        required property int index
        width: root.options.length > 0
          ? (parent.width - parent.spacing * Math.max(0, root.options.length - 1)) / root.options.length
          : 0
        height: parent.height
        radius: Style.space(8)
        color: modelData.key === root.current ? ChronoTheme.accent : "transparent"

        Text {
          anchors.centerIn: parent
          width: parent.width - Style.space(6)
          text: modelData.label
          textFormat: Text.PlainText
          color: modelData.key === root.current ? ChronoTheme.onAccent : root.ink
          font.family: root.fontFamily
          font.pixelSize: root.compact ? Style.font.caption : Style.font.bodySmall
          font.bold: modelData.key === root.current
          horizontalAlignment: Text.AlignHCenter
          elide: Text.ElideRight
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.picked(modelData.key)
        }
      }
    }
  }
}
