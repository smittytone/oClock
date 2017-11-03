
//  Created by Tony Smith on 06/12/2016.
//  Copyright © 2016-17 Tony Smith. All rights reserved.


import UIKit

class DisplayViewController:
    UIViewController,
    URLSessionDelegate,
    URLSessionDataDelegate {

    @IBOutlet weak var brightnessSlider:UISlider!
    @IBOutlet weak var ledColourView:UIImageView!
    @IBOutlet weak var flashColonSwitch:UISwitch!
    @IBOutlet weak var flashColonLabel:UILabel!
    @IBOutlet weak var setColonLabel:UILabel!
    @IBOutlet weak var setColonSwitch:UISwitch!
    @IBOutlet weak var onSwitch:UISwitch!
    @IBOutlet weak var onLabel:UILabel!
    @IBOutlet weak var debugSwitch:UISwitch!
    @IBOutlet weak var debugLabel:UILabel!

    @IBOutlet weak var connectionProgress:UIActivityIndicatorView!
    @IBOutlet weak var clockNameLabel:UILabel!
    @IBOutlet weak var statusLabel:UILabel!



    var connexions:[Connexion] = []
    var myClocks:ImpList!

    var currentImpIndex:Int = -1
    var clockResetFlag:Bool = false
    var sliderStartFlag:Bool = true
    var initialQueryFlag:Bool = false

    var timeSession:URLSession?

    
    // MARK: - Initialization Methods

    override func viewDidLoad() {

        super.viewDidLoad()

        // Get list of imps
        myClocks = ImpList.sharedImps

        // Initialise object properties
        currentImpIndex = -1
        connexions = []

        // Initialise UI
        ledColourView.alpha = 1.0
        onLabel.text = "Turn display off";
        connectionProgress.isHidden = true;

        // Set up notifications
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector:#selector(self.setResetFlag),
                       name:NSNotification.Name("com.bps.clock.reset.clock"),
                       object:nil)
        nc.addObserver(self,
                       selector:#selector(self.appWillQuit),
                       name:NSNotification.Name("com.bps.clock.will.quit"),
                       object:nil)
    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)

        if myClocks != nil {
            if myClocks.currentImp != -1 {
                let clock:Imp = myClocks.imps[myClocks.currentImp]
                clockNameLabel.text = clock.name
                statusLabel.text = "Currently selected Cløck:"

                // Set the LED image colour
                var colour: String = ""
                switch (clock.colour) {
                    case 1:
                        colour = "led_green.png"
                    case 2:
                        colour = "led_yellow.png"
                    case 3:
                        colour = "led_blue.png"
                    default:
                        colour = "led_red.png"
                }

                ledColourView.image = UIImage.init(named:colour)

                // Check if the current clock is still being shown; if not, reload data
                // If it is, there's no need to reload data and put extra strain on phone battery
                if currentImpIndex != myClocks.currentImp || clockResetFlag == true {
                    currentImpIndex = myClocks.currentImp
                    initialQueryFlag = true
                    clockResetFlag = false
                    getMode()
                }

                return
            }
            else
            {
                resetControls()
            }
        }
    }

    func resetControls() {

        clockNameLabel.text = "No Cløck selected"
        statusLabel.text = ""
        brightnessSlider.value = 15.0
        setColonSwitch.isOn = false
        flashColonSwitch.isOn = false
        onSwitch.isOn = false
    }


    // MARK: - Notification Methods

    @objc func setResetFlag() {

        clockResetFlag = true
    }


    @objc func appWillQuit(note:NSNotification) {

        NotificationCenter.default.removeObserver(self)
    }


    // MARK: - Digital Clock Methods

    @IBAction func setColon(sender:AnyObject) {

        // If no imp has been selected, bail
        if myClocks == nil || myClocks.currentImp == -1 { return }

        // Get the current imp's details and send the command to the clock
        let clock:Imp = myClocks.imps[myClocks.currentImp]
        let url:String = imp_url_string + clock.code + "/settings"
        var dict = [String: String]()

        if (setColonSwitch.isOn) {
            dict["setcolon"] = "1"
            flashColonSwitch.isEnabled = true
            flashColonLabel.isEnabled = true
        }  else {
            dict["setcolon"] = "1"
            flashColonSwitch.isEnabled = false
            flashColonLabel.isEnabled = false
        }

        makeConnection(url, dict)
    }

    @IBAction func flashColon(sender:AnyObject) {

        // If no imp has been selected, bail
        if myClocks == nil || myClocks.currentImp == -1 { return }

        // Get the current imp's details and send the command to the clock
        let clock:Imp = myClocks.imps[myClocks.currentImp]
        let url:String = imp_url_string + clock.code + "/settings"
        var dict = [String: String]()
        dict["setflash"] = flashColonSwitch.isOn ? "1" : "0"
        makeConnection(url, dict)
    }

    @IBAction func setDisplay(sender:AnyObject) {

        // If no imp has been selected, bail
        if myClocks == nil || myClocks.currentImp == -1 { return }

        let clock:Imp = myClocks.imps[myClocks.currentImp]
        let url:String = imp_url_string + clock.code + "/settings"
        var dict = [String: String]()

        if onSwitch.isOn {
            dict["setlight"] = "1"
            onLabel.text = "Turn Cløck display off"
        } else {
            dict["setlight"] = "0"
            onLabel.text = "Turn Cløck display on"
        }

        makeConnection(url, dict)
    }

    @IBAction func doBrightnessSlider(sender:AnyObject) {

        // If no imp has been selected, bail
        if myClocks == nil || myClocks.currentImp == -1 { return }

        // UI slider early call bug trap
        if (!sliderStartFlag) { return }

        let newBrightness = Int(round(brightnessSlider.value))
        brightnessSlider.setValue(Float(newBrightness), animated:false)

        var alpha = CGFloat(newBrightness + 1) / 16.0
        if alpha < 0.25 { alpha = 0.25 }
        ledColourView.alpha = alpha

        let clock:Imp = myClocks.imps[myClocks.currentImp]
        let url:String = imp_url_string + clock.code + "/settings"
        var dict = [String: String]()
        dict["setbright"] = "\(newBrightness)"
        makeConnection(url, dict)
    }

    @IBAction func setDebug(_ sender:Any) {

        // If no imp has been selected, bail
        if myClocks == nil || myClocks.currentImp == -1 { return }

        let clock:Imp = myClocks.imps[myClocks.currentImp]
        let url:String = imp_url_string + clock.code + "/action"
        var dict = [String: String]()
        dict["action"] = "debug"

        if debugSwitch.isOn {
            dict["debug"] = "1"
            debugLabel.text = "Debug mode off"
        } else {
            dict["debug"] = "0"
            debugLabel.text = "Debug mode on"
        }

        makeConnection(url, dict)
    }

    func getMode() {

        // If no imp has been selected, bail
        if myClocks == nil || myClocks.currentImp == -1 { return }

        let clock:Imp = myClocks.imps[myClocks.currentImp]
        makeConnection(imp_url_string + clock.code + "/settings", nil)
    }


    // MARK: - Connection Methods

    func makeConnection(_ urlPath:String = "", _ data:[String:String]?) {

        if urlPath.isEmpty {
            reportError("DisplayViewController.makeConnection() passed empty URL string")
            return
        }

        let url:URL? = URL(string: urlPath)

        if url == nil {
            reportError("DisplayViewController.makeConnection() passed malformed URL string")
            return
        }
        
        if timeSession == nil {
            timeSession = URLSession(configuration:URLSessionConfiguration.default,
                                     delegate:self,
                                     delegateQueue:OperationQueue.main)
        }

        var request = URLRequest.init(url: url!,
                                      cachePolicy:URLRequest.CachePolicy.reloadIgnoringLocalCacheData,
                                      timeoutInterval: 60.0)

        if (data != nil) {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: data!, options: [])
                request.httpMethod = "POST"
            } catch {
                reportError("DisplayViewController.makeConnection() passed malformed data")
                return
            }
        }

        let aConnexion = Connexion()
        aConnexion.errorCode = -1;
        aConnexion.data = NSMutableData(capacity:0)
        aConnexion.task = timeSession!.dataTask(with:request)

        if let task = aConnexion.task {
            task.resume()
            connexions.append(aConnexion)
            connectionProgress.isHidden = false
            connectionProgress.startAnimating()
            statusLabel.text = "Loading Cløck settings"
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {

        // This delegate method is called when the server sends some data back
        // Add the data to the correct connexion object

        for aConnexion in connexions {
            // Run through the connections in our list and 
            // add the incoming data to the correct one
            if aConnexion.task == dataTask {
                if let connData = aConnexion.data { connData.append(data) }
            }
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {

        // This delegate method is called when the server responds to the connection request
        // Use it to trap certain status codes
        let rps = response as! HTTPURLResponse
        let code = rps.statusCode;

        if code > 399 {
            // The API has responded with a status code that indicates an error
            for aConnexion in connexions {
                // Run through the connections in our list and add the incoming error code to the correct one
                if aConnexion.task == dataTask { aConnexion.errorCode = code }

                if code == 404 {
                    // Agent is moving for production shift, so delay check
                    completionHandler(URLSession.ResponseDisposition.cancel)
                } else {
                    completionHandler(URLSession.ResponseDisposition.allow)
                }
            }
        } else {
            completionHandler(URLSession.ResponseDisposition.allow);
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // All the data has been supplied by the server in response to a connection - or an error has been encountered
        // Parse the data and, according to the connection activity - update device, create model etc –
        // apply the results
        var disconnected: Bool = false
        connectionProgress.isHidden = true;
        connectionProgress.stopAnimating()

        if error != nil {
            // React to a passed client-side error - most likely a timeout or inability to resolve the URL
            // Notify the host app
            reportError("Could not connect to the Electric Imp impCloud")
            statusLabel.text = "Could not connect to the Cløck"

            // Terminate the failed connection and remove it from the list of current connections
            var index: Int = -1

            for i in 0..<connexions.count {
                // Run through the connections in the list and find the one that has just finished loading
                let aConnexion = connexions[i]
                if aConnexion.task == task {
                    task.cancel()
                    index = i
                }
            }

            if index != -1 { connexions.remove(at:index) }
        } else {
            for i in 0..<connexions.count {
                let aConnexion = connexions[i]

                if aConnexion.task == task {
                    if let data = aConnexion.data {
                        let inString = String(data:data as Data, encoding:String.Encoding.ascii)!

                        if inString == "OK" {
                            //alert = [[UIAlertView alloc] initWithTitle:@"Wrong øClock" message:@"You have selected a device that is not an øClock. We suggest you delete it." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            return
                        }

                        if inString == "Not Found\n" {
                            //alert = [[UIAlertView alloc] initWithTitle:@"Wrong øClock" message:@"You have selected a device that is not an øClock. We suggest you delete it." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            return
                        }

                        if inString == "No handler" {
                            //alert = [[UIAlertView alloc] initWithTitle:@"Wrong øClock" message:@"You have selected a device that is not an øClock. We suggest you delete it." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            return
                        }

                        let dataArray = inString.components(separatedBy:".")
                        let dis = dataArray[8] as String
                        disconnected = dis == "d" ? true : false

                        if initialQueryFlag == true {
                            initialQueryFlag = false

                            // Incoming string looks like this:
                            //    1.1.1.1.01.1.01.1.d.1
                            // with the values
                            //    0. mode (1: 24hr, 0: 12hr)
                            //    1. bst state
                            //    2. colon flash
                            //    3. colon state
                            //    4. brightness
                            //    5. world time state
                            //    6. world time offset (0-24 -> -12 to 12)
                            //    7. display state
                            //    8. connection status
                            //    9. debug status

                            let flashString = dataArray[2] as String
                            let colonString = dataArray[3] as String
                            let brightString = dataArray[4] as String
                            let onString = dataArray[7] as String
                            let debugString = dataArray[9] as String

                            // Set the colon value

                            if let value = Int(colonString) {
                                if value == 1 {
                                    setColonSwitch.setOn(true, animated:false)
                                    flashColonLabel.isEnabled = true
                                    flashColonSwitch.isEnabled = true
                                } else {
                                    setColonSwitch.setOn(false, animated:false)
                                    flashColonLabel.isEnabled = false
                                    flashColonSwitch.isEnabled = false
                                }
                            }

                            // Set the colon flash value
                            if let value = Int(flashString) {
                                flashColonSwitch.setOn((value == 1 ? true : false), animated:false)
                            }

                            // Set brightness
                            if let value = Float(brightString) {
                                brightnessSlider.value = value
                                sliderStartFlag = true
                                var alpha = CGFloat(brightnessSlider.value + 1) / 16.0
                                if (alpha < 0.25) { alpha = 0.25 }
                                ledColourView.alpha = alpha
                            }

                            // Set on or off
                            if let value = Int(onString) {
                                onSwitch.setOn((value == 1 ? true : false), animated:false)
                            }

                            // Set debug mode
                            if let value = Int(debugString) {
                                debugSwitch.setOn((value == 1 ? true : false), animated:false)
                                debugLabel.text = "Debug mode " + (value == 1 ? "off" : "on")
                            }
                        }
                    }
                    
                    // End connection
                    statusLabel.text = !disconnected ? "Currently selected Cløck:" : "Cløck is disconnected"
                    task.cancel()
                    connexions.remove(at:i)
                    break
                }
            }
        }
    }

    
    func reportError(_ message:String) {
        NSLog(message)
    }
    
}
