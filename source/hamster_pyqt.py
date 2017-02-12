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
import datetime
from datetime import timedelta 

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot, QDateTime, QDate, QTime

import hamster_lib
from hamster_lib import Fact, HamsterControl, reports, Category, Activity
from hamster_lib.helpers import time as time_helpers

class FactPyQt(QObject):
    """ QObject wrapper for a fact """
    def __init__(self, fact):
        super(FactPyQt, self).__init__()
        self._fact = fact
        
    @pyqtSlot(result='QDateTime')
    def start(self):
        return QDateTime(self._fact.start)
    
    @pyqtSlot(result='QDateTime')
    def end(self):
        return QDateTime(self._fact.end)
    
    @pyqtSlot(result='QString')
    def description(self):
        return self._fact.description
    
    @pyqtSlot(result='QString')
    def category(self):
        if not self._fact.category:
            return ""
        else:
            return self._fact.category.name
        
    @pyqtSlot(result='QString')
    def activity(self):
        return self._fact.activity.name
        
    @pyqtSlot(result='int')
    def key(self): 
        return self._fact.pk
        
    @pyqtSlot(result='QTime')
    def duration(self):
        return QTime(0, 0, 0).addSecs(self.start().secsTo(self.end()))
        
    @pyqtSlot(result='QDate')
    def day(self):
        return self.end().date()

class HamsterConfig():
    """ Configuration class for the Hamster Library 
        This class will most probrbaly be replaced by a ConfigParser class """
    
    def __init__(self):
        self._options = {
            'store'          : 'sqlalchemy',
            'daystart'       : '00:00:00',
            'fact_min_delta' : '60',
            'db_engine'      : 'sqlite',
            'db_path'        : 'hamster_pyqt.sqlite',
            'tmpfile_path'   : 'hamster_pyqt.fact'
        } 
        
    def get(self, key, default = ''):
        if key in self._options:
            return self._options[key]
        else:
            return default;
        
    def __getitem__(self, key):
        return self.get(key)   

        
class HamsterPyQt(QObject):
    """ Hamser interface """
    
    currentUpdated  = pyqtSignal(FactPyQt, name='currentUpdated', arguments=['current'])
    errorMessage    = pyqtSignal('QString', name='errorMessage', arguments=['message'])
    startSuccessful = pyqtSignal(name='startSuccessful')
    stopSuccessful  = pyqtSignal(name='stopSuccessful')
    factUpdated     = pyqtSignal(FactPyQt, name='factUpdated', arguments=['fact'])
    factAdded       = pyqtSignal(FactPyQt, name='factAdded', arguments=['fact'])
    
    def __init__(self):
        super(HamsterPyQt, self).__init__()
        self._config     = HamsterConfig()
        self._control    = HamsterControl(self._config);

    def _cleanStart(self, start):
        # Always update the start time to be on the minute with 10 seconds added.
        # This overcomes the issue where facts are started without specifying
        # a time that conflicts with one that was stopped by specifying a time.
        # Sometimes there were a small overlap in seconds and the backend did
        # not like this. This should ensure that this does not happen.
        return start.replace(second=10, microsecond=0)

    def _cleanEnd(self, end):
        # Update the stop time of the fact to always be on the minute.
        # this will overcome the issue of stopping a fact and starting
        # one for the same minute.
        return end.replace(second=0, microsecond=0)
        
    @pyqtSlot()
    def list(self, start_time = '', end_time = ''):
        """ List all facts that are between the supplied start and end times. """
        if start_time and end_time:
            print('Listing:  %s - %s' % (start_time, end_time) )
        elif start_time:
            print('Listing: %s' % (start_time) )
        else:
            factsPyQt = []
            facts = self._control.facts.get_all()
            for fact in facts:
                # Convert the hamster-lib fact to a PyQt fact
                factPyQt = FactPyQt(fact)
                factsPyQt.append(factPyQt)
            return factsPyQt
        
    @pyqtSlot('QString')
    def start(self, command):
        """ Start a fact """
        if not command:
            self.errorMessage.emit('Empty fact information, can\'t start fact.')
            return
        fact = Fact.create_from_raw_fact(command) 
        if not fact.start:
            # No start time for the fact, set to now 
            fact.start = datetime.datetime.now()
        fact.start = self._cleanStart(fact.start)
        # Save the fact. If the fact does not have an end time it will be set as the 
        # current fact.
        try: 
            fact = self._control.facts.save(fact)
        except ValueError as err:
            self.errorMessage.emit("Fact error: {0}".format(err))
        else:
            self.startSuccessful.emit()
        # Check if the started fact has a end time. If it does have one, a
        # start and end time was specified and the fact was added to the
        # database. If it does not have a end it is an ongoing fact.
        if fact.end:
            self.factAdded.emit(FactPyQt(fact))
        self.current()


    @pyqtSlot(QDateTime, QDateTime, 'QString', 'QString', 'QString')
    def create(self, start, end, activity, category, description):
        """ Create a fact for the given date """
        command = activity
        if category:
            command = command + '@' + category
        if description:
            command = command + ',' + description
        fact = Fact.create_from_raw_fact(command)

        fact.start = self._cleanStart(start.toPyDateTime())
        fact.end   = self._cleanEnd(end.toPyDateTime())
        try:
           fact = self._control.facts.save(fact)
        except ValueError as err:
            self.errorMessage.emit("Fact error: {0}".format(err))
        else:
            self.factAdded.emit(FactPyQt(fact))


    @pyqtSlot()
    def stop(self, end_time = ''):
        """ Stop a fact """
        try: 
            fact = self._control.facts.stop_tmp_fact()
        except ValueError as err:
            self.errorMessage.emit("Fact error: {0}".format(err))
        else:
            fact.end = self._cleanEnd(fact.end)
            self._control.facts.save(fact)
            self.stopSuccessful.emit()
            self.factAdded.emit(FactPyQt(fact))
        self.current()

    @pyqtSlot()
    def cancel(self):
        """ Cancel an ongoing fact """
        try:
            self._control.facts.cancel_tmp_fact()
        except KeyError:
            print('No fact to cancel')
        
        self.current()
        
    @pyqtSlot()
    def current(self):
        """ List the current active fact """
        try:
            fact = self._control.facts.get_tmp_fact()
        except KeyError:
            self.currentUpdated.emit(None);
        else: 
            fact.end = datetime.datetime.now()
            string = '{fact} ({duration} minutes)'.format(fact=fact, duration=fact.get_string_delta())
            self.currentUpdated.emit(FactPyQt(fact));
            

    @pyqtSlot(int, 'QDateTime', 'QDateTime', 'QString', 'QString', 'QString')
    def updateFact(self, key, startTime, endTime, activity, category, description):
        # get the fact from the Fact Manager
        try:
            fact = self._control.facts.get(key)
        except KeyError:
            self.errorMessage.emit('Invalid key passed to updateFact() function.')
            return

        # Check the category. An empty category is accepted by the backend
        # but it can not have an empty name, it must be 'None' instead.
        cat = None
        if category:
            cat = Category(category)
        fact.start       = startTime.toPyDateTime()
        fact.end         = endTime.toPyDateTime()
        fact.activity    = Activity(activity, category=cat)
        fact.description = description
        # Save the updated fact
        try:
            self._control.facts.save(fact)
            self.factUpdated.emit(FactPyQt(fact))
        except ValueError as err:
            self.errorMessage.emit("Could not update fact: {0}".format(err))
            return