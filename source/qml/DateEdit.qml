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
import "." as App

Item {
    id : topItem
    width: tf.width + b.width
    height: tf.height

    signal dateSelected(date selectedDate)
    property date currentDate: new Date()
    property bool busyEditing: false
        
    TextField {
        id: tf
        width: 80
        placeholderText: "DD/MM/YYYY"
        validator: RegExpValidator { regExp: /^(?:0[1-9]|[12]\d|3[01])\/(?:0[1-9]|1[0-2])\/(?:20)\d{2}$/ }
//        inputMethodHints: Qt.ImhDate <- Does not seem to do anything

        onAccepted: {
            // Slot called when the text is accepted. This will only be called
            // if the text has the correct format from the validator.
            // When accepted, take the text and update the dateTime property
            // on this item.
            var updatedDateTime = Date.fromLocaleDateString(Qt.locale(), tf.text, 'dd/MM/yyyy')
            currentDate = updatedDateTime
        }

        Keys.onPressed: {
            if(event.key === Qt.Key_Escape) {
                // Reset and set the time again so that the changed() slot
                // can get called to reset the color and update all needed
                // status properties.
                formatDate();
                event.accepted = true;
            } else if(event.key === Qt.Key_Up) {
                addDaysToDate(1)
                event.accepted = true;
            } else if(event.key === Qt.Key_Down) {
                addDaysToDate(-1)
                event.accepted = true;
            } else if(event.key === Qt.Key_PageUp) {
                addDaysToDate(10)
                event.accepted = true;
            } else if(event.key === Qt.Key_PageDown) {
                addDaysToDate(-10)
                event.accepted = true;
            }
        }

        // Update the color of the text when the text changes. If the text is
        // valid the color is set to blue to indicate that the text was not
        // applied and does not correspond to the current date set on the item.
        // If the text is not yet a valid time, then the text color will be
        // red.
        onTextChanged: {
            color = acceptableInput? 'blue' : 'red'
            busyEditing = true
        }

        // Function to add the supplied number of minutes to the current time.
        // The time can be positive or negative. The Date type handles wrapping
        // automatically so there is no need to handle this.
        function addDaysToDate(daysToAdd) {
            var updatedDateTime = new Date( currentDate )
            updatedDateTime.setDate( Number(Qt.formatDate(currentDate, "dd")) + daysToAdd )
            currentDate = updatedDateTime
        }
    }

    Button {
        id: b
        text: "..."
        width: 35
        anchors.left: tf.right

        onClicked: {
            calendar.currentDate = topItem.currentDate
            popup.open()
        }
    }

    Popup {
        id: popup
        x: 0
        y: 0
        contentWidth : calendar.width
        contentHeight: calendar.height

        modal: true
        focus: true
        CalendarPicker {
            id: calendar
            onDateSelected: {
                popup.close()
                updateDate(selectedDate)
            }
        }

        Component.onCompleted: {
            /* Ensure that the calendar popup is onscreen on the application window.
             * If the popup will be past the window, move it to the opposite side of
             * the button so that the whole popup will be visable on the screen. If
             * this is not done, the popup for buttons on the right will be offscreen.
             * There will still be an issue if the whole application is not wide enough
             * for the popup, but this should not happen. */
            popup.x = ((calendar.width + topItem.mapToItem(null, 0, 0).x) > appWindow.width)? (b.x - calendar.width): topItem.x
        }

        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    }

    function updateDate(newDate) {
        currentDate = newDate
        topItem.dateSelected(currentDate)
    }

    function formatDate() {
        tf.text = Qt.formatDate(currentDate, "dd/MM/yyyy")
    }

    onCurrentDateChanged : {
        formatDate()
        tf.color    = 'black'
        busyEditing = false;
    }
    Component.onCompleted: formatDate()
}
