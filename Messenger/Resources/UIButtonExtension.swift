//
//  UIButtonExtension.swift
//  Messenger
//
//  Created by Agata Menes on 04/08/2022.
//

import Foundation
import UIKit

@IBDesignable class MyButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()

        updateCornerRadius()
    }

    @IBInspectable var rounded: Bool = false {
        didSet {
            updateCornerRadius()
        }
    }

    func updateCornerRadius() {
        layer.cornerRadius = rounded ? frame.size.height / 2 : 0
    }
}
