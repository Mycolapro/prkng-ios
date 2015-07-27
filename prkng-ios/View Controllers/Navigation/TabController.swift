//
//  PrkTabBarController.swift
//  prkng-ios
//
//  Created by Cagdas Altinkaya on 24/03/15.
//  Copyright (c) 2015 PRKNG. All rights reserved.
//

import UIKit
import QuartzCore


class TabController: GAITrackedViewController, PrkTabBarDelegate, MapViewControllerDelegate, SearchViewControllerDelegate, HereViewControllerDelegate, MyCarNoCheckinViewControllerDelegate, MyCarCheckedInViewControllerDelegate, SettingsViewControllerDelegate, CLLocationManagerDelegate {
    
    var selectedTab : PrkTab
    
    var tabBar : PrkTabBar
    var containerView : UIView
    
    var mapViewController : MapViewController
    
    var searchViewController : SearchViewController?
    var hereViewController : HereViewController
    
    var settingsViewController : SettingsViewController?
    
    var activeViewController : UIViewController
    
    var switchingMainView : Bool
    
    var locationManager = CLLocationManager()
    var locationFixAchieved : Bool = false

    init () {
        selectedTab = PrkTab.None
        tabBar = PrkTabBar()
        containerView = UIView()
        switchingMainView = false
        let useAppleMaps = NSUserDefaults.standardUserDefaults().boolForKey("use_apple_maps")
        mapViewController = useAppleMaps ? MKMapViewController() : RMMapViewController()
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
        self.screenName = "Tab Bar - Controller"
        
        selectedTab = PrkTab.Here
        hereViewController.willMoveToParentViewController(self)
        addChildViewController(hereViewController)
        containerView.addSubview(hereViewController.view)
        tabBar.updateSelected()
        hereViewController.delegate = self
        hereViewController.searchFilterView.delegate = self
        hereViewController.view.snp_makeConstraints { (make) -> () in
            make.edges.equalTo(self.containerView)
        }
        
        if Settings.checkedIn() {
            loadMyCarTab()
        }
        
        setCurrentCityFromUserLocation()
        
    }
    
    func setCurrentCityFromUserLocation() {
        
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.delegate = self
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
            make.height.equalTo(Styles.Sizes.tabbarHeight)
        }
        
        /// child view controllers
        
        mapViewController.view.snp_makeConstraints { (make) -> () in
            make.edges.equalTo(self.containerView)
        }
        
    }
    
    
    func handleTabBadge() {
        
        if Settings.hasNotificationBadge() {
            tabBar.myCarButton.badge.hidden = false
        } else {
            tabBar.myCarButton.badge.hidden = true
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
//        mapViewController.mapView.userTrackingMode = MKUserTrackingMode.None
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
        
        mapViewController.removeSelectedAnnotationIfExists()
        mapViewController.clearSearchResults()
        mapViewController.showUserLocation(true)
        
        switchActiveViewController(hereViewController, completion: { (finished) -> Void in
            self.selectedTab = PrkTab.Here
            self.tabBar.updateSelected()
        })
        
    }
    
    func loadSearchInHereTab() {
        loadHereTab()
        hereViewController.showFilters()
        hereViewController.searchFilterView.makeActive()
    }
    
    
    
    func loadMyCarTab() {
        if (selectedTab == PrkTab.MyCar || switchingMainView) {
            return;
        }

        var myCarViewController : AbstractViewController?
        
        if (Settings.checkedIn()) {
            myCarViewController = MyCarCheckedInViewController()
            (myCarViewController as! MyCarCheckedInViewController).delegate = self
        } else {
            myCarViewController = MyCarNoCheckinViewController()
            (myCarViewController as! MyCarNoCheckinViewController).delegate = self
        }

        let navigationController = UINavigationController(rootViewController: myCarViewController!)
        navigationController.navigationBarHidden = true        

        switchActiveViewController(navigationController, completion: { (finished) -> Void in
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
        
        settingsViewController?.delegate = self
        
        mapViewController.showUserLocation(false)
        mapViewController.trackUser(false)

        let navigationController = UINavigationController(rootViewController: settingsViewController!)
        navigationController.navigationBarHidden = true
        
        switchActiveViewController(navigationController, completion: { (finished) -> Void in
            self.selectedTab = PrkTab.Settings
            self.tabBar.updateSelected()
        })
        
    }
    
    
    func updateMapAnnotations() {
        mapViewController.updateAnnotations()
    }
    
    func switchActiveViewController  (newViewController : UIViewController, completion : ((finished:Bool) -> Void)) {
        
        if switchingMainView {
            return
        }
        
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
        
        updateTabBar()
        
    }
    
    func updateTabBar() {
        
        handleTabBadge()
    }
    
    func showLoginViewController ()  {
        let loginViewController = LoginViewController()
        presentViewController(loginViewController, animated: true) { () -> Void in
            
        }
    }
    
    
    // MapViewControllerDelegate
    func mapDidDismissSelection() {
        
//        if(selectedTab == PrkTab.Search) {
//            searchViewController?.transformToStepTwo()
//            
//            SearchOperations.getStreetName(center.coordinate, completion: { (result) -> Void in
//                searchViewController?.showStreetName(result)
//            })
//        } else if (selectedTab == PrkTab.Here) {
            hereViewController.updateSpotDetails(nil)
            hereViewController.hideFilters(alsoHideFilterButton: false)
//        }
                
    }
    
    func didSelectSpot (spot : ParkingSpot) {
        
        loadHereTab()
        hereViewController.updateSpotDetails(spot)
        
    }
    
    func shouldShowUserTrackingButton() -> Bool {
        return selectedTab == PrkTab.Here
    }
    
    func showMapMessage(message: String?) {

        if message != nil {
            hereViewController.mapMessageLabel.text = message
        }
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.hereViewController.mapMessageView.alpha = message == nil ? 0 : 1
        })
    }
    
    func activeFilterDuration() -> Float? {
        if self.activeFilterPermit() {
            return 24
        }
        var hours = hereViewController.timeFilterView.selectedValueInHours()
        return hours
    }
    
    func activeFilterPermit() -> Bool {
//        return hereViewController.timeFilterView.selectedPermitValue
        return Settings.shouldFilterForCarSharing()
    }
    
    
    // MARK: SearchViewControllerDelegate
    
    func setSearchParameters(time : NSDate?, duration : Float?) {
        mapViewController.searchCheckinDate = time
        mapViewController.searchDuration = duration
    }

    
    func displaySearchResults(results : Array<SearchResult>, checkinTime : NSDate?) {
        mapViewController.trackUser(false)
        mapViewController.displaySearchResults(results, checkinTime: checkinTime)
    }
    
    func clearSearchResults() {
        mapViewController.clearSearchResults()
    }
    
    // MARK: MyCarNoCheckinViewControllerDelegate
    
    
    // MARK : MyCarCheckedInViewControllerDelegate
    
    func reloadMyCarTab() {
        
        mapViewController.showUserLocation(false)
        mapViewController.trackUser(false)
        
        
        var myCarViewController : AbstractViewController?
        
        if (Settings.checkedIn()) {
            myCarViewController = MyCarCheckedInViewController()
            (myCarViewController as! MyCarCheckedInViewController).delegate = self
        } else {
            myCarViewController = MyCarNoCheckinViewController()
            (myCarViewController as! MyCarNoCheckinViewController).delegate = self
        }
        
        let navigationController = UINavigationController(rootViewController: myCarViewController!)
        navigationController.navigationBarHidden = true
        
        switchActiveViewController(navigationController, completion: { (finished) -> Void in
            self.selectedTab = PrkTab.MyCar
            self.tabBar.updateSelected()
        })
        
    }
    
    func showSpotOnMap(spot: ParkingSpot) {
        let coordinate = spot.buttonLocation.coordinate
        let name = spot.name
        goToCoordinate(coordinate, named: name)
    }

    
    // MARK: SettingsViewControllerDelegate
    
    func goToCoordinate(coordinate: CLLocationCoordinate2D, named name: String) {
        loadHereTab()
        self.mapViewController.trackUser(false)
        self.mapViewController.goToCoordinate(coordinate, named:name)
    }
    
    func cityDidChange(#fromCity: Settings.City, toCity: Settings.City) {
        let coordinate = Settings.selectedCityPoint()
        self.mapViewController.goToCoordinate(coordinate, named:Settings.selectedCity().rawValue, withZoom:13)
    }
    
    // MARK: Location Manager Delegate stuff
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if (locationFixAchieved == false) {
            locationFixAchieved = true
            var location = locations.last as! CLLocation
            var coord = location.coordinate
            
            println(coord.latitude)
            println(coord.longitude)
            
            manager.stopUpdatingLocation()
            
            Settings.setClosestSelectedCity(coord)
        }
    }
    
    func locationManager(manager: CLLocationManager!,
        didChangeAuthorizationStatus status: CLAuthorizationStatus) {
            
            var locationStatus : NSString = "Not Started"
            
            var shouldIAllow = false
            
            switch status {
            case CLAuthorizationStatus.Restricted:
                locationStatus = "Restricted Access to location"
            case CLAuthorizationStatus.Denied:
                locationStatus = "User denied access to location"
            case CLAuthorizationStatus.NotDetermined:
                locationStatus = "Status not determined"
            default:
                locationStatus = "Allowed to location Access"
                shouldIAllow = true
            }
            NSNotificationCenter.defaultCenter().postNotificationName("LabelHasbeenUpdated", object: nil)
            if (shouldIAllow == true) {
                NSLog("Location to Allowed")
                // Start location services
                locationManager.startUpdatingLocation()
            } else {
                NSLog("Denied access: \(locationStatus)")
            }
    }


}


enum PrkTab {
//    case Search
    case MyCar
    case Here
    case Settings
    case None
}