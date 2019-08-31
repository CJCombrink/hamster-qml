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

import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtQuick.Controls 1.6 as C1
import QtQuick.Controls.Styles 1.4

Item {
  id: pageConfigure
  anchors.fill: parent

  property int margin: 11

  ColumnLayout {
    id: mainLayout
    anchors.fill: parent
    anchors.margins: margin

    GroupBox {
      title: "Options"
      Layout.fillWidth: true

      Column {
        CheckBox {
          text: "Dynamic Activities"
          hoverEnabled: true
          ToolTip.delay: 500
          ToolTip.timeout: 5000
          ToolTip.visible: hovered
          ToolTip.text: "Allow activities to be created on the fly. \nIf not enabled, the application will only allow activities that was added previously"

        }
        CheckBox {
          text: "Dynamic Categories"
          hoverEnabled: true
          ToolTip.delay: 500
          ToolTip.timeout: 5000
          ToolTip.visible: hovered
          ToolTip.text: "Allow categories to be created on the fly. \nIf not enabled, the application will only allow categories that was added previously"
        }
      }
    }

    GroupBox {
      title: "Activities"
      Layout.fillWidth: true
      Layout.fillHeight: true

      ColumnLayout {
        anchors.fill: parent
        ToolBar {
          id: toolBar_
          property int iconSize: 23
          property string imageProvider: "image://images/"
          Layout.fillWidth: true
          RowLayout {
            anchors.fill: parent
            ToolButton {
              icon.name: 'view-refresh'
              icon.source: toolBar_.imageProvider + 'view-refresh'
              icon.width : toolBar_.iconSize
              icon.height: toolBar_.iconSize
              onPressed: py.category_model.refreshCategories()
            }
            ToolButton {
              icon.name: 'list-add'
              icon.source: toolBar_.imageProvider + 'list-add'
              icon.width : toolBar_.iconSize
              icon.height: toolBar_.iconSize
              onPressed: py.category_model.refreshCategories()
            }
            ToolButton {
              id: toolButtonRemove_
              icon.name: 'list-remove'
              icon.source: toolBar_.imageProvider + 'list-remove'
              icon.width : toolBar_.iconSize
              icon.height: toolBar_.iconSize
              icon.color: enabled? "transparent": "lightgray"
              enabled: false
              onClicked:  {
                // Get reference to the parent to try and expand it
                // once the model gets updated. This is probably not
                // the best idea since the model will be reset.
                // For now it works
                var p = tree_.currentIndex.parent
                tree_.model.removeItem( tree_.currentIndex )
                enabled = false
                if( p ) {
                  tree_.expand(p)
                }
              }
            }
            Item {
              Layout.fillWidth: true
            }
          }
        }

        RowLayout {
          Layout.fillHeight: true

          C1.TreeView {
            id: tree_
            Layout.fillHeight: true
            Layout.fillWidth: true
            onClicked: {
              toolButtonRemove_.enabled = tree_.model.canRemove( index )
            }

            C1.TableViewColumn {
              title: "name"
              role: "name"
            }
            // C1.TableViewColumn {
            //   title: "key"
            //   role: "key"
            // }
            // C1.TableViewColumn {
            //   title: "type"
            //   role: "type"
            // }
            rowDelegate:
                Rectangle {
              color: (styleData.selected? "#0077CC" : (styleData.alternate && (styleData.row % 2)? "#F5F5F5": "white"))
              height: 25
            }

            itemDelegate: Rectangle {
              color: "transparent"
              anchors.fill: parent.contentItem
              Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                color: styleData.textColor
                elide: styleData.elideMode
                text: styleData.value
              }
            }

            model: py.category_model
          }
        }
      }
    }
  }
}
