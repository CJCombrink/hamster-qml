import QtQuick 2.8
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Controls.Fusion 2.12
import QtQuick.Controls.Fusion.impl 2.12

/* This Custom ComboBox implementation uses the implemantion from
 * the normal ComboBox as part of Qt from
 * <QtDir>\qml\QtQuick\Controls.2\Fusion\ComboBox.qml and adds the
 * placeholderText property to the ComboBox. This implementation
 * is Fustion style specific and should be rethinked when the style
 * of the app changes.
 * The final usage of this implementation will depend on feedback
 * received from a question related to the placeholderText on the
 * qt-interest mailing list:
 * https://lists.qt-project.org/pipermail/interest/2019-September/033732.html */
ComboBox {
  id: root_
  property alias placeholderText:  text_.placeholderText
  property alias selectByMouse: text_.selectByMouse
  property bool showAcceptable: false

  /* Interesting way to overlay an item on top of the
   * text field to allow changing the border color without
   * the need to change the contentItem since the TextField
   * does not have a boder color. */
  Rectangle {
    anchors.fill: parent
    parent: root_.contentItem
    color: 'transparent'
    border.color: (!text_.acceptableInput && showAcceptable)? '#80ff0000': 'transparent'
  }

  contentItem: TextField {
    id: text_
    topPadding: 4
    leftPadding: 4 - root_.padding
    rightPadding: 4 - root_.padding
    bottomPadding: 4

    text: root_.editable ? root_.editText : root_.displayText

    enabled: root_.editable
    autoScroll: root_.editable
    readOnly: root_.down
    inputMethodHints: root_.inputMethodHints
    validator: root_.validator

    font: root_.font
    color: root_.editable ? root_.palette.text : root_.palette.buttonText
    selectionColor: root_.palette.highlight
    selectedTextColor: root_.palette.highlightedText
    verticalAlignment: Text.AlignVCenter

    background: PaddedRectangle {
      clip: true
      radius: 2
      padding: 1
      leftPadding: root_.mirrored ? -2 : padding
      rightPadding: !root_.mirrored ? -2 : padding
      color: root_.palette.base
      visible: root_.editable && !root_.flat

      Rectangle {
        x: parent.width - width
        y: 1
        width: 1
        height: parent.height - 2
        color: Fusion.buttonOutline(root_.palette, root_.activeFocus, root_.enabled)
      }

      Rectangle {
        x: 1
        y: 1
        width: parent.width - 3
        height: 1
        color: Fusion.topShadow
      }
    }

    Rectangle {
      x: 1 - root_.leftPadding
      y: 1
      width: root_.width - 2
      height: root_.height - 2
      color: "transparent"
      border.color: Color.transparent(Fusion.highlightedOutline(root_.palette), 40 / 255)
      visible: root_.activeFocus
      radius: 1.7
    }
  }
}
