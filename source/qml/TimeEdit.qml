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

// The Time Edit Item.
// This item allows one to edit the time part of a date object.
// The item also indicte the state of the time field using different
// colors:
//  - Blue : Indicates that the time field was changed but was not applied.
//           This means that the dateTime property of the item does not 
//           yet refer to the updated time in the time edit field.
//  - Red  : Indicates that the value in the time field is not a valid 
//           time. The time must be in the format HH:MM before the value 
//           will be valid. 
//  - Black: Indicates that the text in the edit field corresponds to the 
//            time in the dateTime property. Thus no changes were made.
//
// The edit field also handles some keyboard inputs. The following are 
// handled:
//  - Escape   : If the value is changed (while the color of the text is blue or 
//               red, escape can be used to revert the change to the current time
//               of the dateTime property. 
//  - Up/Down  : Increase or decrease the time in the edit field with one minute.
//               This will take wrapping on the hour into account.
//  - Page Up /
//    Page Down: Increase or decrease the time in the edit field with 10 minutes.
//               This will take wrapping on the hour into account.

Item {
    id : topItem
    width : tf.width
    height: tf.height
    
    property date dateTime
    property bool busyEditing: false
        
    TextField {
        id: tf
        width           : 60
        placeholderText : "HH:MM"
        validator       : RegExpValidator { regExp: /^(?:(?:([01]?\d|2[0-3]):)([0-5]\d))$/ }
        //inputMethodHints: Qt.ImhTime  //<- does not seem to work
        //inputMethodHints: Qt.ImhNoPredictiveText
        
        // Slot called when the text is accepted. This will only be called
        // if the text has the correct format from the validator. 
        // When accepted, take the text and update the dateTime property
        // on this item.
        onAccepted: {
            var updatedDateTime = new Date( dateTime )
            var timeStrings = text.split(':');
            updatedDateTime.setHours( timeStrings[0] )
            updatedDateTime.setMinutes( timeStrings[1] ) 
            dateTime = updatedDateTime
        }
        
        Keys.onPressed: {
            if(event.key === Qt.Key_Escape) {
                // Reset and set the time again so that the changed() slot
                // can get called to reset the color and update all needed 
                // status properties.
                var tmpDate = new Date( dateTime )
                dateTime = new Date()
                dateTime = tmpDate
                text = Qt.formatTime(dateTime, "hh:mm")
                event.accepted = true;
            } else if(event.key === Qt.Key_Up) {
                addMinutesToTime(1)
                event.accepted = true;
            } else if(event.key === Qt.Key_Down) {
                addMinutesToTime(-1)
                event.accepted = true;
            } else if(event.key === Qt.Key_PageUp) {
                addMinutesToTime(10)
                event.accepted = true;
            } else if(event.key === Qt.Key_PageDown) {
                addMinutesToTime(-10)
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
        function addMinutesToTime(timeToAdd) {
            var updatedDateTime = new Date( dateTime )
            updatedDateTime.setMinutes( Number(Qt.formatTime(dateTime, "mm")) + timeToAdd )
            dateTime = updatedDateTime
        }
    }
    
    // Slot called when the dateTime property changes to update the 
    // text edit, reset the color and update the busyEditing property 
    // to indiciate that the text corresponds to the time held by the 
    // item.
    onDateTimeChanged: {
        tf.text = Qt.formatTime(dateTime, "hh:mm")
        tf.color = 'black'
        busyEditing = false
    }
}
// Look at time picker here: http://stackoverflow.com/questions/29273544/time-picker-in-qml
// QML Calendar: http://doc.qt.io/qt-5/qml-qtquick-controls-calendar.html
