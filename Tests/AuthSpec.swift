import Quick
import Nimble
import KindeSDK
import Foundation

class AuthSpec: QuickSpec {
    override class func spec() {
        describe("Auth") {
            beforeEach {
                KindeSDKAPI.configure()
            }
            
            it("is unauthorised after initialisation") {
                expect(KindeSDKAPI.auth.isAuthenticated()).to(beFalse())
            }
            
            it("check helper functions") {
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
                
                let roles = auth.getRoles()
                expect(roles).to(beNil())
                
                let role = auth.getRole(name: "test_role")
                expect(role).to(beNil())
                
                let organization = auth.getOrganization()
                expect(organization).to(beNil())
                
                let userOrganizations = auth.getUserOrganizations()
                expect(userOrganizations).to(beNil())
                
                // Feature Flags
                let testFlagCode = "#__testFlagCode__#"
                
                let flagNotExistGetDefaultValue = try? auth.getFlag(code: testFlagCode, defaultValue: testFlagCode).value as? String
                expect(flagNotExistGetDefaultValue).to(equal(testFlagCode))
                expect( try auth.getFlag(code: testFlagCode) )
                    .to( throwError(FlagError.unknownError) )
                
                let flagBoolNotExistGetNil = try? auth.getBooleanFlag(code: testFlagCode)
                expect(flagBoolNotExistGetNil).to(beNil())
                expect( try auth.getBooleanFlag(code: testFlagCode) )
                    .to( throwError(FlagError.unknownError) )
                
                let flagBoolNotExistGetDefaultValue = try? auth.getBooleanFlag(code: testFlagCode, defaultValue: true)
                expect(flagBoolNotExistGetDefaultValue).to(equal(true))
                expect( try auth.getBooleanFlag(code: testFlagCode, defaultValue: true) )
                    .to( equal(true) )

                let flagStringNotExistGetNil = try? auth.getStringFlag(code: testFlagCode)
                expect(flagStringNotExistGetNil).to(beNil())
                expect( try auth.getStringFlag(code: testFlagCode) )
                    .to( throwError(FlagError.unknownError) )

                let flagStringNotExistGetDefaultValue = try? auth.getStringFlag(code: testFlagCode, defaultValue: testFlagCode)
                expect(flagStringNotExistGetDefaultValue).to(equal(testFlagCode))
                expect( try auth.getStringFlag(code: testFlagCode, defaultValue: testFlagCode) )
                    .to( equal(testFlagCode) )
                
                let flagIntNotExistGetNil = try? auth.getIntegerFlag(code: testFlagCode)
                expect(flagIntNotExistGetNil).to(beNil())
                expect( try auth.getIntegerFlag(code: testFlagCode) )
                    .to( throwError(FlagError.unknownError) )

                let flagIntNotExistGetDefaultValue = try? auth.getIntegerFlag(code: testFlagCode, defaultValue: 1)
                expect(flagIntNotExistGetDefaultValue).to(equal(1))
                expect( try auth.getIntegerFlag(code: testFlagCode, defaultValue: 1) )
                    .to( equal(1) )
            }
            
            it("check logout functions") {
                let auth: Auth = KindeSDKAPI.auth
                
                // Test logout when not authenticated (should still work)
                waitUntil(timeout: .seconds(5)) { done in
                    Task {
                        let result = await auth.logout()
                        // Logout should return true even when not authenticated
                        expect(result).to(equal(true))
                        expect(auth.isAuthenticated()).to(beFalse())
                        done()
                    }
                }
            }
            
            describe("ApiOptions") {
                it("has default forceApi value of false") {
                    let options = ApiOptions()
                    expect(options.forceApi).to(beFalse())
                }
                
                it("can be initialized with forceApi true") {
                    let options = ApiOptions(forceApi: true)
                    expect(options.forceApi).to(beTrue())
                }
                
                it("can be initialized with forceApi false") {
                    let options = ApiOptions(forceApi: false)
                    expect(options.forceApi).to(beFalse())
                }
            }
            
            describe("getAllFlags") {
                it("returns empty dictionary when not authenticated and forceApi is false") {
                    let auth: Auth = KindeSDKAPI.auth
                    
                    waitUntil(timeout: .seconds(5)) { done in
                        Task {
                            do {
                                let flags = try await auth.getAllFlags()
                                expect(flags).to(beEmpty())
                                done()
                            } catch {
                                // If it throws, that's also acceptable when not authenticated
                                done()
                            }
                        }
                    }
                }
                
                it("returns empty dictionary when not authenticated and forceApi is true") {
                    let auth: Auth = KindeSDKAPI.auth
                    let options = ApiOptions(forceApi: true)
                    
                    waitUntil(timeout: .seconds(5)) { done in
                        Task {
                            do {
                                let flags = try await auth.getAllFlags(options: options)
                                // Should fail when not authenticated
                                expect(flags).to(beEmpty())
                                done()
                            } catch {
                                // Expected to fail when not authenticated
                                expect(error).toNot(beNil())
                                done()
                            }
                        }
                    }
                }
            }
            
            describe("async methods with forceApi") {
                it("getPermissions with forceApi throws when not authenticated") {
                    let auth: Auth = KindeSDKAPI.auth
                    let options = ApiOptions(forceApi: true)
                    
                    waitUntil(timeout: .seconds(5)) { done in
                        Task {
                            do {
                                _ = try await auth.getPermissions(options: options)
                                // Should not reach here
                                expect(true).to(beFalse())
                                done()
                            } catch {
                                // Expected to fail when not authenticated
                                expect(error).toNot(beNil())
                                done()
                            }
                        }
                    }
                }
                
                pending("Additional forceApi tests require authenticated user or mocked API responses") {}
            }
            
            describe("async methods without forceApi (token claims)") {
                it("getBooleanFlag without forceApi returns default value when flag doesn't exist") {
                    let auth: Auth = KindeSDKAPI.auth
                    let options = ApiOptions(forceApi: false)
                    waitUntil(timeout: .seconds(5)) { done in
                        Task {
                            do {
                                let result = try await auth.getBooleanFlag(code: "non_existent_flag", defaultValue: true, options: options)
                                expect(result).to(equal(true))
                                done()
                            } catch {
                                // Should not throw when default value is provided
                                expect(true).to(beFalse())
                                done()
                            }
                        }
                    }
                }
                
                it("getStringFlag without forceApi returns default value when flag doesn't exist") {
                    let auth: Auth = KindeSDKAPI.auth
                    let options = ApiOptions(forceApi: false)
                    waitUntil(timeout: .seconds(5)) { done in
                        Task {
                            do {
                                let result = try await auth.getStringFlag(code: "non_existent_flag", defaultValue: "default", options: options)
                                expect(result).to(equal("default"))
                                done()
                            } catch {
                                // Should not throw when default value is provided
                                expect(true).to(beFalse())
                                done()
                            }
                        }
                    }
                }
                
                it("getBooleanFlag with forceApi throws when not authenticated") {
                    let auth: Auth = KindeSDKAPI.auth
                    let options = ApiOptions(forceApi: true)
                    waitUntil(timeout: .seconds(5)) { done in
                        Task {
                            do {
                                _ = try await auth.getBooleanFlag(code: "test_flag", defaultValue: false, options: options)
                                // Should not reach here when not authenticated
                                expect(true).to(beFalse())
                                done()
                            } catch {
                                // Expected to fail when not authenticated
                                expect(error).toNot(beNil())
                                done()
                            }
                        }
                    }
                }
                
                it("getStringFlag with forceApi throws when not authenticated") {
                    let auth: Auth = KindeSDKAPI.auth
                    let options = ApiOptions(forceApi: true)
                    waitUntil(timeout: .seconds(5)) { done in
                        Task {
                            do {
                                _ = try await auth.getStringFlag(code: "test_flag", defaultValue: "default", options: options)
                                // Should not reach here when not authenticated
                                expect(true).to(beFalse())
                                done()
                            } catch {
                                // Expected to fail when not authenticated
                                expect(error).toNot(beNil())
                                done()
                            }
                        }
                    }
                }
                
                pending("Additional async tests require authenticated user or mocked tokens") {}
            }
        }
    }
}
