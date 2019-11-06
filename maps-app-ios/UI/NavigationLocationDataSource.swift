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

class NavigationLocationDataSource : AGSLocationDataSource, AGSLocationChangeHandlerDelegate, AGSRouteTrackerDelegate {
    
    let routeTracker: AGSRouteTracker
    let baseLocationDataSource: AGSLocationDataSource // provides GPS locations
    var delegate: AGSRouteTrackerDelegate?
    
    init(routeTracker: AGSRouteTracker, baseLocationDataSource: AGSLocationDataSource) {
        self.routeTracker = routeTracker
        self.baseLocationDataSource = baseLocationDataSource
        super.init()
        
        baseLocationDataSource.locationChangeHandlerDelegate = self
        routeTracker.delegate = self
    }
    
    // This will be called from system location data source
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        // Pass in the raw location to the RouteTracker
        routeTracker.trackLocation(location, completion: nil)
    }
    
    // This will ping the map
    func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
        // Update the Location Display with a location marker that reflects
        // being on the route or not.
        didUpdate(trackingStatus.displayLocation)
        
        delegate?.routeTracker?(routeTracker, didUpdate: trackingStatus)
    }
}

// Additional RouteTrackerDelegate stuff to act as a full proxy.
extension NavigationLocationDataSource {
    func routeTrackerRerouteDidStart(_ routeTracker: AGSRouteTracker) {
        delegate?.routeTrackerRerouteDidStart?(routeTracker)
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
        delegate?.routeTracker?(routeTracker, didGenerateNewVoiceGuidance: voiceGuidance)
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, rerouteDidCompleteWith trackingStatus: AGSTrackingStatus?, error: Error?) {
        delegate?.routeTracker?(routeTracker, rerouteDidCompleteWith: trackingStatus, error: error)
    }
}

// Subclass stuff. When we're started and stopped, control the base data source.
extension NavigationLocationDataSource {
    override func doStart() {
        baseLocationDataSource.start { [weak self] error in
            self?.didStartOrFailWithError(error)
        }
    }
    
    override func doStop() {
        baseLocationDataSource.stop()
        didStop()
    }
}

// Additional AGSLocationChangeHandlerDelegate handlers for the baseLocationDataSource…
extension NavigationLocationDataSource {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, headingDidChange heading: Double) {
        // Do I need to let RouteTracker know?
        didUpdateHeading(heading)
    }
    
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, statusDidChange status: AGSLocationDataSourceStatus) {
        // What should I do here?
    }
}
