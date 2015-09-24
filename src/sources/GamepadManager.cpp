/*
 * Copyright (c) 2015 WinT 3794 <http://wint3794.org>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <QDir>
#include <QFile>
#include <QTimer>
#include <QMessageBox>
#include <QApplication>

#include <math.h>
#include <DriverStation.h>

#include "Settings.h"
#include "GamepadManager.h"

/* Maximum axis value */
#define _MAX_VAL 32767

/* Location of community-maintained joystick mappings */
#define _CONTROLLER_DB ":/sdl/database.txt"

/* Used to create mappings from unsupported controllers */
#if defined _WIN32 || defined _WIN64
#define _GENERIC_MAPPINGS ":/sdl/generic/windows.txt"
#elif defined __APPLE__
#define _GENERIC_MAPPINGS ":/sdl/generic/mac-osx.txt"
#elif defined __gnu_linux__
#define _GENERIC_MAPPINGS ":/sdl/generic/linux.txt"
#endif

#define SDL_MAIN_HANDLED
#define _INIT_CODE SDL_INIT_JOYSTICK | SDL_INIT_GAMECONTROLLER

GamepadManager* GamepadManager::m_instance = nullptr;

GamepadManager::GamepadManager()
{
    SDL_SetHint (SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");

    if (SDL_Init (_INIT_CODE) != 0) {
        QMessageBox::critical (nullptr, tr ("Fatal Error!"),
                               tr ("SDL Init Error: %1").arg (SDL_GetError()));

        exit (EXIT_FAILURE);
    }

    /* Enable event states to use them in the event loop */
    SDL_JoystickEventState (SDL_ENABLE);
    SDL_GameControllerEventState (SDL_ENABLE);

    /* Load community controller database */
    QFile db (_CONTROLLER_DB);
    if (db.open (QFile::ReadOnly)) {
        while (!db.atEnd())
            SDL_GameControllerAddMapping (
                QVariant (db.readLine()).toString().toStdString().c_str());

        db.close();
    }

    /* Load generic mapping string, used for unsupported controllers */
    QFile generic (_GENERIC_MAPPINGS);
    if (generic.open (QFile::ReadOnly)) {
        m_genericMapping = (QString)generic.readAll();
        generic.close();
    }

    /* Register joysticks automatically on DS */
    m_ds = DriverStation::getInstance();
    connect (this, SIGNAL (countChanged (int)),
             this, SLOT   (registerJoysticksToDriverStation (int)));
}

GamepadManager::~GamepadManager()
{
    for (int i = 0; i < SDL_NumJoysticks(); ++i)
        SDL_GameControllerClose (SDL_GameControllerOpen (i));

    SDL_Quit();
}

GamepadManager* GamepadManager::getInstance()
{
    if (m_instance == nullptr)
        m_instance = new GamepadManager();

    return m_instance;
}

int GamepadManager::getNumAxes (int joystick)
{
    return SDL_JoystickNumAxes (SDL_JoystickOpen (joystick));
}

int GamepadManager::getNumButtons (int joystick)
{
    return SDL_JoystickNumButtons (SDL_JoystickOpen (joystick));
}

QString GamepadManager::getAxisName (int axis)
{
    return QString ("Axis %1").arg (axis);
}

QString GamepadManager::getButtonName (int button)
{
    return QString ("Button %1").arg (button);
}

QString GamepadManager::getJoystickName (int joystick)
{
    return SDL_JoystickNameForIndex (joystick);
}

QStringList GamepadManager::joystickList()
{
    QStringList list;

    for (int i = 0; i < SDL_NumJoysticks(); ++i)
        list.append (getJoystickName (i));

    return list;
}

void GamepadManager::init()
{
    m_time = 20;
    m_tracker = -1;
    QTimer::singleShot (500, this, SLOT (readSdlEvents()));
}

void GamepadManager::setUpdateInterval (int time)
{
    if (time >= 0)
        m_time = time;
}

void GamepadManager::rumble (int joystick, int time)
{
    SDL_InitSubSystem (SDL_INIT_HAPTIC);
    SDL_Haptic* haptic = SDL_HapticOpen (joystick);

    if (haptic != nullptr) {
        SDL_HapticRumbleInit (haptic);
        SDL_HapticRumblePlay (haptic, 1, time);
    }
}

GM_Axis GamepadManager::getAxis (const SDL_Event* event)
{
    GM_Axis axis;

    axis.rawId = event->caxis.axis;
    axis.joystick = getJoystick (event);
    axis.identifier = getAxisName (axis.rawId);
    axis.value = (double) (event->caxis.value) / _MAX_VAL;

    return axis;
}

GM_Button GamepadManager::getButton (const SDL_Event* event)
{
    GM_Button button;

    button.rawId = event->cbutton.button;
    button.joystick = getJoystick (event);
    button.identifier = getButtonName (button.rawId);
    button.pressed = event->cbutton.state == SDL_PRESSED;

    return button;
}

GM_Joystick GamepadManager::getJoystick (const SDL_Event* event)
{
    GM_Joystick stick;

    stick.id = getDynamicId (event->cdevice.which);
    stick.numAxes = getNumAxes (event->cdevice.which);
    stick.numButtons = getNumButtons (event->cdevice.which);
    stick.displayName = getJoystickName (event->cdevice.which);

    return stick;
}

int GamepadManager::getDynamicId (int id)
{
    id = m_tracker - (id + 1);
    if (id < 0) id = abs (id);
    if (id >= SDL_NumJoysticks()) id -= 1;

    return id;
}

void GamepadManager::readSdlEvents()
{
    SDL_Event event;
    while (SDL_PollEvent (&event)) {
        switch (event.type) {
        case SDL_JOYDEVICEADDED:
            ++m_tracker;
            onControllerAdded (&event);
            emit countChanged (joystickList());
            emit countChanged (SDL_NumJoysticks());
            break;
        case SDL_CONTROLLERDEVICEREMOVED:
            onControllerRemoved (&event);
            emit countChanged (joystickList());
            emit countChanged (SDL_NumJoysticks());
            break;
        case SDL_CONTROLLERAXISMOTION:
            onAxisEvent (&event);
            break;
        case SDL_CONTROLLERBUTTONDOWN:
            onButtonEvent (&event);
            break;
        case SDL_CONTROLLERBUTTONUP:
            onButtonEvent (&event);
            break;
        }
    }

    QTimer::singleShot (m_time, this, SLOT (readSdlEvents()));
}

void GamepadManager::onAxisEvent (const SDL_Event* event)
{
    GM_Axis axis = getAxis (event);
    m_ds->updateJoystickAxis (axis.joystick.id,
                              axis.rawId,
                              axis.value);

    emit axisEvent (axis);
}

void GamepadManager::onButtonEvent (const SDL_Event* event)
{
    GM_Button button = getButton (event);
    m_ds->updateJoystickButton (button.joystick.id,
                                button.rawId,
                                button.pressed);

    emit buttonEvent (button);
}

void GamepadManager::onControllerAdded (const SDL_Event* event)
{
    if (!SDL_IsGameController (event->cdevice.which)) {
        SDL_Joystick* js = SDL_JoystickOpen (event->cdevice.which);

        if (js) {
            char guid[1024];
            SDL_JoystickGetGUIDString (SDL_JoystickGetGUID (js),
                                       guid,
                                       sizeof (guid));

            QString mapping = QString ("%1,%2,%3")
                              .arg (guid)
                              .arg (SDL_JoystickName (js))
                              .arg (m_genericMapping);

            SDL_GameControllerAddMapping (mapping.toStdString().c_str());
            SDL_JoystickClose (js);
        }
    }

    SDL_GameControllerOpen (event->cdevice.which);
}

void GamepadManager::onControllerRemoved (const SDL_Event* event)
{
    SDL_GameControllerClose (SDL_GameControllerOpen (event->cdevice.which));
}

void GamepadManager::registerJoysticksToDriverStation (int joystickCount)
{
    m_ds->removeAllJoysticks();

    for (int i = 0; i <= joystickCount - 1; ++i)
        m_ds->addJoystick (getNumAxes (i), getNumButtons (i));
}