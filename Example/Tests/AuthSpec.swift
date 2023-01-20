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
                expect(Auth.isAuthorized()) == false
            }
            
            it("check helper functions") {
                guard Auth.isAuthorized() == true else { return }
                let userDetails = Auth.getUserDetails()
                expect(userDetails.keys.count).to(beGreaterThan(0))
                
                let audClaim = Auth.getClaim(key: "aud")
                expect(audClaim).notTo(beNil())
                
                let permissions = Auth.getPermissions()
                expect(permissions.keys.count).to(beGreaterThan(0))
                
                let organization = Auth.getOrganization()
                expect(organization.keys.count).to(beGreaterThan(0))
                
                let userOrganizations = Auth.getUserOrganizations()
                expect(userOrganizations.keys.count).to(beGreaterThan(0))
            }
        }
    }
}
