/**************************************************************************
**
** Copyright (c) 2017 Carel Combrink
**
** This file is part of the Hamster QML GUI, a QML GUI for the hamster-lib.
**
** The Hamster QML GUI is free software: you can redistribute it and/or
** modify it under the terms of the GNU Lesser General Public License as
** published by the Free Software Foundation, either version 3 of the
** License, or (at your option) any later version.
**
** The Hamster QML GUI is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU Lesser General Public License for more details.
**
** You should have received a copy of the GNU Lesser General Public License
** along with the Hamster QML GUI. If not, see <http://www.gnu.org/licenses/>.
****************************************************************************/

import QtQuick 2.8
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2
import QtQuick.Controls.Styles 1.1
import SortFilterModelPyQt 1.0

Item {
  id: pageMain

  width: 668
  height: mainLayout.implicitHeight + 2 * margin

  property int margin: 11

  Component.onCompleted: {
    py.hamster_lib.current()
    currentTimer.running = true
  }

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    anchors.margins: margin

    GroupBox {
      id: groupBoxCurrent
      title: "Current work"
      Layout.fillWidth: true

      RowLayout {
        id: currentRowLayout
        anchors.fill: parent

        TextField {
          id: textFieldCurrent
          placeholderText: "<no work in progress>"
          selectByMouse: true
          readOnly: true
          Layout.fillWidth: true
        }
        Button {
          id: buttonCurrentStop
          text: "Stop"
          enabled: textFieldCurrent.text
          onClicked: py.hamster_lib.stop()
        }
        Button {
          id: buttonCurrentCancel
          text: "Cancel"
          enabled: textFieldCurrent.text
          onClicked: py.hamster_lib.cancel()
        }
        Button {
          id: buttonCurrentRefresh
          text: "Refresh"
          onClicked: py.hamster_lib.current()
        }
      }
    }

    GroupBox {
      id: rowBox
      title: "Log work"
      Layout.fillWidth: true

      ColumnLayout {
        anchors.fill: parent

        RowLayout {
          id: rowLayoutActivity
          Layout.fillWidth: true

          TextField {
            id: textFieldNew
            placeholderText: "<time> [activity]@<category>, description"
            validator: RegExpValidator { }
            Layout.fillWidth: true
            focus: true
            selectByMouse: true
            Keys.onPressed: {
              if ((event.key == Qt.Key_Enter) || (event.key == Qt.Key_Return) ){
                buttonStart.clicked()
                event.accepted = true;
              } else if(event.key == Qt.Key_Escape) {
                textFieldNew.text = ""
                event.accepted = true;
              }
            }
            Component.onCompleted: {
              /* Build up the final RegExp using logical parts.
                         * This is to allow for better understanding, and will
                         * allow future work to allow custom formats */
              const reTimeFormat    = '(([01]\\d|2[0-3]):)([0-5]\\d)'
              const reMaybeTimeSpan =  '((' + reTimeFormat +' )(- (' + reTimeFormat + ') )?)'
              const reMinutesAgo    = '(-\\d+)'
              const reActivity      = '[A-Za-z0-9_-]+'
              const reCategory      = '@[A-Za-z0-9_-]*'
              const reComment       = ', .+'
              const reMaybeCategory = '(' + reCategory + ')?'
              const reMaybeComment  = '(' + reComment + ')?'
              /* Create the final pattern. */
              const reFinal         = '^('+ reMaybeTimeSpan + '|' + reMinutesAgo + ' )?' + reActivity + reMaybeCategory + reMaybeComment + '$'
              validator.regExp      = new RegExp( reFinal )
            }
          }
          Button {
            id: buttonStart
            text: "Start"
            enabled: textFieldNew.text ? true: false
            onClicked: {
              py.hamster_lib.start(textFieldNew.text)
            }
          }
        }

        RowLayout {
          id: controlFactNew_
          Layout.fillWidth: true

          function clear() {
            textTime_.text              = ""
            textActivity_.text          = ""
            comboCategory_.currentIndex = -1
            textDescription_.text       = ""
          }

          TextField {
            id: textTime_
            placeholderText: "<time>"
            focus: true
            selectByMouse: true

            TextMetrics {
                id: textMetrics_
                text: "00:00 - 00:00"
            }
            // Ensure that the size will fit the TextMetrics
            Layout.maximumWidth: leftPadding + textMetrics_.advanceWidth + rightPadding

            KeyNavigation.tab: rowActCat_.normal? textActivity_: comboCategory_

            property var _reTimeFormat   : '(([01]\\d|2[0-3]):)([0-5]\\d)'
            property var _reMaybeTimeSpan:  '((' + _reTimeFormat +')( - (' + _reTimeFormat + '))?)'
            property var _reMinutesAgo   : '(-\\d+)'
            property var _regExpTimeSpan : new RegExp('^' + _reTimeFormat + ' - ' + _reTimeFormat + '$')

            validator: RegExpValidator {}

            Keys.onPressed: {
              if( event.key == Qt.Key_Space) {
                if( _regExpTimeSpan.test( text ) === true ) {
                  event.accepted = true
                  textTime_.KeyNavigation.tab.focus = true
                }
              } else if ( event.key == Qt.Key_At ) {
                event.accepted = true
                if( rowActCat_.normal ) {
                  comboCategory_.focus = true
                } else {
                  textActivity_.focus = true
                }
              }
            }
            Component.onCompleted: {
              /* Create the final pattern. */
              const reFinal         = '^('+ _reMaybeTimeSpan + '|' + _reMinutesAgo + ')?$'
              validator.regExp      = new RegExp( reFinal )
            }
          }

          RowLayout {
            id: rowActCat_
            property bool normal: py.settings.dynamicActivities || py.settings.dynamicCategories

            layoutDirection: normal? Qt.LeftToRight: Qt.RightToLeft
            TextField {
              id: textActivity_
              placeholderText: "[activity]"
              selectByMouse: true
              validator: RegExpValidator { regExp: /^[A-Za-z0-9_-]+$/ }
              Keys.onPressed: {
                if( event.key == Qt.Key_At) {
                  event.accepted = true
                  comboCategory_.focus = true
                }
              }
              KeyNavigation.tab: rowActCat_.normal? comboCategory_: textDescription_
            }
            Label {
              text: "@"
            }
            CustomComboBox {
              id: comboCategory_
              editable: py.settings.dynamicCategories
              currentIndex: -1
              placeholderText: "<category>"
              textRole: "name"
              model: py.category_model

              onCurrentIndexChanged: {
                /* Clear the text when selecting the (uncategorised) option */
                if(currentIndex === 0) {
                  currentIndex = -1
                }
              }

              validator: RegExpValidator { regExp: /^[A-Za-z0-9_-]*$/ }
              Keys.onPressed: {
                if( event.key == Qt.Key_Comma) {
                  event.accepted = true
                  textDescription_.focus = true
                }
              }
              KeyNavigation.tab: rowActCat_.normal? textDescription_: textActivity_
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
                _buttonStart2.clicked()
              } else if( event.key == Qt.Key_Escape ) {
                event.accepted = true;
                controlFactNew_.clear()
              }
            }
          }
          Button {
            id: _buttonStart2
            text: "Start"
            enabled: textTime_.acceptableInput && textActivity_.acceptableInput && comboCategory_.acceptableInput && textDescription_.acceptableInput
            onClicked: {
              var fact = textTime_.text +' ' + textActivity_.text + '@' + comboCategory_.editText + ', ' + textDescription_.text
              py.hamster_lib.start( fact )
            }
          }
        }
      }
    }

    GroupBox {
      id: groupBoxToday
      title: "Today"
      Layout.fillWidth: true
      Layout.fillHeight: true

      SortFilterModelPyQt {
        id: sortFilterModel
        startDate  : new Date()
        endDate    : new Date()
        sourceModel: py.fact_model
      }

      FactView {
        id: tableViewToday
        anchors.fill: parent
        model: sortFilterModel
      }
    }
  }

  Popup {
    id: errorPopup
    x: 20
    y: (pageMain.height / 2) - (height / 2)
    width : pageMain.width - 40
    height: 40
    modal: true
    focus: true
    Label  {
      id: labelErrorPopup
      font.italic: true
      color: "red"
    }
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
  }

  Timer {
    id: currentTimer
    interval: 1000
    running : false
    repeat  : true
    onTriggered: {
      py.hamster_lib.current()
    }
  }

  Connections {
    target: py.hamster_lib
    onCurrentUpdated: {
      if(current != null) {
        textFieldCurrent.text = Qt.formatDateTime(current.start(), "hh:mm") + " " + current.activity() + "@" + current.category() + " " + current.description() + " (" + Qt.formatTime(current.duration(), "hh:mm") + ")"
      } else {
        textFieldCurrent.text = ""
      }
    }
    onErrorMessage   : {
      labelErrorPopup.text = message
      errorPopup.open()
    }
    onStartSuccessful: {
      textFieldNew.text = ""
      controlFactNew_.clear()
    }
    onStopSuccessful: {
      /* For now do nothing. Previously the model was refreshed, but since the model
             * will now automatically add the fact from the signal emitted when a fact
             * is stopped, there is no need to refresh the model any more. The slot is
             * left here as a placeholder for now. */
      // py.fact_model.refreshFacts()
    }
  }
}
