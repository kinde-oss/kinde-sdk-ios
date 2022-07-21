import XCTest

// Test configuration
struct Config {
    // Add credentials for a registered user
    static let userId = "<test-user@example.com>"
    static let password = "<test-user-password>"

    // App
    static let signInButtonLabel = "Sign in"
    static let signOutButtonLabel = "Sign out"
    static let signInContinueAlertButtonLabel = "Continue"

    // OpenID Connect User Agent
    static let signInCancelButtonLabel = "Cancel"
    static let signInContinueButtonLabel = "Continue"
    
    static let uiElementWaitTimeout = 10.0
}

class ViewControllerTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
    }
    
    func testSignInAndSignOut() {
        // Sign in
        waitThenTapButton(button: Config.signInButtonLabel)
        waitThenTapAlertButton(button: Config.signInContinueAlertButtonLabel)
        
        let app = XCUIApplication()
        // User ID is assumed to be the first text field
        let userIdInput = app.webViews.textFields.firstMatch
        XCTAssertTrue(userIdInput.waitForExistence(timeout: Config.uiElementWaitTimeout))
        userIdInput.tap()
        userIdInput.typeText("\(Config.userId)\n")
        
        // Password is assumed to be the first text field
        let passwordInput = app.webViews.secureTextFields.firstMatch
        passwordInput.tap()
        passwordInput.typeText(Config.password)
        
        // Complete login
        let continueLoginButton = app.webViews.buttons.element(matching: NSPredicate(format: "label CONTAINS '\(Config.signInContinueButtonLabel)'"))
        continueLoginButton.tap()
        
        // TODO: test the user profile has been fetched (pending inclusion in ID token)
        
        // Sign out
        waitThenTapButton(button: Config.signOutButtonLabel)
    }

    func testSignInCancellation() {
        waitThenTapButton(button: Config.signInButtonLabel)
        waitThenTapAlertButton(button: Config.signInCancelButtonLabel)
        
        // Confirm the Sign In button is visible after cancellation
        let signInButton = XCUIApplication().buttons[Config.signInButtonLabel]
        XCTAssertTrue(signInButton.waitForExistence(timeout: Config.uiElementWaitTimeout))
    }
    
    func testConcurrentSignInAttempts() {
        // TODO
    }
}

private extension ViewControllerTests {
    /// Wait for an app button to appear and tap it
    func waitThenTapButton(button label: String) {
        let button = XCUIApplication().buttons[label]
        XCTAssertTrue(button.waitForExistence(timeout: Config.uiElementWaitTimeout))
        button.tap()
    }

    /// Wait for a button on the system Alert to appear and tap it
    func waitThenTapAlertButton(button label: String) {
        let alertButton = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons[label]
        XCTAssertTrue(alertButton.waitForExistence(timeout: Config.uiElementWaitTimeout))
        alertButton.tap()
    }
}
