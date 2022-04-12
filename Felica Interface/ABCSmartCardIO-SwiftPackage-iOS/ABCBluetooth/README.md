# AB Circle Bluetooth iOS Sample

The AB Circle Bluetooth iOS Sample Application is a small Swift application demonstrating the use of scanning for readers using the "ABCSmartCardIO" framework.  

The "ABCSmartCardIO" framework is a Swift framework used for iOS applications to communicate with ABC Bluetooth Smart Card Readers through a derived version of the Java Smart 
Card I/O API as defined by [JSR 268](https://jcp.org/en/jsr/detail?id=268). To do so, the framework implements a custom "TerminalFactory" interface written in Swift which 
is referenced by this demo application.

## Supported Readers

- CIR415
- CIR515

## OS Support

- This application supports iOS 13.0 or above.

## Prerequisites

1. A Mac computer
2. An Apple Developer Account: https://developer.apple.com/programs/register/
2. Xcode IDE - Xcode 11 or higher
2. An iOS device  - iPhone or iPad

## Getting Started

1. Open the project in Xcode 11 or higher
2. Connect the iPhone or iPad to the Mac
3. Select the iPhone or iPad as Target and press "Run" to start the sample application on the device

Note: it is also possible to run the application in a simulator also, but simulators do not have bluetooth support available.

## Application Details
  
The application demonstrates to the user a way to scan for a AB Circle bluetooth reader using the ABCSmartCardIO BT library.
It has a simple UI containing a 'Scan' button and a label showing the first found reader. Further output is shown in the
output screen from Xcode. 

When pressing 'Scan' the application will start scanning for available readers. If readers are found, it will select the first
listed reader. Then use this reader to get the firmware version, battery level and try to do a small I/O test. 

Then it will try a second scan to see if there are more terminals. After this scan, it'll try to do 2 multiple connection tests.
The first test will connect, then perform simple I/O and then disconnect to all terminals found. The second test
will do the same, but using 1 queue per reader so access will be done simultaneously.

Results are shown in the output screen from Xcode.
<br>

### Application Contents

The following files are shown in the project:
- Main.storyboard : Holds the main views used in the sample application
- ViewController.Swift: Main class controlling the main view and using the ABCSmartCardIO framework functionality
- info.plist: application information property list (see also the paragraph below for bluetooth access)
- Assets.sxassets: defines the icons used in this sample application
  
Notes:
- Other files are auto-generated files when the project was created and should not be modified
<br>

### Bluetooth Access Rights for applications

In order for applications to use bluetooth,  access needs to be enabled by adding a usage description key to the info.plist file.
On apps linked on or after iOS 13, include the "NSBluetoothAlwaysUsageDescription" key. In iOS 12 and earlier, include "NSBluetoothPeripheralUsageDescription" to access Bluetooth peripheral data.

See also:  https://developer.apple.com/documentation/corebluetooth
<br>
  
## History

v1.2.2                02 September 2021
* Uses AB Circle SmartCardIO framework v1.4.2

v1.2.1                26 May 2021
* Uses AB Circle SmartCardIO framework v1.4.1

v1.2.0                03 May 2021
* Uses AB Circle SmartCardIO framework v1.4.0

v1.1.0                12 April 2021
* Uses AB Circle SmartCardIO framework v1.3.0

v1.0.0                18 Februari 2021
* Initial release

## Authors

* **ABC Software Team** (engineering@abcircle.com)

## License
```
Copyright (c) 2018-2021, AB Circle Ltd. All rights reserved.
```
