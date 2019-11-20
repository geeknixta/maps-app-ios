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

class RouteResultViewController : UIViewController {
    
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    var displayManueverIndex = 0
    
    lazy var durationFormatter:DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute]
        formatter.allowsFractionalUnits = false
        return formatter
    }()
    
    lazy var distanceFormatter:MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.unitStyle = .long
        formatter.numberFormatter.numberStyle = .decimal
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()
    
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
    
    // MARK: Navigation API properties
    var currentTracker: AGSRouteTracker? = nil {
        didSet {
            navigateButton.isHidden = currentTracker != nil
            endNavigatingButton.isHidden = !navigateButton.isHidden
            reroutingActivityView.stopAnimating()
        }
    }
    
    let synth = AVSpeechSynthesizer()

    // MARK: Navigation Map Feedback
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
    
    // MARK: Navigation UI properties
    @IBOutlet weak var navigateButton: RoundedButton!
    @IBOutlet weak var endNavigatingButton: RoundedButton!
    
    var previewNextManuever = false
    var lastShownManeuverIndex = 0

    @IBOutlet weak var reroutingActivityView: UIActivityIndicatorView!
    var rerouteActivityViewMinDismissTime: DispatchTime?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MapsAppNotifications.observeRouteSolvedNotification(owner: self) { [weak self] route in
            self?.route = route
        }

        setupNavigation()
    }
    
    deinit {
        stopNavigating()
        
        if let mapView = mapsAppContext.currentMapView {
            mapView.graphicsOverlays.remove(traversedRouteOverlay)
            mapView.graphicsOverlays.remove(remainingRouteOverlay)
        }

        MapsAppNotifications.deregisterNotificationBlocks(forOwner: self)
    }
    
    @IBAction func summaryTapped(_ sender: Any) {
        MapsAppNotifications.postMapViewResetExtentForModeNotification()
    }
}
