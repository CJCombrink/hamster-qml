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

# The start time has the following offset in seconds applied when started.
# This overcomes the issue where facts are started without specifying
# a time that conflicts with one that was stopped by specifying a time.
# Sometimes there were a small overlap in seconds and the backend did
# not like this. This should ensure that this does not happen.
FACT_START_OFFSET = 10 # seconds

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
        return QTime(0, 0, FACT_START_OFFSET).addSecs(self.start().secsTo(self.end()))

    @pyqtSlot(result='QDate')
    def day(self):
        return self.end().date()

class HqActivity(QObject):
    """ HamsterQML QObject wrapper for a Activity

    The hamster object must be wrapped by a QObject to be
    able to access the slot members from QML
    """
    def __init__(self, activity):
        super(HqActivity, self).__init__()
        self._activity = activity

    @pyqtSlot(result=str)
    def name(self):
      return self._activity.name

    @pyqtSlot(result=str)
    def categoryName(self):
      return self._activity.category.name

    @pyqtSlot(result=int)
    def key(self):
      return self._activity.pk

class HqCategory(QObject):
    """ HamsterQML QObject wrapper for a Category

    The hamster object must be wrapped by a QObject to be
    able to access the slot members from QML
    """
    def __init__(self, category = None):
        super(HqCategory, self).__init__()
        self._category   = category
        self._activities = set()

    @pyqtSlot(result=str)
    def name(self):
      if self._category is None:
        return "(uncategorised)"
      return self._category.name

    @pyqtSlot(result=int)
    def key(self):
      if self._category is None:
        return -1
      return self._category.pk

    @pyqtSlot(HqActivity, result=int)
    def addActivity(self, activity):
      self._activities.add( activity )

    @pyqtSlot(result=HqActivity)
    def activities(self):
      return self._activities


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

    currentUpdated    = pyqtSignal(FactPyQt, name='currentUpdated', arguments=['current'])
    errorMessage      = pyqtSignal('QString', name='errorMessage', arguments=['message'])
    startSuccessful   = pyqtSignal(name='startSuccessful')
    stopSuccessful    = pyqtSignal(name='stopSuccessful')
    factUpdated       = pyqtSignal(FactPyQt, name='factUpdated', arguments=['fact'])
    factAdded         = pyqtSignal(FactPyQt, name='factAdded', arguments=['fact'])
    categoriesChanged = pyqtSignal(name='categoriesChanged')
    activitiesChanged = pyqtSignal(name='activitiesChanged')

    def __init__(self):
        super(HamsterPyQt, self).__init__()
        self._config     = HamsterConfig()
        self._control    = HamsterControl(self._config);
        self.categories()

    def _cleanStart(self, start):
        # Always update the start time to be on the minute with 10 seconds added.
        # This overcomes the issue where facts are started without specifying
        # a time that conflicts with one that was stopped by specifying a time.
        # Sometimes there were a small overlap in seconds and the backend did
        # not like this. This should ensure that this does not happen.
        return start.replace(second=FACT_START_OFFSET, microsecond=0)

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

    @pyqtSlot()
    def categories(self):
      categories  = self._control.categories.get_all()
      categoryDic = {}
      categoryDic[None] = HqCategory()
      for cat in categories:
        categoryDic[cat] = HqCategory(cat)
      activities  = self._control.activities.get_all()
      for act in activities:
        cat = act.category
        categoryDic[cat].addActivity(HqActivity(act))
      return categoryDic

    @pyqtSlot('QString')
    def start(self, command):
        """ Start a fact """
        if not command:
            self.errorMessage.emit('Empty fact information, can\'t start fact.')
            return

        # Some basic handling
        # If the command has a comma but no @, add the @ since comma is for comment
        if ( ',' in command ) and ( not '@' in command ):
            command = command.replace( ',', '@,' )

        fact = Fact.create_from_raw_fact(command)
        if not fact.start:
            # No start time for the fact, set to now
            fact.start = datetime.datetime.now()
        # Clean up the fact start as per the hamster-QML interface.
        fact.start = self._cleanStart(fact.start)
        # Save the fact. If the fact does not have an end time it will be set as the
        # current fact.

        # At this point first check if there is not alreay a fact ongoing,
        # if there it, it must be stopped with the stop time set to before
        # the stop time of the ongoing fact.
        self.stop(fact.start, True)

        try:
            fact = self._control.facts.save(fact)
        except ValueError as err:
            self.errorMessage.emit("Fact start error: {0}".format(err))
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
    def stop(self, endTime = None, ignoreError=False):
        """ Stop an ongoing fact """
        try:
            fact = self._control.facts.stop_tmp_fact()
        except ValueError as err:
            if ignoreError == False:
                self.errorMessage.emit("Fact stop error: {0}".format(err))
            self.current()
            return
        # If the end time is supplied, update the end time to the
        # supplied time instead of using the end time obtained from
        # the fact stop.
        if endTime:
            fact.end = endTime
        # Make the end time clean according what is required for this app.
        fact.end = self._cleanEnd(fact.end)
        try:
            self._control.facts.save(fact)
        except ValueError as err:
            self.errorMessage.emit("Fact stop error: {0}".format(err))
            self.current()
            return
        # At this point adding the fact should have been successful.
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
        fact.start       = self._cleanStart(startTime.toPyDateTime())
        fact.end         = self._cleanEnd(endTime.toPyDateTime())
        fact.activity    = Activity(activity, category=cat)
        fact.description = description
        # Save the updated fact
        try:
            self._control.facts.save(fact)
            self.factUpdated.emit(FactPyQt(fact))
        except ValueError as err:
            self.errorMessage.emit("Could not update fact: {0}".format(err))
            return

    @pyqtSlot(int)
    def removeCategory(self, pk):
      if int(pk) == -1:
        return
      category = self._control.categories.get( pk )
      if category is None:
        return
      self._control.categories.remove( category )
      self.categoriesChanged.emit()

    @pyqtSlot(int)
    def removeActivity(self, pk):
      activity = self._control.activities.get( pk )
      rawActivity = self._control.activities.get( pk, raw=True )
      if activity is None:
        return
      self._control.activities.remove( activity )
      self.activitiesChanged.emit()

    @pyqtSlot(int, result=bool)
    def canRemoveCategory(self, pk):
      if int(pk) == -1:
        return False
      # Get the category and then get the raw category using the
      # get_by_name() function. The CategoryManager does not have
      # a get( pk, raw ) function like the ActivityManager.
      # Using the raw objects is easier than finding the
      # number of associted activities manually.
      category = self._control.categories.get( pk )
      if category is None:
        return
      rawCategory = self._control.categories.get_by_name( category.name, raw=True )
      return len( rawCategory.activities ) == 0

    @pyqtSlot(int, result=bool)
    def canRemoveActivity(self, pk):
      rawActivity = self._control.activities.get( pk, raw=True )
      return len( rawActivity.facts ) == 0

