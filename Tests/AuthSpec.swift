import Quick
import Nimble
import KindeSDK
import Foundation

class AuthSpec: QuickSpec {
    override class func spec() {
        describe("Auth") {
            it("is unauthorised after initialisation") {
                KindeSDKAPI.configure()
                expect(KindeSDKAPI.auth.isAuthenticated()).to(beFalse())
            }
            
            it("check helper functions") {
                KindeSDKAPI.configure()
                let auth: Auth = KindeSDKAPI.auth
                
                // Test authentication state
                expect(auth.isAuthenticated()).to(beFalse())
                
                // Test helper functions when not authenticated
                let userDetails: User? = auth.getUserDetails()
                expect(userDetails).to(beNil())
                
                let audClaim = auth.getClaim(forKey: "aud")
                expect(audClaim).to(beNil())
                
                let permissions = auth.getPermissions()
                expect(permissions).to(beNil())
                
                let organization = auth.getOrganization()
                expect(organization).to(beNil())
                
                let userOrganizations = auth.getUserOrganizations()
                expect(userOrganizations).to(beNil())
                
                // Feature Flags
                let testFlagCode = "#__testFlagCode__#"
                
                let flagNotExistGetDefaultValue = try? auth.getFlag(code: testFlagCode, defaultValue: testFlagCode).value.value as? String
                expect(flagNotExistGetDefaultValue).to(equal(testFlagCode))
                expect( try auth.getFlag(code: testFlagCode) )
                    .to( throwError(FlagError.notFound) )
                
                let flagBoolNotExistGetNil = try? auth.getBooleanFlag(code: testFlagCode)
                expect(flagBoolNotExistGetNil).to(beNil())
                expect( try auth.getBooleanFlag(code: testFlagCode) )
                    .to( throwError(FlagError.notFound ) )
                
                let flagBoolNotExistGetDefaultValue = try? auth.getBooleanFlag(code: testFlagCode, defaultValue: true)
                expect(flagBoolNotExistGetDefaultValue).to(equal(true))
                expect( try auth.getBooleanFlag(code: testFlagCode, defaultValue: true) )
                    .to( equal(true) )

                let flagStringNotExistGetNil = try? auth.getStringFlag(code: testFlagCode)
                expect(flagStringNotExistGetNil).to(beNil())
                expect( try auth.getStringFlag(code: testFlagCode) )
                    .to( throwError(FlagError.notFound) )

                let flagStringNotExistGetDefaultValue = try? auth.getStringFlag(code: testFlagCode, defaultValue: testFlagCode)
                expect(flagStringNotExistGetDefaultValue).to(equal(testFlagCode))
                expect( try auth.getStringFlag(code: testFlagCode, defaultValue: testFlagCode) )
                    .to( equal(testFlagCode) )
                
                let flagIntNotExistGetNil = try? auth.getIntegerFlag(code: testFlagCode)
                expect(flagIntNotExistGetNil).to(beNil())
                expect( try auth.getIntegerFlag(code: testFlagCode) )
                    .to( throwError(FlagError.notFound) )

                let flagIntNotExistGetDefaultValue = try? auth.getIntegerFlag(code: testFlagCode, defaultValue: 1)
                expect(flagIntNotExistGetDefaultValue).to(equal(1))
                expect( try auth.getIntegerFlag(code: testFlagCode, defaultValue: 1) )
                    .to( equal(1) )
            }
            
            it("check logout functions") {
                let auth: Auth = KindeSDKAPI.auth
                
                // Test logout when not authenticated (should still work)
                Task {
                    let result = await auth.logout()
                    // Logout should return true even when not authenticated
                    expect(result).to(equal(true))
                    expect(auth.isAuthenticated()).to(beFalse())
                }
            }
        }
    }
}
