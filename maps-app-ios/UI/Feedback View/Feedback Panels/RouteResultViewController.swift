// Copyright 2017 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import ArcGIS

public var simulationGPXFileName: String? = nil

class RouteResultViewController : UIViewController, AGSRouteTrackerDelegate {
    
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    var previewNextManuever = false
    var displayManueverIndex = 0
    var traversedRouteOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.renderer = AGSSimpleRenderer(symbol: AGSSimpleLineSymbol(style: .solid, color: .gray, width: 5))
        return overlay
    }()
    var remainingRouteOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        let remainingSymbol: AGSSymbol = {
            if let symbol = Bundle.main.agsSymbolFromJSON(resourceNamed: "DirectionsManeuverSymbol") {
                return symbol
            }
            
            print("Returning fallback maneuver symbol")
            let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.orange.withAlphaComponent(0.9), width: 8)
            let backingSymbol = AGSSimpleLineSymbol(style: .solid, color: UIColor.white.withAlphaComponent(0.6), width: 13)
            return AGSCompositeSymbol(symbols: [backingSymbol, lineSymbol])
        }()
        overlay.renderer = AGSSimpleRenderer(symbol: remainingSymbol)
        return overlay
    }()
    
    var prevManueverIndex = 0
    var route:AGSRoute? {
        didSet {
            // Here we want to set the route results.
            if let result = route {
                if let from = result.stops.first {
                    self.fromLabel.text = from.name
                }
                
                if let to = result.stops.last {
                    self.toLabel.text = to.name
                }
                
                let time = durationFormatter.string(from: result.totalTime*60) ?? ""
                
                let distance = distanceFormatter.string(from: Measurement(value: result.totalLength, unit: UnitLength.meters))
                
                self.summaryLabel.text = "\(distance) ∙ \(time)"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MapsAppNotifications.observeRouteSolvedNotification(owner: self) { [weak self] route in
            self?.route = route
        }
        
        MapsAppNotifications.observeModeChangeNotification(owner: self) { [weak self] (oldMode, newMode) in
            switch (oldMode) {
            case .routeResult(_):
                // Cancel the route interface
                self?.stopTracking()
            default:
                print("No need to cancel the tracking")
            }
        }

        currentTracker = nil
    }
    
    deinit {
        stopTracking()
        
        MapsAppNotifications.deregisterNotificationBlocks(forOwner: self)
    }
    
    @IBAction func summaryTapped(_ sender: Any) {
        MapsAppNotifications.postMapViewResetExtentForModeNotification()
    }
    
    private lazy var durationFormatter:DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute]
        formatter.allowsFractionalUnits = false
        return formatter
    }()
    
    private lazy var distanceFormatter:MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .long
        formatter.numberFormatter.numberStyle = .decimal
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()
    
    func stopTracking() {
        remainingRouteOverlay.graphics.removeAllObjects()
        traversedRouteOverlay.graphics.removeAllObjects()
        
        remainingRouteOverlay.isVisible = false
        traversedRouteOverlay.isVisible = false

        currentTracker?.delegate = nil
        currentTracker = nil

        if let mapView = mapsAppContext.currentMapView {
//            mapView.locationDisplay.stop()
//            mapView.locationDisplay.dataSource = AGSCLLocationDataSource()
            mapView.locationDisplay.locationChangedHandler = nil
//            mapView.locationDisplay.start { (error) in
//                if let error = error {
//                    print("Error starting the location display: \(error)")
//                }
//            }
        }
        
        MapsAppNotifications.postNavigationEnded()
        
        print("Tracking Ended")
    }
    
    @IBOutlet weak var navigateButton: RoundedButton!
    @IBOutlet weak var endNavigatingButton: RoundedButton!
    var currentTracker: AGSRouteTracker? {
        didSet {
            navigateButton.isHidden = currentTracker != nil
            endNavigatingButton.isHidden = !navigateButton.isHidden
        }
    }
    let synth = AVSpeechSynthesizer()
    
    @IBAction func endNavigation(_ sender: Any) {
        stopTracking()
    }

    @IBAction func navigate(_ sender: Any) {
        guard let mapView = mapsAppContext.currentMapView,
            let routeResult = mapsAppContext.routeResult else {
                return
        }
        
        //Setup route tracker
        currentTracker = AGSRouteTracker(routeResult: routeResult, routeIndex: 0)
        if let currentTracker = currentTracker {
            
            prevManueverIndex = 0
            
            currentTracker.voiceGuidanceUnitSystem = .imperial
            currentTracker.delegate = self
            
            if let defaultParams = reroutingParameters {
                currentTracker.enableRerouting(with: arcGISServices.routeTask, routeParameters: defaultParams,
                                             strategy: AGSReroutingStrategy.toNextStop,
                                             visitFirstStopOnStart: false) { error in
                                                if let error = error {
                                                    print("Error requesting rerouting: \(error)")
                                                } else {
                                                    print("Rerouting enabled OK")
                                                }
                }
            }
            
            if let gpxFileName = simulationGPXFileName {
                //Simulate location based on GPX
                mapView.locationDisplay.stop()
                mapView.locationDisplay.autoPanMode = .navigation
                let gpxDS = AGSGPXLocationDataSource(name: gpxFileName)
                mapView.locationDisplay.dataSource = gpxDS
                mapView.locationDisplay.start(completion: nil)
            } else {
                if !(mapView.locationDisplay.dataSource is AGSCLLocationDataSource) {
                    mapView.locationDisplay.dataSource = AGSCLLocationDataSource()
                }
                mapView.locationDisplay.start(completion: nil)
            }

            if let guidance = currentTracker.generateVoiceGuidance() {
                speakText(text: guidance.text)
            }

            //For location updates....
            mapView.locationDisplay.locationChangedHandler = { [weak self]
                newLocation in
                
                DispatchQueue.main.async {
                    guard let mapView = mapsAppContext.currentMapView else { return }

                    if mapView.locationDisplay.autoPanMode != AGSLocationDisplayAutoPanMode.navigation {
                        if let position = newLocation.position {
                            mapView.setViewpoint(AGSViewpoint(center: position, scale: 5000))
                        }
                        mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanMode.navigation
                    }
                    
                    //update route tracker
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        self?.currentTracker?.trackLocation(newLocation, completion: nil)
                    }
                }
            }
            
            if !mapView.graphicsOverlays.contains(traversedRouteOverlay) {
                mapView.graphicsOverlays.add(traversedRouteOverlay)
            }
            if !mapView.graphicsOverlays.contains(remainingRouteOverlay) {
                mapView.graphicsOverlays.add(remainingRouteOverlay)
            }
            
            remainingRouteOverlay.isVisible = true
            traversedRouteOverlay.isVisible = true
            
            MapsAppNotifications.postNavigationStarted()
        }
    }
    
    //AGSRouteTrackerDelegate
    
    //Handle route tracker updates to refresh Manuever & Destination display
    func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
        
        //Update Manuever display (direction & distance)
        let maneuverDistance = trackingStatus.maneuverProgress.remainingDistance
        let displayManueverIndex = manueverIndex(for: trackingStatus)
        MapsAppNotifications.postNextManeuverNotification(manueverIndex: IndexPath(row: displayManueverIndex, section: 0), text:text(for:maneuverDistance))
        
        
        //Update Destination display (distance & time)
        let remainingDestDistance = trackingStatus.routeProgress.remainingDistance
        let remainingDestTime = trackingStatus.routeProgress.remainingTime
        self.summaryLabel.text = text(forDistance:remainingDestDistance,time: remainingDestTime)
        
        //gray out the travelled route
        updateTrackingGeometries(trackingStatus)
        
        if trackingStatus.destinationStatus == .reached {
            print("ROUTE COMPLETE!")
            speakText(text: "Navigation complete")
            stopTracking()
        }
    }
    
    func speakText(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch {
            print("Unable to set audio session: \(error.localizedDescription)")
        }
        synth.speak(utterance)
    }
    
    //Speak voice guidance provided by route tracker
    func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
        print("Goto new voice guidance: \"\(voiceGuidance.text)\"")
        
        speakText(text: voiceGuidance.text)
        
        //Manage display of approaching manuever
        if(voiceGuidance.type == .approachingManeuver) {
            previewNextManuever = true
        }
        
        if let trackingStatus = routeTracker.trackingStatus {
            let maneuverDistance = trackingStatus.maneuverProgress.remainingDistance
            let displayManueverIndex = manueverIndex(for: trackingStatus)
            MapsAppNotifications.postNextManeuverNotification(manueverIndex: IndexPath(row: displayManueverIndex, section: 0), text:text(for:maneuverDistance))
        }
    }
    
    //handle re-routing
    func routeTrackerRerouteDidStart(_ routeTracker: AGSRouteTracker) {
        print("Rerouting…")
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, rerouteDidCompleteWith trackingStatus: AGSTrackingStatus?, error: Error?) {
        print("Rerouted OK…")
        
        if let newRoute = trackingStatus?.routeResult.routes.first {
            self.route = newRoute
            (self.remainingRouteOverlay.graphics.firstObject as? AGSGraphic)?.geometry = trackingStatus?.routeProgress.remainingGeometry
        }
    }
    
    fileprivate func text(for remainingManeuverDistance: AGSTrackingDistance) -> String {
        return remainingManeuverDistance.displayText + " " +  remainingManeuverDistance.displayTextUnits.abbreviation + "."
    }
    
    fileprivate func text(forDistance remainingDestinationDistance: AGSTrackingDistance, time remainingDestinationTime: Double) -> String {
        return remainingDestinationDistance.displayText + " " + remainingDestinationDistance.displayTextUnits.abbreviation + " ∙ " + (durationFormatter.string(from: remainingDestinationTime*60) ?? "")
    }
    
    fileprivate func manueverIndex(for trackingStatus: AGSTrackingStatus) -> Int{
        // MARK: manage manueverIndex
        if(self.prevManueverIndex < trackingStatus.currentManeuverIndex){
            self.previewNextManuever = false
        }
        let displayManueverIndex = trackingStatus.currentManeuverIndex + (self.previewNextManuever ? 1 : 0)
        self.prevManueverIndex = displayManueverIndex
        return displayManueverIndex
    }
    
    fileprivate func updateTrackingGeometries(_ status: AGSTrackingStatus) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            
            self.remainingRouteOverlay.graphics.removeAllObjects()
            self.remainingRouteOverlay.graphics.add(AGSGraphic(geometry: status.routeProgress.remainingGeometry, symbol: nil, attributes: nil))
            
            self.traversedRouteOverlay.graphics.removeAllObjects()
            self.traversedRouteOverlay.graphics.add(AGSGraphic(geometry: status.routeProgress.traversedGeometry, symbol: nil, attributes: nil))
        }
    }

}

// MARK: External Notification API
extension MapsAppNotifications {
    static func observeNavigationStarted(owner:Any, handler:@escaping ()->Void) {
        let ref = NotificationCenter.default.addObserver(forName: MapsAppNotifications.Names.navigationStarted, object: mapsApp, queue: OperationQueue.main) { notification in
            handler()
        }
        MapsAppNotifications.registerBlockHandler(blockHandler: ref, forOwner: owner)
    }

    static func observeNavigationEnded(owner:Any, handler:@escaping ()->Void) {
        let ref = NotificationCenter.default.addObserver(forName: MapsAppNotifications.Names.navigationEnded, object: mapsApp, queue: OperationQueue.main) { notification in
            handler()
        }
        MapsAppNotifications.registerBlockHandler(blockHandler: ref, forOwner: owner)
    }
}

// MARK: Internals
extension MapsAppNotifications {
    static func postNavigationStarted() {
        NotificationCenter.default.post(name: MapsAppNotifications.Names.navigationStarted, object: mapsApp, userInfo: nil)
    }

    static func postNavigationEnded() {
        NotificationCenter.default.post(name: MapsAppNotifications.Names.navigationEnded, object: mapsApp, userInfo: nil)
    }
}

// MARK: Typed Notification Pattern
extension MapsAppNotifications.Names {
    static let navigationStarted = NSNotification.Name("MapsAppNavigationStarted")
    static let navigationEnded = NSNotification.Name("MapsAppNavigationEnded")
}
