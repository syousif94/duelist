//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by Sammy Yousif on 12/12/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreData
import PinLayout
import RxSwift
import RxCocoa
import SwiftDate
import UIColor_Hex_Swift
import DeepDiff
import CloudKit
import MMWormhole

class TodayViewController: UIViewController, NCWidgetProviding, UICollectionViewDataSource, ETCollectionViewDelegateWaterfallLayout {
    
    let bag = DisposeBag()
    
    var dataSource: [TodayDueItem] = []
    
    lazy var collectionView: UICollectionView = {
        let layout = ETCollectionViewWaterfallLayout()
        layout.columnCount = 3
        layout.minimumInteritemSpacing = 10
        layout.minimumColumnSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layout.itemRenderDirection = .leftToRight
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.alwaysBounceVertical = true
        view.register(Cell.self)
        view.backgroundColor = .clear
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        
        TodayManager.shared.startListening(with: { [unowned self] message in
            switch message.messageType {
            case .reload:
                self.reloadItems()
            default:
                break
            }
        })
    }
    
    deinit {
        TodayManager.shared.wormhole.stopListeningForMessage(withIdentifier: "message")
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .compact {
            self.preferredContentSize = maxSize
        } else if activeDisplayMode == .expanded {
            self.preferredContentSize = CGSize(width: maxSize.width, height: 350)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: Cell = collectionView.dequeueReusableCell(for: indexPath)
        cell.item = dataSource[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return Cell.size(for: dataSource[indexPath.item], frame: collectionView.frame)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        collectionView.pin.all()
    }
    
    func reloadItems() {
        if let items = TodayDueItem.retrieveList() {
            let changes = diff(old: self.dataSource, new: items)
            DispatchQueue.main.async {
                self.collectionView.reload(changes: changes, updateData: {
                    self.dataSource = items
                })
            }
        }
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        reloadItems()
    }
    
}

extension TodayViewController {
    class Cell: UICollectionViewCell, ReusableView {
        
        static let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        static let subFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        
        static func size(for item: TodayDueItem, frame: CGRect) -> CGSize {
            let width = (frame.size.width - 40) / 3
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
            
            init?(item: TodayDueItem) {
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
        
        var item: TodayDueItem? {
            didSet {
                guard let item = item else { return }
                configure(for: item)
            }
        }
        
        func configure(for item: TodayDueItem) {
            if let timeStrings = TimeStrings(item: item) {
                dateLabel.text = timeStrings.date
                remainingLabel.text = timeStrings.remaining
                remainingLabel.textColor = timeStrings.pastDue ? .red : UIColor.black.withAlphaComponent(0.6)
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
        
        let button = FadingButton()
        
        let dateLabel: UILabel = {
            let label = UILabel()
            label.font = Cell.font
            label.textColor = UIColor.black.withAlphaComponent(0.6)
            label.numberOfLines = 0
            return label
        }()
        
        let titleLabel: UILabel = {
            let label = UILabel()
            label.font = Cell.font
            label.textColor = .black
            label.numberOfLines = 0
            return label
        }()
        
        let remainingLabel: UILabel = {
            let label = UILabel()
            label.font = Cell.subFont
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = UIColor.white.withAlphaComponent(0.1)
            
            layer.cornerRadius = 8
            
            contentView.addSubview(button)
            
            button.addSubview(dateLabel)
            button.addSubview(titleLabel)
            button.addSubview(remainingLabel)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            button.pin.all()
            
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
}
