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

from PyQt5.QtCore import QObject, pyqtProperty, pyqtSignal, pyqtSlot
from PyQt5.QtGui  import QGuiApplication
from PyQt5.QtQuick import QQuickView
from PyQt5.QtQml import qmlRegisterType, QQmlApplicationEngine

from hamster_pyqt      import HamsterPyQt, FactPyQt
from facts_model       import FactModelPyQt
from sort_filter_model import SortFilterModelPyQt

class Namespace(QObject):

    """Namespace to add clarity on the QML side, contains all Python objects
    exposed to the QML root context as attributes."""
    
    someSignal = pyqtSignal()
    hamsterLibChanged = pyqtSignal()
    nameChanged = pyqtSignal('QString', name='nameChanged', arguments=['value'])
    
    def __init__(self):
        super(Namespace, self).__init__()
        # Initialise the value of the properties.
        self._name = 'hamster'
        self._shoeSize = 0
        self._hamster_lib = HamsterPyQt()
        self._facts = FactModelPyQt(self._hamster_lib);

    # Define the getter of the 'name' property.  The C++ type of the
    # property is QString which Python will convert to and from a string.
    @pyqtProperty('QString', notify=nameChanged)
    def name(self):
        return self._name

    # Define the setter of the 'name' property.
    @name.setter
    def name(self, name):
        self._name = name
        self.nameChanged.emit(self._name)

    # Define the getter of the 'shoeSize' property.  The C++ type and
    # Python type of the property is int.
    @pyqtProperty(int)
    def shoeSize(self):
        return self._shoeSize

    # Define the setter of the 'shoeSize' property.
    @shoeSize.setter
    def shoeSize(self, shoeSize):
        self._shoeSize = shoeSize
        
    @pyqtSlot('QString')
    def setup_new_name(self, new_name):
        self.name = new_name
        
    @pyqtProperty(QObject, notify=hamsterLibChanged)
    def hamster_lib(self):
        return self._hamster_lib

    @pyqtProperty(QObject, notify=hamsterLibChanged)
    def fact_model(self):
        return self._facts

# Main Function
if __name__ == '__main__':
    # Create main app
    myApp = QGuiApplication(sys.argv)
    # Register the Python type. Its URI is 'SortFilterModelPyQt', it's v1.0 and the type
    # will be called 'SortFilterModelPyQt' in QML.
    qmlRegisterType(SortFilterModelPyQt, 'SortFilterModelPyQt', 1, 0, 'SortFilterModelPyQt')
    # Create the QML Engine
    engine = QQmlApplicationEngine()
    context = engine.rootContext()
    # Add the namespace as 'py' in the QML context. If this is done, one can
    # clearly see which objects are accessed from the python side. 
    py =  Namespace()
    context.setContextProperty('py', py)
    engine.load('qml/main.qml')
    sys.exit(myApp.exec_())
    
    #http://stackoverflow.com/questions/33374257/pyqt-5-5-qml-combobox
