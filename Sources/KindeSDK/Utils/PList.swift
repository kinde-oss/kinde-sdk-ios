
import Foundation
class PList {
    static func value(forKey key: String, from plistFileName: String) -> Any? {
        let bundle = Bundle.init(for: PList.self)
        guard let plistPath = bundle.path(forResource: plistFileName, ofType: "plist") else {
            return nil
        }
        guard let plistData = FileManager.default.contents(atPath: plistPath)  else {
            return nil
        }
        do {
            let plistObject = try PropertyListSerialization.propertyList(from: plistData, options: [.mutableContainersAndLeaves], format: nil)
            
            if let plistDict = plistObject as? [String: Any] {
                return plistDict[key]
            }
        } catch {
            print("Error reading plist: \(error)")
        }
        return nil
    }
}
