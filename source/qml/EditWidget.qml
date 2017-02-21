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

import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QtQuick.Window 2.2  

Window {
    id: mypopDialog
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
                id: currentRowLayout
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
                ColumnLayout {
                    Label  {
                        text: "Activity"
                    }
                    TextField {
                        id: textFieldActivity
                        text: activity
                    }
                }
                ColumnLayout {
                    Label  {
                        text: "Category"
                    }
                    TextField {
                        id: textFieldCategory
                        text: category? category : ""
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Label  {
                        text: "Description"
                        Layout.fillWidth: true
                    }
                    TextField {
                        id: textFieldDescription
                        text: description? description : ""
                        Layout.fillWidth: true
                    }
                }
                ColumnLayout {
                    Label  {
                        text: "Duration"
                        width: 30
                    }
                    TextField {
                        id: textFieldDuration
                        readOnly: true
                        width   : 30
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
                //anchors.fill: parent
                Button {
                    text: "Ok" 
                    enabled: (timeEditStart.busyEditing == false) && (timeEditEnd.busyEditing == false) && (textFieldActivity.text != "")
                    onClicked: {
                        mypopDialog.accepted(key
                                             , timeEditStart.dateTime
                                             , timeEditEnd.dateTime
                                             , textFieldCategory.text
                                             , textFieldActivity.text
                                             , textFieldDescription.text)
                        mypopDialog.close();
                    }
                }
                
                Button {
                    text: "Cancel" 
                    onClicked: {
                        mypopDialog.close();
                    }
                }   
                
                Rectangle {
                    Layout.fillWidth: true
                }
            }
        }
    }
}
