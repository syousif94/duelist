//
//  FilterButton.swift
//  DueList
//
//  Created by Sammy Yousif on 12/6/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit
import RxSwift

class FilterButton: FadingButton {
    static let height: CGFloat = 68
    
    static let countFont: UIFont = {
        
        let fontSize: CGFloat = 28
        let fontWeight: UIFont.Weight = .semibold
        
        let systemFont = UIFont.systemFont(ofSize: fontSize, weight: fontWeight)

        let font: UIFont
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: descriptor, size: fontSize)
        } else {
            font = systemFont
        }
        
        return font
    }()
    
    var count: Int? {
        didSet {
            guard let count = count else { return }
            countLabel.text = "\(count)"
            setNeedsLayout()
        }
    }
    
    let mode: DueItems.List
    
    let label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor("#666")
        return label
    }()
    
    let countLabel: UILabel = {
        let label = UILabel()
        label.font = FilterButton.countFont
        return label
    }()
    
    lazy var color: UIColor = {
        let color: UIColor
        switch mode {
        case .all: color = .gray
        case .today: color = .blue
        case .late: color = .orange
        case .done: color = .green
        }
        return color
    }()
    
    let iconBackgroundView: UIView = {
        let view = UIView()
        view.frame.size.width = 32
        view.frame.size.height = 32
        view.layer.cornerRadius = view.frame.size.height / 2
        view.isUserInteractionEnabled = false
        return view
    }()
    
    let iconView: UIImageView
    
    let bag = DisposeBag()
    
    init(mode: DueItems.List) {
        self.mode = mode
        self.iconView = UIImageView(image: mode.imageValue)
        super.init(frame: .zero)
        
        iconBackgroundView.backgroundColor = mode.colorValue
        label.text = mode.stringValue
        
        addSubview(label)
        addSubview(countLabel)
        addSubview(iconBackgroundView)
        iconBackgroundView.addSubview(iconView)
        
        layer.cornerRadius = 8
        
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
        
        appDelegate.dueItems.list.subscribe(onNext: { list in
            self.backgroundColor = list == self.mode ? UIColor.black.withAlphaComponent(0.07) : UIColor.black.withAlphaComponent(0.03)
        }).disposed(by: bag)
    }
    
    @objc func onTap() {
        if appDelegate.dueItems.list.value != self.mode {
            appDelegate.dueItems.list.accept(self.mode)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.pin.left(10).bottom(5).sizeToFit()
        countLabel.pin.right(10).top(5).sizeToFit()
        iconBackgroundView.pin.left(6).vCenter(to: countLabel.edge.vCenter).marginBottom(1)
        switch mode {
        case .all:
            iconView.pin.hCenter().vCenter()
        case .today:
            iconView.pin.hCenter().vCenter()
        case .late:
            iconView.pin.hCenter().vCenter()
        case .done:
            iconView.pin.hCenter().vCenter()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
