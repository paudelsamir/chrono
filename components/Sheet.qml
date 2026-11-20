import QtQuick
import qs.Commons
import "."

Rectangle {
  id: root

  default property alias content: column.data
  property int pad: Style.space(14)
  property int gap: Style.space(10)
  property color ink: Color.foreground

  implicitWidth: column.implicitWidth + pad * 2
  implicitHeight: column.implicitHeight + pad * 2
  radius: Style.space(18)
  color: ChronoTheme.alpha(ink, ChronoTheme.frosted ? 0.045 : 0.085)
  border.width: 1
  border.color: ChronoTheme.alpha(ink, ChronoTheme.frosted ? 0.07 : 0.12)

  Column {
    id: column
    x: root.pad
    y: root.pad
    width: root.width - root.pad * 2
    spacing: root.gap
  }
}
