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
import QtQuick.Controls.Styles 1.1
import SortFilterModelPyQt 1.0

Item {
    id: pageOverview

    width: 668
    height: mainLayout.implicitHeight + 2 * margin

    property int margin: 11

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: margin

        GroupBox {
            id: groupBoxCurrent
            Layout.fillWidth: true
            RowLayout {
                id: currentRowLayout
                anchors.fill: parent
                ColumnLayout {
                    Label  {
                        text: "Start"
                        font.pixelSize: 14
                        font.bold     : true
                        color         : "steelblue"
                    }
                    DateEdit {
                        id: timeEditStart
                        currentDate: new Date()
                        onCurrentDateChanged: sortFilterModel.startDate = currentDate
                        Component.onCompleted: {
                            // The overview page starts on the first day of the month and
                            // shows the facts for the rest of the month up to the current
                            // date.
                            var date = new Date();
                            date.setDate(1)
                            currentDate = date
                        }
                    }
                }
                ColumnLayout {
                    Label  {
                        text: "End"
                        font.pixelSize: 14
                        font.bold     : true
                        color         : "steelblue"
                    }
                    DateEdit {
                        id: timeEditEnd
                        currentDate: new Date()
                        onCurrentDateChanged: sortFilterModel.endDate = currentDate
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                }

                ColumnLayout {
                    Label {
                        text: "New Fact"
                    }
                    DateEdit {
                        id: timeEditNewFact
                        currentDate: new Date()

                        Component.onCompleted: {
                            timeEditNewFact.onDateSelected.connect(showCreationDialog)
                        }

                        function showCreationDialog() {
                            var editWidgetComponent = Qt.createComponent("EditWidget.qml");
                            if (editWidgetComponent.status === Component.Ready) {
                                var dialog = editWidgetComponent.createObject(parent,{start: currentDate, end: currentDate});
                                dialog.accepted.connect(dialogAccepted)
                                dialog.clearAll();
                                dialog.show()
                            } else {
                                console.log('Component is not ready: ', component.errorString())
                            }
                        }

                        function dialogAccepted(key, start, end, category, activity, description) {
                            py.hamster_lib.create(start, end, activity, category, description);
                        }
                    }
                }
            }
        }

        GroupBox {
            id: groupBoxToday
            title: "Facts"
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

    Connections {
        target: py.hamster_lib
        onCurrentUpdated : {}
        onErrorMessage   : {}
        onStartSuccessful: {}
        onStopSuccessful : {}
    }
}
