
//  Created by Tony Smith on 07/12/2016.
//  Copyright © 2016-17 Tony Smith. All rights reserved.


import UIKit

class AboutViewController: UIViewController {

    @IBOutlet weak var buildNumber:UILabel!


    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!
        buildNumber.text = "Version \(version) (Build \(build))"
    }
}
