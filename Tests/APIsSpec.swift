import Quick
import Nimble
@testable import KindeSDK
import Foundation

class MockBundle: Bundle, @unchecked Sendable {
    var mockedInfoDictionary: [String: Any] = [:]
    
    override func object(forInfoDictionaryKey key: String) -> Any? {
        return mockedInfoDictionary[key] ?? super.object(forInfoDictionaryKey: key)
    }
}

class APIsSpec: QuickSpec {
    override class func spec() {
        describe("KindeSDKAPI") {
            
            describe("handle(url:)") {
                
                it("returns true when the URL contains an invitation code") {
                    let urlWithInvitationCode = URL(string: "myapp://callback?invitation_code=12345")!
                    let result = KindeSDKAPI.handle(url: urlWithInvitationCode)
                    
                    expect(result).to(beTrue())
                }
                
                it("returns false when the URL is missing an invitation code") {
                    let urlWithoutInvitationCode = URL(string: "myapp://callback?some_other_param=123")!
                    let result = KindeSDKAPI.handle(url: urlWithoutInvitationCode)
                    
                    expect(result).to(beFalse())
                }
                
                it("returns false if URL components fail to parse") {
                    let malformedUrl = URL(string: "invalid://url")!
                    let result = KindeSDKAPI.handle(url: malformedUrl)
                    
                    expect(result).to(beFalse())
                }
            }
            
            describe("configure()") {
                
                afterEach {
                    // Reset to default
                    KindeSDKAPI.bundle = .main
                    KindeURLInterceptor.onURLReceived = nil
                }
                
                it("does not start intercepting URLs when proxy is disabled in Info.plist") {
                    let mockBundle = MockBundle()
                    mockBundle.mockedInfoDictionary = ["KindeURLInterceptorEnabled": false]
                    
                    KindeSDKAPI.bundle = mockBundle
                    KindeSDKAPI.configure()
                    
                    expect(KindeURLInterceptor.onURLReceived).to(beNil())
                }
                
                it("starts intercepting URLs when proxy is enabled in Info.plist") {
                    let mockBundle = MockBundle()
                    mockBundle.mockedInfoDictionary = ["KindeURLInterceptorEnabled": true]
                    
                    KindeSDKAPI.bundle = mockBundle
                    KindeSDKAPI.configure()
                    
                    expect(KindeURLInterceptor.onURLReceived).toNot(beNil())
                }
            }
        }
    }
}
