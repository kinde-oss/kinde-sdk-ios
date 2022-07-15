import Quick
import Nimble
import KindeAuthSwift

class ConfigSpec: QuickSpec {
    override func spec() {
        describe("Config") {

            it("can parse a valid issuer URI") {
                let expectedHost = "example.kinde.com"
                let config = Config(issuer: "https://\(expectedHost)", clientId: "", redirectUri: "", postLogoutRedirectUri: "", scope: "")
                let issuerUrl = config.getIssuerUrl()
                
                expect(issuerUrl?.host) == expectedHost
            }
            
            it("can handle an invalid issuer URI") {
                let issuer = ""
                let config = Config(issuer: issuer, clientId: "", redirectUri: "", postLogoutRedirectUri: "", scope: "")
                let issuerUrl = config.getIssuerUrl()
                
                expect(issuerUrl) == nil
            }
            
            // TODO: increase test coverage
        }
    }
}
