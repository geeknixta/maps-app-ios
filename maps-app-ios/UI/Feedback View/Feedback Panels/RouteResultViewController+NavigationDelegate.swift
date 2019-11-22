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

/// Route Tracker Delegate
extension RouteResultViewController: AGSRouteTrackerDelegate {
    // Handle updates to the Route Tracker status
    func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
        
        // Update UI to show distance to next maneuver
        let maneuverDistance = trackingStatus.maneuverProgress.remainingDistance
        let displayManueverIndex = manueverIndex(for: trackingStatus)
        MapsAppNotifications.postNextManeuverNotification(manueverIndex: IndexPath(row: displayManueverIndex, section: 0), text:text(for:maneuverDistance))
        
        // Update UI to show overall remaining time and distance
        let remainingDestDistance = trackingStatus.routeProgress.remainingDistance
        let remainingDestTime = trackingStatus.routeProgress.remainingTime
        summaryLabel.text = text(forDistance:remainingDestDistance,time: remainingDestTime)
        
        // Update the remaining and traveled geometries on the map
        updateTrackingGeometries(trackingStatus)
        
        // Stop navigating if we've arrived
        if trackingStatus.destinationStatus == .reached {
            print("ROUTE COMPLETE!")
            stopNavigating()
            speakText(text: "You have reached your destination")
        }
    }
    
    // Speak voice guidance as it's provided by the Route Tracker
    func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
        print("Goto new voice guidance: \"\(voiceGuidance.text)\"")
        
        // Speak the maneuver to the user
        speakText(text: voiceGuidance.text)
        
        // Update UI to display upcoming maneuver if need be
        if(voiceGuidance.type == .approachingManeuver) {
            previewNextManuever = true
        }
        
        if let trackingStatus = routeTracker.trackingStatus {
            let maneuverDistance = trackingStatus.maneuverProgress.remainingDistance
            let displayManueverIndex = manueverIndex(for: trackingStatus)
            MapsAppNotifications.postNextManeuverNotification(manueverIndex: IndexPath(row: displayManueverIndex, section: 0), text:text(for:maneuverDistance))
        }
    }
    
    // Re-routing began. Show a spinner.
    func routeTrackerRerouteDidStart(_ routeTracker: AGSRouteTracker) {
        print("Rerouting…")
        
        // Update the UI to let the user know.
        reroutingActivityView.startAnimating()
        rerouteActivityViewMinDismissTime = .now() + 0.5
    }
    
    // Re-routing finished. Hide the spinner and update the UI with the updated route.
    func routeTracker(_ routeTracker: AGSRouteTracker, rerouteDidCompleteWith trackingStatus: AGSTrackingStatus?, error: Error?) {
        
        // Dismiss the UI spinner
        let dismissTime: DispatchTime = rerouteActivityViewMinDismissTime ?? .now() + 0.5
        DispatchQueue.main.asyncAfter(deadline: dismissTime) { [weak self] in
            self?.reroutingActivityView.stopAnimating()
        }
        
        // Update the app to display and follow the new route
        if let newRoute = trackingStatus?.routeResult.routes.first {
            print("Rerouted OK…")
            MapsAppNotifications.postReRouteSolvedNotification(result: newRoute)
            (remainingRouteOverlay.graphics.firstObject as? AGSGraphic)?.geometry = trackingStatus?.routeProgress.remainingGeometry
        }
    }
}
