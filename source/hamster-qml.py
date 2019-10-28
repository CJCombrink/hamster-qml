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

from PySide2.QtCore    import QObject, QSettings, Property, Signal, Slot, Qt
from PySide2.QtGui     import QGuiApplication, QIcon, QImage
from PySide2.QtWidgets import qApp
from PySide2.QtQuick   import QQuickView, QQuickImageProvider
from PySide2.QtQml     import qmlRegisterType, QQmlApplicationEngine

from hamster_pyqt      import HamsterPyQt, FactPyQt
from facts_model       import FactModelPyQt
from sort_filter_model import SortFilterModelPyQt
from categories_model  import HqCategoriesModel

cVERSION = u'0.4'
# Set the windows ICON (need to figure out what happens on Linux)
import ctypes
myappid = u'cjc.hamster-qml.' + cVERSION
ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(myappid)

class ImageProvider(QQuickImageProvider):
    """
    Image provider for the qml to resolve images from name
    if the style does not provide the correct image.
    The provider uses the icon naming spec from:
    https://specifications.freedesktop.org/icon-naming-spec/icon-naming-spec-latest.html
    """
    def __init__(self):
        super(ImageProvider, self).__init__(QQuickImageProvider.Image)

    def requestImage(self, imageId, size, requestedSize):
        imagePath = '../Resources/Images/'
        imageDict = {
          'list-add'    : 'list-add.svg',
          'list-remove' : 'list-remove.svg',
          'view-refresh': 'view-refresh.svg'
        }

        imageName = imageDict.get( imageId )
        if imageName is not None:
          if size:
            size = requestedSize
          img = QImage( imagePath + imageName).scaled(requestedSize, Qt.KeepAspectRatio, Qt.SmoothTransformation)
        else:
          img = QImage()
        return img


class Settings( QObject ):
  """
  The Hamster-Qml Appliction Settings
  This class contains settings used by the Hamster-Qml application.
  TODO: Store settings to QSettings ini file.
  """
  dynamicCategoriesChanged = Signal(bool)
  dynamicActivitiesChanged = Signal(bool)

  def __init__(self):
      super().__init__()
      settings = QSettings()
      self._dynamicCategories = bool( settings.value( "DynamicCategories", True ) )
      self._dynamicActivities = bool( settings.value( "DynamicActivities", True ) )

  @Property(bool, notify=dynamicCategoriesChanged)
  def dynamicCategories(self):
    """If dynamic categories are set to True, categories can be added on the fly
       when new facts are created. Otherwise the GUI will only allow selecting
       existing categories. The Configure page is used to add new categories. """
    return self._dynamicCategories

  @dynamicCategories.setter
  def set_dynamicCategories(self, value):
    if self._dynamicCategories != value:
      self._dynamicCategories = value
      QSettings().setValue( "DynamicCategories", value )
      self.dynamicCategoriesChanged.emit( value )

  @Property(bool, notify=dynamicActivitiesChanged)
  def dynamicActivities(self):
    """If dynamic activities are set to True, activities can be added on the fly
       when new facts are created. Otherwise the GUI will only allow selecting
       existing activities. The Configure page is used to add new activities. """
    return self._dynamicActivities

  @dynamicActivities.setter
  def set_dynamicActivities(self, value):
    if self._dynamicActivities != value:
      self._dynamicActivities = value
      QSettings().setValue( "DynamicActivities", value )
      self.dynamicActivitiesChanged.emit( value )

class Namespace(QObject):
    """Namespace to add clarity on the QML side, contains all Python objects
    exposed to the QML root context as attributes."""

    hamsterLibChanged = Signal()

    def __init__(self):
        super(Namespace, self).__init__()
        # Initialise the value of the properties.
        self._name        = 'hamster'
        self._hamster_lib = HamsterPyQt()
        self._facts       = FactModelPyQt(self._hamster_lib);
        self._categories  = HqCategoriesModel(self._hamster_lib)
        self._settings    = Settings()

    @Property(str)
    def version(self):
        return cVERSION

    @Property(QObject, notify=hamsterLibChanged)
    def hamster_lib(self):
        return self._hamster_lib

    @Property(QObject, notify=hamsterLibChanged)
    def fact_model(self):
        return self._facts

    @Property(QObject, notify=hamsterLibChanged)
    def category_model(self):
        return self._categories

    @Property(QObject, notify=hamsterLibChanged)
    def settings(self):
      return self._settings

# Main Function
if __name__ == '__main__':
    # Create main app
    sys.argv += ['--style', 'fusion']
    myApp = QGuiApplication(sys.argv)
    # Setting the application name and organisation
    # so that the default constructor of QSettings will
    # create an INI file on disk
    qApp.setApplicationName( 'Hamster-QML' )
    qApp.setApplicationVersion( cVERSION )
    qApp.setOrganizationName( 'cjc' )
    qApp.setWindowIcon(QIcon('../Resources/Images/hamster-gray_256.png'))
    # Setting the defaultf format for QSettins to be INI files.
    # I don't like stuff writing to the Registry on Windows...
    QSettings.setDefaultFormat( QSettings.IniFormat )
    # Register the Python type. Its URI is 'SortFilterModelPyQt', it's v1.0 and the type
    # will be called 'SortFilterModelPyQt' in QML.
    qmlRegisterType(SortFilterModelPyQt, 'SortFilterModelPyQt', 1, 0, 'SortFilterModelPyQt')
    # Create the QML Engine
    engine = QQmlApplicationEngine()
    engine.addImageProvider("images", ImageProvider())
    context = engine.rootContext()
    # Add the namespace as 'py' in the QML context. If this is done, one can
    # clearly see which objects are accessed from the python side.
    py = Namespace()
    context.setContextProperty('py', py)
    engine.load('qml/main.qml')
    sys.exit(myApp.exec_())

    #http://stackoverflow.com/questions/33374257/pyqt-5-5-qml-combobox
