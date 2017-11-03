
//  Created by Tony Smith on 07/12/2016.
//  Copyright © 2016-17 Tony Smith. All rights reserved.


import UIKit

class ImpColourView: UIView {

    var colourIndex: Int = 0
    var colours: [UIColor]?

    
    override func draw(_ rect: CGRect) {

        if colours == nil {
            colours = [UIColor.red, UIColor.green, UIColor.yellow, UIColor.blue]
        }

        if colourIndex < 0 || colourIndex > 3 { colourIndex = 0 }

        let drawColour:UIColor = colours![colourIndex]
        drawColour.setFill()
        drawColour.setStroke()

        let centerX = (rect.size.width / 2) + rect.origin.x
        let centerY = (rect.size.height / 2) + rect.origin.y

        let path = UIBezierPath.init(arcCenter:CGPoint(x:centerX, y:centerY),
                                     radius:14.0,
                                     startAngle:0.0,
                                     endAngle:360.0,
                                     clockwise:true)
        path.fill()
    }

    func changeColour() {

        self.setNeedsDisplay()
    }
}
