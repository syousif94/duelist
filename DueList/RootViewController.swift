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
import CloudKit
import Disk

class RootViewController: UIViewController,
    UICollectionViewDataSource,
    ETCollectionViewDelegateWaterfallLayout,
    UINavigationControllerDelegate {
    
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
        
        observeList()
        
        Observable.combineLatest(
            DueItems.shared.complete.results,
            DueItems.shared.incomplete.results
        ).subscribe(onNext: { [unowned self] _, _ in
            self.updateFilters()
        }).disposed(by: bag)
        
        subscribeToDueItemsChanges()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeList()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listSubscription?.dispose()
        listSubscription = nil
    }
    
    var listSubscription: Disposable?
    
    func observeList() {
        guard listSubscription == nil else { return }
        
        listSubscription = Observable.combineLatest(
            DueItems.shared.list,
            DueItems.shared.complete.results,
            DueItems.shared.incomplete.results
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
        })
    }
    
    func subscribeToDueItemsChanges() {
        
        let subscription = CKQuerySubscription(
            recordType: "CD_DueItem",
            predicate: NSPredicate(format: "CD_completed = %d", false),
            options: [
                .firesOnRecordCreation,
                .firesOnRecordUpdate,
                .firesOnRecordDeletion
            ]
        )
        
        let info = CKSubscription.NotificationInfo()
        
        subscription.notificationInfo = info
        
        info.shouldSendContentAvailable = true
        
        CKContainer(identifier: "iCloud.DueList").privateCloudDatabase.save(subscription) { subscription, error in
            if let error = error {
                print("error", error)
            }
            else {
                print("subscription successful")
            }
        }
    }
    
    func updateTime() {
        let date = Date()
        let dateString = date.in(region: Region.current).toFormat("EEEE MMM d")
        dateLabel.text = dateString
    }
    
    // MARK: Layout
    
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
        DispatchQueue.global(qos: .userInteractive).async { [unowned self] in
            let all = DueItems.shared.incomplete.results.value.count
            let complete = DueItems.shared.complete.results.value.count
            var today = 0
            var late = 0
            
            for object in DueItems.shared.incomplete.results.value {
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
    
    // MARK: UICollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: Cell = collectionView.dequeueReusableCell(for: indexPath)
        cell.item = dataSource[indexPath.item]
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return Cell.size(for: dataSource[indexPath.item], in: collectionView.frame)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= headerHeight {
            headerView.transform = CGAffineTransform(translationX: 0, y: -scrollView.contentOffset.y)
        }
    }
    
    // MARK: Navigation
    
    var itemInteractor: ItemInteractor?
    
    weak var selectedCell: Cell?
    
    func presentItemView(sender: Cell) {
        guard let item = sender.item else { return }
        self.selectedCell = sender
        let frame = collectionView.convert(sender.frame, to: view)
        NavigationController.shared.delegate = self
        let viewController = ItemViewController(item: item, originFrame: frame)
        NavigationController.shared.pushViewController(viewController, animated: true)
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        guard let cell = selectedCell else { return nil }
        
        let frame = collectionView.convert(cell.frame, to: view)
        
        switch operation {
        case .push:
            self.itemInteractor = ItemInteractor(viewController: toVC)
            return ItemAnimator(isPresenting: true, originFrame: frame, cell: cell)
        case .pop:
            return ItemAnimator(isPresenting: false, originFrame: frame, cell: cell)
        default:
            return nil
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let interactor = itemInteractor, interactor.transitionInProgress else { return nil }
        
        return interactor
    }
}

extension RootViewController {
    
    // MARK: Cell
    
    class Cell: UICollectionViewCell, ReusableView {
        
        static func size(for item: DueItem, in frame: CGRect) -> CGSize {
            return ItemView.size(for: item, in: frame)
        }
        
        weak var delegate: RootViewController?
        
        var bag = DisposeBag()
        
        var item: DueItem? {
            willSet {
                bag = DisposeBag()
            }
            didSet {
                guard let item = item else { return }
                configure(for: item)
                
                item.observable.subscribe(onNext: { [unowned self] _, _, _ in
                    self.delegate?.collectionView.collectionViewLayout.invalidateLayout()
                }).disposed(by: bag)
            }
        }
        
        func configure(for item: DueItem) {
            itemView.item = item
        }
        
        let button = FadingButton()
        
        let itemView = ItemView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            backgroundColor = ItemView.backgroundColor
            
            layer.cornerRadius = ItemView.radius
            
            contentView.addSubview(button)
            
            button.addSubview(itemView)
            
            itemView.isUserInteractionEnabled = false
            
            button.addGestureRecognizer(longPressRecognizer)
            
            button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        }
        
        @objc func onTap() {
            delegate?.presentItemView(sender: self)
        }
        
        @objc func onLongTap() {
            guard let item = item else { return }
            DueItems.shared.delete(item: item)
        }
        
        lazy var longPressRecognizer: UILongPressGestureRecognizer = {
            return UILongPressGestureRecognizer(target: self, action: #selector(onLongTap))
        }()
        
        // MARK: Cell Layout
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            button.pin.all()
            
            itemView.pin.all()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

