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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.2

ApplicationWindow {
    id: appWindow

    title: qsTr("Hamster-QML")

    width: 710
    minimumWidth: 470
    height: 500

    Component.onCompleted: {
        visible = true;
        textHeader.text = textHeader.text + " (" + py.version + ")"
        py.hamster_lib.current()
    }
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent

        Label {
            id: textHeader
            text: "Hamster QML"
            color: "blue"
            font.pointSize:  14
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        TabBar {
            id: mainTabBar
            Layout.fillWidth: true
            TabButton {
                text: qsTr("Input")
            }
            TabButton {
                text: qsTr("Overview")
            }
            TabButton {
                text: qsTr("Configure")
            }
        }

        StackLayout {
            Layout.fillWidth : true
            Layout.fillHeight: true
            currentIndex: mainTabBar.currentIndex
            Item {
                PageMain {
                    visible: true
                    anchors.fill: parent
                }
            }
            Item {
                PageOverview {
                    visible: true
                    anchors.fill: parent
                }
            }
            Item {
                PageConfigure {
                    visible: true
                    anchors.fill: parent
                }
            }

        }
    }
}
