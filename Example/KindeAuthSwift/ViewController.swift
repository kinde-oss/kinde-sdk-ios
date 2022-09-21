import UIKit
import KindeAuthSwift

class ViewController: UIViewController {
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.text = "KindeAuthSwift Example"
        return label
    }()
    
    private let signInSignOutButton: UIButton = {
        let button = UIButton(type: .system)
        return button
    }()
    
    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign up", for: .normal)
        return button
    }()
    
    private let makeAuthenticatedRequestButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Fetch user (authenticated request)", for: .normal)
        return button
    }()
    
    private let userLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "User"
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.addSubview(headerLabel)
        view.addSubview(signInSignOutButton)
        view.addSubview(signUpButton)
        view.addSubview(makeAuthenticatedRequestButton)
        view.addSubview(userLabel)
        
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        headerLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        
        signInSignOutButton.translatesAutoresizingMaskIntoConstraints = false
        signInSignOutButton.topAnchor.constraint(equalTo: headerLabel.bottomAnchor).isActive = true
        signInSignOutButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        signInSignOutButton.addTarget(self, action: #selector(signInOrSignOut), for: .primaryActionTriggered)
        
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        signUpButton.topAnchor.constraint(equalTo: signInSignOutButton.bottomAnchor).isActive = true
        signUpButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        signUpButton.addTarget(self, action: #selector(register), for: .primaryActionTriggered)
        
        makeAuthenticatedRequestButton.translatesAutoresizingMaskIntoConstraints = false
        makeAuthenticatedRequestButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor).isActive = true
        makeAuthenticatedRequestButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        makeAuthenticatedRequestButton.addTarget(self, action: #selector(makeAuthenticatedRequest), for: .primaryActionTriggered)
        
        userLabel.translatesAutoresizingMaskIntoConstraints = false
        userLabel.topAnchor.constraint(equalTo: makeAuthenticatedRequestButton.bottomAnchor).isActive = true
        userLabel.centerXAnchor.constraint(equalTo: makeAuthenticatedRequestButton.centerXAnchor).isActive = true
        
        isAuthenticated = Auth.isAuthorized()
    }
    
    private var isAuthenticated = false {
        didSet {
            signInSignOutButton.setTitle(isAuthenticated ? "Sign out" : "Sign in", for: .normal)
            signUpButton.isHidden = isAuthenticated
            makeAuthenticatedRequestButton.isHidden = !isAuthenticated
        }
    }

    @objc private func signInOrSignOut(_ target: UIButton) {
        if isAuthenticated {
            Auth.logout(viewController: self) { result in
                if result {
                    self.isAuthenticated = false
                    self.userLabel.text = ""
                }
            }
        } else {
            Auth.login(viewController: self) { result in
                switch result {
                case let .failure(error):
                    if (!Auth.isUserCancellationErrorCode(error)) {
                        self.alert("Login failed: \(error.localizedDescription)")
                    }
                case .success:
                    self.isAuthenticated = true
                }
            }
        }
    }
    
    @objc private func register(_ target: UIButton) {
        Auth.register(viewController: self) { result in
            switch result {
            case let .failure(error):
                if (!Auth.isUserCancellationErrorCode(error)) {
                    self.alert("Registration failed: \(error.localizedDescription)")
                }
            case .success:
                self.isAuthenticated = true
            }
        }
    }
    
    @objc private func makeAuthenticatedRequest(_ target: UIButton) {
        Auth.performWithFreshTokens { tokens in
            switch tokens {
            case let .failure(error):
                self.alert("Failed to get auth token: \(error.localizedDescription)")
            case let .success(tokens):
                let accessToken = tokens.accessToken
                print("Calling API with accessToken: \(accessToken)")
                KindeManagementApiClient.getUser(accessToken: accessToken) { (userProfile, error) in
                    if let userProfile = userProfile {
                        let userName = "\(userProfile.firstName ?? "") \(userProfile.lastName ?? "")"
                        print("Got profile for user \(userName)")
                        self.userLabel.text = "User fetched: \(userName)"
                    }
                    if let error = error {
                        self.alert("Failed to get user profile: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Present an error alert with the given message and print it to the console
    @objc private func alert(_ message: String) {
        let defaultAction = UIAlertAction(title: "OK",
                                style: .default)
        
        let alert = UIAlertController(title: "Error",
                 message: message,
                 preferredStyle: .alert)
        alert.addAction(defaultAction)
        
        print(message)
        self.present(alert, animated: true)
    }
}

