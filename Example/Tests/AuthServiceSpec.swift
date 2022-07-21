import Quick
import Nimble
import Mockingbird
import KindeAuthSwift
import AppAuth
import KindeAuthSwift_Example

class AuthServiceSpec: QuickSpec {
    override func spec() {
        let logger = Logger()
        let config = ConfigLoader.load()!
        
        describe("AuthServiceSpec") {
            
            it("is unauthorised after initialisation") {
                let authService = AuthService(config: config, logger: logger)
                expect(authService.isAuthorized) == false
            }
        }
    }
}
