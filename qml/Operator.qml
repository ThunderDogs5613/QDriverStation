/*
 * Copyright (c) 2015-2016 WinT 3794 <http://wint3794.org>
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

import QtQuick 2.0
import QtQuick.Layouts 1.0
import Qt.labs.settings 1.0

import "widgets"
import "globals.js" as Globals

RowLayout {
    spacing: Globals.spacing

    //
    // If emitted, the status controls will blink to indicate an error
    //
    signal flashStatusIndicators

    //
    // Emitted when the window mode is changed
    //
    signal windowModeChanged (var isDocked)

    //
    // Save the dock state and the selected alliance
    //
    Settings {
        category: "Operator"
        property alias dockSelected: docked.checked
        property alias selectedAlliance: alliances.currentIndex
    }

    //
    // Update the UI when the DS emits a corresponding signal
    //
    Connections {
        target: DriverStation
        onEnabledChanged: enable.checked = enabled
        onControlModeChanged: enable.checked = false
        onElapsedTimeChanged: elapsedTime.text = time
    }

    //
    // Query for CPU usage and battery level every second
    //
    Timer {
        repeat: true
        interval: 1000

        onTriggered: {
            cpuProgressBar.value = cUtilities.getCpuUsage()
            batteryProgressBar.value = cUtilities.getBatteryLevel()
        }

        Component.onCompleted: {
            start()
            cpuProgressBar.value = cUtilities.getCpuUsage()
            batteryProgressBar.value = cUtilities.getBatteryLevel()
        }
    }

    //
    // Robot modes & enable/disable buttons
    //
    ColumnLayout {
        Layout.fillWidth: false
        Layout.fillHeight: true
        spacing: Globals.spacing
        Layout.minimumWidth: Globals.scale (172)
        Layout.maximumWidth: Globals.scale (172)

        //
        // Robot modes selector
        //
        Column {
            Layout.fillHeight: true
            spacing: Globals.scale (-1)

            anchors {
                left: parent.left
                right: parent.right
            }

            function uncheckEverything() {
                test.checked = false
                teleop.checked = false
                practice.checked = false
                autonomous.checked = false
            }

            Button {
                id: teleop
                checked: true
                text: "  " + qsTr ("Teleoperated")
                anchors.left: parent.left
                anchors.right: parent.right
                caption.horizontalAlignment: Text.AlignLeft

                onClicked: {
                    parent.uncheckEverything()
                    checked = true

                    DriverStation.startTeleoperated (false)
                }
            }

            Button {
                id: autonomous
                text: "  " + qsTr ("Autonomous")
                anchors.left: parent.left
                anchors.right: parent.right
                caption.horizontalAlignment: Text.AlignLeft

                onClicked: {
                    parent.uncheckEverything()
                    checked = true

                    DriverStation.startAutonomous (false)
                }
            }

            Button {
                id: practice
                enabled: false
                anchors.left: parent.left
                anchors.right: parent.right
                text: "  " + qsTr ("Practice")
                caption.horizontalAlignment: Text.AlignLeft

                onClicked: {
                    parent.uncheckEverything()
                    checked = true
                }
            }

            Button {
                id: test
                text: "  " + qsTr ("Test")
                anchors.left: parent.left
                anchors.right: parent.right
                caption.horizontalAlignment: Text.AlignLeft

                onClicked: {
                    parent.uncheckEverything()
                    checked = true

                    DriverStation.startTest (false)
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        //
        // Enable/Disable buttons
        //
        RowLayout {
            spacing: Globals.scale (-1)

            anchors {
                left: parent.left
                right: parent.right
            }

            Button {
                id: enable
                text: qsTr ("Enable")
                caption.font.bold: true
                implicitWidth: parent.width / 2
                caption.size: Globals.scale (14)
                implicitHeight: Globals.scale (48)
                caption.color: checked ? Globals.Colors.EnableButtonSelected :
                                         Globals.Colors.EnableButtonUnselected

                onClicked: {
                    if (DriverStation.canBeEnabled())
                        checked = true
                    else
                        flashStatusIndicators()
                }

                onCheckedChanged: {
                    disable.checked = !checked
                    DriverStation.setEnabled (checked)
                }
            }

            Button {
                id: disable
                checked: true
                text: qsTr ("Disable")
                caption.font.bold: true
                implicitWidth: parent.width / 2
                caption.size: Globals.scale (14)
                implicitHeight: Globals.scale (48)
                caption.color: checked ? Globals.Colors.DisableButtonSelected :
                                         Globals.Colors.DisableButtonUnselected

                onClicked: checked = true

                onCheckedChanged: {
                    enable.checked = !checked
                    DriverStation.setEnabled (!checked)
                }
            }
        }
    }

    //
    // A horizontal spacer...
    //
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
    }

    //
    // The right controls (such as CPU/battery progress bars, window mode
    // and team station selectors). This is a mess, but this is nothing
    // compared to the Operator widget done with C++
    //
    GridLayout {
        id: grid
        columns: 2
        Layout.fillWidth: false
        Layout.fillHeight: true
        rowSpacing: Globals.spacing
        columnSpacing: Globals.spacing

        Layout.minimumWidth: minWidth * 2
        Layout.preferredWidth: maxWidth * 2

        property int minWidth: Globals.scale (80)
        property int maxWidth: Globals.scale (100)

        Label {
            Layout.fillWidth: true
            text: qsTr ("Elapsed Time")
        }

        Label {
            size: large
            text: "00:00.0"
            id: elapsedTime
            font.bold: true
            Layout.fillWidth: true
            Layout.minimumWidth: grid.minWidth
            Layout.maximumWidth: grid.maxWidth
            horizontalAlignment: Text.AlignRight
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Label {
            Layout.fillWidth: true
            text: qsTr ("PC Battery")
        }

        Progressbar {
            id: batteryProgressBar

            text: ""
            value: 0
            Layout.fillWidth: true
            Layout.minimumWidth: grid.minWidth
            Layout.maximumWidth: grid.maxWidth
            barColor: {
                if (value > 60)
                    return Globals.Colors.HighlightColor

                else if (value > 20)
                    return Globals.Colors.CPUProgress

                return Globals.Colors.IndicatorError
            }
        }

        Label {
            Layout.fillWidth: true
            text: qsTr ("PC CPU") + " %"
        }

        Progressbar {
            id: cpuProgressBar

            text: ""
            value: 0
            Layout.fillWidth: true
            barColor: Globals.Colors.CPUProgress
            Layout.minimumWidth: grid.minWidth
            Layout.maximumWidth: grid.maxWidth
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Label {
            text: qsTr ("Window")
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Globals.scale (-1)

            Button {
                id: normal
                checked: true
                Layout.fillWidth: true
                icon: icons.fa_mail_reply
                height: Globals.scale (24)
                iconSize: Globals.scale (12)
                Layout.minimumWidth: grid.minWidth / 2
                Layout.maximumWidth: grid.maxWidth / 2

                onClicked: {
                    normal.checked = true
                    docked.checked = false
                }

                onCheckedChanged: {
                    docked.checked = !checked
                    windowModeChanged (docked.checked)
                }
            }

            Button {
                id: docked
                icon: icons.fa_expand
                Layout.fillWidth: true
                height: Globals.scale (24)
                iconSize: Globals.scale (12)
                Layout.minimumWidth: grid.minWidth / 2
                Layout.maximumWidth: grid.maxWidth / 2

                onClicked: {
                    docked.checked = true
                    normal.checked = false
                }

                onCheckedChanged: {
                    normal.checked = !checked
                    windowModeChanged (docked.checked)
                }
            }
        }

        Label {
            Layout.fillWidth: true
            text: qsTr ("Team Station")
        }

        Combobox {
            id: alliances
            Layout.fillWidth: true
            height: Globals.scale (24)
            model: DriverStation.alliances()
            Layout.minimumWidth: grid.minWidth
            Layout.maximumWidth: grid.maxWidth
            onCurrentIndexChanged: DriverStation.setAlliance (currentIndex)
        }
    }
}
