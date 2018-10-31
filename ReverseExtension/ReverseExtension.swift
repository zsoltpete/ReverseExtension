//
//  ReverseExtension.swift
//  ReverseExtension
//
//  Created by marty-suzuki on 2017/03/01.
//
//

import UIKit

extension UITableView {
    private struct AssociatedKey {
        static var re: UInt8 = 0
        static var isReversed: UInt8 = 0
    }
    
    private var isReversed: Bool {
        set {
            objc_setAssociatedObject(self, &AssociatedKey.isReversed, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            guard let isReversed = objc_getAssociatedObject(self, &AssociatedKey.isReversed) as? Bool else {
                objc_setAssociatedObject(self, &AssociatedKey.isReversed, false, .OBJC_ASSOCIATION_ASSIGN)
                return false
            }
            return isReversed
        }
    }
    
    public var re: ReverseExtension {
        guard let re = objc_getAssociatedObject(self, &AssociatedKey.re) as? ReverseExtension else {
            let re = ReverseExtension(self)
            objc_setAssociatedObject(self, &AssociatedKey.re, re, .OBJC_ASSOCIATION_RETAIN)
            isReversed = true
            return re
        }
        return re
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil && isReversed {
            re.contentInsetObserver = nil
        }
    }
}

extension UITableViewCell {
    private struct AssociatedKey {
        static var frameObserver: UInt8 = 0
    }
    
    var frameObserver: KeyValueObserver? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.frameObserver) as? KeyValueObserver
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.frameObserver, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard let _ = newSuperview else {
            frameObserver = nil
            return
        }
    }
}

extension UITableView {
    public final class ReverseExtension {

        #if swift(>=4.2)
        public typealias UITableViewCellEditingStyle = UITableViewCell.EditingStyle
        public typealias UITableViewScrollPosition = UITableView.ScrollPosition
        public typealias UITableViewRowAnimation = UITableView.RowAnimation
        #endif

        private(set) weak var base: UITableView?
        fileprivate var nonNilBase: UITableView {
            guard let base = base else { fatalError("base is nil") }
            return base
        }
        
        //MARK: Delegate
        public weak var delegate: UITableViewDelegate? {
            set {
                base?.delegate = newValue
            }
            get {
                return base?.delegate
            }
        }
        public weak var dataSource: UITableViewDataSource? {
            set {
                base?.dataSource = newValue
            }
            get {
                return base?.dataSource
            }
        }
        
        //MARK: - reachedBottom
        private lazy var _reachedBottom: Bool = {
            return base.map { $0.contentOffset.y <= 0 } ?? false
        }()
        fileprivate(set) var reachedBottom: Bool {
            set {
                let oldValue = _reachedBottom
                _reachedBottom = newValue
                if _reachedBottom == oldValue { return }
                guard let base = base, _reachedBottom else { return }
                scrollViewDidReachBottom?(base)
            }
            get {
                return _reachedBottom
            }
        }
        public var scrollViewDidReachBottom: ((UIScrollView) -> ())?
        
        //MARK: - reachedTop
        private lazy var _reachedTop: Bool = {
            return base.map { $0.contentOffset.y >= max(0, $0.contentSize.height - $0.bounds.size.height) } ?? false
        }()
        fileprivate(set) var reachedTop: Bool {
            set {
                let oldValue = _reachedTop
                _reachedTop = newValue
                if _reachedTop == oldValue { return }
                guard let base = base, _reachedTop else { return }
                scrollViewDidReachTop?(base)
            }
            get {
                return _reachedTop
            }
        }
        public var scrollViewDidReachTop: ((UIScrollView) -> ())?
        
        private var lastScrollIndicatorInsets: UIEdgeInsets?
        private var lastContentInset: UIEdgeInsets?

        fileprivate lazy var contentInsetObserver: KeyValueObserver? = {
            guard let base = self.base else { return nil }
            let keyPath: String
            if #available(iOS 11, *) {
                keyPath = #keyPath(UITableView.safeAreaInsets)
            } else {
                keyPath = #keyPath(UITableView.contentInset)
            }
            return KeyValueObserver(tareget: base, forKeyPath: keyPath)
        }()
        
        //MARK: - Initializer
        fileprivate init(_ base: UITableView) {
            self.base = base
        }
    }
}
