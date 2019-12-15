//
//  ItemAnimator.swift
//  DueList
//
//  Created by Sammy Yousif on 12/14/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit

class ItemAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting : Bool
    let originFrame : CGRect
    let cell: RootViewController.Cell?
    
    init(isPresenting: Bool, originFrame: CGRect, cell: RootViewController.Cell? = nil) {
        self.isPresenting = isPresenting
        self.originFrame = originFrame
        self.cell = cell
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let startOpacity: Float
        let endOpacity: Float
        
        let itemViewController: ItemViewController
        let rootViewController: RootViewController
        
        if isPresenting {
            startOpacity = 0
            endOpacity = 1
            guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? ItemViewController,
                let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? RootViewController else { return }
            
            itemViewController = toVC
            rootViewController = fromVC
            
            itemViewController.backgroundView.layer.opacity = startOpacity
            
            cell?.isHidden = true
            
            transitionContext.containerView.insertSubview(itemViewController.view, aboveSubview: rootViewController.view)
        }
        else {
            startOpacity = 1
            endOpacity = 0
            
            guard let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? RootViewController,
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? ItemViewController else { return }
            
            itemViewController = fromVC
            rootViewController = toVC
            
            transitionContext.containerView.insertSubview(rootViewController.view, belowSubview: itemViewController.view)
        }
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext) * 0.45, animations: {
            itemViewController.backgroundView.layer.opacity = endOpacity
        })
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: self.isPresenting ? 0.8 : 0.6,
            initialSpringVelocity: 0,
            options: [],
            animations: {  [unowned self] in
                if self.isPresenting {
                    itemViewController.layout()
                }
                else {
                    itemViewController.disappear()
                }
        }) { [unowned self] _ in
            let completed = !transitionContext.transitionWasCancelled
            if completed {
                if self.isPresenting {
                    rootViewController.view.removeFromSuperview()
                }
                else {
                    self.cell?.isHidden = false
                    itemViewController.view.removeFromSuperview()
                }
            }
            transitionContext.completeTransition(completed)
        }
    }
}
