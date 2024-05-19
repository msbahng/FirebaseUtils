//
//  FirebaseUIView.swift
//  BaroiOS
//
//  Created by Mooseok Bahng on 2023/05/20.
//

import SwiftUI
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseOAuthUI
import FirebaseEmailAuthUI

public enum LoginMethod {
    case apple
    case google
    case email
}

public struct FirebaseUIView: UIViewControllerRepresentable {
    
    let errorTitle: String
    let confirmButtonTitle: String
    let signInErrorMessage: String
    let loginMethods: [LoginMethod]
    
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    
    public init(
        errorTitle: String,
        confirmButtonTitle: String,
        signInErrorMessage: String,
        loginMethods: [LoginMethod]
    ) {
        self.errorTitle = errorTitle
        self.confirmButtonTitle = confirmButtonTitle
        self.signInErrorMessage = signInErrorMessage
        
        self.loginMethods = loginMethods
    }
    
    public func makeUIViewController(context: Context) -> UINavigationController {
        
        let authUI = FUIAuth.defaultAuthUI()!
        authUI.delegate = context.coordinator
        
        var providers = [FUIAuthProvider]()
        
        if loginMethods.contains(.apple) {
            providers.append(FUIOAuth.appleAuthProvider())
        }
        
        if loginMethods.contains(.google) {
            providers.append(FUIGoogleAuth(authUI: authUI))
        }
        
        if loginMethods.contains(.email) {
            providers.append(FUIEmailAuth())
        }
        
        authUI.providers = providers
        
        return authUI.authViewController()
    }
    
    public func updateUIViewController(_ viewController: UINavigationController, context: Context) {
        
        if showError {
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: errorTitle,
                    message: errorMessage,
                    preferredStyle: .alert
                )
                alert.addAction(
                    UIAlertAction(title: confirmButtonTitle, style: .default, handler: nil)
                )
                
                viewController.present(
                    alert,
                    animated: true,
                    completion: {
                        self.showError = false
                    }
                )
            }
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self, signInErrorMessage: signInErrorMessage)
    }
    
    public class Coordinator: NSObject, FUIAuthDelegate {
        var parent: FirebaseUIView
        var signInErrorMessage: String
        
        init(_ parent: FirebaseUIView, signInErrorMessage: String) {
            self.parent = parent
            self.signInErrorMessage = signInErrorMessage
        }
        
        public func authUI(_ authUI: FUIAuth, didSignInWith authDataResult: AuthDataResult?, error: Error?) {
            
            guard let error = error else {
                return
            }
            
#if DEBUG
            parent.errorMessage = error.localizedDescription
#else
            parent.errorMessage = signInErrorMessage
#endif
            parent.showError = true
        }
    }
}
