//
//  PrkTabBarController.swift
//  prkng-ios
//
//  Created by Cagdas Altinkaya on 24/03/15.
//  Copyright (c) 2015 PRKNG. All rights reserved.
//

import UIKit
import QuartzCore


class TabController: UIViewController, PrkTabBarDelegate, MapViewControllerDelegate, SearchViewControllerDelegate, HereViewControllerDelegate, MyCarNoCheckinViewControllerDelegate, MyCarCheckedInViewControllerDelegate {
    
    var selectedTab : PrkTab
    
    var tabBar : PrkTabBar
    var containerView : UIView
    
    var mapViewController : MapViewController
    
    var searchViewController : SearchViewController?
    var hereViewController : HereViewController
    
    var settingsViewController : SettingsViewController?
    
    var activeViewController : AbstractViewController
    
    var switchingMainView : Bool
    
    
    init () {
        selectedTab = PrkTab.None
        tabBar = PrkTabBar()
        containerView = UIView()
        switchingMainView = false
        mapViewController = MapViewController()
        hereViewController = HereViewController()
        activeViewController = hereViewController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func loadView() {
        self.view = UIView()
        
        setupViews()
        setupConstraints()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        
        selectedTab = PrkTab.Here
        hereViewController.willMoveToParentViewController(self)
        addChildViewController(hereViewController)
        containerView.addSubview(hereViewController.view)
        tabBar.updateSelected()
        hereViewController.delegate = self
        hereViewController.searchDelegate = self
        hereViewController.view.snp_makeConstraints { (make) -> () in
            make.edges.equalTo(self.containerView)
        }
        
    }
    
    func setupViews() {
        
        containerView.clipsToBounds = true
        view.addSubview(containerView)

        mapViewController.delegate = self
        addChildViewController(mapViewController)
        mapViewController.willMoveToParentViewController(self)
        containerView.addSubview(mapViewController.view)
        
        tabBar.delegate = self
        tabBar.backgroundColor = Styles.Colors.stone
        tabBar.layer.shadowColor = UIColor.blackColor().CGColor
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -0.5)
        tabBar.layer.shadowOpacity = 0.2
        tabBar.layer.shadowRadius = 0.5
        view.addSubview(tabBar)
    }
    
    func setupConstraints() {
        
        containerView.snp_makeConstraints { (make) -> () in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.tabBar.snp_top)
        }
        
        tabBar.snp_makeConstraints { (make) -> () in
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
            make.height.equalTo(71)
        }
        
        /// child view controllers
        
        mapViewController.view.snp_makeConstraints { (make) -> () in
            make.edges.equalTo(self.containerView)
        }
        
    }
    
    
    // PrkTabBarDelegate
    
    func activeTab() -> PrkTab {
        return selectedTab
    }
//    
//    func loadSearchTab() {
//        if (selectedTab == PrkTab.Search || switchingMainView) {
//            return;
//        }
//                
//        if (searchViewController == nil) {
//            searchViewController = SearchViewController()
//            searchViewController!.delegate = self
//        }
//        
//        searchViewController!.markerIcon.hidden = false
//        mapViewController.mapView.zoom = 17
//        mapViewController.trackUserButton.hidden = true
//        mapViewController.mapView.showsUserLocation = false
//        mapViewController.mapView.userTrackingMode = RMUserTrackingModeNone
//        
//        
//        switchActiveViewController(searchViewController!, completion: { (finished) -> Void in
//            self.selectedTab = PrkTab.Search
//            self.tabBar.updateSelected()
//        })
//        
//        
//    }
    
    func loadHereTab() {
        if (selectedTab == PrkTab.Here || switchingMainView) {
            return;
        }
        
        mapViewController.clearSearchResults()
        mapViewController.mapView.showsUserLocation = true
        mapViewController.mapView.userTrackingMode = RMUserTrackingModeFollowWithHeading
        
        switchActiveViewController(hereViewController, completion: { (finished) -> Void in
            self.selectedTab = PrkTab.Here
            self.tabBar.updateSelected()
        })
        
    }
    
    
    
    func loadMyCarTab() {
        if (selectedTab == PrkTab.MyCar || switchingMainView) {
            return;
        }
        
        mapViewController.mapView.showsUserLocation = false
        mapViewController.mapView.userTrackingMode = RMUserTrackingModeNone
        

        var myCarViewController : AbstractViewController?
        
        if (Settings.checkedIn()) {
            myCarViewController = MyCarCheckedInViewController()
            (myCarViewController as! MyCarCheckedInViewController).delegate = self
        } else {
            myCarViewController = MyCarNoCheckinViewController()
            (myCarViewController as! MyCarNoCheckinViewController).delegate = self
        }

        
        switchActiveViewController(myCarViewController!, completion: { (finished) -> Void in
            self.selectedTab = PrkTab.MyCar
            self.tabBar.updateSelected()
        })
        
    }
    
    func loadSettingsTab() {
        if (selectedTab == PrkTab.Settings || switchingMainView) {
            return;
        }
        
        if(settingsViewController == nil) {
            settingsViewController = SettingsViewController()
        }
        
        mapViewController.mapView.showsUserLocation = false
        mapViewController.mapView.userTrackingMode = RMUserTrackingModeNone
        
        switchActiveViewController(settingsViewController!, completion: { (finished) -> Void in
            self.selectedTab = PrkTab.Settings
            self.tabBar.updateSelected()
        })
        
    }
    
    
    func switchActiveViewController  (newViewController : AbstractViewController, completion : ((finished:Bool) -> Void)) {
        
        if switchingMainView {
            return
        }
        
        mapViewController.updateMapCenterIfNecessary()
        
        switchingMainView = true
        newViewController.view.alpha = 0.0;
        newViewController.willMoveToParentViewController(self)
        addChildViewController(newViewController)
        containerView.addSubview(newViewController.view)
        
        newViewController.view.snp_remakeConstraints({ (make) -> () in
            make.edges.equalTo(self.containerView)
        })
        
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.activeViewController.view.alpha = 0.0
            newViewController.view.alpha = 1.0
            
            }) { (finished) -> Void in
                self.activeViewController.removeFromParentViewController()
                self.activeViewController.view.removeFromSuperview()
                self.activeViewController.willMoveToParentViewController(nil)
                self.activeViewController = newViewController
                self.switchingMainView = false
                completion(finished: finished)
        }
        
    }
    
    func updateTabBar() {
        
    }
    
    func showLoginViewController ()  {
        let loginViewController = LoginViewController()
        presentViewController(loginViewController, animated: true) { () -> Void in
            
        }
    }
    
    
    // MapViewControllerDelegate
    func mapDidMove (center : CLLocation) {
        
//        if(selectedTab == PrkTab.Search) {
//            searchViewController?.transformToStepTwo()
//            
//            SearchOperations.getStreetName(center.coordinate, completion: { (result) -> Void in
//                searchViewController?.showStreetName(result)
//            })
//        } else if (selectedTab == PrkTab.Here) {
            hereViewController.hideSpotDetails()
//        }
        
    }
    
    func didSelectSpot (spot : ParkingSpot) {
        
        hereViewController.activeSpot = spot
        loadHereTab()
        hereViewController.showSpotDetails()
        
    }
    
    func shouldShowUserTrackingButton() -> Bool {
        return selectedTab == PrkTab.Here
    }
    
    
    // MARK: SearchViewControllerDelegate
    
    func setSearchParameters(time : NSDate?, duration : Float?) {
        mapViewController.searchCheckinDate = time
        mapViewController.searchDuration = duration
    }

    
    func displaySearchResults(results : Array<SearchResult>, checkinTime : NSDate?) {
        mapViewController.mapView.userTrackingMode = RMUserTrackingModeNone
        mapViewController.displaySearchResults(results, checkinTime: checkinTime)
    }
    
    func clearSearchResults() {
        mapViewController.clearSearchResults()
    }
    
    // MARK: MyCarNoCheckinViewControllerDelegate
    
    
    // MARK : MyCarCheckedInViewControllerDelegate
    
    func reloadMyCarTab() {
        
        mapViewController.mapView.showsUserLocation = false
        mapViewController.mapView.userTrackingMode = RMUserTrackingModeNone
        
        
        var myCarViewController : AbstractViewController?
        
        if (Settings.checkedIn()) {
            myCarViewController = MyCarCheckedInViewController()
            (myCarViewController as! MyCarCheckedInViewController).delegate = self
        } else {
            myCarViewController = MyCarNoCheckinViewController()
            (myCarViewController as! MyCarNoCheckinViewController).delegate = self
        }
        
        switchActiveViewController(myCarViewController!, completion: { (finished) -> Void in
            self.selectedTab = PrkTab.MyCar
            self.tabBar.updateSelected()
        })
        
    }

}


enum PrkTab {
//    case Search
    case MyCar
    case Here
    case Settings
    case None
}