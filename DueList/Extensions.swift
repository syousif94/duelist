//
//  Extensions.swift
//  DueList
//
//  Created by Sammy Yousif on 12/5/19.
//  Copyright © 2019 Sammy Yousif. All rights reserved.
//

import UIKit

extension UIColor {
    static let blue = UIColor("#007AFF")
    static let green = UIColor("#20CB37")
    static let gray = UIColor("#58636B")
    static let orange = UIColor("#FC9500")
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return boundingBox.height
    }
    
    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        return boundingBox.width
    }
    
    func slice(from: String, to: String) -> String? {
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    func replace(pattern: String, with template: String) -> String {
        let options: NSRegularExpression.Options = [.caseInsensitive]
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return self }
        
        let range = NSRange(
            self.startIndex..<self.endIndex,
            in: self
        )
        
        return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: template)
        
    }
    
    func numberOfMatches(pattern: String) -> Int {
        let options: NSRegularExpression.Options = [.caseInsensitive]
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return 0 }
        
        let range = NSRange(
            self.startIndex..<self.endIndex,
            in: self
        )
        
        return regex.numberOfMatches(in: self, options: [], range: range)
    }
}

extension NSAttributedString {
    
    func height(containerWidth: CGFloat) -> CGFloat {
        let rect = self.boundingRect(with: CGSize.init(width: containerWidth, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(rect.size.height)
    }
    
    func width(containerHeight: CGFloat) -> CGFloat {
        let rect = self.boundingRect(with: CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: containerHeight), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return ceil(rect.size.width)
    }
    
}

extension UIViewController {
    func add(to viewController: UIViewController, view: UIView? = nil) {
        viewController.addChild(self)
        (view ?? viewController.view).addSubview(self.view)
        didMove(toParent: viewController)
    }
}

public protocol ReusableView: class {
    static var defaultReuseIdentifier: String { get }
}

extension ReusableView where Self: UIView {
    public static var defaultReuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionView {
    func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView {
        register(T.self, forCellWithReuseIdentifier: T.defaultReuseIdentifier)
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T where T: ReusableView {
        return dequeueReusableCell(withReuseIdentifier: T.defaultReuseIdentifier, for: indexPath) as! T
    }
}
