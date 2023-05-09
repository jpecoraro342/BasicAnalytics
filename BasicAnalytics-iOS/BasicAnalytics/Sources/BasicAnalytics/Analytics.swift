import Foundation

public class Analytics {
    
    var uploader : Uploader
    var configuration : Configuration?
    
    public static let shared = Analytics()
    
    private init() {
        uploader = Uploader()
    }
    
    func initialize(_ configuration: Configuration) {
        
    }
    
    func initialize(_ url: URL) {
        
    }
    
    func logEvent(_ event: Event) {
        
    }
    
    func logEvent(_ eventName: String) {
        
    }
}

struct Configuration {
    let url: URL
    let uploadOnBackground = true
    let uploadOnStart = true
    let eventUploadThreshold = 20
    let tempFileName: String? = nil
    /// 0 to disable upload on a timer
    let uploadTimerSeconds = 120
}
