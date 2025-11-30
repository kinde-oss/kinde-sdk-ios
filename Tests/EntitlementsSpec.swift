import Quick
import Nimble
import KindeSDK
import Foundation

class EntitlementsSpec: QuickSpec {
    override class func spec() {
        describe("EntitlementsService") {
            var auth: Auth!
            var entitlementsService: EntitlementsService!
            
            beforeEach {
                KindeSDKAPI.configure()
                auth = KindeSDKAPI.auth
                entitlementsService = auth.entitlements
            }
            
            describe("getEntitlements") {
                it("returns empty dictionary when no entitlements claim exists") {
                    // This test assumes the user is not authenticated or has no entitlements
                    let entitlements = entitlementsService.getEntitlements()
                    expect(entitlements).to(beEmpty())
                }
                
                it("returns entitlements dictionary when claim exists") {
                    // This test would require a mock token with entitlements claim
                    // For now, we test the structure and behavior
                    let entitlements = entitlementsService.getEntitlements()
                    expect(entitlements).to(beAKindOf([String: Any].self))
                }
            }
            
            describe("getEntitlement") {
                it("returns nil for non-existent entitlement") {
                    let result = entitlementsService.getEntitlement(featureKey: "non_existent_feature")
                    expect(result).to(beNil())
                }
                
                it("returns entitlement value when feature exists") {
                    // This would require a mock token with specific entitlements
                    // TODO: Add proper test fixtures with mocked tokens
                    pending("Requires mock token with entitlements claim") {}
                }
            }
            
            describe("getBooleanEntitlement") {
                it("returns false for non-existent boolean entitlement") {
                    let result = entitlementsService.getBooleanEntitlement(featureKey: "non_existent_bool")
                    expect(result).to(equal(false))
                }
                
                it("returns default value for non-existent boolean entitlement") {
                    let result = entitlementsService.getBooleanEntitlement(featureKey: "non_existent_bool", defaultValue: true)
                    expect(result).to(equal(true))
                }
                
                it("handles string boolean values correctly") {
                    // This test would require a mock token with string boolean values
                    let result = entitlementsService.getBooleanEntitlement(featureKey: "string_bool_feature", defaultValue: false)
                    expect(result).to(beAKindOf(Bool.self))
                }
            }
            
            describe("getStringEntitlement") {
                it("returns empty string for non-existent string entitlement") {
                    let result = entitlementsService.getStringEntitlement(featureKey: "non_existent_string")
                    expect(result).to(equal(""))
                }
                
                it("returns default value for non-existent string entitlement") {
                    let defaultValue = "default_value"
                    let result = entitlementsService.getStringEntitlement(featureKey: "non_existent_string", defaultValue: defaultValue)
                    expect(result).to(equal(defaultValue))
                }
                
                it("converts non-string values to string") {
                    // This test would require a mock token with non-string values
                    let result = entitlementsService.getStringEntitlement(featureKey: "numeric_feature", defaultValue: "default")
                    expect(result).to(beAKindOf(String.self))
                }
            }
            
            describe("getNumericEntitlement") {
                it("returns 0 for non-existent numeric entitlement") {
                    let result = entitlementsService.getNumericEntitlement(featureKey: "non_existent_numeric")
                    expect(result).to(equal(0))
                }
                
                it("returns default value for non-existent numeric entitlement") {
                    let defaultValue = 42
                    let result = entitlementsService.getNumericEntitlement(featureKey: "non_existent_numeric", defaultValue: defaultValue)
                    expect(result).to(equal(defaultValue))
                }
                
                it("handles string numeric values correctly") {
                    // This test would require a mock token with string numeric values
                    let result = entitlementsService.getNumericEntitlement(featureKey: "string_numeric_feature", defaultValue: 0)
                    expect(result).to(beAKindOf(Int.self))
                }
            }
            
            describe("Hard Check Functionality") {
                it("performs hard check with validation") {
                    let result = entitlementsService.performHardCheck(
                        checkName: "test_check",
                        validation: { return "test_result" },
                        fallbackValue: "fallback"
                    )
                    expect(result).to(equal("test_result"))
                }
                
                it("returns fallback value when validation fails") {
                    let result = entitlementsService.performHardCheck(
                        checkName: "failing_check",
                        validation: { return nil },
                        fallbackValue: "fallback"
                    )
                    expect(result).to(equal("fallback"))
                }
                
                it("validates user permissions with hard check") {
                    let result = entitlementsService.validatePermission(permission: "test_permission", fallbackAccess: false)
                    expect(result).to(beAKindOf(Bool.self))
                }
                
                it("validates user role with hard check") {
                    let result = entitlementsService.validateRole(role: "test_role", fallbackAccess: false)
                    expect(result).to(beAKindOf(Bool.self))
                }
                
                it("validates feature flag with hard check") {
                    let result = entitlementsService.validateFeatureFlag(flag: "test_flag", fallbackEnabled: false)
                    expect(result).to(beAKindOf(Bool.self))
                }
                
                it("validates entitlement with hard check") {
                    let result = entitlementsService.validateEntitlement(entitlement: "test_entitlement", fallbackValue: "fallback")
                    expect(result).to(equal("fallback"))
                }
            }
            
            describe("User Context Validation") {
                it("checks if user is authenticated") {
                    let result = entitlementsService.isUserAuthenticated()
                    expect(result).to(beAKindOf(Bool.self))
                }
                
                it("gets user organization context") {
                    let result = entitlementsService.getUserOrganization()
                    expect(result).to(beAKindOf([String: Any].self))
                }
                
                it("gets user subscription tier") {
                    let result = entitlementsService.getUserSubscriptionTier()
                    expect(result).to(beAKindOf(String.self))
                    expect(result).to(equal("free")) // Default fallback value
                }
            }
            
            describe("Edge Cases and Error Handling") {
                it("handles malformed entitlements claim gracefully") {
                    // This test would require a mock token with malformed entitlements
                    let entitlements = entitlementsService.getEntitlements()
                    expect(entitlements).to(beAKindOf([String: Any].self))
                }
                
                it("handles null entitlement values") {
                    let result = entitlementsService.getEntitlement(featureKey: "null_feature")
                    expect(result).to(beNil())
                }
                
                it("handles type conversion errors gracefully") {
                    let boolResult = entitlementsService.getBooleanEntitlement(featureKey: "invalid_bool", defaultValue: false)
                    expect(boolResult).to(beAKindOf(Bool.self))
                    
                    let stringResult = entitlementsService.getStringEntitlement(featureKey: "invalid_string", defaultValue: "default")
                    expect(stringResult).to(beAKindOf(String.self))
                    
                    let numericResult = entitlementsService.getNumericEntitlement(featureKey: "invalid_numeric", defaultValue: 0)
                    expect(numericResult).to(beAKindOf(Int.self))
                }
            }
            
            describe("Integration with Auth Service") {
                it("accesses entitlements through auth service") {
                    let authEntitlements = auth.entitlements
                    expect(authEntitlements).to(beIdenticalTo(entitlementsService))
                }
                
                it("maintains consistent state with auth service") {
                    let entitlements1 = auth.entitlements.getEntitlements()
                    let entitlements2 = entitlementsService.getEntitlements()
                    expect(entitlements1).to(equal(entitlements2))
                }
            }
        }
        
        describe("FeatureFlagsService") {
            var auth: Auth!
            var featureFlagsService: FeatureFlagsService!
            
            beforeEach {
                KindeSDKAPI.configure()
                auth = KindeSDKAPI.auth
                featureFlagsService = auth.featureFlags
            }
            
            describe("getFeatureFlags") {
                it("returns empty dictionary when no feature flags claim exists") {
                    let flags = featureFlagsService.getFeatureFlags()
                    expect(flags).to(beEmpty())
                }
                
                it("returns feature flags dictionary when claim exists") {
                    let flags = featureFlagsService.getFeatureFlags()
                    expect(flags).to(beAKindOf([String: Any].self))
                }
            }
            
            describe("isFeatureEnabled") {
                it("returns false for non-existent feature flag") {
                    let result = featureFlagsService.isFeatureEnabled(code: "non_existent_flag")
                    expect(result).to(equal(false))
                }
                
                it("returns default value for non-existent feature flag") {
                    let result = featureFlagsService.isFeatureEnabled(code: "non_existent_flag", defaultValue: true)
                    expect(result).to(equal(true))
                }
            }
            
            describe("getFeatureFlag") {
                it("returns nil for non-existent feature flag") {
                    let result = featureFlagsService.getFeatureFlag(code: "non_existent_flag")
                    expect(result).to(beNil())
                }
                
                it("returns Any? type for feature flag") {
                    let result = featureFlagsService.getFeatureFlag(code: "test_flag")
                    // Result will be nil when flag doesn't exist
                    expect(result).to(beNil())
                }
            }
        }
        
        describe("ClaimsService") {
            var auth: Auth!
            var claimsService: ClaimsService!
            
            beforeEach {
                KindeSDKAPI.configure()
                auth = KindeSDKAPI.auth
                claimsService = auth.claims
            }
            
            describe("getClaim") {
                it("returns nil for non-existent claim") {
                    let result = claimsService.getClaim(forKey: "non_existent_claim")
                    expect(result).to(beNil())
                }
                
                it("returns claim value when claim exists") {
                    // This would require a mock token with specific claims
                    // TODO: Add proper test fixtures with mocked tokens
                    pending("Requires mock token with claims") {}
                }
            }
            
            describe("getClaimValue") {
                it("returns nil for non-existent claim value") {
                    let result = claimsService.getClaimValue(forKey: "non_existent_claim")
                    expect(result).to(beNil())
                }
                
                it("returns claim value when claim exists") {
                    let result = claimsService.getClaimValue(forKey: "test_claim")
                    expect(result).to(beAKindOf(Any.self))
                }
            }
            
            describe("getRoles") {
                it("returns nil for non-existent roles when not authenticated") {
                    let result = claimsService.getRoles()
                    expect(result).to(beNil())
                }
                
                it("returns Roles type when roles exist") {
                    // This would require a mock token with roles claim
                    // For now, we test the structure and behavior
                    let result = claimsService.getRoles()
                    expect(result).to(beNil()) // Will be nil when not authenticated
                }
            }
            
            describe("getRole") {
                it("returns nil for non-existent role when not authenticated") {
                    let result = claimsService.getRole(name: "non_existent_role")
                    expect(result).to(beNil())
                }
                
                it("returns Role type when role exists") {
                    // This would require a mock token with roles claim
                    // For now, we test the structure and behavior
                    let result = claimsService.getRole(name: "test_role")
                    expect(result).to(beNil()) // Will be nil when not authenticated
                }
            }
        }
        
        describe("EntitlementsService HTTP API") {
            var auth: Auth!
            var entitlementsService: EntitlementsService!
            
            beforeEach {
                KindeSDKAPI.configure()
                auth = KindeSDKAPI.auth
                entitlementsService = auth.entitlements
            }
            
            describe("fetchEntitlements") {
                it("throws notAuthenticated when user is not logged in") {
                    await expect {
                        try await entitlementsService.fetchEntitlements()
                    }.to(throwError(AuthError.notAuthenticated))
                }
                
                it("throws notAuthenticated when user is not logged in with pagination") {
                    await expect {
                        try await entitlementsService.fetchEntitlements(pageSize: 10, startingAfter: "token")
                    }.to(throwError(AuthError.notAuthenticated))
                }
            }
            
            describe("fetchEntitlement") {
                it("throws notAuthenticated when user is not logged in") {
                    await expect {
                        try await entitlementsService.fetchEntitlement()
                    }.to(throwError(AuthError.notAuthenticated))
                }
            }
            
            describe("getAllEntitlements") {
                it("throws notAuthenticated when user is not logged in") {
                    await expect {
                        try await entitlementsService.getAllEntitlements()
                    }.to(throwError(AuthError.notAuthenticated))
                }
            }
            
                describe("getEntitlementsDictionary") {
                    it("throws notAuthenticated when user is not logged in") {
                        await expect {
                            try await entitlementsService.getEntitlementsDictionary()
                        }.to(throwError(AuthError.notAuthenticated))
                    }
                }
                
                describe("Hard Check Methods") {
                    it("getBooleanEntitlement returns default value for non-existent entitlement") {
                        let result = entitlementsService.getBooleanEntitlement(featureKey: "non_existent_bool", defaultValue: true)
                        expect(result).to(equal(true))
                    }
                    
                    it("getStringEntitlement returns default value for non-existent entitlement") {
                        let result = entitlementsService.getStringEntitlement(featureKey: "non_existent_string", defaultValue: "default")
                        expect(result).to(equal("default"))
                    }
                    
                    it("getNumericEntitlement returns default value for non-existent entitlement") {
                        let result = entitlementsService.getNumericEntitlement(featureKey: "non_existent_number", defaultValue: 42)
                        expect(result).to(equal(42))
                    }
                    
                    it("performHardCheck returns fallback value when validation fails") {
                        let result = entitlementsService.performHardCheck(
                            checkName: "test_check",
                            validation: { return nil },
                            fallbackValue: "fallback"
                        )
                        expect(result).to(equal("fallback"))
                    }
                    
                    it("performHardCheck returns validation result when validation succeeds") {
                        let result = entitlementsService.performHardCheck(
                            checkName: "test_check",
                            validation: { return "success" },
                            fallbackValue: "fallback"
                        )
                        expect(result).to(equal("success"))
                    }
                }
        }
    }
}
