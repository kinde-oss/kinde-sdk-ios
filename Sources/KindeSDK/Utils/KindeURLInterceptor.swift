import UIKit
import ObjectiveC.runtime
import os.log

// MARK: - URL and Universal Link interception
// Directs URL handling to the Kinde SDK automatically.

/// Automatically intercepts authentication URLs and Universal Links from the system
/// before they reach the developer's app logic.
enum KindeURLInterceptor {
    // Completion flags
    private static var didSwizzleApplicationOpenURLOptions = false
    private static var didSwizzleApplicationContinueUserActivity = false
    private static var swizzledSceneOpenURLContextsClasses: Set<String> = []
    private static var swizzledSceneWillConnectToSessionClasses: Set<String> = []
    private static var swizzledSceneContinueUserActivityClasses: Set<String> = []

    /// Callback to be triggered when a URL is intercepted.
    static var onURLReceived: ((URL) -> Void)?
    
    public static func startInterceptingURLs(with urlHandler: @escaping (URL) -> Void) {
        self.onURLReceived = urlHandler

        let sceneClasses = findSceneDelegateClasses()
        for delegateClass in sceneClasses {
            swizzleSceneOpenURLContexts(on: delegateClass)
            swizzleSceneContinueUserActivity(on: delegateClass)
            swizzleSceneWillConnectToSession(on: delegateClass)
        }
        swizzleApplicationOpenURLOptions()
        swizzleApplicationContinueUserActivity()
    }

    private static func findSceneDelegateClasses() -> [AnyClass] {
        var discoveredClasses = [AnyClass]()

        // Parse Info.plist:
        // This is necessary for apps where the scenes are defined in the Info.plist, allowing us to find the 
        // delegate classes even if KindeSDKAPI.configure() is called before any scenes are actively connected.
        if let manifest = Bundle.main.object(forInfoDictionaryKey: "UIApplicationSceneManifest") as? [String: Any],
           let configurations = manifest["UISceneConfigurations"] as? [String: Any] {
            
            for (_, roleConfigs) in configurations {
                guard let configsArray = roleConfigs as? [[String: Any]] else { continue }

                for config in configsArray {
                    if let className = config["UISceneDelegateClassName"] as? String,
                       let delegateClass = NSClassFromString(className) {
                        if !discoveredClasses.contains(where: { String(describing: $0) == String(describing: delegateClass) }) {
                            discoveredClasses.append(delegateClass)
                        }
                    }
                }
            }
        }

        // Scan connected scenes:
        // This is necessary for modern SwiftUI apps where the SceneDelegate is managed implicitly 
        // and is not listed in the Info.plist statically.
        for scene in UIApplication.shared.connectedScenes {
            if let delegate = scene.delegate,
               let delegateClass = object_getClass(delegate) {
                if !discoveredClasses.contains(where: { String(describing: $0) == String(describing: delegateClass) }) {
                    discoveredClasses.append(delegateClass)
                }
            }
        }

        return discoveredClasses
    }

    /// Safely replaces an iOS lifecycle method with Kinde's URL-handling logic, 
    /// while preserving the developer's original code so it can run afterwards.
    static func swizzle(_ originalSelector: Selector, on delegateClass: AnyClass, with kindeSelector: Selector, onSuccess: () -> Void) {
        // Get the Kinde logic implementation from our extension
        guard let kindeMethod = class_getInstanceMethod(UIResponder.self, kindeSelector) else { return }

        // 1. Add the Kinde selector to the delegate class, pointing it to the original implementation.
        // This allows Kinde to call the developer's original code when it finishes.
        if let originalMethod = class_getInstanceMethod(delegateClass, originalSelector) {
            // Method exists (either implemented or inherited).
            // Point the internal kinde name to the original implementation.
            let originalImplementation = method_getImplementation(originalMethod)
            let originalTypeEncoding = method_getTypeEncoding(originalMethod)
            class_addMethod(delegateClass, kindeSelector, originalImplementation, originalTypeEncoding)
        } else {
            // Method is completely missing.
            // Point the internal kinde name to a dummy method to stop any potential loop.
            let dummyMethod = class_getInstanceMethod(UIResponder.self, #selector(UIResponder.kinde_dummy))!
            let dummyImplementation = method_getImplementation(dummyMethod)
            let dummyTypeEncoding = method_getTypeEncoding(dummyMethod)
            class_addMethod(delegateClass, kindeSelector, dummyImplementation, dummyTypeEncoding)
        }


        let kindeImplementation = method_getImplementation(kindeMethod)
        let kindeTypeEncoding = method_getTypeEncoding(kindeMethod)
        
        // 2. Point the original selector on the delegate class to Kinde's implementation.
        // This allows iOS to trigger Kinde's logic first (then call the developer's original implementation).
        let didAdd = class_addMethod(delegateClass, originalSelector, kindeImplementation, kindeTypeEncoding)
        if !didAdd {
            // If the method already exists in the delegateClass (didAdd == false),
            // we safely swap its implementation.
            let existingMethod = class_getInstanceMethod(delegateClass, originalSelector)!
            method_setImplementation(existingMethod, kindeImplementation)
        }

        os_log("[KINDE_PROXY] Success: Setup swizzle for %{public}@", type: .default, String(describing: originalSelector))
        onSuccess()
    }

    private static func swizzleApplicationOpenURLOptions() {
        guard !didSwizzleApplicationOpenURLOptions,
              let delegate = UIApplication.shared.delegate else { return }

        let delegateClass: AnyClass = type(of: delegate)
        let openURLSelector = #selector(UIApplicationDelegate.application(_:open:options:))
        let kindeOpenURLSelector = #selector(UIResponder.kinde_application(_:open:options:))
        
        swizzle(openURLSelector, on: delegateClass, with: kindeOpenURLSelector) {
            didSwizzleApplicationOpenURLOptions = true
        }
    }

    private static func swizzleApplicationContinueUserActivity() {
        guard !didSwizzleApplicationContinueUserActivity,
              let delegate = UIApplication.shared.delegate else { return }

        let delegateClass: AnyClass = type(of: delegate)
        let continueUserActivitySelector = #selector(UIApplicationDelegate.application(_:continue:restorationHandler:))
        let kindeContinueUserActivitySelector = #selector(UIResponder.kinde_application(_:continue:restorationHandler:))
        
        swizzle(continueUserActivitySelector, on: delegateClass, with: kindeContinueUserActivitySelector) {
            didSwizzleApplicationContinueUserActivity = true
        }
    }

    private static func swizzleSceneOpenURLContexts(on delegateClass: AnyClass) {
        let className = String(describing: delegateClass)
        guard !swizzledSceneOpenURLContextsClasses.contains(className) else { return }

        let sceneOpenURLSelector = #selector(UISceneDelegate.scene(_:openURLContexts:))
        let kindeSceneOpenURLSelector = #selector(UIResponder.kinde_scene(_:openURLContexts:))
        
        swizzle(sceneOpenURLSelector, on: delegateClass, with: kindeSceneOpenURLSelector) {
            swizzledSceneOpenURLContextsClasses.insert(className)
        }
    }

    private static func swizzleSceneContinueUserActivity(on delegateClass: AnyClass) {
        let className = String(describing: delegateClass)
        guard !swizzledSceneContinueUserActivityClasses.contains(className) else { return }

        let sceneContinueUserActivitySelector = #selector(UISceneDelegate.scene(_:continue:))
        let kindeSceneContinueUserActivitySelector = #selector(UIResponder.kinde_scene(_:continue:))
        
        swizzle(sceneContinueUserActivitySelector, on: delegateClass, with: kindeSceneContinueUserActivitySelector) {
            swizzledSceneContinueUserActivityClasses.insert(className)
        }
    }

    private static func swizzleSceneWillConnectToSession(on delegateClass: AnyClass) {
        let className = String(describing: delegateClass)
        guard !swizzledSceneWillConnectToSessionClasses.contains(className) else { return }

        let sceneWillConnectSelector = #selector(UISceneDelegate.scene(_:willConnectTo:options:))
        let kindeSceneWillConnectSelector = #selector(UIResponder.kinde_scene(_:willConnectTo:options:))
        
        swizzle(sceneWillConnectSelector, on: delegateClass, with: kindeSceneWillConnectSelector) {
            swizzledSceneWillConnectToSessionClasses.insert(className)
        }
    }
}

// MARK: - Swizzle Implementations
/// Kinde's injected URL handling logic. These methods take over the system callbacks,
/// process the Kinde authentication URL, and then pass control back to the app.
extension UIResponder {
    /// A dummy method used to terminate forwarding loops for injected methods.
    @objc func kinde_dummy() {}

    @objc func kinde_application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        os_log("[KINDE_PROXY] AppDelegate Intercepted URL: %{public}@", type: .default, url.absoluteString)
        KindeURLInterceptor.onURLReceived?(url)
        return self.kinde_application(app, open: url, options: options)
    }

    @objc func kinde_application(_ app: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            os_log("[KINDE_PROXY] AppDelegate Intercepted Universal Link: %{public}@", type: .default, url.absoluteString)
            KindeURLInterceptor.onURLReceived?(url)
        }
        return self.kinde_application(app, continue: userActivity, restorationHandler: restorationHandler)
    }

    @objc func kinde_scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            os_log("[KINDE_PROXY] Scene Intercepted URL: %{public}@", type: .default, context.url.absoluteString)
            KindeURLInterceptor.onURLReceived?(context.url)
        }
        self.kinde_scene(scene, openURLContexts: URLContexts)
    }

    @objc func kinde_scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            os_log("[KINDE_PROXY] Scene Intercepted Universal Link: %{public}@", type: .default, url.absoluteString)
            KindeURLInterceptor.onURLReceived?(url)
        }
        self.kinde_scene(scene, continue: userActivity)
    }

    @objc func kinde_scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Handle Custom Scheme URLs
        let contexts = connectionOptions.urlContexts
        for context in contexts {
            os_log("[KINDE_PROXY] Scene Cold Start Intercepted URL: %{public}@", type: .default, context.url.absoluteString)
            KindeURLInterceptor.onURLReceived?(context.url)
        }
        
        // Handle Universal Links
        let activities = connectionOptions.userActivities
        for activity in activities {
            if activity.activityType == NSUserActivityTypeBrowsingWeb, let url = activity.webpageURL {
                os_log("[KINDE_PROXY] Scene Cold Start Intercepted Universal Link: %{public}@", type: .default, url.absoluteString)
                KindeURLInterceptor.onURLReceived?(url)
            }
        }
        
        self.kinde_scene(scene, willConnectTo: session, options: connectionOptions)
    }
}
