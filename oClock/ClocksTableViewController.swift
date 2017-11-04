
//  Created by Tony Smith on 07/12/2016.
//  Copyright © 2016-17 Tony Smith. All rights reserved.


import UIKit

class ClocksTableViewController: UITableViewController {

    @IBOutlet weak var clockTable:UITableView!

    var myClocks:ImpList!
    var editingClock:Imp!
    var cdvc:ClockDetailViewController!
    var orderButton:UIBarButtonItem!

    var clockRow:Int = -1
    var currentClock:Int = -1
    var tableEditingFlag:Bool = false
    var showClockIDflag:Bool = false
    var tableOrderingFlag:Bool = false


    override func viewDidLoad() {

        super.viewDidLoad()

        // Set up the table's selection persistence
        self.clearsSelectionOnViewWillAppear = false

        // Set up the Navigation Bar with an Edit button
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.rightBarButtonItem!.tintColor = UIColor.white
        self.navigationItem.rightBarButtonItem!.action = #selector(self.editTouched)

        // Set up the Navigation Bar with a Reorder button
        orderButton = UIBarButtonItem.init(title:"Reorder",
                                           style:UIBarButtonItemStyle.plain,
                                           target:self,
                                           action:#selector(self.orderTouched))
        self.navigationItem.leftBarButtonItem = orderButton
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white

        // Initialise object properties
        tableOrderingFlag = false
        tableEditingFlag = false
        editingClock = nil
        cdvc = nil

        // Watch for app returning to foreground with ImpDetailViewController active
        NotificationCenter.default.addObserver(self,
                                               selector:#selector(self.viewWillAppear),
                                               name:NSNotification.Name.UIApplicationWillEnterForeground,
                                               object:nil)
    }

    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)

        // Get list of imps
        myClocks = ImpList.sharedImps

        if editingClock != nil {
            // editingImp is only non-nil if we have edited a imp's details
            let clock = myClocks.imps[clockRow]
            clock.name = editingClock.name
            clock.code = editingClock.code
            clock.colour = editingClock.colour

            editingClock = nil
            cdvc = nil
        }

        let indexPath = IndexPath.init(row:myClocks.currentImp, section:0)
        tableView(clockTable, didSelectRowAt:indexPath)

        // Check for show/hide Clock IDs preference
        let settings = UserDefaults.standard
        settings.synchronize()
        showClockIDflag = settings.bool(forKey:"ts.oclock.show.agent.url")

        // Update table to show any changes made
        clockTable.reloadData()
    }


    // MARK: - Control Methods

    @objc func editTouched() {

        // The Nav Bar's Edit button has been tapped, so select or cancel editing mode

        clockTable.setEditing(!clockTable.isEditing, animated: true)

        // According to the current mode, set the title of the Edit button:
        // Editing mode: Done
        // Viewing mode: Edit

        if clockTable.isEditing {
            tableEditingFlag = true
            self.navigationItem.rightBarButtonItem!.title = "Done"
            self.navigationItem.leftBarButtonItem!.isEnabled = false
            clockTable.reloadData()
        } else {
            tableEditingFlag = false
            self.navigationItem.rightBarButtonItem!.title = "Edit"
            self.navigationItem.leftBarButtonItem!.isEnabled = true
            clockTable.reloadData()
        }
    }

    @objc func orderTouched() {

        tableOrderingFlag = !tableOrderingFlag;

        // Switch off editing if it is on
        clockTable.setEditing(!clockTable.isEditing, animated:true)

        // But use the editing flag to manage the right-hand button
        if tableOrderingFlag {
            tableEditingFlag = true
            self.navigationItem.leftBarButtonItem!.title = "Done"
            self.navigationItem.rightBarButtonItem!.isEnabled = false
            clockTable.reloadData()
        } else {
            tableEditingFlag = false
            self.navigationItem.leftBarButtonItem!.title = "Reorder"
            self.navigationItem.rightBarButtonItem!.isEnabled = true
            clockTable.reloadData()
        }
    }

    // MARK: - Table View Data Source Methods

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if tableEditingFlag == true && tableOrderingFlag == false {
            return myClocks.imps.count + 1
        } else {
            return myClocks.imps.count
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Is the currently selected row *already* the currentImp? If so, bail
        if indexPath.row == currentClock {
            let cell:UITableViewCell? = tableView.cellForRow(at:indexPath)

            if let nopCell = cell  {
                if nopCell.accessoryType == UITableViewCellAccessoryType.none {
                    nopCell.accessoryType = UITableViewCellAccessoryType.checkmark
                }
            }

            return
        }

        // Remove checkmark from previous selection...
        tableView.deselectRow(at:indexPath, animated:false)

        if currentClock != -1 {
            let oldIndexPath = NSIndexPath.init(row:currentClock, section:0) as IndexPath
            let cell:UITableViewCell? = tableView.cellForRow(at:oldIndexPath)

            if let nopCell = cell {
                nopCell.accessoryType = UITableViewCellAccessoryType.none
            }
        }

        // ... and add it to the new one
        let cell:UITableViewCell? = tableView.cellForRow(at:indexPath)

        if let nopCell = cell {
            nopCell.accessoryType = UITableViewCellAccessoryType.checkmark
            nopCell.accessoryView?.tintColor = UIColor.darkGray
        }

        // Record the index of the now-selected imp
        myClocks.currentImp = indexPath.row
        currentClock = indexPath.row
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Get a new table cell from the queue of existing cells, or create one if none are available
        let cell = tableView.dequeueReusableCell(withIdentifier:"imp_table_cell", for:indexPath)

        if indexPath.row == myClocks.imps.count {
            // Append the extra row required by entering the table's editing mode
            cell.textLabel?.text = "Add new cløck"
            cell.detailTextLabel?.text = ""
            cell.accessoryView?.tintColor = UIColor.darkGray
            cell.accessoryType = UITableViewCellAccessoryType.none
            cell.editingAccessoryType = UITableViewCellAccessoryType.none
        } else {
            let clock = myClocks.imps[indexPath.row]
            cell.textLabel?.text = clock.name
            cell.accessoryType = UITableViewCellAccessoryType.none

            if indexPath.row == myClocks.currentImp {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            }

            if tableOrderingFlag {
                cell.showsReorderControl = true
                cell.editingAccessoryType = UITableViewCellAccessoryType.none
            } else {
                cell.showsReorderControl = false
                cell.editingAccessoryType = UITableViewCellAccessoryType.detailDisclosureButton
            }

            // Hide or Show ID according to setting
            if showClockIDflag {
                cell.detailTextLabel!.text = clock.code
            } else {
                var bullets: String = ""

                for _ in 0..<(clock.code as NSString).length { bullets = bullets + "•" }
                
                cell.detailTextLabel!.text = bullets
            }
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {

        // All table rows are editable, including the 'Add new imp' row
        return true
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) ->UITableViewCellEditingStyle {

        if !tableOrderingFlag {
            if indexPath.row == myClocks.imps.count {
                return UITableViewCellEditingStyle.insert
            } else {
                return UITableViewCellEditingStyle.delete
            }
        } else {
            return UITableViewCellEditingStyle.none
        }
    }


    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            // Deselect and remove the accessory
            tableView.deselectRow(at:indexPath, animated:true)
            let oldIndexPath = NSIndexPath.init(row:currentClock, section:0) as IndexPath
            let cell = tableView.cellForRow(at:oldIndexPath)!
            cell.accessoryType = UITableViewCellAccessoryType.none

            // Remove the deleted row's imp from the data source FIRST
            if indexPath.row == myClocks.currentImp {
                myClocks.currentImp = -1
                currentClock = -1
            } else if indexPath.row < myClocks.currentImp {
                currentClock -= 1
                myClocks.currentImp -= 1
            }

            myClocks.imps.remove(at:indexPath.row)

            // Now delete the table row itself then update the table
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            if currentClock != -1 {
                let oldIndexPath = NSIndexPath.init(row:currentClock, section:0) as IndexPath
                let cell = tableView.cellForRow(at:oldIndexPath)!
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            }
            
            tableView.reloadData()
        } else if editingStyle == .insert {
            // Create a new imp with default name and code values FOR DISPLAY ONLY
            let imp = Imp()
            imp.name = "Cløck \(myClocks.imps.count + 1)"
            imp.code = "Cløck \(myClocks.imps.count + 1) ID code"

            // Add new imp to the list
            myClocks.imps.append(imp)
            
            // And add it to the table
            tableView.insertRows(at:[indexPath], with:UITableViewRowAnimation.none)
            clockTable.reloadData()
        }    
    }

    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

        // Preserve the currently selected clock
        var selectedImp:Imp?
        var imps:[Imp] = myClocks.imps

        if myClocks.currentImp != -1 && imps.count != 0 { selectedImp = imps[myClocks.currentImp] }

        let start = fromIndexPath.startIndex
        let end = to.startIndex
        let anImp = imps[start]
        imps.remove(at:start)
        imps.insert(anImp, at:end)

        // Move selection if necessary
        if selectedImp != nil {
            if let imp = imps.index(of:selectedImp!) {
                myClocks.currentImp = imp
                currentClock = myClocks.currentImp
            }
        }
        
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {

        if indexPath.row == myClocks.imps.count { return false }
        return tableOrderingFlag
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {

        // Instantiate the imp detail view controller as required - ie. every time
        if cdvc == nil {
            let storyboard = UIStoryboard.init(name:"Main", bundle:nil)
            cdvc = storyboard.instantiateViewController(withIdentifier:"imp_clock_detail_view") as! ClockDetailViewController
            cdvc.navigationItem.title = "Cløck Info"
            cdvc.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title:"Cløcks",
                                                                         style:UIBarButtonItemStyle.plain,
                                                                         target:cdvc,
                                                                         action:#selector(cdvc.changeDetails))
            cdvc.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
        }

        // Set ImpDetailViewController's currentClock properties

        if editingClock == nil { editingClock = Imp() }

        let clock = myClocks.imps[indexPath.row]
        editingClock.name = clock.name
        editingClock.code = clock.code
        editingClock.colour = clock.colour
        clockRow = indexPath.row

        // Set the LED colour graphic

        cdvc.currentClock = editingClock
        
        // Present the imp detail view controller
        
        self.navigationController?.pushViewController(cdvc, animated: true)
    }

}
