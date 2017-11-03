
//  Created by Tony Smith on 06/12/2016.
//  Copyright © 2016-17 Tony Smith. All rights reserved.


import Foundation

class ImpList: NSObject, NSCoding {

    static let sharedImps: ImpList = { return ImpList() }()

    var imps: [Imp] = []
    var currentImp: Int = -1

    
    // MARK: - Initialization Methods

    override init() {

        currentImp = -1
        imps = []
    }

    
    // MARK: - NSCoding Methods

    func encode(with encoder:NSCoder) {

        encoder.encode(currentImp, forKey:"clock.current.index")
        encoder.encode(imps, forKey:"clock.list")
    }

    required init?(coder decoder: NSCoder) {
        imps = decoder.decodeObject(forKey: "clock.list") as! Array
        currentImp = decoder.decodeInteger(forKey: "clock.current.index")
    }
}
