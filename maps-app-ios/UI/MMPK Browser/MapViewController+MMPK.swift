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

fileprivate var currentMMPK: AGSMobileMapPackage?
public var reroutingParameters: AGSRouteParameters?

extension MapViewController {
    func setupMMPK() {
        MapsAppNotifications.observeCurrentItemChangedToMMPKNotification(owner: self) { [weak self] mmpk in
            guard let self = self else { return }
            
            if let currentOpenMMPK = currentMMPK {
                currentOpenMMPK.close()
            }
            
            currentMMPK = mmpk

            currentMMPK?.load(completion: { error in
                if let error = error {
                    print("Error opening mmpk: \(error.localizedDescription)")
                    return
                }
                
                guard let mmpk = currentMMPK else { return }

                print("Opening mmpk at \(mmpk.fileURL.absoluteString)")
                
                guard let mmpkMap = mmpk.maps.first else { return }
                
                AppPreferences.mmpkFileName = mmpk.fileURL.lastPathComponent
                
                if let mapView = self.mapView {
                    if let storedViewpoint = AppPreferences.viewpoint {
                        mmpkMap.initialViewpoint = storedViewpoint
                    }
                    mapView.map = mmpkMap
                    print("USING LOCAL MAP FROM MMPK")
                }

                if let network = mmpkMap.transportationNetworks.first {
                    let mmpkRouteTask = AGSRouteTask(dataset: network)
                    arcGISServices.routeTask = mmpkRouteTask
                    print("USING LOCAL ROUTE TASK FROM MMPK")
                } else {
                    arcGISServices.routeTask = defaultRouteTask
                    print("USING DEFAULT ROUTE TASK")
                }
                
//                if let locatorTask = mmpk.locatorTask {
//                    arcGISServices.locator = locatorTask
//                    print("USING LOCAL LOCATOR TASK FROM MMPK")
//                } else {
//                    arcGISServices.locator = defaultLocator
//                    print("USING DEFAULT LOCATOR TASK")
//                }
            })
        }
        
        if let mmpkFileName = AppPreferences.mmpkFileName {
            let mmpkURL = FileManager.default.mmpksDirectory.appendingPathComponent(mmpkFileName)
            guard FileManager.default.fileExists(atPath: mmpkURL.path) else {
                print("No MMPK at \(mmpkURL.absoluteString)")
                AppPreferences.mmpkFileName = nil
                return
            }
            let mmpk = AGSMobileMapPackage(fileURL: mmpkURL)
            MapsAppNotifications.postCurrentItemChangeToMMPKNotification(mmpk: mmpk)
        }
    }
}
