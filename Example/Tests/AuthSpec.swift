import Quick
import Nimble
import Mockingbird
import KindeAuthSwift
import AppAuth
import KindeAuthSwift_Example

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
