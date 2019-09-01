##########################################################################
##
## Copyright (c) 2017 Carel Combrink
##
## This file is part of the Hamster QML GUI, a QML GUI for the hamster-lib.
##
## The Hamster QML GUI is free software: you can redistribute it and/or
## modify it under the terms of the GNU Lesser General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## The Hamster QML GUI is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public License
## along with the Hamster QML GUI. If not, see <http://www.gnu.org/licenses/>.
############################################################################

import sys
from PyQt5.QtCore import Qt, QObject, pyqtProperty, pyqtSignal, pyqtSlot, QModelIndex, QByteArray, QVariant, Q_ENUMS
from PyQt5.QtCore import QTime, QDate
from PyQt5.QtGui  import QStandardItemModel, QStandardItem

from hamster_lib import Fact

from hamster_pyqt import HamsterPyQt
from hamster_pyqt import FactPyQt

class HqCategoriesModel(QStandardItemModel):
    """
    Categories Tree Model.
    This model contains the categories and their activities in a tree model.
    Uncategorised activities are shown in the 'Uncategorised' node.
    This model allows for the removal of categories and activities if the
    respective item does not have dependents.
    Use the canRemove() function to check if the removeItem() function will
    remove the item.
    """
    COLUMNS = ('name'       ,
               'key'        ,
               'type'       )

    def __init__(self, hamster):
        super(HqCategoriesModel, self).__init__()
        self._hamster      = hamster
        self._categories        = []
        self._totals       = {} # Day totals maintained in the model. When the model is refreshed this
                                # list is refreshed. When new facts are added or exising ones updated,
                                # the totals are updated accordingly.
        self._roles        = QStandardItemModel.roleNames(self)
        roleIndexes        = Qt.UserRole + 1
        self._rName        = roleIndexes; roleIndexes += 1
        self._rKey         = roleIndexes; roleIndexes += 1
        self._rType        = roleIndexes; roleIndexes += 1
        # Reset the index to reuse
        roleIndexes      = 0
        self._roles[self._rName       ] = QByteArray().append(HqCategoriesModel.COLUMNS[roleIndexes]); roleIndexes += 1
        self._roles[self._rKey        ] = QByteArray().append(HqCategoriesModel.COLUMNS[roleIndexes]); roleIndexes += 1
        self._roles[self._rType       ] = QByteArray().append(HqCategoriesModel.COLUMNS[roleIndexes]); roleIndexes += 1

        self.refreshCategories()
        self._hamster.categoriesChanged.connect(self.refreshCategories)
        self._hamster.activitiesChanged.connect(self.refreshCategories)

    @pyqtSlot()
    def refreshCategories(self):
        self.beginResetModel()
        self._categories = self._hamster.categories()
        parent = self.invisibleRootItem()
        parent.removeRows(0, parent.rowCount() )
        for cat in self._categories.values():
            item = QStandardItem(cat.name() )
            parent.appendRow( [ item, QStandardItem( str(cat.key()) ), QStandardItem( "Category" ) ] )
            for act in cat.activities():
                item.appendRow( [ QStandardItem( act.name() ), QStandardItem( str(act.key()) ), QStandardItem( "Activity" ) ] )
        self.endResetModel()

    def roleNames(self):
        return self._roles

    def data(self, index, role):
        if not index.isValid():
            return None
        col = index.column()
        if   role == self._rName: col = 0
        elif role == self._rKey : col = 1
        elif role == self._rType: col = 2
        return QStandardItemModel.data(self, index.siblingAtColumn( col ), Qt.DisplayRole)

    @pyqtSlot(QModelIndex)
    def removeItem(self, index):
      type = index.data(self._rType)
      if type == 'Category':
        self._hamster.removeCategory(index.data(self._rKey))
      if type == "Activity":
        self._hamster.removeActivity(index.data(self._rKey))

    @pyqtSlot(QModelIndex, result=bool)
    def canRemove(self, index):
      type = index.data(self._rType)
      if type == 'Category':
        return self._hamster.canRemoveCategory(index.data(self._rKey))
      if type == "Activity":
        return self._hamster.canRemoveActivity(index.data(self._rKey))
      return False

    @pyqtSlot(str, str)
    def addActivity(self, activity, category):
      added = self._hamster.addActivity( activity, category )
      if added:
        self.refreshCategories()

