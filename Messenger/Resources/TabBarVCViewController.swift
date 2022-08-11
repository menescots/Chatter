//
//  TabBarVCViewController.swift
//  Messenger
//
//  Created by Agata Menes on 04/08/2022.
//

import UIKit

class TabBarVCViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.backgroundColor = UIColor(named: "tabbarColor")
        ChangeRadiusOfTabbar()
    }
    
    func ChangeRadiusOfTabbar(){
        self.tabBar.layer.masksToBounds = true
        self.tabBar.isTranslucent = true
        self.tabBar.layer.cornerRadius = 35
        self.tabBar.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //ChangeHeightOfTabbar()
    }

//    func ChangeHeightOfTabbar(){
//        if UIDevice().userInterfaceIdiom == .phone {
//            var tabFrame            = tabBar.frame
//            tabFrame.size.height    = 60
//            tabFrame.origin.y       = view.frame.size.height - 60
//            tabBar.frame            = tabFrame
//        }
//
//    }
}
