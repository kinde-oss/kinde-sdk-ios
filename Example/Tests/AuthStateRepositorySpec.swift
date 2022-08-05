import Quick
import Nimble
import Mockingbird
import KindeAuthSwift
import AppAuth

class AuthStateRepositorySpec: QuickSpec {
    override func spec() {
        describe("AuthStateRepository") {

            it("can cache authentication state (in memory)") {
                let authStateMock = mock(OIDAuthState.self)
                // Stub the only required method
                given(authStateMock.replacementObject(for: any())!).will {
                    return "unused"
                }
                
                let sut = AuthStateRepository(key: "\(Bundle.main.bundleIdentifier ?? "com.kinde.KindeAuth").authState", logger: nil)
                
                // The auth state repository is initialised with no state
                expect(sut.state) == nil
                
                let saved = sut.setState(authStateMock)
                
                // After state save, the auth state repository has cached state
                expect(saved) == true
                expect(sut.state) != nil
            }
        }
    }
}
