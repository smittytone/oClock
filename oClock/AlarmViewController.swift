
//  Created by Tony Smith on 08/12/2016.
//  Copyright © 2016-17 Tony Smith. All rights reserved.


import UIKit

class AlarmViewController: UIViewController, UIPickerViewDelegate {

    @IBOutlet weak var repeatSwitch:UISwitch!
    @IBOutlet weak var alarmTimePicker:UIDatePicker!

    var alarms:Alarms = Alarms()


    override func viewDidLoad() {

        super.viewDidLoad()

        // Set up the Navigation Bar with a Cancel button
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem:UIBarButtonSystemItem.cancel,
                                                                 target: self,
                                                                 action: #selector(self.cancel))
        self.navigationItem.leftBarButtonItem!.tintColor = UIColor.white

        // Set up the Navigation Bar with a Save button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem:UIBarButtonSystemItem.save,
                                                                 target: self,
                                                                 action: #selector(self.save))
        self.navigationItem.rightBarButtonItem!.tintColor = UIColor.white
    }

    @objc func cancel() {

        // Jump back to the list of alarms
        self.navigationController!.popViewController(animated: true)
    }

    @objc func save() {

        // Save the alarm then jump back to the list of alarms
        var alarm = Alarm()
        alarm.again = repeatSwitch.isOn

        let df = DateFormatter()
        df.dateFormat = "hh:mm:aa"
        let ds = df.string(from:alarmTimePicker.date)
        let da = ds.components(separatedBy:":")
        alarm.hour = Int(da[0])!
        alarm.min = Int(da[1])!

        if da[2] == "PM" { alarm.hour += 12 }

        if alarms.alarmarray.count > 0 {
            var flag = false
            for var anAlarm in alarms.alarmarray {
                if anAlarm.hour == alarm.hour && anAlarm.min == alarm.min {
                    if anAlarm.again != alarm.again { anAlarm.again = alarm.again }
                    flag = true
                    break
                }
            }

            if !flag { alarms.alarmarray.append(alarm) }
        } else {
            alarms.alarmarray.append(alarm)
        }

        self.navigationController!.popViewController(animated: true)
    }

}
