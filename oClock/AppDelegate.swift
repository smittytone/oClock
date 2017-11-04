
//  Created by Tony Smith on 06/12/2016.
//  Copyright © 2016 Tony Smith. All rights reserved.


import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window:UIWindow?
    var myClocks:ImpList!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // Set universal window tint for views that delegate this property to this object
        window?.tintColor = UIColor.white

        myClocks = ImpList.sharedImps

        // Load in default imp list if the file has already been saved
        let docsDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsPath = docsDir[0] + "/oclocks"

        if FileManager.default.fileExists(atPath: docsPath) {
            // If imps file is present on the iDevice, load it in
            let load = NSKeyedUnarchiver.unarchiveObject(withFile:docsPath)

            if load != nil {
                let clocks = load as! ImpList
                myClocks.imps.removeAll()
                let imps = clocks.imps as Array
                myClocks.imps.append(contentsOf:imps)
                myClocks.currentImp = clocks.currentImp
                NSLog("Imp list loaded (%@)", docsPath);
            }
        }

        // Register settings
        UserDefaults.standard.register(defaults: ["ts.oclock.show.agent.url": NSNumber.init(value: true)])
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {

        saveImps()
        NotificationCenter.default.post(name:NSNotification.Name("com.bps.clock.will.quit"),
                                        object:self)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {

        saveImps()
    }

    func saveImps() {

        // The app is going into the background or closing, so save the list of imps
        let docsDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let docsPath = docsDir[0] + "/oclocks"
        let success = NSKeyedArchiver.archiveRootObject(myClocks, toFile:docsPath)
        if success {
            NSLog("Imp list saved (%@)", docsPath)
        } else {
            NSLog("Imp list save failed")
        }
    }

}
