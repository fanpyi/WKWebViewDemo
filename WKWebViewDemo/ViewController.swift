//
//  ViewController.swift
//  WKWebViewDemo
//
//  Created by fanpyi on 26/1/16.
//  Copyright © 2016 fanpyi. All rights reserved.
//

import UIKit
import WebKit
class ViewController: UIViewController,WKScriptMessageHandler,WKNavigationDelegate,WKUIDelegate {
  
    @IBOutlet weak var nativeCallBtn: UIButton!
    let userScriptName = "beequick"
    var webview:WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = .None
        
        let preference = WKPreferences()
        preference.minimumFontSize = 10.0
        
        let userContentController = WKUserContentController()
        userContentController.addScriptMessageHandler(self, name: userScriptName)
        let configuretion = WKWebViewConfiguration()
        configuretion.preferences = preference
        configuretion.userContentController = userContentController
        
        webview = WKWebView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 150.0), configuration: configuretion)
        webview.navigationDelegate = self
        webview.UIDelegate = self
        let url = NSBundle.mainBundle().URLForResource("index", withExtension: "html")
        webview.loadRequest(NSURLRequest(URL: url!))
        self.view.addSubview(webview)
        webview.estimatedProgress
        webview.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
        webview.addObserver(self, forKeyPath: "title", options: .New, context: nil)
        webview.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        //这里javascript对象会自动转化成Swift或者Objective-C对象(NSNumber, NSString, NSDate, NSArray,NSDictionary, and NSNull
        print("didReceiveScriptMessage body is \(message.body),name is \(message.name)")
        if message.body is Dictionary<String, AnyObject> {
            let dic = message.body as! Dictionary<String,AnyObject>
            print("keys=\(dic.keys),values=\(dic.values)")
            
        } else if message.body is Array<AnyObject> {
            let array = message.body as! Array<AnyObject>
            for i in 0..<array.count {
                print("\(array[i])")
            }
        }
    
    }
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "loading" {
            print("------loading-------")
        } else if keyPath == "title" {
            self.title = webview.title
        } else if keyPath == "estimatedProgress" {
            print("progress is \(webview.estimatedProgress)")
        }
    }
    // MARK: - WKNavigationDelegate
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        decisionHandler(.Allow)
    }
    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.Allow)
    }
    //WKWebView里html5 alert、confirm prompt不能直接弹出来，分别会调用runJavaScriptAlertPanelWithMessage、runJavaScriptConfirmPanelWithMessage、runJavaScriptTextInputPanelWithPrompt方法，通过completionHandler将用户操作结果返回给js
    // MARK: - WKUIDelegate
    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        print("message is \(message)")
        let alert = UIAlertController(title: "alert", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (alertAction: UIAlertAction) -> Void in
             print("alertAction is \(alertAction.title)")
             completionHandler()
        }))
       self.presentViewController(alert, animated: true, completion: nil)
        
    }
    func webView(webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (Bool) -> Void) {
        print("message is \(message)")
        
        let confirm = UIAlertController(title: "confirm", message: message, preferredStyle: .Alert)
        confirm.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: { (_) -> Void in
            completionHandler(false)
        }))
        confirm.addAction(UIAlertAction(title: "确定", style: .Default, handler: { (_) -> Void in
            completionHandler(true)
        }))
        self.presentViewController(confirm, animated: true, completion: nil)
    }
    func webView(webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String?) -> Void) {
        print("prompt is \(prompt),defaultText is \(defaultText)")
        
        let prompt = UIAlertController(title: "prompt", message: prompt, preferredStyle: .Alert)
        prompt.addTextFieldWithConfigurationHandler { (textField: UITextField) -> Void in
            textField.placeholder = defaultText
            textField.textColor = UIColor.redColor()
        }
        prompt.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (_) -> Void in
             completionHandler(prompt.textFields![0].text)
        }))
        self.presentViewController(prompt, animated: true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

  
    @IBAction func nativeCalljs(sender: AnyObject) {
        let param = ["id":20,"name":"Jobs","ext":[1,2,3,4,5]]
        let js = "nativeCallJS('\(param.JSONString)')"
        webview.evaluateJavaScript(js) { (obj: AnyObject?, error: NSError?) -> Void in
            if error != nil {
                print("error is \(error!.localizedDescription)")
            }else{
                 print("obj is \(obj)")
            }
        }
    }
}

extension Dictionary where Key: StringLiteralConvertible, Value: AnyObject {
    var JSONString: String {
        if let dict = (self as? AnyObject) as? Dictionary<String, AnyObject> {
            do {
                let data = try NSJSONSerialization.dataWithJSONObject(dict, options: NSJSONWritingOptions.PrettyPrinted)
                let string = String(data: data, encoding: NSUTF8StringEncoding)!
                return string.escapeString()
                
            }catch {
                return ""
            }
        }
        return ""
    }
}

extension String {
    func escapeString() -> String {
      return self.stringByReplacingOccurrencesOfString("\\", withString: "\\\\").stringByReplacingOccurrencesOfString("'", withString: "\\x27").stringByReplacingOccurrencesOfString("/", withString: "\\/").stringByReplacingOccurrencesOfString("\n", withString: "\\n").stringByReplacingOccurrencesOfString("\r", withString: "\\r").stringByReplacingOccurrencesOfString("\"", withString: "\\x22")
    }
}
