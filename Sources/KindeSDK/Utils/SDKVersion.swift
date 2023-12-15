struct SDKVersion {
     static var versionString: String {
        PList.value(forKey: "SDKVersionString", from: "info") as? String ?? "1.2.0"
    }
}
