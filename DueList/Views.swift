//
//  Views.swift
//  DueList
//
//  Created by Sammy Yousif on 12/5/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit

class PassthroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}

class PassthroughScrollView: UIScrollView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}

class FadingButton: UIButton {
    override open var isHighlighted: Bool {
        didSet {
            self.fade()
        }
    }
    
    func fade() {
        let opacity: Float = self.isHighlighted ? 0.2 : 1
        UIView.animate(withDuration: 0.2) {
            for view in self.subviews {
                view.layer.opacity = opacity
            }
        }
    }
}
