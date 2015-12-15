//
//  UIViewControllerExtension.swift
//  UnfoldingWord
//
//  Created by David Solberg on 7/21/15.
//  Copyright (c) 2015 Acts Media Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func addChildViewController(childVC : UIViewController, toView view : UIView) {
        
        childVC.willMoveToParentViewController(self)
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childVC.view)
        let constraints = NSLayoutConstraint.constraintsForView(childVC.view, insideView: view, topMargin: 0, bottomMargin: 0, leftMargin: 0, rightMargin: 0)
        view.addConstraints(constraints)
        self.addChildViewController(childVC)
        childVC.didMoveToParentViewController(self)
    }
}