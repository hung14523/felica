# AB Circle Smart Card I/O Bluetooth iOS Framework


The "ABCSmartCardIO" framework is a Swift framework used for iOS applications to communicate with ABC Bluetooth Smart Card Readers
through a derived version of the Java Smart Card I/O API as defined by [JSR 268](https://jcp.org/en/jsr/detail?id=268). 
To do so, the framework implements a custom "TerminalFactory" interface written in Swift which can be referenced by iOS applications.

The Java Smart Card I/O API itself defines an API for communication with Smart Cards using ISO/IEC 7816-4 APDUs. 
It thereby allows applications to interact with applications running on the Smart Card, and to store and retrieve data on the card, etc.

## Supported Readers

- CIR415
- CIR515

## OS Support

- This framework supports iOS 10.0 or above.

## Getting Started

1. Extract and save the AB Circle SmartCard I/O package to a convenient folder 
2. In Xcode create an App project using the Swift language
3. Drag the extracted ABCSmartCardIO-SwiftPackage-iOS folder from Finder onto the project
4. Click on the project name (root node) in the project details
5. In the project details window that opens, select the project Target
6. From the project details, under Frameworks, select the ABCSmartCardIO.xcframework and drag it to the section 'Frameworks, Libraries and Embedded Content'
7. In the Swift file that references the framework add the following line: "Import ABCSmartCardIO"

The API is now available for use.  
  
### Note: Bluetooth Access Rights for applications
  
In order for applications to use bluetooth,  access needs to be enabled by adding a usage description key to the info.plist file.
On apps linked on or after iOS 13, include the "NSBluetoothAlwaysUsageDescription" key. In iOS 12 and earlier, include "NSBluetoothPeripheralUsageDescription" to access Bluetooth peripheral data.

See also:  https://developer.apple.com/documentation/corebluetooth

### Development Environment
```
Xcode - Xcode 11 or higher
```
## Demo Application source

A demo application is included in the ABCBluetoothDemo folder.

The demo application allows:
1. Discovery and selection of a Card Terminal
2. Connection to a Card on the Terminal
3. Sending APDU or Escape Commands to the connected Terminal
4. Monitor the status of Card Terminals by use of a monitor class.

For more details, see also the documentation included with the demo application in the ABCBluetoothDemo/Documentation folder.

## Sample Application source

Additionally, a small sample application is included in the ABCBluetoothSample folder.

This application allows terminal discovery (using the sample scanBluetooth code below) and simple card detection and APDU sending.

## Usage Example

```
/// Scans for CIR415/CIR515 bluetooth terminals and returns the first one in the terminal list.
/// Uses a DispatchSemaphore to wait for the scan to be completed
///
/// - Parameter duration: Duration of scan in seconds (5 seconds by default)
func scanForABCircleTerminals(duration: Int = 5) -> CardTerminal? {
    /// queue used for scanning
    let queue  = DispatchQueue(label: "abc.scan.queue")
    /// Dispatch semaphore used for leaving the scan queue
    let semaphore = DispatchSemaphore(value: 0)
    /// Stopper in case no terminals were found
    var stop = false
    /// (Optional) terminal to return
    var firstTerminal: CardTerminal? = nil
    
    /// Start scan in queue
    queue.async {[weak self] in
        guard let self = self else {
            return
        }
        print("Scanning for terminals...")
        do {
            self.firstTerminal = nil
            /// Scan for AB Circle readers (no need to wait)
            try self.abcTerminalFactory.scanBluetooth(durationInSeconds: duration)
            /// Check the list of terminals until we have one
            repeat {
                let terminals = self.abcTerminalFactory.terminals().list()
                if !terminals.isEmpty {
                    /// Set the first terminal
                    firstTerminal = terminals.first
                }
            }
            while (firstTerminal == nil && !stop)
            /// Leave
            semaphore.signal()
        }
        catch {
            /// In case of error, display it
            let status = error as! Status.StatusCode
            
            print("Scan failed with status" + status.name + ", " + self.abcTerminalFactory.statusDescription(status: status))
            semaphore.signal()
        }
    }
    if semaphore.wait(timeout: .now() + .seconds(duration)) == DispatchTimeoutResult.timedOut {
        /// waiting time out, means no terminal was found...
        print("Waiting timed out...")
    }
    stop = true
    
    /// Return the first terminal found (if any)
    return firstTerminal
}

```

## Known issues

- None at this time.
Note: please use the latest CIR415/CIR515 firmware available.

## History

v1.4.2                02 September 2021
* Fixed issue causing readTimeout in certain cases
* Fixed issue with setting card state after power off in certain cases
* Added more detailed error return values for CIR515 readers in case of errors

v1.4.1                26 May 2021
* Fixed minor issue in getBatteryLevel

v1.4.0                03 May 2021
* Added support for the CIR515 reader
* Improved stability
* Added ABCCardTerminalMonitor class in demo application

v1.3.0                12 April 2021
* Added new functionality in CardTerminal:
    - getBatteryLevel ; gets the battery level of the current terminal.
    - getFirmwareVersion ; gets the firmware version of the current terminal.
* Fixed issue with card tap interrupting escape command in rare cases even if connected in direct mode.

v1.2.1                25 March 2021
* Fixed issue with CardTerminals.list while using a state filter
* Fixed an issue in Get Response APDU handling
* Improved stability on removing readers while in use

v1.2.0                18 February 2021
* Added new functionality:
    - Disconnect(cardTerminal: CardTerminal) ; disconnect and unpairs a AB Circle reader completely.
    - scanBluetooth(name: String) ; scans for AB Circle readers using a (case insensitive) name filter
    - setBluetoothRssiFilter(rssiValue: Int) ; sets a reader filter on RSSI value, used when scanning for readers
* Improved speed
* Improved stability
* Added an additional sample application (& its source code)

v1.1.1                21 December 2020
* Added demo application source code and documentation
* Added "Note: Bluetooth Access Rights for applications" section to this readme 

v1.1.0                24 November 2020
* Added support for setting custom encryption key for reader authentication and data encryption
* Added additional error handling in case bluetooth is unavailable 
* Fixed an issue in Get Response APDU handling
* Fixed a reader name sorting issue when more than 1 readers are found

v1.0.0                18 November 2020
* Official release 
* Added HMTL documentation (open Documentation/index.html)
* Improved comments on API functions

v0.9.0                10 November 2020
* Initial beta release


## Authors

* **ABC Software Team** (engineering@abcircle.com)

## License
```
Copyright (c) 2018-2021, AB Circle Ltd. All rights reserved.
```
