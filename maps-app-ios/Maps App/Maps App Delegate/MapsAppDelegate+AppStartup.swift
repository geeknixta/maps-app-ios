// Copyright 2017 Esri.
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

import ArcGIS

extension MapsAppDelegate {
    
    // MARK: App start
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // License the runtime
        do {
            try AGSArcGISRuntimeEnvironment.setLicenseKey(AppSettings.licenseKey, extensions: smpLicenses)
        } catch {
            print("Error licensing app: \(error.localizedDescription)")
        }
        print("ArcGIS Runtime License: \(AGSArcGISRuntimeEnvironment.license())")
        
        mapsAppContext.setInitialPortal()
        
        return true
    }

}

private let smpLicenses = [
    "runtimesmpna,1000,rud823492765,21-oct-2020,5H7L04SZ8L93EHT8A083",
    "runtimesmpe,1000,rud846385964,21-oct-2020,YYRDFK9HRGP1J4JEY150",
    "runtimesmpmea,1000,rud236549873,21-oct-2020,PM0PRK8ELBCH4R8FK214",
    "runtimesmpap,1000,rud175987450,21-oct-2020,HC4Z8AZ7G3D3EHT8A051",
    "runtimesmpla,1000,rud578909385,21-oct-2020,B5F1ERFLTJ0BYKZAD035"
]
