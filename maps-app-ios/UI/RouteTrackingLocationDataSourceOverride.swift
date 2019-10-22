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

class RouteTrackingLocationDataSourceOverride: AGSCLLocationDataSource, RouteTrackingLocationDataSource, CLLocationManagerDelegate {
    weak var routeTracker: AGSRouteTracker?
    var actualLastLocation: AGSLocation?
    
    // The original AGSCLLocationDataSource is the delegate to its CLLocationManager.
    // By declaring this function on this subclass, we're overriding that handler.
    // We snap the location that CoreLocation returns to the AGSRoute, and pass that
    // on through the AGSLocationDataSource method `didUpdate()`.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let lastLocation = locations.last, lastLocation.horizontalAccuracy >= 0 else {
            return
        }

        actualLastLocation = AGSLocation(clLocation: lastLocation)

        if let routeTracker = routeTracker {
            // This is used for display. In the locationDisplay.locationChanged handler, pass the
            // actualLastLocation to the RouteTracker. This ensures the AGSMapView display shows the
            // snapped location while the tracker works off the actual location.
            let snappedLocation = AGSLocation(clLocation: snap(location: lastLocation, to: routeTracker))
            didUpdate(snappedLocation)
        } else {
            // Just pass through the location unmodified
            didUpdate(actualLastLocation!)
            return
        }
        
    }
}
