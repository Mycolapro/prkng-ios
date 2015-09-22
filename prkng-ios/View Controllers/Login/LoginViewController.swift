//
//  LoginViewController.swift
//  prkng-ios
//
//  Created by Cagdas Altinkaya on 06/05/15.
//  Copyright (c) 2015 PRKNG. All rights reserved.
//

import UIKit

class LoginViewController: AbstractViewController, LoginMethodSelectionViewDelegate, LoginEmailViewControllerDelegate, LoginExternalViewControllerDelegate, RegisterEmailViewControllerDelegate, GPPSignInDelegate {
    
    var backgroundImageView : UIImageView
    var logoView : UIImageView
    var methodSelectionView : LoginMethodSelectionView
    
    var loginEmailViewController : LoginEmailViewController?
    var registerEmailViewController : RegisterEmailViewController?
    var loginExternalViewController : LoginExternalViewController?
    
    var selectedMethod : LoginMethod?
    
    var googleSignIn : GPPSignIn?
    
    init() {
        backgroundImageView = UIImageView()
        logoView = UIImageView()
        methodSelectionView = LoginMethodSelectionView()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func loadView() {
        self.view = UIView()
        setupViews()
        setupConstraints()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.screenName = "Login - First Screen"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    func setupViews () {
        
        view.backgroundColor = Styles.Colors.petrol1
        
        backgroundImageView.image = UIImage(named: "bg_login")
        backgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
        view.addSubview(backgroundImageView)
        
        logoView.image = UIImage(named: "logo_opening")
        logoView.contentMode = UIViewContentMode.Bottom
        view.addSubview(logoView)
        
        methodSelectionView.delegate = self
        view.addSubview(methodSelectionView)
    }
    
    func setupConstraints () {
        
        backgroundImageView.snp_makeConstraints { (make) -> () in
            make.edges.equalTo(self.view)
        }
        
        logoView.snp_makeConstraints { (make) -> () in
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view).multipliedBy(0.5)
        }
        
        methodSelectionView.snp_makeConstraints { (make) -> () in
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
            make.height.equalTo(LoginMethodSelectionView.HEIGHT)
        }
        
    }
    
    // MARK: LoginMethodSelectionViewDelegate
    
    func loginFacebookSelected() {
        if (selectedMethod == LoginMethod.Facebook) {
            return
        }
        
        self.methodSelectionView.userInteractionEnabled = false
        
        let login =  FBSDKLoginManager()
        let permissions = ["email", "public_profile"]
        login.logInWithReadPermissions(permissions, handler: { (result, error) -> Void in
            
            if (error != nil || result.isCancelled) {
                // Handle errors and cancellations
                
                self.deselectMethod()
                
                let alertView = UIAlertView(title: "login_error_title_facebook".localizedString , message: "login_error_message".localizedString, delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "OK")
                alertView.alertViewStyle = .Default
                alertView.show()
                
            } else {
                
                self.methodSelectionView.userInteractionEnabled = false
                
                UserOperations.loginWithFacebook(FBSDKAccessToken.currentAccessToken().tokenString, completion: { (user, apiKey) -> Void in
                    
                    AuthUtility.saveUser(user)
                    AuthUtility.saveAuthToken(apiKey)
                    
                    self.displayExternalInfo(user, loginType: .Facebook)
                    
                })
            }
            
        })
        
        selectedMethod = LoginMethod.Facebook
        
    }
    
    func loginGoogleSelected() {
        
        if (selectedMethod == LoginMethod.Google) {
            return
        }
        
        googleSignIn = GPPSignIn.sharedInstance()
        googleSignIn?.shouldFetchGooglePlusUser = true
        googleSignIn?.clientID = "632562278503-4c9tkt6hsk8qm2c70b3cjom7vjq7158k.apps.googleusercontent.com"
        googleSignIn?.scopes = [kGTLAuthScopePlusLogin, kGTLAuthScopePlusMe, kGTLAuthScopePlusUserinfoEmail, kGTLAuthScopePlusUserinfoProfile]
        googleSignIn?.delegate = self
        googleSignIn?.authenticate()
        
        selectedMethod = LoginMethod.Google
        
    }
    
    func loginEmailSelected() {
        
        if (selectedMethod == LoginMethod.Email) {
            return
        }
        
        signUp()
        
        selectedMethod = LoginMethod.Email
    }
    
    func displayExternalInfo(user: User, loginType : LoginType) {
        
        loginExternalViewController = LoginExternalViewController(usr : user, loginType : loginType)
        loginExternalViewController!.delegate = self
        self.addChildViewController(loginExternalViewController!)
        self.view.insertSubview(loginExternalViewController!.view, belowSubview: methodSelectionView)
        loginExternalViewController!.didMoveToParentViewController(self)
        
        
        loginExternalViewController!.view.snp_makeConstraints { (make) -> () in
            make.top.equalTo(self.methodSelectionView.snp_bottom)
            make.centerX.equalTo(self.view)
            make.size.equalTo(self.view)
        }
        self.loginExternalViewController!.view.layoutIfNeeded()
        
        
        methodSelectionView.snp_remakeConstraints { (make) -> () in
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.top.equalTo(self.view)
            make.height.equalTo(0)
        }
        
        
        UIView.animateWithDuration(0.15, animations: { () -> Void in
            self.view.layoutIfNeeded()
            }) { (finished) -> Void in
                
        }
        
    }
    
    // MARK: GPPSignInDelegate
    func finishedWithAuth(auth: GTMOAuth2Authentication!, error: NSError!) {
        println(auth)
        
        if error != nil {
            //error!
            deselectMethod()
            
            let alertView = UIAlertView(title: "login_error_title_google".localizedString , message: "login_error_message".localizedString, delegate: nil, cancelButtonTitle: nil, otherButtonTitles: "OK")
            alertView.alertViewStyle = .Default
            alertView.show()
            
        } else {
            //success!
            self.methodSelectionView.userInteractionEnabled = false
            
            UserOperations.loginWithGoogle(auth.accessToken, completion: { (user, apiKey) -> Void in
                AuthUtility.saveUser(user)
                AuthUtility.saveAuthToken(apiKey)
                self.displayExternalInfo(user, loginType : .Google)
            })

            
        }
        
    }
    
    func didDisconnectWithError(error: NSError!) {
        
    }
    
    
    
    // MARK: LoginEmailViewControllerDelegate
    
    func signUp() {
        
        loginEmailViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.loginEmailViewController = nil
        })

        registerEmailViewController = RegisterEmailViewController()
        registerEmailViewController!.delegate = self
        self.presentViewController(registerEmailViewController!, animated: true) { () -> Void in }

        
    }
    
    func didLogin() {
        AuthUtility.saveLoginType(.Email)
        dismiss()
    }
    
    // MARK: LoginExternalViewControllerDelegate
    func didLoginExternal(loginType : LoginType) {
        AuthUtility.saveLoginType(loginType)
        dismiss()
    }
    
    // MARK: RegisterEmailViewControllerDelegate
    func didRegister() {
        AuthUtility.saveLoginType(.Email)
        dismiss()
    }
    
    func showLogin() {
        
        registerEmailViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.registerEmailViewController = nil
        })
        
        loginEmailViewController = LoginEmailViewController()
        loginEmailViewController!.delegate = self
        self.presentViewController(loginEmailViewController!, animated: true) { () -> Void in }
    }

    
    // MARK: All login delegates
    func back() {
        
        methodSelectionView.snp_remakeConstraints { (make) -> () in
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
            make.height.equalTo(LoginMethodSelectionView.HEIGHT)
        }
        
        registerEmailViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.registerEmailViewController = nil
        })

        loginEmailViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            self.loginEmailViewController = nil
        })

        deselectMethod()

    }
    
    func dismiss() {
        
        Settings.setFirstUsePassed(true)
        
        self.dismissViewControllerAnimated(true, completion: { () -> Void in
            
            let window: UIWindow = (UIApplication.sharedApplication().delegate as! AppDelegate).window!
            let tabController = TabController()
            
            window.rootViewController = tabController
            window.makeKeyWindow()
            
        })
    }
    
    func deselectMethod() {
        selectedMethod = nil
        self.methodSelectionView.userInteractionEnabled = true
        self.methodSelectionView.deselectAll()

    }
}
