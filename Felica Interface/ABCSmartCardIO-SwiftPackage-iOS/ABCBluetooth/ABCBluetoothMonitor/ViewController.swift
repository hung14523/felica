//
//  ViewController.swift
//  ABCBluetoothSample
//
//  Small demo application demonstrating some ways to scan for readers,
//  connect and perform some simple I/O on them.
//
//  Output is generated in the output window of Xcode.
//
//  Created by AB Circle on 10/2/2021.
//

import UIKit
import ABCSmartCardIO
import QuartzCore
import SafariServices
//20220411
import CoreBluetooth
class ViewController: UIViewController{

    //20220411
    @IBOutlet weak var bt_Scan:UIButton!
    /// Control outlet for Scan UIButton
    @IBOutlet weak var buttonScan: UIButton!
    /// Control outlet for Terminal UILabel
    @IBOutlet weak var labelTerminal: UITextField!
    
    @IBOutlet weak var labelInfo: UITextView!
    
    /// Get the AB Circle Terminal Factory
    private let abcTerminalFactory = ABCircleTerminalFactory.getDefault()
    
    /// Optional first terminal found
    private var firstTerminal: CardTerminal? = nil
    
    /// Test number (used in multi connections)
    private var testNumber: UInt8 = 0
    
    //タイマー
    var timer:Timer!
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        //最初の画面呼び出しで画面を右横画面に変更させる。
        UIDevice.current.setValue(3, forKey: "orientation")
        return .landscapeRight
     }

      // 画面を自動で回転させるかを決定する。
      override var shouldAutorotate: Bool {
         //画面が縦だった場合は回転させない
        if(UIDevice.current.orientation.rawValue == 1){
             return false
       }
         else{
             return true
       }
     }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("\nviewWillAppear")
        //self.enableScanButton(enabled: false)
        self.labelInfo.layer.borderWidth = 2.0    // 枠線の幅
        self.labelInfo.layer.borderColor = UIColor.black.cgColor    // 枠線の色
        self.labelInfo.layoutMargins = UIEdgeInsets(top: 5, left: 100, bottom: 5, right: 100)
        labelInfo.alignTextVerticallyInContainer()
        print("\nScanning for 1st terminal for 5 seconds...")
        
        //timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(waitForChange), userInfo: nil, repeats: true)
        
    }
    @objc func waitForChange() {
        
        if self.abcTerminalFactory.terminals().waitForChange(timeout: 5000) == true {
            timer.invalidate()
            print("\nCard change detected!")
            let terminals = self.abcTerminalFactory.terminals().list()
            var cards     = [Card]()
            print("Connect terminals...")
            cards = self.connectCards(terminals: terminals)
            if (cards.isEmpty) {
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.waitForChange), userInfo: nil, repeats: true)
                return
            }
            print("Send APDU's...");
            let idm : String = self.sendCommands(cards: cards)
            print("Disconnect terminals...")
            self.disconnectCards(cards: cards)
            print("idm=" + idm)
            if (!idm.isEmpty) {
                let idmAfter = idm.replacingOccurrences(of: " ", with: "")
                let urlForSetting = UserDefaults.standard.string(forKey: "sendurl") ?? ""
                let url : String =  urlForSetting + "?param=" + idmAfter
                print("url=" + url)
                //20220411
                /*
                let qiitaUrl = URL(string: url)
                if let qiitaUrl = qiitaUrl {
                    UIApplication.shared.open(qiitaUrl)
               }*/
                print("***waitForChange")
                self.goToWebView()
            } else {
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.waitForChange), userInfo: nil, repeats: true)
            }
            
        } else {
            
            print("\nNo detected! ViewController")
            //20220411
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.waitForChange), userInfo: nil, repeats: false)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.current.setValue(4, forKey: "orientation")

        /// Add a border to the button
        /// Set initial label text
        setLabelText(text: "Scan準備中なのでしばらくお待ちください。")
        /// Display some information on the framework in use
        print("Uses " + FrameworkInformation.displayName + " v" + FrameworkInformation.buildNumber)
    }
    //20220411
    @IBAction func goToWebView(){
        self.performSegue(withIdentifier: "GoToWebView", sender: self)
    }
    
    @IBAction func returned(segue: UIStoryboardSegue){
        self.waitForChange()
    }
    /*-------*/
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("viewWillDisappear ")
        timer = nil
    }
    
    @IBAction func onSend(_ sender: UIButton) {
        
        let terminals = self.abcTerminalFactory.terminals().list()
        var cards     = [Card]()
        
        print("Connect terminals...")
        cards = connectCards(terminals: terminals)
        print("Send APDU's...");
        let idm : String = sendCommands(cards: cards)
        print("Disconnect terminals...")
        disconnectCards(cards: cards)
        print("idm=" + idm)
        let idmAfter = idm.replacingOccurrences(of: " ", with: "")
        let urlForSetting = UserDefaults.standard.string(forKey: "sendurl") ?? ""
        let url : String =  urlForSetting + "&kincd=" + idmAfter
        print("url=" + url)
        
        //20220411
        /*
        let qiitaUrl = URL(string: url)
        if let qiitaUrl = qiitaUrl {
           let safariViewController = SFSafariViewController(url: qiitaUrl)
            print("Open safary")
           present(safariViewController, animated: false, completion: nil)
       }*/
        print("***Onsend")
        self.goToWebView()

    }
    /// Scan button handler; starts scanning for readers and tries sending a command to a card on the reader
    ///
    /// Note: this is done in a queue to make sure the label texts are updated (else the UI will just wait for the function to be ready first).
    /// Thus the scan button is disabled / enabled manually.
    ///
    /// - Parameter sender: sender
    @IBAction func onScan(_ sender: UIButton) {
        print("\nScanning for 1st terminal for 5 seconds...")
        enableScanButton(enabled: false)
        DispatchQueue.global(qos: .userInteractive).async {
            
            self.scanForTerminals()
            if let terminal = self.firstTerminal  {
                self.testNumber = 0
                
                print("first Terminal = " + terminal.getName())
                //print("first Terminal　address = " + terminal.g)

                self.setLabelText(text: terminal.getName())

                print("\nTesting First Terminal")
                print("----------------------")
                print("Get Terminal Information...")
                self.getTerminalInfo(terminal: terminal)
            }
            else {
                print("no Terminal found!")
                self.setLabelText(text: "No terminal found!")
            }
            self.enableScanButton(enabled: true)
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.waitForChange), userInfo: nil, repeats: true)
        }
        
        
    }
    
    /// Enables / disables the Scan button
    ///
    /// - Parameter enabled: True to enable, false to disable
    private func enableScanButton(enabled: Bool)
    {
        DispatchQueue.main.async {
            self.buttonScan.isEnabled = enabled
        }
    }
    
    /// Sets the text of the UITextField used as label
    ///
    /// - Parameter text: Text to set
    public func setLabelText(text: String)
    {
        DispatchQueue.main.async {
            self.labelTerminal.text = text
        }
    }
    
    public func setTextView(text: String)
    {
        DispatchQueue.main.async {
            self.labelInfo.text = text
        }
    }

    /// Scans for CIR415/CIR515 bluetooth terminals for 5 seconds and returns the first one in the terminal list while updating the UI
    func scanForTerminals() {
        firstTerminal = scanForABCircleTerminals(duration: 5)
    }

    /// Scans for CIR415/ CIR515 bluetooth terminals and returns the first one in the terminal list.
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

    /// Scans for CIR415/CIR515 bluetooth terminals and waits for it.
    /// Uses a DispatchSemaphore to wait for the scan to be completed
    ///
    /// - Parameter duration: Duration of scan in seconds (5 seconds by default)
    func scanForABCircleTerminalsAndWait(duration: Int = 5) {
        /// queue used for scanning
        let queue  = DispatchQueue(label: "abc.scan.queue")
        /// Dispatch semaphore used for leaving the scan queue
        let semaphore = DispatchSemaphore(value: 0)
        /// Stopper in case no terminals were found
        var stop = false
        
        /// Start scan in queue
        queue.async {[weak self] in
            guard let self = self else {
                return
            }
            do {
                /// Scan for AB Circle readers (no need to wait)
                try self.abcTerminalFactory.scanBluetooth(durationInSeconds: duration)
                /// wait....
                repeat {
                    usleep(100 * 1000)
                }
                while ( !stop)
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
            print("Scan finished...")
        }
        stop = true
    }

    /// Get some terminal Information
    func getTerminalInfo(terminal: CardTerminal) {
        do {
            print("Firmware Version:", try terminal.getFirmwareVersion())
            let level = try terminal.getBatteryLevel()
            if level == 0xFF {
                print("Battery charging...")
            }
            else {
                print("Battery Level:", level , "%")
            }
        }
        catch {
            let status = error as! Status.StatusCode
            
            print("Test failed: get info failed with status ", status.name, " - ",  abcTerminalFactory.statusDescription(status: status))
        }
    }
    
    /// Small test function testing sending an APDU to a terminal
    func testSmartCardIO(terminal: CardTerminal) {
        testNumber += 1
        
        let number = testNumber
        print(number, "- Testing Terminal:", terminal.getName())
        if let card = connect(number, terminal: terminal)
        {
            _ = sendAPDU(number, card: card, apduCommand: "FF CA 00 00 00")
            disconnect(number, card: card)
        }
    }
    
    /// Small (test) function that checks for card present
    /// It might be a good idea to ask a user to present the card at this point,
    /// but this check works as well in case the reader is initializing still.
    ///
    /// - Returns: True if a card is present, else false
    func isCardPresent(_ number: UInt8, terminal: CardTerminal) -> Bool {
        var cardPresent: Bool = false
        var retries = 0

        repeat {
            cardPresent = terminal.isCardPresent()
            if (!cardPresent) {
                print(number, "- No card present, try again...")
                retries += 1
                usleep(250000)
            }
        }
        while (!cardPresent) && (retries < 4)

        return cardPresent
    }
    
    /// Displays the Card Terminals found
    func displayTerminals()
    {
        let terminals = self.abcTerminalFactory.terminals().list()
        
        testNumber = 0
        print("Terminals found:")
        for terminal in terminals {
            testNumber += 1
            print(testNumber, "- Terminal:", terminal.getName())
        }
    }
    
    /// Tests connection and I/O to multiple Card Terminals (if present)
    func testMultipleIO()
    {
        let terminals = self.abcTerminalFactory.terminals().list()
        var cards     = [Card]()
        
        print("Connect terminals...")
        cards = connectCards(terminals: terminals)
        print("Send APDU's...");
        sendCommands(cards: cards)
        print("Disconnect terminals...")
        disconnectCards(cards: cards)
    }
    
    /// Tests connection and I/O to multiple Card Terminals (if present) using queues
    func testMultipleIOMultiThreaded()
    {
        let terminals = self.abcTerminalFactory.terminals().list()

        testNumber = 0
        print("Simultaneously accessing terminals\nFor each thread, just follow the thread number...")
        for terminal in terminals {
            DispatchQueue.global(qos: .utility).async {
                self.testSmartCardIO(terminal: terminal)
            }
        }
    }
    
    /// Tries to connect to CardTerminals found and returns the connected Cards.
    ///
    /// - Parameter terminals: Array of CardTerminals found
    /// - Returns: Array of connected Card objects
    func connectCards(terminals: [CardTerminal]) -> [Card] {
        var cards = [Card]()
        
        testNumber = 0
        for terminal in terminals {
            testNumber += 1
            if let validCard = connect(testNumber, terminal: terminal) {
                cards.append(validCard)
            }
        }
        return cards
    }
    
    /// Connects to an entered CardTerminal and returns the connected Card on success
    /// - Parameters:
    ///   - number: Test index number
    ///   - terminal: CardTerminal to try to connect to
    /// - Returns: Card on success, else nil
    func connect(_ number: UInt8, terminal: CardTerminal) -> Card? {
        var card: Card? = nil
        
        print(number, "- Connecting to terminal ", terminal.getName())
        if isCardPresent(number, terminal: terminal) {
            do {
                card = try terminal.connect(protocolString: "*")
                print(number, "- Connected")
            }
            catch {
                let status = error as! Status.StatusCode
                
                print(number, "- Connect failed with status ", status.name, " - ",  abcTerminalFactory.statusDescription(status: status))
                // Disconnect if card is valid, we do not care the result at this point
                let _ = try? card?.disconnect(reset: false)
            }
        }
        else {
            print(number, "- Test skipped -> no card present")
        }
        return card
    }
    
    /// Sends  a test command to all connected Cards in the entered Card array
    /// - Parameter cards: Array of Card objects
    func sendCommands(cards: [Card]) -> String {

        testNumber = 0
        for card in cards {
            testNumber += 1
            return sendAPDU(testNumber, card: card, apduCommand: "FF CA 00 00 00")
        }
        return ""
    }
    
    /// Sends a test APDU to the entered connected Card
    ///
    /// - Parameters:
    ///   - number: Test index number
    ///   - card: A connected Card
    func sendAPDU(_ number: UInt8, card: Card, apduCommand: String) -> String  {
        do {
            // Send a test APDU and see if we get a response
            let channel: CardChannel = try card.getBasicChannel()
            
            let command: CommandAPDU = try CommandAPDU(apdu: apduCommand)
            print(number, "- Sending command: ", command.toString())
            
            // Transmit command and get response
            let responseAPDU: ResponseAPDU = try channel.transmit(command: command)
            
            print(number, "- Response received: ", responseAPDU.toString())
            
            return responseAPDU.toString()
        }
        catch {
            let status = error as! Status.StatusCode
            
            print(number, "- Test failed: send APDU failed with status ", status.name, " - ",  abcTerminalFactory.statusDescription(status: status))
        }
        return ""
    }
    
    /// Disconnect from all Cards entered
    ///
    /// - Parameter cards: Array of Card objects
    func disconnectCards(cards: [Card]) {
        testNumber = 0
        for card in cards {
            testNumber += 1
            disconnect(testNumber, card: card)
        }
    }
    
    /// Disconnects from a connected Card
    ///
    /// - Parameters:
    ///   - number: Test index number
    ///   - card: A connected Card
    func disconnect(_ number: UInt8, card: Card) {
        do {
            try card.disconnect(reset: false)
            print(number, "- Disconnected")
        }
        catch {
            let status = error as! Status.StatusCode
            
            print(number, "- Test failed: disconnect returned status ", status.name, " - ",  abcTerminalFactory.statusDescription(status: status))
        }
    }
}


