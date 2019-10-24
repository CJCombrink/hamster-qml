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

  /* Control whether the editor must include the names of the
   * fields above the field or not. */
  property bool simple: true

  signal clearRequested
  signal accepted

  function clear() {
    comboActivity_.currentIndex = -1
    comboCategory_.currentIndex = -1
    comboActivity_.editText = ""
    comboCategory_.editText = ""
    textDescription_.text   = ""
  }

  function setCategory( category ) {
    var idx = comboCategory_.find( category )
    if( idx < 0 ) {
      return;
    }
    comboCategory_.currentIndex = idx
  }

  function setActivity( activity ) {
    var idx = comboActivity_.find( activity )
    if( idx < 0 ) {
      return;
    }
    comboActivity_.currentIndex = idx
  }

  RowLayout {
    id: controlFactNew_
    anchors.fill: parent

    ColumnLayout {
        Label  {
            text: "Category"
            visible: !simple
        }
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
    }
    ColumnLayout {
        Label  {
            // Empty padding string to push the @ down when the
            // Editor is not simple.
            text: ""
            visible: !simple
        }
        Label {
          text: "@"
        }
    }
    ColumnLayout {
        Label  {
            text: "Activity"
            visible: !simple
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
    }
    ColumnLayout {
        Label  {
            // Empty padding string to push the comma down when the
            // Editor is not simple.
            text: ""
            visible: !simple
        }
        Label {
          text: ","
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        Label  {
            text: "Description"
            Layout.fillWidth: true
            visible: !simple
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
}
