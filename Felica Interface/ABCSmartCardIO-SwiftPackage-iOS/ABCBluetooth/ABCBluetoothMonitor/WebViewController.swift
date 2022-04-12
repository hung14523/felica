//
//  WebViewController.swift
//  ABCBluetoothMonitor
//
//  Created by JigyoKaihatsu on 2022/04/11.
//

import UIKit
import WebKit
class WebViewController: UIViewController, WKUIDelegate{

    @IBOutlet var webView: WKWebView!
    var syacd: String = "14523"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame:CGRect(x:0, y:100, width:930, height:800))
        
        // URL設定
        let urlString = "https://test.jobs-logistics.jp/csp/butsu/COM100090.csp?kincd="+syacd+"&kencd=&kincd=14523&pass=seisan&syacd=9999995"
        let encodedUrlString = urlString.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        
        let url = NSURL(string: encodedUrlString!)
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
