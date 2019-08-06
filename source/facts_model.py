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
from PyQt5.QtCore import Qt, QObject, pyqtProperty, pyqtSignal, pyqtSlot, QAbstractTableModel, QModelIndex, QByteArray, QVariant
from PyQt5.QtCore import QTime, QDate

from hamster_lib import Fact

from hamster_pyqt import HamsterPyQt
from hamster_pyqt import FactPyQt

class FactModelPyQt(QAbstractTableModel):
    """ Fact Model """
    COLUMNS = ('key'        ,
               'start'      ,
               'end'        ,
               'activity'   ,
               'category'   ,
               'description',
               'duration'   ,
               'day'        )

    def __init__(self, hamster):
        super(FactModelPyQt, self).__init__()
        self._hamster      = hamster
        self._facts        = []
        self._totals       = {} # Day totals maintained in the model. When the model is refreshed this
                                # list is refreshed. When new facts are added or exising ones updated,
                                # the totals are updated accordingly.
        self._roles        = QAbstractTableModel.roleNames(self)
        roleIndexes        = Qt.UserRole + 1
        self._rKey         = roleIndexes; roleIndexes += 1
        self._rStart       = roleIndexes; roleIndexes += 1
        self._rEnd         = roleIndexes; roleIndexes += 1
        self._rActivity    = roleIndexes; roleIndexes += 1
        self._rCategory    = roleIndexes; roleIndexes += 1
        self._rDescription = roleIndexes; roleIndexes += 1
        self._rDuration    = roleIndexes; roleIndexes += 1
        self._rDay         = roleIndexes; roleIndexes += 1
        # Reset the index to reuse
        roleIndexes      = 0
        self._roles[self._rKey        ] = QByteArray().append(FactModelPyQt.COLUMNS[roleIndexes]); roleIndexes += 1
        self._roles[self._rStart      ] = QByteArray().append(FactModelPyQt.COLUMNS[roleIndexes]); roleIndexes += 1
        self._roles[self._rEnd        ] = QByteArray().append(FactModelPyQt.COLUMNS[roleIndexes]); roleIndexes += 1
        self._roles[self._rActivity   ] = QByteArray().append(FactModelPyQt.COLUMNS[roleIndexes]); roleIndexes += 1
        self._roles[self._rCategory   ] = QByteArray().append(FactModelPyQt.COLUMNS[roleIndexes]); roleIndexes += 1
        self._roles[self._rDescription] = QByteArray().append(FactModelPyQt.COLUMNS[roleIndexes]); roleIndexes += 1
        self._roles[self._rDuration   ] = QByteArray().append(FactModelPyQt.COLUMNS[roleIndexes]); roleIndexes += 1
        self._roles[self._rDay        ] = QByteArray().append(FactModelPyQt.COLUMNS[roleIndexes]); roleIndexes += 1

        self.refreshFacts()
        self._hamster.factUpdated.connect(self.updateFact)
        self._hamster.factAdded.connect(self.addFact)

    @pyqtSlot()
    def refreshFacts(self):
        self.beginResetModel()
        self._facts = self._hamster.list();
        # Clear the totals and then iterate all facts and
        # create a map with the day and the total for that day.
        self._totals = {}
        for fact in self._facts:
            day = fact.day()
            if day not in self._totals:
                self._totals[ day ] = QTime(0, 0, 0)
            factDur = fact.duration()
            self._totals[ day ] = self._totals[ day ].addSecs( ( factDur.hour() * 60 * 60 ) + ( factDur.minute() * 60 ) + factDur.second() )
        self.endResetModel()

    @pyqtSlot(FactPyQt)
    def updateFact(self, updatedFact):
        index = len(self._facts)
        for fact in reversed(self._facts):
            index -= 1
            if fact.key() == updatedFact.key():
                # Get the duration that we know about for the fact
                # before the fact is updated
                factOldDur = fact.duration()
                factOldDay = fact.day()
                # Now replace the old fact with the new one
                self._facts[index] = updatedFact
                # Update the totals with the new data
                # First remove the old duration for the old day
                self._totals[ factOldDay ] = self._totals[ factOldDay ].addSecs( - ( ( factOldDur.hour() * 60 * 60 ) + ( factOldDur.minute() * 60 ) + factOldDur.second() ) )
                # Then add the new duration
                factDur = updatedFact.duration();
                factDay = updatedFact.day()
                self._totals[ factDay ] = self._totals[ factDay ].addSecs( ( factDur.hour() * 60 * 60 ) + ( factDur.minute() * 60 ) + factDur.second() )
                # Notify that the data changed
                self.dataChanged.emit(self.index(index, 0), self.index(index, self.columnCount() - 1), )
                return

    @pyqtSlot(FactPyQt)
    def addFact(self, fact):
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount() + 1)
        self._facts.append(fact)
        # Add the duration to the day of the given fact
        day = fact.day()
        if day not in self._totals:
            self._totals[ day ] = QTime(0, 0, 0)
        factDur = fact.duration()
        self._totals[ day ] = self._totals[ day ].addSecs( ( factDur.hour() * 60 * 60 ) + ( factDur.minute() * 60 ) + factDur.second() )
        self.endInsertRows()

    def rowCount(self, parent=QModelIndex()):
        return len(self._facts)

    def columnCount(self, parent=QModelIndex()):
        return len(FactModelPyQt.COLUMNS)

    def data(self, index, role):
        if not index.isValid():
            return None
        if   role == self._rKey         : return self._facts[index.row()].key()
        elif role == self._rStart       : return self._facts[index.row()].start()
        elif role == self._rEnd         : return self._facts[index.row()].end()
        elif role == self._rActivity    : return self._facts[index.row()].activity()
        elif role == self._rCategory    : return self._facts[index.row()].category()
        elif role == self._rDescription : return self._facts[index.row()].description()
        elif role == self._rDuration    : return self._facts[index.row()].duration()
        elif role == self._rDay         : return self._facts[index.row()].day()
        else: return None

    def roleNames(self):
        return self._roles

    @pyqtSlot(QDate, result='QVariant')
    def getDayTotal(self, day):
        """ Get the total time for the specified day.

        This function uses the day totals that are maintained inside the mode.
        """
        duration = QTime(0, 0, 0)
        if day in self._totals:
          duration = self._totals[ day ]
        return duration;

    @pyqtSlot(int, result='QVariant')
    def get(self, row):
        headers = {}
        tmpFact = self._facts[row]
        headers['key'        ] = tmpFact.key()
        headers['start'      ] = tmpFact.start()
        headers['end'        ] = tmpFact.end()
        headers['activity'   ] = tmpFact.activity()
        headers['category'   ] = tmpFact.category()
        headers['description'] = tmpFact.description()
        headers['duration'   ] = tmpFact.duration()
        headers['day'        ] = tmpFact.day()
        return QVariant(headers)
