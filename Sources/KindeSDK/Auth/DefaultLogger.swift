import os.log

/// A simple logging protocol with levels
public protocol Logger {
    func debug(message: String)
    func info(message: String)
    func error(message: String)
    func fault(message: String)
}

public struct DefaultLogger: Logger {
    
    public init() {}
    
    public func debug(message: String) {
        os_log("%s", type: .debug, message)
    }
    
    public func info(message: String) {
        os_log("%s", type: .info, message)
    }
    
    public func error(message: String) {
        os_log("%s", type: .error, message)
    }

    public func fault(message: String) {
        os_log("%s", type: .fault, message)
    }
}
