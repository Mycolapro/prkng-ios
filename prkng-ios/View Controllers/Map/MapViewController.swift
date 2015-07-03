//
//  MapViewController.swift
//  prkng-ios
//
//  Created by Antonino Urbano on 2015-06-11.
//  Copyright (c) 2015 PRKNG. All rights reserved.
//

import UIKit

class MapViewController: AbstractViewController {

    var delegate: MapViewControllerDelegate?
    
    var searchCheckinDate : NSDate?
    var searchDuration : Float?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func displaySearchResults(results: Array<SearchResult>, checkinTime : NSDate?) { }
    func clearSearchResults() { }
    func showUserLocation(shouldShow: Bool) { }
    func trackUser(shouldTrack: Bool) { }
    func updateAnnotations() { }

    //shows a checkin on the map as a regular marker
    func goToCoordinate(coordinate: CLLocationCoordinate2D, named name: String, withZoom zoom:Float? = nil) { }
    
    func removeSelectedAnnotationIfExists() { }

    
    
    func getAndDownloadCityOverlays() -> [MKPolygon] {
        
//        let offlineUrl = NSBundle.mainBundle().pathForResource("AvailabilityMap", ofType: "json")
//
//        let url = APIUtility.APIConstants.rootURLString + "areas"
//        request(.GET, url, parameters: nil).responseSwiftyJSON {
//            (request, response, json, error) in
//            
//            if response?.statusCode < 400 && error == nil {
//                var errorPointer = NSErrorPointer()
//                var jsonData = NSJSONSerialization.dataWithJSONObject(json.object, options: NSJSONWritingOptions.PrettyPrinted, error: errorPointer)
//                jsonData?.writeToFile(offlineUrl!, atomically: true)
//            }
//        }
//
//        let overlays = GeoJsonParser.overlaysFromFilePath(offlineUrl) as! [MKPolygon]
//        return overlays
        
        if let url = NSBundle.mainBundle().URLForResource("AvailabilityMap", withExtension: "json") {
            var data = NSData(contentsOfURL: url)
            var errorPointer = NSErrorPointer()
            var json = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: errorPointer) as! [NSObject : AnyObject]
            
            if let overlays = GeoJSONSerialization.shapesFromGeoJSONFeatureCollection(json, error: nil) as? [MKPolygon] {
                return overlays
            }
        }

        return []
    }

}

protocol MapViewControllerDelegate {
    
    func mapDidDismissSelection()
    
    func didSelectSpot(spot: ParkingSpot)
    
    func shouldShowUserTrackingButton() -> Bool
    
    //returns the number of hours to search for as a minimum parking duration
    func activeFilterDuration() -> Float?
    
}