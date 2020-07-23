// Copyright 2019 Esri.
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

import Foundation
import ArcGIS

fileprivate var simulationGPXFileName: String? = "home2park"

/// UI Interactions and initial setup
extension RouteResultViewController {
    // MARK: Respond to UI interactions to start/stop navigation
    @IBAction func startNavigation(_ sender: Any) {
        startNavigating()
    }

    @IBAction func endNavigation(_ sender: Any) {
        stopNavigating()
    }
    
    // MARK: Set up the app to handle and display navigation progress
    func setupNavigation() {
        MapsAppNotifications.observeReRouteSolvedNotification(owner: self) { [weak self] route in
            // Update the app if the user is re-routed during navigation.
            self?.route = route
        }
        
        if let mapView = mapsAppContext.currentMapView {
            // Make sure the MapView contains the graphics overlays we've created for routing.
            mapView.graphicsOverlays.add(traversedRouteOverlay)
            mapView.graphicsOverlays.add(remainingRouteOverlay)
        }

        MapsAppNotifications.observeModeChangeNotification(owner: self) { [weak self] (oldMode, newMode) in
            // Make sure we stop tracking if the user changes app mode
            if case .routeResult(_) = oldMode {
                // Cancel the route interface
                self?.stopNavigating()
            }
        }
        
        endNavigatingButton.isHidden = true
    }
}

/// Helper Functions
extension RouteResultViewController {
    internal func text(for remainingManeuverDistance: AGSTrackingDistance) -> String {
        return remainingManeuverDistance.displayText + " " +  remainingManeuverDistance.displayTextUnits.abbreviation + "."
    }
    
    internal func text(forDistance remainingDestinationDistance: AGSTrackingDistance, time remainingDestinationTime: Double) -> String {
        return remainingDestinationDistance.displayText + " " + remainingDestinationDistance.displayTextUnits.abbreviation + " ∙ " + (durationFormatter.string(from: remainingDestinationTime*60) ?? "")
    }
    
    internal func manueverIndex(for trackingStatus: AGSTrackingStatus) -> Int{
        // MARK: manage manueverIndex
        if(lastShownManeuverIndex < trackingStatus.currentManeuverIndex) {
            previewNextManuever = false
        }
        let displayManeuverIndex = trackingStatus.currentManeuverIndex + (previewNextManuever ? 1 : 0)
        lastShownManeuverIndex = displayManeuverIndex
        return displayManeuverIndex
    }
    
    internal func updateTrackingGeometries(_ status: AGSTrackingStatus) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            
            self.remainingRouteOverlay.graphics.removeAllObjects()
            self.remainingRouteOverlay.graphics.add(AGSGraphic(geometry: status.routeProgress.remainingGeometry, symbol: nil, attributes: nil))
            
            self.traversedRouteOverlay.graphics.removeAllObjects()
            self.traversedRouteOverlay.graphics.add(AGSGraphic(geometry: status.routeProgress.traversedGeometry, symbol: nil, attributes: nil))
        }
    }
    
    func setupSimulatedGPSifRequired(on mapView: AGSMapView) -> Bool {
        guard UserDefaults.standard.bool(forKey: "simulateGPS") == true else { return false }
        
        guard let currentTracker = currentTracker else { return false }
        
        guard let gpxFileName = simulationGPXFileName else { return false }
        
        //Simulate location based on GPX
        mapView.locationDisplay.stop()
        let gpxDS = AGSGPXLocationDataSource(name: gpxFileName)
        mapView.locationDisplay.dataSource = AGSRouteTrackerLocationDataSource(routeTracker: currentTracker, locationDataSource: gpxDS)
        mapView.locationDisplay.start() { (error) in
            if let error = error {
                print("Error starting GPX location data source! \(error.localizedDescription)")
                return
            }
            print("Started GPX location data source OK.")
        }
        
        return true
    }
}
