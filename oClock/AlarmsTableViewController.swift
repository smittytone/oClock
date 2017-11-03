
//  Created by Tony Smith on 08/12/2016.
//  Copyright © 2016-17 Tony Smith. All rights reserved.


import UIKit

class AlarmsTableViewController: UITableViewController {

    @IBOutlet var alarmTable:UITableView!

    var myClocks:ImpList!
    var editingClock:Imp!
    var newAlarmButton:UIBarButtonItem!
    var alvc:AlarmViewController!
    var alarms:Alarms = Alarms()
    var lastSelectedClockIndex:Int = -1


    override func viewDidLoad() {

        super.viewDidLoad()

        // Get the list of imps
        myClocks = ImpList.sharedImps

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
            }
            else
            {
                self.navigationItem.title = "Alarms"
            }
        }
    }

    @objc func editTouched() {

    }

    @objc func newTouched() {

        // Instantiate the imp detail view controller as required - ie. every time
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
