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
                    anchors.fill: parent
                    TextField {
                        id: textFieldNew
                        placeholderText: "<time> [activity]@<category>, description"
                        validator: RegExpValidator { regExp: /^((((([01]\d|2[0-3]):)([0-5]\d) )(- ((([01]\d|2[0-3]):)([0-5]\d)) )?)|(-\d+) )?\w+(@\w+(, .+)?)?$/ }
                        Layout.fillWidth: true
                        focus: true
                        Keys.onPressed: {
                            if ((event.key == Qt.Key_Enter) || (event.key == Qt.Key_Return) ){
                                buttonStart.clicked()
                                event.accepted = true;
                            } else if(event.key == Qt.Key_Escape) {
                                textFieldNew.text = ""
                                event.accepted = true;
                            }
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
                Layout.fillWidth: true
                Layout.fillHeight: true
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
