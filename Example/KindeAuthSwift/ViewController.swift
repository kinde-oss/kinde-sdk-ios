import UIKit
import KindeAuthSwift

struct KindeAuth {
    static let auth = AuthService(config: ConfigLoader.load()!, logger: Logger())
}

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
        button.setTitle("Make authenticated request", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.addSubview(headerLabel)
        view.addSubview(signInSignOutButton)
        view.addSubview(signUpButton)
        view.addSubview(makeAuthenticatedRequestButton)
        
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
        
        isAuthenticated = KindeAuth.auth.isAuthorized()
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
            KindeAuth.auth.logout(viewController: self) { result in
                if result {
                    self.isAuthenticated = false
                }
            }
        } else {
            KindeAuth.auth.login(viewController: self) { result in
                switch result {
                case let .failure(error):
                    print("Login failed: \(error.localizedDescription)")
                case .success:
                    self.isAuthenticated = true
                }
            }
        }
    }
    
    @objc private func register(_ target: UIButton) {
        KindeAuth.auth.register(viewController: self) { result in
            switch result {
            case let .failure(error):
                print("Registration failed: \(error.localizedDescription)")
            case .success:
                self.isAuthenticated = true
            }
        }
    }
    
    @objc private func makeAuthenticatedRequest(_ target: UIButton) {
        KindeAuth.auth.performWithFreshTokens { tokenResult in
            switch tokenResult {
            case let .failure(error):
                print("Failed to make API call: \(error.localizedDescription)")
            case let .success(accessToken):
                print("Making authenticated API call with access token: \(accessToken.dropLast(accessToken.count - 10))...")
            }
        }
    }
}

