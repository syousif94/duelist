//
//  ViewController.swift
//  DueList
//
//  Created by Sammy Yousif on 12/5/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit
import CoreData
import SwiftDate
import RxSwift
import DeepDiff

class RootViewController: UIViewController, UICollectionViewDataSource, ETCollectionViewDelegateWaterfallLayout {
    
    var managedObjectContext: NSManagedObjectContext!
    
    let dueInputViewController = InputViewController()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    let bag = DisposeBag()
    
    var dataSource: [DueItem] = []
    
    lazy var headerHeight: CGFloat = {
        let dateLabelHeight: CGFloat = dateLabel.font.lineHeight
        let padding: CGFloat = 10 * 3 + 30 + 110
        let filterButtonHeight: CGFloat = FilterButton.height * 2
        let topInset = SceneDelegate.shared.insets.top
        let inputHeight = InputViewController.height
        let height: CGFloat = dateLabelHeight + padding + filterButtonHeight + topInset + inputHeight
        return height
    }()
    
    let headerView = UIView()
    
    let allButton = FilterButton(mode: .all)
    let todayButton = FilterButton(mode: .today)
    let lateButton = FilterButton(mode: .late)
    let doneButton = FilterButton(mode: .done)
    
    lazy var collectionView: UICollectionView = {
        let layout = ETCollectionViewWaterfallLayout()
        layout.columnCount = 3
        layout.minimumInteritemSpacing = 10
        layout.minimumColumnSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: headerHeight, left: 20, bottom: max(40, SceneDelegate.shared.insets.bottom), right: 20)
        layout.itemRenderDirection = .leftToRight
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.alwaysBounceVertical = true
        view.register(Cell.self)
        view.backgroundColor = .white
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        
        view.addSubview(headerView)
        
        headerView.addSubview(dateLabel)
        headerView.addSubview(allButton)
        headerView.addSubview(todayButton)
        headerView.addSubview(lateButton)
        headerView.addSubview(doneButton)
        
        dueInputViewController.add(to: self, view: headerView)
        dueInputViewController.delegate = self
        
        updateTime()
        
        view.addGestureRecognizer(collectionView.panGestureRecognizer)
        
        Observable.combineLatest(
            appDelegate.dueItems.complete.results,
            appDelegate.dueItems.incomplete.results
        ).subscribe(onNext: { [unowned self] _, _ in
            self.updateFilters()
        }).disposed(by: bag)
        
        Observable.combineLatest(
            appDelegate.dueItems.list,
            appDelegate.dueItems.complete.results,
            appDelegate.dueItems.incomplete.results
        ).subscribe(onNext: { [unowned self] list, complete, incomplete in
            
            let newList: [DueItem]
            
            switch list {
            case .all:
                newList = incomplete
            case .today:
                newList = incomplete.filter { object in
                    if let date = object.dueDate?.in(region: Region.current) {
                        if date.isToday {
                            return true
                        }
                    }
                    return false
                }
            case .late:
                newList = incomplete.filter { object in
                    if let date = object.dueDate?.in(region: Region.current) {
                        if date.isInPast {
                            return true
                        }
                    }
                    return false
                }
            case .done:
                newList = complete
            }
            
            let changes = diff(old: self.dataSource, new: newList)
            
            self.collectionView.reload(changes: changes, updateData: {
                self.dataSource = newList
            })
        }).disposed(by: bag)
        
        appDelegate.dueItems.complete.results.subscribe(onNext: { [unowned self] list in
            self.updateFilters()
        }).disposed(by: bag)
    }
    
    func updateTime() {
        let date = Date()
        let dateString = date.in(region: Region.current).toFormat("EEEE MMM d")
        dateLabel.text = dateString
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        headerView.pin.top().height(headerHeight).horizontally()
        
        let buttonWidth = (UIScreen.main.bounds.width - 50) / 2
        
        dateLabel.pin
            .top(SceneDelegate.shared.insets.top + 110)
            .left(20)
            .sizeToFit()
        
        allButton.pin
            .below(of: dateLabel)
            .marginTop(10)
            .left(20)
            .width(buttonWidth)
            .height(FilterButton.height)
        
        doneButton.pin
            .top(to: allButton.edge.top)
            .right(20)
            .width(buttonWidth)
            .height(FilterButton.height)
        
        todayButton.pin
            .below(of: allButton)
            .marginTop(10)
            .left(20)
            .width(buttonWidth)
            .height(FilterButton.height)
        
        lateButton.pin
            .top(to: todayButton.edge.top)
            .right(20)
            .width(buttonWidth)
            .height(FilterButton.height)
        
        dueInputViewController.view.pin
            .bottom(20)
            .horizontally(20)
            .height(InputViewController.height)
        
        collectionView.pin.all()
    }
    
    func updateFilters() {
        guard let dueItems = appDelegate.dueItems else { return }
        DispatchQueue.global(qos: .userInteractive).async { [unowned self] in
            let all = dueItems.incomplete.results.value.count
            let complete = dueItems.complete.results.value.count
            var today = 0
            var late = 0
            
            for object in dueItems.incomplete.results.value {
                if let date = object.dueDate?.in(region: Region.current) {
                    if date.isInPast {
                        late += 1
                    }
                    if date.isToday {
                        today += 1
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.allButton.count = all
                self.todayButton.count = today
                self.lateButton.count = late
                self.doneButton.count = complete
            }
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
        return Cell.size(for: dataSource[indexPath.item])
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= headerHeight {
            headerView.transform = CGAffineTransform(translationX: 0, y: -scrollView.contentOffset.y)
        }
    }
}

extension RootViewController {
    class Cell: UICollectionViewCell, ReusableView {
        
        static let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        static let subFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        
        static func size(for item: DueItem) -> CGSize {
            let width = (UIScreen.main.bounds.width - 60) / 3
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
        
        let button = FadingButton()
        
        let dateLabel: UILabel = {
            let label = UILabel()
            label.font = Cell.font
            label.textColor = UIColor("#666")
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
            label.textColor = UIColor("#666")
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = UIColor("#f5f5f5")
            
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

