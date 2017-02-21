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
import QtQuick.Controls 1.3

TableView {
    id: factView
    anchors.fill: parent

    /* Key column should not be displayed. The code is left here for
     * debugging if needed. */
//    TableViewColumn { role: "key"        ;  title: "Key"        ; width: 35  }
    TableViewColumn { role: "start"      ;  title: "Start"      ; width: 60;  delegate: timeDelegate}
    TableViewColumn { role: "end"        ;  title: "End"        ; width: 60;  delegate: timeDelegate}
    TableViewColumn { role: "activity"   ;  title: "Activity"   ; width: 70 }
    TableViewColumn { role: "category"   ;  title: "Category"   ; width: 70 }
    TableViewColumn { role: "description";  title: "Description"; width: parent.width - 330 }
    TableViewColumn { role: "duration"   ;  title: "Duration"   ; width: 55;   delegate: timeDelegate }

    section.property: "day"
    section.criteria: ViewSection.FullString
    section.delegate: daySectionHeading

    property variant editWidgetComponent

    Component.onCompleted: {
        /* Load the Edit Widget component and store it in a variable.
         * This is done so that there is no need to reload the
         * component each time when the edit widget is opened. Although
         * this does not allow one to edit the qml file before oepening
         * a new edit widget, it is seen as a good thing.
         * Each instance of this FactView created will load the component
         * and keep a variable to it. This will be kept as is until
         * a singleton type solution can be found. */
        editWidgetComponent = Qt.createComponent("EditWidget.qml");
        if (editWidgetComponent.status !== Component.Ready) {
            console.log('Component is not ready: ', component.errorString())
        }
    }

    onDoubleClicked: {
        if (editWidgetComponent.status === Component.Ready) {
            var fact = model.get(row)
            var dialog = editWidgetComponent.createObject(parent,{
                                                              key        : fact.key,
                                                              start      : fact.start,
                                                              end        : fact.end,
                                                              category   : fact.category,
                                                              activity   : fact.activity,
                                                              description: fact.description });
            dialog.accepted.connect(dialogAccepted)
            dialog.show()
        } else {
            console.log('Component is not ready: ', component.errorString())
        }
    }

    function dialogAccepted(key, start, end, category, activity, description) {
        py.hamster_lib.updateFact(key, start, end, activity, category, description);
    }

    Component {
        id: daySectionHeading
        Rectangle {
            width : parent.width
            height: childrenRect.height
            color : "lightsteelblue"

            Text {
                text          : Qt.formatDate(section, "d MMMM yyyy (dddd)")
                font.bold     : true
                font.pixelSize: 20
            }
        }
    }

    Component {
        id: timeDelegate
        Text {
            text: Qt.formatTime(styleData.value, "hh:mm")
            horizontalAlignment : Text.AlignHCenter
        }
    }
}
