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
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2

Window {
  id: root_
  title        : "Update Fact"
  width        : mainLayout.implicitWidth + 2 * margin
  height       : mainLayout.implicitHeight + 2 * margin
  minimumWidth : mainLayout.Layout.minimumWidth + 2 * margin
  minimumHeight: mainLayout.Layout.minimumHeight + 2 * margin
  flags        : Qt.Dialog
  modality     : Qt.WindowModal

  property int key
  property date start
  property date end
  property string category
  property string activity
  property string description

  property int margin: 10

  signal accepted(int key, date start, date end, string category, string activity, string description)

  function clearAll() {
    timeEditStart.text = ""
    timeEditEnd.text = ""
  }

  ColumnLayout {
    id: mainLayout
    anchors.fill   : parent
    anchors.margins: margin

    Text {
      id: textHeader
      text               : "Update Existing Fact"
      color              : "blue"
      font.pointSize     :  14
      Layout.fillWidth   : true
      horizontalAlignment: Text.AlignLeft
    }

    GroupBox {
      id: groupBoxCurrent
      Layout.fillWidth: true
      RowLayout {
        anchors.fill: parent
        ColumnLayout {
          Label  {
            text: "Start"
          }
          TimeEdit {
            id: timeEditStart
            dateTime: start
          }
        }
        ColumnLayout {
          Label  {
            text: "End"
          }
          TimeEdit {
            id: timeEditEnd
            dateTime: end
          }
        }
        FactEditor {
          id: factEditor_
          Layout.fillWidth: true
          simple: false
          Component.onCompleted: {
            factEditor_.setCategory( root_.category )
            factEditor_.setActivity( root_.activity )
            factEditor_.description = root_.description
          }
        }
        ColumnLayout {
          Label  {
            text: "Duration"
          }
          TextField {
            id: textFieldDuration
            readOnly: true
            implicitWidth: leftPadding + textMetrics_.advanceWidth + rightPadding
            TextMetrics {
              id: textMetrics_
              text: "HH:MM"
            }
          }

          Component.onCompleted: {
            timeEditStart.onDateTimeChanged.connect(updateDuration)
            timeEditEnd.onDateTimeChanged.connect(updateDuration)
            updateDuration()
          }

          function updateDuration() {
            var duration = new Date(0, 0, 0)
            duration.setMilliseconds((timeEditEnd.dateTime - timeEditStart.dateTime))
            textFieldDuration.text = Qt.formatTime(duration, "hh:mm")
          }
        }
      }
    }
    Rectangle {
      height: 30
      Layout.fillWidth: true

      RowLayout {
        id: buttonsRowLayout
        Button {
          text: "Ok"
          enabled: (timeEditStart.busyEditing == false)
                   && (timeEditEnd.busyEditing == false)
                   && (factEditor_.valid == true)
          onClicked: {
            root_.accepted(key
                           , timeEditStart.dateTime
                           , timeEditEnd.dateTime
                           , factEditor_.category
                           , factEditor_.activity
                           , factEditor_.description)
            root_.close();
          }
        }

        Button {
          text: "Cancel"
          onClicked: {
            root_.close();
          }
        }

        Rectangle {
          Layout.fillWidth: true
        }
      }
    }
  }
}
