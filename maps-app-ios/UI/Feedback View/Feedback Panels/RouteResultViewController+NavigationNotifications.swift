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
