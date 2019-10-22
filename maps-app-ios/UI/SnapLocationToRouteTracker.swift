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

internal func snap(location: CLLocation, to routeTracker: AGSRouteTracker) -> CLLocation {
    guard let status = routeTracker.trackingStatus,
        status.isOnRoute == true,
        let route = routeTracker.trackingStatus?.routeResult.routes.first,
        route.directionManeuvers.count > 0 else { return location }

    let locationAsPoint = AGSPoint(clLocationCoordinate2D: location.coordinate)
    let currentManeuver = route.directionManeuvers[status.currentManeuverIndex]

    guard let maneuverGeom = currentManeuver.geometry,
        let projectedManeuverGeom = AGSGeometryEngine.projectGeometry(maneuverGeom, to: locationAsPoint.spatialReference!),
        let snappedCoordinate = AGSGeometryEngine.nearestCoordinate(in: projectedManeuverGeom,
                                                                    to: locationAsPoint)?.point.toCLLocationCoordinate2D() else {
                                                                        return location
    }
    
    return CLLocation(coordinate: snappedCoordinate,
                      altitude: location.altitude,
                      horizontalAccuracy: location.horizontalAccuracy,
                      verticalAccuracy: location.verticalAccuracy,
                      course: location.course, speed: location.speed,
                      timestamp: location.timestamp)
}
