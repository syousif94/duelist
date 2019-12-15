//
//  ItemCell.swift
//  DueList
//
//  Created by Sammy Yousif on 12/15/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit
import SwiftDate

class ItemView: UIView {
    
    static let backgroundColor = UIColor("#f5f5f5")
    
    static let radius: CGFloat = 8
    
    static let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    
    static let subFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
    
    static func size(for item: DueItem, in frame: CGRect) -> CGSize {
        let width = (frame.width - 60) / 3
        let textWidth = width - 20
        
        let dateheight: CGFloat
        let remainingheight: CGFloat
        if let timeStrings = TimeStrings(item: item) {
            dateheight = timeStrings.date.height(withConstrainedWidth: textWidth , font: font)
            remainingheight = timeStrings.remaining.height(withConstrainedWidth: textWidth , font: subFont)
        }
        else {
            dateheight = 0
            remainingheight = 0
        }
        
        let titleheight = item.title?.height(withConstrainedWidth: textWidth , font: font) ?? 0
        
        let height = 7 + dateheight + titleheight + remainingheight + 7
        return CGSize(width: width, height: max(height, 44))
    }
    
    struct TimeStrings {
        let date: String
        let remaining: String
        let pastDue: Bool
        
        init?(item: DueItem) {
            guard let date = item.dueDate?.in(region: Region.current) else { return nil }
            
            self.date = "\(date.toFormat("MMM d"))\n\(date.toFormat("h:mm"))\(date.toFormat("a").lowercased())"
            
            self.pastDue = date.isInPast
            
            let relative = date.toRelative(style: RelativeFormatter.twitterStyle(), locale: Locales.english)
            
            var suffix = ""
            if !pastDue {
                suffix = " left"
            }
            else if relative != "now" {
                suffix = " ago"
            }
            
            self.remaining = "\(relative)\(suffix)"
        }
    }
    
    var item: DueItem? {
        didSet {
            guard let item = item else { return }
            configure(for: item)
        }
    }
    
    func configure(for item: DueItem) {
        if let timeStrings = TimeStrings(item: item) {
            dateLabel.text = timeStrings.date
            remainingLabel.text = timeStrings.remaining
            remainingLabel.textColor = timeStrings.pastDue ? .red : UIColor("#666")
            dateLabel.isHidden = false
            remainingLabel.isHidden = false
        }
        else {
            dateLabel.isHidden = true
            remainingLabel.isHidden = true
        }
        
        titleLabel.text = item.title
        
        setNeedsLayout()
    }
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = ItemView.font
        label.textColor = UIColor("#666")
        label.numberOfLines = 0
        return label
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = ItemView.font
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()
    
    let remainingLabel: UILabel = {
        let label = UILabel()
        label.font = ItemView.subFont
        label.textColor = UIColor("#666")
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        
        addSubview(dateLabel)
        addSubview(titleLabel)
        addSubview(remainingLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dateLabel.pin.top(7).horizontally(10).sizeToFit(.width)
        
        titleLabel.pin.horizontally(10).sizeToFit(.width)
        
        if dateLabel.isHidden {
            titleLabel.pin.top(7)
        }
        else {
            titleLabel.pin.below(of: dateLabel)
        }
        
        remainingLabel.pin.horizontally(10).sizeToFit(.width).below(of: titleLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
