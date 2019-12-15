//
//  ItemInteractor.swift
//  DueList
//
//  Created by Sammy Yousif on 12/14/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit

class ItemInteractor: UIPercentDrivenInteractiveTransition {
    let viewController: UIViewController
    var transitionInProgress = false
    var shouldCompleteTransition = false
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
        
        setupDismissGesture(on: viewController.view)
    }
    
    func setupDismissGesture(on view: UIView) {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handleDismissGesture(_:)))
        view.addGestureRecognizer(recognizer)
    }
    
    @objc func handleDismissGesture(_ gesture: UIPanGestureRecognizer) {
        let view = viewController.view!
        
        let translation = gesture.translation(in: view)
        
        let horizontalProgress = translation.x / view.frame.width
        let verticalProgress = translation.y * 1.5 / view.frame.height
        let progress = min(1, max(horizontalProgress, verticalProgress))
        
        if progress == 1 {
            update(progress)
            finish()
            return
        }

        switch gesture.state {
        case .began:
            completionSpeed = 1
            transitionInProgress = true
            NavigationController.shared.popViewController(animated: true)
        case .changed:
            shouldCompleteTransition = progress > 0.1
            update(progress)
        case .cancelled:
            transitionInProgress = false
            cancel()
        case .ended:
            transitionInProgress = false
            if shouldCompleteTransition {
                finish()
            }
            else {
                completionSpeed = 0.1
                cancel()
            }
        default:
            break
        }
    }
}
