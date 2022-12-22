import Quick
import Nimble
import Mockingbird
import KindeSDK
import AppAuth
import KindeSDK_Example

class AuthSpec: QuickSpec {
    override func spec() {
        let logger = Logger()
        
        describe("AuthSpec") {
            
            it("is unauthorised after initialisation") {
                Auth.configure(logger: logger)
                expect(Auth.isAuthorized) == false
            }
        }
    }
}
