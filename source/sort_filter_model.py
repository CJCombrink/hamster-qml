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
from PySide2.QtCore import Qt, QObject, QSortFilterProxyModel, QDate, QModelIndex, QAbstractItemModel
from PySide2.QtCore import Property, Signal, Slot

class SortFilterModel(QSortFilterProxyModel):
    """ The Sort and Filter Proxy model"""

    startDateChanged = Signal(QDate, name='startDateChanged', arguments=['startDate'])
    endDateChanged   = Signal(QDate, name='endDateChanged', arguments=['endDate'])

    def __init__(self):
        super(SortFilterModel, self).__init__()
        self._startDate = QDate()
        self._endDate   = QDate()
        self._dayRole   = 0
        self._startRole = 0

        self.dynamicSortFilter  = True

        self.startDateChanged.connect(self.invalidateFilter)
        self.endDateChanged.connect(self.invalidateFilter)
        self.sourceModelChanged.connect(self._updateDateRoles)

    @Property(QAbstractItemModel)
    def sourceModel(self):
        return super(SortFilterModel, self).sourceModel()

    @sourceModel.setter
    def set_sourceModel(self, model):
        super(SortFilterModel, self).setSourceModel(model)

    @Property(QDate, notify=startDateChanged)
    def startDate(self):
        return self._startDate

    @startDate.setter
    def set_startDate(self, startDate):
        if startDate != self._startDate:
            self._startDate = startDate
            self.startDateChanged.emit(startDate)

    @Property(QDate, notify=endDateChanged)
    def endDate(self):
        return self._endDate

    @endDate.setter
    def set_endDate(self, endDate):
        if endDate != self._endDate:
            self._endDate = endDate
            self.endDateChanged.emit(endDate)

    @Slot(int, QModelIndex, result=bool)
    def filterAcceptsRow(self, row, parentIndex):
        index = self.sourceModel.index(row, 0, parentIndex)
        if not index.isValid():
            return False
        day = self.sourceModel.data(index, self._dayRole)
        if self._startDate == self._endDate:
            return (day == self._startDate)
        # Check if the day is in between the start and end.
        if (day >= self._startDate) and (day <= self._endDate):
            return True
        return False

    @Slot()
    def _updateDateRoles(self):
        dictionary  = dict(self.roleNames())
        for role, name in dictionary.items():
            if name == 'day':
                  self._dayRole = role
            elif name == 'start':
                  self._startRole = role
                  self.setSortRole(self._startRole)
                  self.invalidate()
                  self.sort(0, Qt.AscendingOrder )


    @Slot(int, result='QVariant')
    def get(self, row):
        dictionary  = dict(self.roleNames())
        headers = {}
        index = self.index(row, 0)
        for role, name in dictionary.items():
            headers[str(name, "utf-8")] = self.data(index, role)
        return headers

    @Slot(QModelIndex, QModelIndex, result=bool)
    def lessThan(self, left, right):
        leftStart  = self.sourceModel.data(left, self._startRole)
        rightStart = self.sourceModel.data(right, self._startRole)
        return (leftStart < rightStart)


