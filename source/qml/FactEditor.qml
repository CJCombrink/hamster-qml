import QtQuick 2.8
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.12

Item {
  id: root_
  implicitHeight: controlFactNew_.implicitHeight
  implicitWidth: controlFactNew_.implicitWidth

  property bool valid: (comboActivity_.editText !== "" )
                       && comboCategory_.acceptableInput
                       && textDescription_.acceptableInput

  property string factInfo: comboActivity_.editText + '@' + comboCategory_.editText + ', ' + textDescription_.text

  property alias activity: comboActivity_.editText
  property alias category: comboCategory_.editText
  property alias description: textDescription_.text

  signal clearRequested
  signal accepted

  function clear() {
    comboActivity_.currentIndex = -1
    comboCategory_.currentIndex = -1
    comboActivity_.editText = ""
    comboCategory_.editText = ""
    textDescription_.text   = ""
  }

  RowLayout {
    id: controlFactNew_
    anchors.fill: parent

    CustomComboBox {
      id: comboCategory_
      editable: py.settings.dynamicCategories
      currentIndex: -1
      placeholderText: "<category>"
      selectByMouse: true
      validator: RegExpValidator { regExp: /^[A-Za-z0-9_-]*$/ }
      textRole: "name"
      model: py.category_model
      onCurrentIndexChanged: {
        /* Clear the text when selecting the (uncategorised) option */
        if(currentIndex === 0) {
          currentIndex = -1
        }
      }
      Keys.onPressed: {
        if( event.key == Qt.Key_At) {
          event.accepted = true
          comboActivity_.focus = true
        }
      }
    }
    Label {
      text: "@"
    }
    CustomComboBox {
      id: comboActivity_
      editable: py.settings.dynamicActivities
      currentIndex: -1
      placeholderText: "[activity]"
      selectByMouse: true
      validator: RegExpValidator { regExp: /^[A-Za-z0-9_-]+$/ }
      model: py.category_model.activitiesList(comboCategory_.currentText, true)
      showAcceptable: comboCategory_.editText != ""
      Keys.onPressed: {
        if( event.key == Qt.Key_Comma) {
          event.accepted = true
          textDescription_.focus = true
        }
      }
    }
    Label {
      text: ","
    }
    TextField {
      id: textDescription_
      Layout.fillWidth: true
      placeholderText: "description"
      selectByMouse: true
      Keys.onPressed: {
        if ( ( event.key == Qt.Key_Enter ) || ( event.key == Qt.Key_Return ) ){
          event.accepted = true;
          root_.accepted()
        } else if( event.key == Qt.Key_Escape ) {
          event.accepted = true;
          root_.clearRequested()
        }
      }
    }
  }
}
