
//  Created by Tony Smith on 06/12/2016.
//  Copyright © 2016-17 Tony Smith. All rights reserved.


import Foundation

class Imp: NSObject, NSCoding {

    var name: String = ""
    var code: String = ""
    var colour: Int = 0


    // MARK: - Initialization Methods

    override init() {
        name = ""
        code = ""
        colour = 0  // Assume red
    }


    // MARK: - NSCoding Methods

    required init?(coder decoder: NSCoder) {

        name = ""
        code = ""
        colour = 0

        if let n = decoder.decodeObject(forKey: "clock.name") { name = n as! String }
        if let c = decoder.decodeObject(forKey: "clock.code") { code = c as! String }
        colour = decoder.decodeInteger(forKey: "clock.colour")
    }


    func encode(with encoder: NSCoder) {

        encoder.encode(name, forKey: "clock.name")
        encoder.encode(code, forKey: "clock.code")
        encoder.encode(colour, forKey: "clock.colour")
    }
}
