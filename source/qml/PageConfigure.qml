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
import QtQuick.Window 2.12

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
          id: checkBoxDynamicActivities_
          text: "Dynamic Activities"
          checked: py.settings.dynamicActivities
          hoverEnabled: true
          ToolTip.delay: 500
          ToolTip.timeout: 5000
          ToolTip.visible: hovered
          ToolTip.text: "Allow activities to be created on the fly. \nIf not enabled, the application will only allow activities that was added previously"
          onCheckedChanged: py.settings.dynamicActivities = checked
        }
        CheckBox {
          id: checkBoxDynamicCategories_
          text: "Dynamic Categories"
          checked: py.settings.dynamicCategories
          hoverEnabled: true
          ToolTip.delay: 500
          ToolTip.timeout: 5000
          ToolTip.visible: hovered
          ToolTip.text: "Allow categories to be created on the fly. \nIf not enabled, the application will only allow categories that was added previously"
          onCheckedChanged: py.settings.dynamicCategories = checked
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
              onClicked: py.category_model.refreshCategories()
            }
            ToolButton {
              icon.name: 'list-add'
              icon.source: toolBar_.imageProvider + 'list-add'
              icon.width : toolBar_.iconSize
              icon.height: toolBar_.iconSize
              onClicked: windowCategoryAdd_.show()
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


  Window {
    id: windowCategoryAdd_
    title        : "Add Activity or Category"
    width        : layout_.implicitWidth + 2 * margin
    height       : layout_.implicitHeight + 2 * margin
    minimumWidth : layout_.Layout.minimumWidth + 2 * margin
    minimumHeight: layout_.Layout.minimumHeight + 2 * margin
    flags        : Qt.Dialog
    modality     : Qt.WindowModal

    ColumnLayout {
      id: layout_
      anchors.fill   : parent
      anchors.margins: margin

      Text {
        id: textHeader
        text               : "Enter Activity or Category to add"
        color              : "blue"
        font.pointSize     : 14
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
            Layout.fillWidth: true
            Label  {
              text: "Activity"
            }
            TextField {
              id: textActivity_
              Layout.fillWidth: true
              selectByMouse: true
            }
          }
          ColumnLayout {
            Layout.fillWidth: true
            Label  {
              text: "Category"
            }
            ComboBox {
              id: comboCategory_
              Layout.fillWidth: true
              editable: true
              currentIndex: -1
              textRole: "name"
              model: py.category_model
            }
          }
        }
      }
      Rectangle {
        height: 30
        Layout.fillWidth: true

        RowLayout {
          Button {
            text: "Ok"
            enabled: true
            onClicked: {
              py.category_model.addActivity(textActivity_.text, comboCategory_.editText )
              windowCategoryAdd_.close();
            }
          }

          Button {
            text: "Cancel"
            onClicked: windowCategoryAdd_.close()
          }

          Rectangle {
            Layout.fillWidth: true
          }
        }
      }
    }
  }
}
