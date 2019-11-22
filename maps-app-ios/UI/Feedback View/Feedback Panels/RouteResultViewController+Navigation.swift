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

/// Navigation Logic
extension RouteResultViewController {
    func startNavigating() {
        guard let mapView = mapsAppContext.currentMapView,
            let routeResult = mapsAppContext.routeResult else {
                return
        }
        
        //Setup route tracker from the current route result, if possible
        guard let currentTracker = AGSRouteTracker(routeResult: routeResult, routeIndex: 0) else { return }

        // Hold on to the tracker
        self.currentTracker = currentTracker
        
        // Configure the tracker
        currentTracker.voiceGuidanceUnitSystem = .imperial
        
        if let reroutingParameters = lastRouteParameters {
            currentTracker.enableRerouting(with: arcGISServices.routeTask, routeParameters: reroutingParameters,
                                           strategy: AGSReroutingStrategy.toNextStop,
                                           visitFirstStopOnStart: false) { error in
                                            if let error = error {
                                                print("Error requesting rerouting: \(error)")
                                            } else {
                                                print("Rerouting enabled OK")
                                            }
            }
        }

        if !setupSimulatedGPSifRequired(on: mapView) {
            mapView.locationDisplay.dataSource = NavigationLocationDataSource(routeTracker: currentTracker, baseLocationDataSource: AGSCLLocationDataSource())
            mapView.locationDisplay.start(completion: nil)
        }
        
        mapView.locationDisplay.autoPanMode = .navigation
        
        (mapView.locationDisplay.dataSource as? NavigationLocationDataSource)?.delegate = self
        
        // Optional: make sure that while we're navigating, we lock the Location Display navigation mode.
        mapView.locationDisplay.autoPanModeChangedHandler = { [weak mapView] newMode in
            if let locationDisplay = mapView?.locationDisplay,
                let status = (locationDisplay.dataSource as? NavigationLocationDataSource)?.routeTracker.trackingStatus?.destinationStatus,
                status != .reached,
                locationDisplay.autoPanMode != .navigation {
                    mapView?.setViewpointScale(5000)
                    locationDisplay.autoPanMode = .navigation
            }
        }
        
        remainingRouteOverlay.isVisible = true
        traversedRouteOverlay.isVisible = true

        lastShownManeuverIndex = 0
        
        MapsAppNotifications.postNavigationStarted()
    }

    func stopNavigating() {
        // Clean up the current tracker
        currentTracker?.delegate = nil
        currentTracker = nil
        
        if let mapView = mapsAppContext.currentMapView {
            // Stop resetting the location display mode to .navigation
            mapView.locationDisplay.autoPanModeChangedHandler = nil
            mapView.locationDisplay.autoPanMode = .recenter

            // Restore the location data source
            if let navigationLocationDataSource = mapView.locationDisplay.dataSource as? NavigationLocationDataSource {
                mapView.locationDisplay.stop()
                mapView.locationDisplay.dataSource = navigationLocationDataSource.baseLocationDataSource
                mapView.locationDisplay.start { error in
                    if let error = error {
                        print("Error restarting location display: \(error.localizedDescription)")
                    }
                }
            }
        }

        // Clear up graphics overlays for navigation
        remainingRouteOverlay.graphics.removeAllObjects()
        traversedRouteOverlay.graphics.removeAllObjects()
        remainingRouteOverlay.isVisible = false
        traversedRouteOverlay.isVisible = false
        
        // Declare that we've ended navigating.
        MapsAppNotifications.postNavigationEnded()
        
        synth.stopSpeaking(at: .word)
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
}
