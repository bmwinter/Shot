//
//  ShotTestRootController.swift
//  Shot
//
//  Created by Brendan Winter on 11/7/16.
//  Copyright © 2016 TechFi Apps. All rights reserved.
//

import UIKit
import Material

class ShotPageTabBarController: PageTabBarController {
    
    //private lazy var buttons = [Button]()
    //private var tabBar: TabBar!
    
    open override func prepare() {
        super.prepare()
        
        delegate = self
        preparePageTabBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
      
    }
    
    private func preparePageTabBar() {
        pageTabBar.dividerColor = Color.grey.lighten3
        pageTabBar.dividerAlignment = .bottom
        pageTabBar.dividerThickness = 0
        
        pageTabBar.lineColor = Color.white
        pageTabBar.lineAlignment = .bottom
        
        let grayColor = UIColor(red: 38/255, green: 35/255, blue: 36/255, alpha: 1)
        pageTabBar.backgroundColor = grayColor

        //view.layout(pageTabBar).horizontally().top()
        pageTabBarAlignment = PageTabBarAlignment.top
    }
    
}


extension ShotPageTabBarController
: PageTabBarControllerDelegate {
    func pageTabBarController(pageTabBarController: PageTabBarController, didTransitionTo viewController: UIViewController) {
        
        //print("pageTabBarController", pageTabBarController, "didTransitionTo viewController:", viewController)
    }
}

