//
//  SceneDelegate.swift
//  ABCBluetoothSample
//
//  Created by AB Circle on 10/2/2021.
//

import UIKit
import ABCSmartCardIO
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// Get the AB Circle Terminal Factory
    private let abcTerminalFactory = ABCircleTerminalFactory.getDefault()
    
    /// Optional first terminal found
    private var firstTerminal: CardTerminal? = nil

    /// Test number (used in multi connections)
    private var testNumber: UInt8 = 0
    
    //タイマー
    var timer:Timer!
    var ok:UIAlertAction!
    var alert:UIAlertController!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("\nsceneDidBecomeActive")
        let rootVC = self.window?.rootViewController as? ViewController
        //ここから追加
        if (alert == nil) {
            alert = UIAlertController(title: "警告", message: "スキャン準備完了後、PMSに遷移するまでカードを外さないでください。", preferredStyle: .alert)
            ok = UIAlertAction(title: "OK", style: .default) { (action) in
                rootVC?.dismiss(animated: true, completion: nil)
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.waitForChange), userInfo: nil, repeats: false)
            }
            alert.addAction(ok)
        }
        scanForTerminals()
        if let terminal = self.firstTerminal  {
            self.testNumber = 0
            
            print("first Terminal = " + terminal.getName())
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                rootVC?.setLabelText(text: terminal.getName())
                rootVC?.setTextView(text: "スキャン可")
            }
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.waitForChange), userInfo: nil, repeats: false)
            print("\nTesting First Terminal")
            print("----------------------")
            print("Get Terminal Information...")
            self.getTerminalInfo(terminal: terminal)
        } else {
            print("no Terminal found!")
            rootVC?.setLabelText(text: "ERROR! 再起動してください。")
            rootVC?.setTextView(text: "スキャン不可")
        }
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        self.timer?.invalidate()
        print("\nsceneWillResignActive")
        let rootVC = self.window?.rootViewController as? ViewController
        rootVC?.setLabelText(text: "Scan準備中なのでしばらくお待ちください。")
        rootVC?.setTextView(text: "スキャン準備中")
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("\nsceneWillResignActive")
        let rootVC = self.window?.rootViewController as? ViewController
        rootVC?.setLabelText(text: "Scan準備中なのでしばらくお待ちください。")
        rootVC?.setTextView(text: "スキャン準備中")
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("\nsceneDidEnterBackground")
        let rootVC = self.window?.rootViewController as? ViewController
        rootVC?.setLabelText(text: "Scan準備中なのでしばらくお待ちください。")
        rootVC?.setTextView(text: "スキャン準備中")
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    @objc func waitForChange() {
        
        let rootVC = self.window?.rootViewController as? ViewController
        if self.abcTerminalFactory.terminals().waitForChange(timeout: 5000) == true {
            timer.invalidate()
            
            print("\nCard change detected!")
            let terminals = self.abcTerminalFactory.terminals().list()
            var cards     = [Card]()
            print("Connect terminals...")
            cards = self.connectCards(terminals: terminals)
            if (cards.isEmpty) {
                //ここまで追加
                rootVC?.present(alert, animated: true, completion: nil)
                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.waitForChange), userInfo: nil, repeats: false)
                return
            }
            print("Send APDU's...");
            let idm : String = self.sendCommands(cards: cards)
            print("Disconnect terminals...")
            self.disconnectCards(cards: cards)
            print("idm=" + idm)
            if (!idm.isEmpty) {
                
                let idmAfter = idm.replacingOccurrences(of: " ", with: "")
                let idmAfter2 = idmAfter.dropLast(4);
                let urlForSetting = UserDefaults.standard.string(forKey: "sendurl") ?? ""
                let urlStr : String =  urlForSetting + "&kincd=" + idmAfter2
                print("url=" + urlStr)
                /*
                let url = URL(string: urlStr)
                if let url = url {
                    UIApplication.shared.open(url)
               }*/
                self.window?.rootViewController!.performSegue(withIdentifier: "GoToWebView", sender: nil)
            } else {
                //ここまで追加
                rootVC?.present(alert, animated: true, completion: nil)
            }
            
        } else {
            
            print("\nNo detected! App delegate")
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.waitForChange), userInfo: nil, repeats: false)
        }
    }
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! WebViewController
        destination.syacd = "13458"
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

