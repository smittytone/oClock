
//  Created by Tony Smith on 08/12/2016.
//  Copyright © 2016-17 Tony Smith. All rights reserved.


import UIKit

class AlarmsTableViewController:
    UITableViewController,
    URLSessionDelegate,
    URLSessionDataDelegate {

    @IBOutlet var alarmTable:UITableView!

    var myClocks:ImpList!
    var editingClock:Imp!
    var newAlarmButton:UIBarButtonItem!
    var alvc:AlarmViewController!
    var alarms:Alarms = Alarms()
    var connexions:[Connexion] = []
    var lastSelectedClockIndex:Int = -1
    var timeSession:URLSession?

    override func viewDidLoad() {

        super.viewDidLoad()

        // Set up the table's selection persistence
        self.clearsSelectionOnViewWillAppear = false

        // Set up the Navigation Bar with an Edit button
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        self.navigationItem.leftBarButtonItem!.tintColor = UIColor.white
        self.navigationItem.leftBarButtonItem!.action = #selector(self.editTouched)

        // Set up the Navigation Bar with a New Alarm button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem:UIBarButtonSystemItem.add,
                                                                 target: self,
                                                                 action: #selector(self.newTouched))
        self.navigationItem.rightBarButtonItem!.tintColor = UIColor.white

        alvc = nil
        editingClock = nil
    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)

        // Get list of imps
        myClocks = ImpList.sharedImps

        if myClocks == nil {
            if myClocks.currentImp != -1 {
                // We have a selected clock, so we should make sure we have the correct alarms list
                self.navigationItem.title = myClocks.imps[myClocks.currentImp].name + " Alarms"

                if myClocks.currentImp != lastSelectedClockIndex {
                    // Clock selection has changed, so reload alarm list
                    lastSelectedClockIndex = myClocks.currentImp
                    getAlarms()
                    return
                }

                alarmTable.reloadData()
            } else {
                self.navigationItem.title = "Alarms"
            }
        }
    }

    @objc func editTouched() {

    }

    @objc func newTouched() {

        // Instantiate the alarm detail view controller as required
        if alvc == nil {
            let storyboard = UIStoryboard.init(name:"Main", bundle:nil)
            alvc = storyboard.instantiateViewController(withIdentifier:"imp_alarm_view") as! AlarmViewController
            alvc.navigationItem.title = "New Alarm"
            alvc.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
            alvc.alarms = alarms
        }

        // Present the alarm view controller
        self.navigationController?.pushViewController(alvc, animated: true)
    }


    // MARK: - Communications methods

    func getAlarms() {

        let clock:Imp = myClocks.imps[lastSelectedClockIndex]
        makeConnection(imp_url_string + clock.code + "/alarms", nil)
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return alarms.alarmarray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "clock_alarm_cell", for: indexPath)

        // Configure the cell...

        return cell
    }

    // MARK: - Connection Methods

    func makeConnection(_ urlPath:String = "", _ data:[String:String]?) {

        if urlPath.isEmpty {
            reportError("AlarmsTableViewController.makeConnection() passed empty URL string")
            return
        }

        let url:URL? = URL(string: urlPath)

        if url == nil {
            reportError("AlarmsTableViewController.makeConnection() passed malformed URL string + \(urlPath)")
            return
        }

        if timeSession == nil {
            timeSession = URLSession(configuration:URLSessionConfiguration.default,
                                     delegate:self,
                                     delegateQueue:OperationQueue.main)
        }

        let request = URLRequest.init(url: url!,
                                      cachePolicy:URLRequest.CachePolicy.reloadIgnoringLocalCacheData,
                                      timeoutInterval: 60.0)

        let aConnexion = Connexion()
        aConnexion.errorCode = -1;
        aConnexion.data = NSMutableData(capacity:0)
        aConnexion.task = timeSession!.dataTask(with:request)

        if let task = aConnexion.task {
            task.resume()
            connexions.append(aConnexion)
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
        if error != nil {
            // React to a passed client-side error - most likely a timeout or inability to resolve the URL
            // Notify the host app
            reportError("Could not connect to the Electric Imp impCloud")

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

                        let als = inString.components(separatedBy:",")

                        alarms.alarmarray.removeAll()

                        for al:String in als {
                            let parts = al.components(separatedBy:".")
                            var alarm = Alarm()
                            alarm.hour = Int(parts[0])!
                            alarm.min = Int(parts[1])!
                            alarm.again = parts[2] == "1" ? true : false
                            alarms.alarmarray.append(alarm)
                        }

                        alarmTable.reloadData()
                        alarmTable.setNeedsDisplay()
                    }

                    // End connection
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
