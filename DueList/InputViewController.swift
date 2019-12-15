//
//  InputViewController.swift
//  DueList
//
//  Created by Sammy Yousif on 12/5/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit
import PinLayout
import CoreData
import RxSwift
import RxCocoa
import SwiftDate

class InputViewController: UIViewController, UITextFieldDelegate {
    
    static let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    
    static let timeFont = UIFont.systemFont(ofSize: 16, weight: .bold)
    
    static let inputHeight: CGFloat = 44
    
    static let height: CGFloat = inputHeight + font.lineHeight + 5
    
    weak var delegate: RootViewController?
    
    let bag = DisposeBag()
    
    let inputParser = InputParser()
    
    let leftView: UIView = {
        let view = UIView()
        view.frame.size.width = 15
        view.frame.size.height = InputViewController.height
        return view
    }()
    
    let promptLabel: UILabel = {
        let label = UILabel()
        label.font = InputViewController.font
        label.text = "What's due?"
        label.textColor = UIColor("#666")
        label.sizeToFit()
        return label
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = InputViewController.timeFont
        return label
    }()
    
    let textField: UITextField = {
        let view = UITextField()
        view.autocapitalizationType = .none
        view.returnKeyType = .done
        view.placeholder = "ex. buy groceries tue 7pm"
        return view
    }()
    
    let accessoryView = AccessoryView()
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        switch reason {
        case .committed:
            saveItem()
        default:
            break
        }
    }
    
    func saveItem() {
        guard let delegate = delegate, let text = textField.text, !text.isEmpty else { return }
        
        let output = inputParser.parse(text: text)
        
        if output.invalid != nil || output.title.isEmpty {
            return
        }
        
        let item = NSEntityDescription.insertNewObject(forEntityName: "DueItem", into: delegate.managedObjectContext) as! DueItem

        item.title = output.title
        item.input = output.raw
        item.dueDate = output.date?.date
        item.createdAt = Date()

        do {
            try delegate.managedObjectContext.save()
            textField.text = nil
            timeLabel.isHidden = true
        }
        catch {
            print(error)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(promptLabel)
        
        view.addSubview(timeLabel)
        
        timeLabel.isHidden = true
        
        textField.leftView = leftView
        textField.leftViewMode = .always
        textField.inputAccessoryView = accessoryView
        
        view.addSubview(textField)
        
        textField.backgroundColor = UIColor.black.withAlphaComponent(0.03)
        
        textField.layer.cornerRadius = 8
        
        textField.delegate = self
        
        textField.rx.text.subscribe(onNext: { [unowned self] text in
            guard let text = text, !text.isEmpty else {
                self.timeLabel.isHidden = true
                return
            }
            
            let output = self.inputParser.parse(text: text)
            
            if let invalid = output.invalid {
                self.timeLabel.text = "Invalid \(invalid.rawValue)"
                self.timeLabel.textColor = .red
            }
            else if let date = output.date {
                let yearText = date.year != Date().in(region: Region.current).year
                    ? ", \(date.year) "
                    : " "
                let text = "\(date.toFormat("MMM d"))\(yearText)\(date.toFormat("h:mm"))\(date.toFormat("a").lowercased())"
                self.timeLabel.text = text
                self.timeLabel.textColor = .green
            }
            else {
                self.timeLabel.text = "No Due Date"
                self.timeLabel.textColor = UIColor("#999")
            }
            
            self.timeLabel.isHidden = false
            self.view.setNeedsLayout()
        }).disposed(by: bag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        promptLabel.pin.top().left(5)
        
        timeLabel.pin.top().sizeToFit().after(of: promptLabel).marginLeft(5)
        
        textField.pin.bottom().horizontally().height(InputViewController.inputHeight)
    }
    
}

extension InputViewController {
    class AccessoryView: UIInputView {
        
        init() {
            super.init(frame: .zero, inputViewStyle: .keyboard)
            frame.size.height = 44
            frame.size.width = UIScreen.main.bounds.width
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
    class AccessoryButton: FadingButton {
        
    }
}
