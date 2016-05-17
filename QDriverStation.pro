#
# Copyright (c) 2015-2016 WinT 3794 <http://wint3794.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#-------------------------------------------------------------------------------
# Deploy configuration
#-------------------------------------------------------------------------------

CONFIG += app
TARGET = QDriverStation

QT += qml
QT += quick

win32* {
    LIBS += -lPdh
    RC_FILE = $$PWD/etc/deploy/windows/info.rc
}

macx* {
    ICON = $$PWD/etc/deploy/mac-osx/AppIcon.icns
    RC_FILE = $$PWD/etc/deploy/mac-osx/AppIcon.icns
    QMAKE_INFO_PLIST = $$PWD/etc/deploy/mac-osx/Info.plist
}

linux:!android {
    target.path = /usr/bin
    TARGET = qdriverstation
    icon.path = /usr/share/pixmaps
    desktop.path = /usr/share/applications
    icon.files += $$PWD/etc/deploy/linux/qdriverstation.png
    desktop.files += $$PWD/etc/deploy/linux/qdriverstation.desktop
    INSTALLS += target desktop icon
}

#-------------------------------------------------------------------------------
# Make options
#-------------------------------------------------------------------------------

UI_DIR = uic
MOC_DIR = moc
RCC_DIR = qrc
OBJECTS_DIR = obj

#-------------------------------------------------------------------------------
# Optimization flags
#-------------------------------------------------------------------------------

QMAKE_CXXFLAGS_RELEASE -= -O
QMAKE_CXXFLAGS_RELEASE -= -O1
QMAKE_CXXFLAGS_RELEASE -= -O2

!win32* {
    QMAKE_CXXFLAGS_RELEASE *= -Ofast
}

win32-gcc* {
    QMAKE_CXXFLAGS_RELEASE *= -Ofast
}

win32-msvc* {
    QMAKE_CXXFLAGS_RELEASE *= -Ot
}

#-------------------------------------------------------------------------------
# Include other libraries
#-------------------------------------------------------------------------------

include ($$PWD/lib/LibDS/LibDS.pri)
include ($$PWD/lib/QJoysticks/QJoysticks.pri)

#-------------------------------------------------------------------------------
# Import source code and QML
#-------------------------------------------------------------------------------

SOURCES += $$PWD/src/main.cpp \
    src/utilities.cpp \
    src/beeper.cpp \
    src/updater.cpp \
    src/dashboards.cpp
RESOURCES += $$PWD/qml/qml.qrc \
    etc/resources/resources.qrc
OTHER_FILES += $$PWD/qml/*.qml
OTHER_FILES += $$PWD/qml/*.js
OTHER_FILES += $$PWD/qml/widgets/*.qml

HEADERS += \
    src/utilities.h \
    src/beeper.h \
    src/updater.h \
    src/dashboards.h

