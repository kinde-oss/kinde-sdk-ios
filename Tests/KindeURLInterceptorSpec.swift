import Quick
import Nimble
import UIKit
@testable import KindeSDK

class MockAppDelegate: UIResponder, UIApplicationDelegate {
    var originalOpenURLCalled = false
    
    @objc dynamic func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        originalOpenURLCalled = true
        return true
    }
    
    var originalContinueUserActivityCalled = false
    @objc dynamic func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        originalContinueUserActivityCalled = true
        return true
    }
}

class MockSceneDelegate: UIResponder, UISceneDelegate {
    var originalOpenURLContextsCalled = false
    var originalContinueUserActivityCalled = false
    var originalWillConnectToCalled = false
    
    @objc dynamic func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        originalOpenURLContextsCalled = true
    }
    
    @objc dynamic func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        originalContinueUserActivityCalled = true
    }
    
    @objc dynamic func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        originalWillConnectToCalled = true
    }
}

class KindeURLInterceptorSpec: QuickSpec {
    override class func spec() {
        describe("KindeURLInterceptor") {
            beforeEach {
                KindeURLInterceptor.onURLReceived = nil
            }
            
            it("swizzles application(_:open:options:) successfully and intercepts URLs") {
                let mockDelegate = MockAppDelegate()
                
                var receivedURL: URL?
                KindeURLInterceptor.onURLReceived = { url in
                    receivedURL = url
                }
                
                let originalSelector = #selector(UIApplicationDelegate.application(_:open:options:))
                let kindeSelector = #selector(UIResponder.kinde_application(_:open:options:))
                
                var successCalled = false
                KindeURLInterceptor.swizzle(originalSelector, on: type(of: mockDelegate), with: kindeSelector) {
                    successCalled = true
                }
                
                expect(successCalled).to(beTrue())
                
                let testURL = URL(string: "kinde://callback")!
                
                let result = mockDelegate.application(UIApplication.shared, open: testURL, options: [:])
                
                expect(receivedURL).to(equal(testURL))
                
                expect(mockDelegate.originalOpenURLCalled).to(beTrue())
                expect(result).to(beTrue())
            }
            
            it("swizzles application(_:continue:restorationHandler:) successfully and intercepts universal links") {
                let mockDelegate = MockAppDelegate()
                
                var receivedURL: URL?
                KindeURLInterceptor.onURLReceived = { url in
                    receivedURL = url
                }
                
                let originalSelector = #selector(UIApplicationDelegate.application(_:continue:restorationHandler:))
                let kindeSelector = #selector(UIResponder.kinde_application(_:continue:restorationHandler:))
                
                var successCalled = false
                KindeURLInterceptor.swizzle(originalSelector, on: type(of: mockDelegate), with: kindeSelector) {
                    successCalled = true
                }
                
                expect(successCalled).to(beTrue())
                
                let testURL = URL(string: "https://yourdomain.kinde.com/callback")!
                let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                userActivity.webpageURL = testURL
                
                let result = mockDelegate.application(UIApplication.shared, continue: userActivity, restorationHandler: { _ in })
                
                expect(receivedURL).to(equal(testURL))
                expect(mockDelegate.originalContinueUserActivityCalled).to(beTrue())
                expect(result).to(beTrue())
            }
            

            it("swizzles scene(_:continueUserActivity:) successfully and intercepts universal links") {
                let mockDelegate = MockSceneDelegate()
                
                var receivedURL: URL?
                KindeURLInterceptor.onURLReceived = { url in
                    receivedURL = url
                }
                
                let originalSelector = #selector(UISceneDelegate.scene(_:continue:))
                let kindeSelector = #selector(UIResponder.kinde_scene(_:continue:))
                
                var successCalled = false
                KindeURLInterceptor.swizzle(originalSelector, on: type(of: mockDelegate), with: kindeSelector) {
                    successCalled = true
                }
                
                expect(successCalled).to(beTrue())
                
                let testURL = URL(string: "https://yourdomain.kinde.com/scene-callback")!
                
                let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
                userActivity.webpageURL = testURL
                
                let sceneClass: AnyClass = NSClassFromString("UIScene")!
                let allocScene = (sceneClass as AnyObject).perform(NSSelectorFromString("alloc"))?.takeUnretainedValue()
                let realScene = allocScene?.perform(NSSelectorFromString("init"))?.takeUnretainedValue() as! UIScene
                
                mockDelegate.perform(#selector(MockSceneDelegate.scene(_:continue:)), with: realScene, with: userActivity)
                
                expect(receivedURL).to(equal(testURL))
                expect(mockDelegate.originalContinueUserActivityCalled).to(beTrue())
            }
            

        }
    }
}
