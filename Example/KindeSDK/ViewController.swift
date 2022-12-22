import UIKit
import KindeSDK

class ViewController: UIViewController {
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.text = "KindeSDK Example"
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
    
    private let getUserButton: UIButton = {
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
        view.addSubview(getUserButton)
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
        
        getUserButton.translatesAutoresizingMaskIntoConstraints = false
        getUserButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor).isActive = true
        getUserButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        getUserButton.addTarget(self, action: #selector(getUser), for: .primaryActionTriggered)
        
        userLabel.translatesAutoresizingMaskIntoConstraints = false
        userLabel.topAnchor.constraint(equalTo: getUserButton.bottomAnchor).isActive = true
        userLabel.centerXAnchor.constraint(equalTo: getUserButton.centerXAnchor).isActive = true
        
        isAuthenticated = Auth.isAuthorized()
    }
    
    private var isAuthenticated = false {
        didSet {
            signInSignOutButton.setTitle(isAuthenticated ? "Sign out" : "Sign in", for: .normal)
            signUpButton.isHidden = isAuthenticated
            getUserButton.isHidden = !isAuthenticated
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
    
    /// Get the current user's profile. A successful response confirms that valid authentication
    /// tokens are available.
    ///
    /// If the request fails due to stale authentication, the current user is logged out.
    @objc private func getUser(_ target: UIButton) {
        
        OAuthAPI.getUser { (userProfile, error) in
            if let userProfile = userProfile {
                let userName = "\(userProfile.firstName ?? "") \(userProfile.lastName ?? "")"
                print("Got profile for user \(userName)")
                self.userLabel.text = "User fetched: \(userName)"
            }
            if let error = error {
                if let errorResponse = error as? ErrorResponse {
                    switch errorResponse {
                    case .error(let code, _, _, let error):
                        if code == BearerTokenHandler.notAuthenticatedCode {
                            self.alert("Your session has expired. Please login again.")
                            Auth.logout(viewController: self) { result in
                                if result {
                                    self.isAuthenticated = false
                                    self.userLabel.text = ""
                                }
                            }
                        } else {
                            self.alert("Failed to get user profile: \(error.localizedDescription)")
                        }
                    }
                } else {
                    self.alert("Failed to get user profile: \(error.localizedDescription)")
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

