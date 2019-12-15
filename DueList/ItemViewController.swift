//
//  ItemViewController.swift
//  DueList
//
//  Created by Sammy Yousif on 12/14/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit

class ItemViewController: UIViewController {
    let item: DueItem
    
    let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.allowsGroupOpacity = true
        view.clipsToBounds = true
        return view
    }()
    
    let itemView = ItemView()
    
    let originFrame: CGRect?
    
    let buttons = Action.allCases.map(ActionButton.init)
    
    init(item: DueItem, originFrame: CGRect? = nil) {
        self.item = item
        self.originFrame = originFrame
        super.init(nibName: nil, bundle: nil)
        
        backgroundView.frame = self.view.frame
        view.addSubview(backgroundView)
        
        if let frame = originFrame {
            itemView.frame = frame
        }
        itemView.item = item
        itemView.backgroundColor = ItemView.backgroundColor
        itemView.layer.cornerRadius = ItemView.radius
        
        view.addSubview(itemView)
        
        for button in buttons {
            backgroundView.addSubview(button)
        }
        
        layoutExceptItem()
    }
    
    func layout() {
        itemView.pin.top(SceneDelegate.shared.insets.top).left(20)
        
        layoutExceptItem()
    }
    
    func layoutExceptItem() {
        backgroundView.pin.all()
        
        let buttonSize = CGSize(width: (view.frame.width - 50) / 2, height: ActionButton.height)
        
        for (index, button) in buttons.enumerated() {
            switch index {
            case 0:
                button.pin.bottom(SceneDelegate.shared.insets.bottom).right(20).size(buttonSize)
            case 1:
                button.pin.bottom(to: buttons[index - 1].edge.bottom).left(20).size(buttonSize)
            case 2, 3:
                button.pin.above(of: buttons[index - 2], aligned: .center).marginBottom(10).size(buttonSize)
            default:
                break
            }
        }
    }
    
    func disappear() {
        if let frame = originFrame {
            itemView.pin.top(frame.minY).left(frame.minX)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        layout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ItemViewController {
    
    enum Action: String, CaseIterable {
        case edit = "Edit"
        case delete = "Delete"
        case complete = "Done"
        case back = "Back"
        
        var colorValue: UIColor {
            switch self {
            case .delete:
                return .red
            case .edit:
                return .gray
            case .complete:
                return .green
            case .back:
                return .blue
            }
        }
        
        var imageValue: UIImage {
            switch self {
            case .complete:
                return #imageLiteral(resourceName: "DoneIcon")
            default:
                return UIImage()
            }
        }
    }
    
    class ActionButton: UIView {
        
        static let height: CGFloat = 68
        
        let action: Action
        
        let button = FadingButton()
        
        let label: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            label.textColor = UIColor("#666")
            return label
        }()
        
        let icon: UIImageView
        
        let iconView: UIView = {
            let view = UIView()
            view.frame.size.width = 32
            view.frame.size.height = 32
            view.layer.cornerRadius = view.frame.size.height / 2
            view.isUserInteractionEnabled = false
            return view
        }()
        
        init(action: Action) {
            self.action = action
            self.icon = UIImageView(image: action.imageValue)
            super.init(frame: .zero)
            
            addSubview(button)
            
            backgroundColor = UIColor.black.withAlphaComponent(0.03)
            layer.cornerRadius = 8
            
            button.addSubview(label)
            
            label.text = action.rawValue
            
            iconView.backgroundColor = action.colorValue
            
            button.addSubview(iconView)
            iconView.addSubview(icon)
            
            button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            button.pin.all()
            label.pin.left(10).bottom(5).sizeToFit()
            iconView.pin.left(6).top(5)
            icon.pin.center()
        }
        
        @objc func onTap() {
            switch action {
            case .delete:
                break
            case .edit:
                break
            case .complete:
                break
            case .back:
                NavigationController.shared.popViewController(animated: true)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
