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
import Qt.labs.calendar 1.0

Item {
    id: calendarPicker

    width : childrenRect.width
    height: childrenRect.height

    signal dateSelected(date selectedDate)
    property date currentDate: new Date()

    QtObject {
        id: d
        property date internalDate: currentDate
        property bool doubleClickValid: false

        function addMonths(monthsToAdd) {
            var updatedDateTime = new Date( internalDate )
            /* Set the day to 1 to make sure that if the month is
             * increased or decreased and the next or previous month does
             * not contain the day it does not skip to the next month.
             * For example without this, if the current date is
             * 30 Jan, going to the next will go to 30 Feb, which is not
             * a valid date, thus it would jump to march. This update
             * fixes that issue.
             * Alternatively once can test for this case, but this is easy
             * enough and doing the correct thing. */
            updatedDateTime.setDate(1)
            updatedDateTime.setMonth( updatedDateTime.getMonth() + monthsToAdd )
            internalDate = updatedDateTime
        }
    }


    Timer {
        id: doubleClickTimer
        interval: 500
        onTriggered: {
            stop()
            d.doubleClickValid = false
        }
    }

    ColumnLayout {

        RowLayout {
            anchors.fill: parent
            Button {
                text: '<'
                width: 10
                flat: true
                onClicked: d.addMonths(-1)
            }
            Text {
                Layout.fillWidth: true
                text: Qt.formatDate(d.internalDate, "MMMM (yyyy)")
            }
            Button {
                text: '>'
                width: 10
                flat: true
                onClicked: d.addMonths(1)
            }
        }

        GridLayout {
            id: calLayout

            DayOfWeekRow {
                id: dowRow
                locale       : monthGrid.locale
                Layout.row   : 0
                Layout.column: 1
            }

            WeekNumberColumn {
                month: monthGrid.month
                year : monthGrid.year
                locale: monthGrid.locale
                Layout.row   : 1
                Layout.column: 0
            }

            MonthGrid {
                id: monthGrid
                month: d.internalDate.getMonth()
                year : d.internalDate.getFullYear()
                locale: Qt.locale("en_ZA")
                Layout.row   : 1
                Layout.column: 1
                Layout.fillHeight: true
                Layout.fillWidth : true
                delegate: Text {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    opacity: model.month === monthGrid.month ? 1 : 0.5
                    text   : model.day
                    color  : getDayColor()

                    function getDayColor() {
                        if((model.day === currentDate.getDate()) && (model.month === currentDate.getMonth())) {
                            return 'blue'
                        }
                        if((model.day === d.internalDate.getDate()) && (model.month === d.internalDate.getMonth())) {
                            return 'skyblue'
                        }
                        if(model.today === true) {
                            return 'steelblue'
                        }

                        return 'black'
                    }
                }

                onClicked: {
                    d.internalDate = date

                    if(d.doubleClickValid == true) {
                        /* The boolean is still true, thus it is a double
                         * click. Set the date of the calender. */
                        currentDate = date
                        calendarPicker.dateSelected(currentDate)
                    } else {
                        d.doubleClickValid = true
                        doubleClickTimer.start()
                    }
                }
            }
        }
    }
}
