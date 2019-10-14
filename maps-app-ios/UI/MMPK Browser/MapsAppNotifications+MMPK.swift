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

// MARK: External Notification API
extension MapsAppNotifications {
    static func observeCurrentItemChangedToMMPKNotification(owner:Any, handler:@escaping (AGSMobileMapPackage)->Void) {
        let ref = NotificationCenter.default.addObserver(forName: MapsAppNotifications.Names.mmpkSelected, object: mapsApp, queue: OperationQueue.main) { notification in
            guard let mmpk = notification.userInfo?["mmpk"] as? AGSMobileMapPackage else {
                print("MMPK exptected but not found in notification payload.")
                return
            }
            handler(mmpk)
        }
        MapsAppNotifications.registerBlockHandler(blockHandler: ref, forOwner: owner)
    }
}

// MARK: Internals
extension MapsAppNotifications {
    static func postCurrentItemChangeToMMPKNotification(mmpk: AGSMobileMapPackage) {
        NotificationCenter.default.post(name: MapsAppNotifications.Names.mmpkSelected, object: mapsApp, userInfo: ["mmpk": mmpk])
    }
}

// MARK: Typed Notification Pattern
extension MapsAppNotifications.Names {
    static let mmpkSelected = NSNotification.Name("MapsAppCurrentItemChangedToMMPKNotification")
}
