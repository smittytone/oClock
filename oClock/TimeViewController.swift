
//  Created by Tony Smith on 06/12/2016.
//  Copyright © 2016-17 Tony Smith. All rights reserved.


import UIKit

class TimeViewController:
    UIViewController,
    UIPickerViewDataSource,
    UIPickerViewDelegate,
    URLSessionDelegate,
    URLSessionDataDelegate {

    @IBOutlet weak var clockModeLabel:UILabel!
    @IBOutlet weak var clockModeSwitch:UISwitch!
    @IBOutlet weak var summerTimeSwitch:UISwitch!
    @IBOutlet weak var worldTimeSwitch:UISwitch!
    @IBOutlet weak var worldTimePicker:UIPickerView!
    @IBOutlet weak var clockNameLabel:UILabel!
    @IBOutlet weak var statusLabel:UILabel!
    @IBOutlet weak var connectionProgress:UIActivityIndicatorView!

    var utcOffsets:[String] = []
    var connexions:[Connexion] = []
    var myClocks:ImpList!

    var initialQueryFlag:Bool = false
    var clockResetFlag:Bool = false
    var utcOffset:Int = 0
    var currentImp:Int = -1

    var timeSession:URLSession?


    // MARK: - Initialization Methods

    override func viewDidLoad() {

        super.viewDidLoad()

        myClocks = ImpList.sharedImps

        // Initialize key arrays
        connexions = []
        utcOffsets = [ "+12", "+11", "+10", "+9", "+8", "+7",
                       "+6", "+5", "+4", "+3", "+2", "+1", "Local Time", "-1", "-2",
                       "-3", "-4", "-5", "-6", "-7", "-8", "-9", "-10", "-11", "-12" ]

        // Set up notification watchers
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector:#selector(self.setResetFlag),
                       name: NSNotification.Name(rawValue: "com.bps.clock.reset.clock"),
                       object: nil)
        nc.addObserver(self,
                       selector:#selector(self.appWillQuit),
                       name: NSNotification.Name(rawValue: "com.bps.clock.will.quit"),
                       object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
        connectionProgress.isHidden = true

        if myClocks != nil {
            if myClocks!.currentImp != -1 {
                let clock:Imp = myClocks!.imps[myClocks!.currentImp]
                statusLabel.text = "Currently selected Cløck:"
                clockNameLabel.text = clock.name

                // Check if the current clock is still being shown; if not, reload data
                // If it is, there's no need to reload data and put extra strain on phone battery
                if currentImp != myClocks.currentImp || clockResetFlag == true {
                    currentImp = myClocks!.currentImp
                    initialQueryFlag = true
                    clockResetFlag = false
                    getMode()
                }

                return
            } else {
                resetControls()
            }
        }
    }

    // MARK: - Notification-triggered Methods

    @objc func setResetFlag() {

        clockResetFlag = true
    }

    @objc func appWillQuit(note:NSNotification) {

        NotificationCenter.default.removeObserver(self)
        if timeSession != nil { timeSession!.invalidateAndCancel() }
    }


    // MARK: - Digital Clock Methods

    @IBAction func modeSwitcher(sender:AnyObject) {

        // If no imp has been selected, bail
        if myClocks == nil { return }

        if myClocks!.currentImp == -1 {
            clockNameLabel.text = "No cløck selected"
            return
        }

        // Get the current imp's details and send the command to the clock
        let clock:Imp = myClocks.imps[myClocks.currentImp]
        let url:String = imp_url_string + clock.code + "/settings"
        var dict = [String: String]()
        dict["setmode"] = clockModeSwitch.isOn ? "1" : "0"
        clockModeLabel.text = clockModeSwitch.isOn ? "24HR" : "AM/PM"
        makeConnection(url, dict)
    }

    @IBAction func worldTimeSwitcher(sender:AnyObject) {

        // If no imp has been selected, bail
        if myClocks == nil { return }

        if myClocks!.currentImp == -1 {
            clockNameLabel.text = "No cløck selected"
            return
        }

        // Get the current imp's details and send the command to the clock
        let clock:Imp = myClocks.imps[myClocks.currentImp]
        let url:String = imp_url_string + clock.code + "/settings"
        var dict = [String: String]()
        dict["setutc"] = worldTimeSwitch.isOn ? "1" : "0"

        utcOffset = worldTimePicker.selectedRow(inComponent:0)

        // Offset value is expected to be 0 to 24, with offset calculated by subtracting
        // 12 from this value to yield -12 to +12. Here row value is 0 to 23, +12 to -12
        let offset = 24 - utcOffset
        let utc:String = offset < 10 ? "0\(offset)" : "\(offset)"
        dict["utcval"] = utc

        makeConnection(url, dict)
    }

    @IBAction func summerTimeSwitcher(sender:AnyObject) {

        // If no imp has been selected, bail
        if myClocks == nil { return }

        if myClocks!.currentImp == -1 {
            clockNameLabel.text = "No cløck selected"
            return
        }

        // Get the current imp's details and send the command to the clock
        let clock:Imp = myClocks.imps[myClocks.currentImp]
        let url:String = imp_url_string + clock.code + "/settings"
        var dict = [String: String]()
        dict["setbst"] = summerTimeSwitch.isOn ? "1" : "0"
        makeConnection(url, dict)
    }

    func getMode() {

        // If no imp has been selected, bail
        if myClocks == nil { return }

        if myClocks.currentImp == -1 {
            clockNameLabel.text = "No cløck selected"
            return
        }

        let clock:Imp = myClocks.imps[myClocks.currentImp]
        makeConnection(imp_url_string + clock.code + "/settings", nil)
    }

    func resetControls() {

        clockNameLabel.text = "No Cløck selected"
        statusLabel.text = ""
        clockModeLabel.text = "24HRR"
        clockModeSwitch.isOn = true
        summerTimeSwitch.isOn = true
        worldTimeSwitch.isOn = false
        worldTimePicker.selectRow(12, inComponent:0, animated:false)
    }


    // MARK: - Picker Methods

    func numberOfComponents(in pickerView: UIPickerView) -> Int {

        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {

        return utcOffsets.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        return utcOffsets[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {

        if worldTimeSwitch.isOn {
            // If no imp has been selected, bail
            if myClocks == nil { return }

            if myClocks!.currentImp == -1 {
                clockNameLabel.text = "No cløck selected"
                return
            }

            // Get the current imp's details and send the command to the clock
            let clock:Imp = myClocks.imps[myClocks.currentImp]
            let url:String = imp_url_string + clock.code + "/settings"
            var dict = [String: String]()

            // Offset value is expected to be 0 to 24, with offset calculated by subtracting
            // 12 from this value to yield -12 to +12. Here row value is 0 to 23, +12 to -12
            let offset = 24 - row
            let utc:String = offset < 10 ? "0\(offset)" : "\(offset)"
            dict["utcval"] = utc
            makeConnection(url, dict)
        }
    }


    // MARK: - Connection Methods

    func makeConnection(_ urlpath:String = "", _ data:[String:String]?) {

        if urlpath.isEmpty {
            reportError("TimeViewController.makeConnection() passed empty URL string")
            return
        }

        let url:URL? = URL(string: urlpath)

        if url == nil {
            reportError("TimeViewController.makeConnection() passed malformed URL string")
            return
        }

        if timeSession == nil {
            timeSession = URLSession(configuration:URLSessionConfiguration.default,
                                               delegate:self,
                                               delegateQueue:OperationQueue.main)
        }

        var request = URLRequest(url: url!,
                                 cachePolicy:URLRequest.CachePolicy.reloadIgnoringLocalCacheData,
                                 timeoutInterval: 60.0)

        if (data != nil) {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: data!, options: [])
                request.httpMethod = "POST"
            } catch {
                reportError("TimeViewController.makeConnection() passed malformed data")
                return
            }
        }

        let aConnexion = Connexion()
        aConnexion.errorCode = -1;
        aConnexion.data = NSMutableData.init(capacity:0)
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
            // Run through the connections in our list and add the incoming data to the correct one
            if aConnexion.task == dataTask {
                if let connData = aConnexion.data {
                    connData.append(data)
                }
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
                // Run through the connections in our list and
                // add the incoming error code to the correct one
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

        // All the data has been supplied by the server in response to a connection -
        // or an error has been encountered
        // Parse the data and, according to the connection activity
        var disconnected: Bool = false
        connectionProgress.isHidden = true;
        connectionProgress.stopAnimating()

        if error != nil {
            // React to a passed client-side error - most likely a timeout or inability to resolve the URL
            // Notify the host app
            reportError("Could not connect to the Electric Imp impCloud")
            statusLabel.text = "Could not connect to the Cløck"

            // Terminate the failed connection and remove it from the list of current connections
            var index = -1

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

                            let modeString = dataArray[0] as String
                            let summerString = dataArray[1] as String
                            let worldString = dataArray[5] as String
                            let offsetString = dataArray[6] as String

                            // Set the clock mode
                            if let value = Int(modeString) {
                                if value == 1 {
                                    clockModeSwitch.setOn(true, animated:false)
                                    clockModeLabel.text = "24HR"
                                } else {
                                    clockModeSwitch.setOn(false, animated:false)
                                    clockModeLabel.text = "AM/PM"
                                }
                            }

                            // Set the BST mode
                            if let value = Int(summerString) {
                                summerTimeSwitch.setOn((value == 1 ? true : false), animated:false)
                            }

                            // Set world time offset
                            if let value = Int(worldString) {
                                worldTimeSwitch.setOn((value == 1 ? true : false), animated:false)
                            }
                            
                            if let utcOffset = Int(offsetString) {
                                worldTimePicker.selectRow(utcOffset, inComponent:0, animated:false)
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


    func reportError(_ message:String)
    {
        NSLog(message)
    }

}
