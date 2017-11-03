
//  Created by Tony Smith on 07/12/2016.
//  Copyright © 2016-17 Tony Smith. All rights reserved.


import UIKit

class ClockDetailViewController:
    UIViewController,
    UITextFieldDelegate,
    URLSessionDelegate,
    URLSessionDataDelegate {


    @IBOutlet weak var colourView:ImpColourView!
    @IBOutlet weak var nameField:UITextField!
    @IBOutlet weak var codeField:UITextField!
    @IBOutlet weak var colourStepper:UIStepper!
    @IBOutlet weak var errorLabel:UILabel!
    @IBOutlet weak var connectionProgress:UIActivityIndicatorView!
    
    var currentClock:Imp!
    var showClockIDflag:Bool = false
    var receivedData:NSMutableData! = nil

    var timeSession:URLSession?

    // MARK: - Initialization Methods

    override func viewDidLoad() {

        super.viewDidLoad()

        errorLabel.text = ""
        connectionProgress.isHidden = true

        if currentClock != nil {
            nameField.text = currentClock.name
            codeField.text = currentClock.code

            // Set the stepper value and the colour graphic
            colourView.colourIndex = currentClock.colour
            colourView.changeColour()
            colourStepper.value = Double(Float(currentClock.colour))
        }

        // Watch for app returning to foreground with ImpDetailViewController active
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector:#selector(self.updateInterfaceElements),
                       name:NSNotification.Name.UIApplicationWillEnterForeground,
                       object:nil)
        nc.addObserver(self,
                       selector:#selector(self.appWillQuit),
                       name:NSNotification.Name("com.bps.clock.will.quit"),
                       object:nil)
    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)

        // Check for show/hide Clock IDs preference
        let settings = UserDefaults.standard
        settings.synchronize()
        showClockIDflag = settings.bool(forKey:"ts.oclock.show.agent.url")
        codeField.isSecureTextEntry = !showClockIDflag ? true : false
        if currentClock != nil { codeField.text = currentClock.code }
    }

    @objc func appWillQuit(note:NSNotification) {

        NotificationCenter.default.removeObserver(self)
    }

    
    // MARK: - Control Methods

    @objc func changeDetails() {

        if currentClock != nil {
            // The view is about to close so save the text fields' content
            currentClock.code = codeField.text!
            currentClock.name = nameField.text!
            currentClock.colour = Int(colourStepper.value)
        }

        // Stop listening for 'will enter foreground' notifications
        NotificationCenter.default.removeObserver(self)

        // Jump back to the list of imps
        self.navigationController!.popViewController(animated: true)
    }

    @objc func updateInterfaceElements() {

        codeField.resignFirstResponder()
        nameField.resignFirstResponder()
    }

    @IBAction func stepColours(sender:AnyObject) {

        colourView.colourIndex = Int(colourStepper.value)
        colourView.changeColour()
    }

    @IBAction func resetClock(sender:AnyObject) {

        let url:URL? = URL(string: imp_url_string + currentClock.code + "/action")

        if url == nil {
            reportError("ClockDetailViewController.resetClock() generated a malformed URL string")
            errorLabel.text = "Error contacting the Cløck server"
            return
        }

        connectionProgress.isHidden = false
        connectionProgress.startAnimating()
        var dict = [String: String]()
        dict["action"] = "reset"

        var request:URLRequest = URLRequest(url:url!,
                                            cachePolicy:URLRequest.CachePolicy.reloadIgnoringLocalCacheData,
                                            timeoutInterval:60.0)

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: dict, options: [])
            request.httpMethod = "POST"
        } catch {
            reportError("ClockDetailViewController.resetClock() passed malformed data")
            return
        }

        if timeSession == nil {
            timeSession = URLSession(configuration:URLSessionConfiguration.default,
                                     delegate:self,
                                     delegateQueue:OperationQueue.main)
        }

        let task:URLSessionDataTask = timeSession!.dataTask(with:request)
        task.resume()
    }


    // MARK: - Text Field Delegate Methods

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        for item in self.view.subviews {
            let view = item as UIView
            if view.isKind(of: UITextField.self) { view.resignFirstResponder() }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        textField.resignFirstResponder()
        return true
    }


    // MARK: - URLSession Methods

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        if receivedData == nil { receivedData = NSMutableData() }
        receivedData.append(data)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

        let rps = response as! HTTPURLResponse
        let code = rps.statusCode;

        if code > 399 {
            if code == 404 {
                completionHandler(URLSession.ResponseDisposition.cancel)
            } else {
                completionHandler(URLSession.ResponseDisposition.allow)
            }
        } else {
            completionHandler(URLSession.ResponseDisposition.allow);
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        if error != nil {
            reportError("Could not connect to the Electric Imp impCloud")
            errorLabel.text = "Could not connect to the Cløck"
        } else {
            if receivedData.length > 0 {
                let dataString:String? = String(data:receivedData as Data, encoding:String.Encoding.ascii)

                if dataString != nil {
                    if dataString! == "Settings reset" {
                        errorLabel.text = dataString!
                        NotificationCenter.default.post(name:NSNotification.Name("com.bps.clock.reset.clock"), object:nil)
                    }
                }
            }
        }

        task.cancel()
        connectionProgress.isHidden = true
        connectionProgress.stopAnimating()
        receivedData = nil
    }

    func reportError(_ message:String) {
        NSLog(message)
    }

}
