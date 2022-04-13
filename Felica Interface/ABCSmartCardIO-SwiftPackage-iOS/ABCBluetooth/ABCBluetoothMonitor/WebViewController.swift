//
//  WebViewController.swift
//  ABCBluetoothMonitor
//
//  Created by JigyoKaihatsu on 2022/04/11.
//

import UIKit
import WebKit
import ABCSmartCardIO

class WebViewController: UIViewController, WKUIDelegate{

    @IBOutlet var webView: WKWebView!
    
    /// Get the AB Circle Terminal Factory
    private let abcTerminalFactory = ABCircleTerminalFactory.getDefault()
    
    /// Optional first terminal found
    private var firstTerminal: CardTerminal? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame:CGRect(x:0, y:100, width:930, height: self.view.frame.height-100))
        
        // URL設定
        /*
        let urlString = "https://test.jobs-logistics.jp/csp/butsu/COM100090.csp?kincd="+syacd+"&kencd=&kincd=14523&pass=seisan&syacd=9999995"
        let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        let url = NSURL(string: encodedUrlString!)
         */
        let url = UserDefaults.standard.url(forKey: "loginURL")
        let request = NSURLRequest(url: url! as URL)
 
        webView.load(request as URLRequest)
        
        self.view.addSubview(webView)
         
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
