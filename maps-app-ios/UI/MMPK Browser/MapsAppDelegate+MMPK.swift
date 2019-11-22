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

extension MapsAppDelegate {
    func openMMPK(url: URL) -> Bool {
        do {
            let targetMMPKURL = try moveMMPKIntoPlace(url: url)
            let mmpk = AGSMobileMapPackage(fileURL: targetMMPKURL)
            MapsAppNotifications.postCurrentItemChangeToMMPKNotification(mmpk: mmpk)
        } catch {
            print("Unable to move MMPK into place! \(error.localizedDescription)")
            return false
        }
        
        return true
    }
    
    func moveMMPKIntoPlace(url: URL) throws -> URL {
        let mmpkName = url.lastPathComponent
        let targetMMPKURL = FileManager.default.mmpksDirectory.appendingPathComponent(mmpkName)
        
        try? FileManager.default.removeItem(at: targetMMPKURL)
        
        try FileManager.default.createDirectory(at: FileManager.default.mmpksDirectory,
                                                withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.copyItem(at: url, to: targetMMPKURL)

        return targetMMPKURL
    }

}

extension FileManager {
    var mmpksDirectory: URL {
        get {
            let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let mmpksDirectoryURL = documentDirectoryURL //.appendingPathComponent("mmpks")
            return mmpksDirectoryURL
        }
    }
}
