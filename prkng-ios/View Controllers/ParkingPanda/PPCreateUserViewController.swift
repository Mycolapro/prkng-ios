//
//  PPCreateUserViewController.swift
//  prkng-ios
//
//  Created by Antonino Urbano on 2016-02-04.
//  Copyright © 2016 PRKNG. All rights reserved.
//

import UIKit
import MessageUI

class PPCreateUserViewController: AbstractViewController, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate, PPHeaderViewDelegate, CardIOPaymentViewControllerDelegate {
    
    var delegate: PPCreateUserViewControllerDelegate?
    
    private var step: Int = 0
    
    private var statusView = UIView()
    private var headerView = PPHeaderView()
    private let tableView = PRKCachedTableView()
    
    private var firstName: String = ""
    private var lastName: String = ""
    private var email: String = ""
    private var password: String = ""
    
    private var creditCards = [CardIOCreditCardInfo]()
    private var redCells = [String]()

    private var brand: String = Settings.getCarDescription()["brand"] ?? ""
    private var plate: String = Settings.getCarDescription()["plate"] ?? ""
    private var model: String = Settings.getCarDescription()["model"] ?? ""
    private var color: String = Settings.getCarDescription()["color"] ?? ""
    private var phone: String = Settings.getCarDescription()["phone"] ?? ""
    
    private(set) var BACKGROUND_COLOR = Styles.Colors.stone
    private(set) var BACKGROUND_TEXT_COLOR = Styles.Colors.anthracite1
    private(set) var BACKGROUND_TEXT_COLOR_EMPHASIZED = Styles.Colors.petrol2
    private(set) var FOREGROUND_COLOR = Styles.Colors.cream1
    private(set) var FOREGROUND_TEXT_COLOR = Styles.Colors.anthracite1
    private(set) var FOREGROUND_TEXT_COLOR_EMPHASIZED = Styles.Colors.red2
    
    private(set) var HEADER_HEIGHT = 80
    private(set) var HEADER_FONT = Styles.FontFaces.regular(12)
    private(set) var MIN_FOOTER_HEIGHT = 65
    private(set) var FOOTER_FONT = Styles.FontFaces.regular(12)
    
    private(set) var SMALL_CELL_HEIGHT: CGFloat = 48
    private(set) var BIG_CELL_HEIGHT: CGFloat = 61
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func loadView() {
        self.view = UIView()
        setupViews()
        setupConstraints()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.screenName = "Parking Panda Create User View"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let nextTextField = tableView.viewWithTag(1) as? UITextField {
            nextTextField.becomeFirstResponder()
        }
    }
    
    func setupViews () {
        
        view.backgroundColor = BACKGROUND_COLOR
        
        statusView.backgroundColor = Styles.Colors.transparentBlack
        self.view.addSubview(statusView)
        
        //TODO: Localize me
        headerView.delegate = self
        headerView.headerText = "CREATE A PARKING PANDA ACCOUNT"
        view.addSubview(headerView)
        
        view.addSubview(tableView)
        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorStyle = .None
        tableView.dataSource = self
        tableView.delegate = self
        tableView.clipsToBounds = true
    }
    
    func setupConstraints () {
        
        statusView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.view)
            make.bottom.equalTo(self.snp_topLayoutGuideBottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
        
        headerView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.snp_topLayoutGuideBottom)
            make.height.equalTo(HEADER_HEIGHT)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
        
        tableView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(self.headerView.snp_bottom)
            make.bottom.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
        }
        
    }
    
    
    //MARK: UITableViewDataSource
    
    //TODO: All these strings need to be localized
    var tableSource: [(String, [SettingsCell])] {
        
        //first up: information section
        let firstNameCell = SettingsCell(placeholderText: "first_name".localizedString, titleText: firstName, cellType: .TextEntry, selectorsTarget: self, callback: "formCallback:",
            userInfo: [
                "textFieldTag": 1,
                "keyboardType": UIKeyboardType.NamePhonePad.rawValue,
                "returnKeyType": UIReturnKeyType.Next.rawValue,
                "autocorrectionType": UITextAutocorrectionType.No.rawValue,
                "redTintOnOrderedCells": [redCells.contains("firstName")],
                "returnCallback": "cellReturnCallback:"])
        let lastNameCell = SettingsCell(placeholderText: "last_name".localizedString, titleText: lastName, cellType: .TextEntry, selectorsTarget: self, callback: "formCallback:",
            userInfo: [
                "textFieldTag": 2,
                "keyboardType": UIKeyboardType.NamePhonePad.rawValue,
                "returnKeyType": UIReturnKeyType.Next.rawValue,
                "autocorrectionType": UITextAutocorrectionType.No.rawValue,
                "redTintOnOrderedCells": [redCells.contains("lastName")],
                "returnCallback": "cellReturnCallback:"])
        let emailCell = SettingsCell(placeholderText: "email".localizedString, titleText: email, cellType: .TextEntry, selectorsTarget: self, callback: "formCallback:",
            userInfo: [
                "textFieldTag": 3,
                "keyboardType": UIKeyboardType.EmailAddress.rawValue,
                "returnKeyType": UIReturnKeyType.Next.rawValue,
                "autocorrectionType": UITextAutocorrectionType.No.rawValue,
                "redTintOnOrderedCells": [redCells.contains("email")],
                "returnCallback": "cellReturnCallback:"])
        let passwordCell = SettingsCell(placeholderText: "password".localizedString, titleText: password, cellType: .TextEntry, selectorsTarget: self, callback: "formCallback:",
            userInfo: [
                "textFieldTag": 4,
                "keyboardType": UIKeyboardType.Default.rawValue,
                "returnKeyType": UIReturnKeyType.Done.rawValue,
                "autocorrectionType": UITextAutocorrectionType.No.rawValue,
                "redTintOnOrderedCells": [redCells.contains("password")],
                "secureTextEntry": true,
                "returnCallback": "cellReturnCallback:"])
        let formSection = [firstNameCell, lastNameCell, emailCell, passwordCell]
        
        
        //next: payment info
        var paymentMethodSection = [SettingsCell]()
        let addPaymentMethodCell = SettingsCell(titleText: "add_payment_method".localizedString, selectorsTarget: self, cellSelector: "addPaymentMethod", canSelect: true)
        for creditCard in creditCards {
            let card = SettingsCell(userInfo: ["card_io_payment_type": creditCard.cardType.rawValue, "token": creditCard.cardNumber, "card_io_credit_card_info": creditCard], titleText: creditCard.cardNumber, canSelect: false, canDelete: true)
            
            paymentMethodSection.append(card)
        }
        paymentMethodSection.append(addPaymentMethodCell)

        //finally, vehicle information:
        let vehicleDescBrandAndPlate = SettingsCell(placeholderTexts: ["brand".localizedString, "license_plate".localizedString], titleTexts: [brand, plate], cellType: .DoubleTextEntry, selectorsTarget: self, callback: "vehicleDescriptionCallback:",
            userInfo: [
                "textFieldTag": 5,
                "keyboardType": UIKeyboardType.Default.rawValue,
                "returnKeyType": UIReturnKeyType.Next.rawValue,
                "autocorrectionType": UITextAutocorrectionType.No.rawValue,
                "redTintOnOrderedCells": [redCells.contains("brand"), redCells.contains("plate")],
                "returnCallback": "cellReturnCallback:"])
        
        let vehicleDescModelAndColor = SettingsCell(placeholderTexts: ["model".localizedString, "color".localizedString], titleTexts: [model, color], cellType: .DoubleTextEntry, selectorsTarget: self, callback: "vehicleDescriptionCallback:",
            userInfo: [
                "textFieldTag": 7,
                "keyboardType": UIKeyboardType.Default.rawValue,
                "returnKeyType": UIReturnKeyType.Next.rawValue,
                "autocorrectionType": UITextAutocorrectionType.No.rawValue,
                "redTintOnOrderedCells": [redCells.contains("model"), redCells.contains("color")],
                "returnCallback": "cellReturnCallback:"])
        
        let vehicleDescPhone = SettingsCell(placeholderText: "phone_number".localizedString, titleText: phone, cellType: .TextEntry, selectorsTarget: self, callback: "vehicleDescriptionCallback:",
            userInfo: [
                "textFieldTag": 9,
                "keyboardType": UIKeyboardType.NumberPad.rawValue,
                "returnKeyType": UIReturnKeyType.Done.rawValue,
                "autocorrectionType": UITextAutocorrectionType.No.rawValue,
                "redTintOnOrderedCells": [redCells.contains("phone")],
                "returnCallback": "cellReturnCallback:"])

        
        let vehicleDescriptionSection = [vehicleDescBrandAndPlate, vehicleDescModelAndColor]
        
        let vehicleDescriptionSection2 = ("", [vehicleDescPhone])

        switch(step) {
        case 0: return [("enter_your_information".localizedString, formSection)]
        case 1: return [("payment_method", paymentMethodSection)]
        case 2: return [("vehicle_description", vehicleDescriptionSection),vehicleDescriptionSection2]
        default:
            return [
                ("enter_your_information".localizedString, formSection),
                ("payment_method", paymentMethodSection),
                ("vehicle_description", vehicleDescriptionSection),
                vehicleDescriptionSection2,
            ]
        }
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tableSource.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableSource[section].1.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let settingsCell = tableSource[indexPath.section].1[indexPath.row]
        
        let section = self.tableSource[indexPath.section]
        if section.0 == "payment_method" {
            
            //the last row in this section should be to add a credit card
            if indexPath.row == section.1.count - 1 {
                
                var addCreditCardCell = tableView.dequeueReusableCellWithIdentifier("add_credit_card") as? PPAddCreditCardCell
                if addCreditCardCell == nil {
                    addCreditCardCell = PPAddCreditCardCell(reuseIdentifier: "add_credit_card")
                }
                self.tableView.cachedCells.append(addCreditCardCell!)
                return addCreditCardCell!
                
            } else {
                
                let rawCardIOCardType = settingsCell.userInfo["card_io_payment_type"] as? Int ?? 0
                let cardIOCardType = CardIOCreditCardType(rawValue: rawCardIOCardType) ?? .Unrecognized
                let cardToken = settingsCell.userInfo["token"] as? String ?? ""
                
                let reuse = "cc_" + String(rawCardIOCardType) + "_" + cardToken
                
                var cell = tableView.dequeueReusableCellWithIdentifier(reuse) as? PPCreditCardCell
                if cell == nil {
                    cell = PPCreditCardCell(creditCardType: cardIOCardType, reuseIdentifier: reuse)
                }
                cell?.creditCardNumber = settingsCell.titleText
                self.tableView.cachedCells.append(cell!)
                return cell!
                
            }
        }
        
        let cell = settingsCell.tableViewCell(tableView)
        self.tableView.cachedCells.append(cell)
        return cell
    }
    
    
    //MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch(editingStyle) {
        case .Delete:
            let settingsCell = self.tableSource[indexPath.section].1[indexPath.row]
            if let cardInfo = settingsCell.userInfo["card_io_credit_card_info"] as? CardIOCreditCardInfo {
                self.creditCards.remove(cardInfo)
                self.tableView.reloadData()
            }
        case .Insert, .None:
            break
        }
    }
    
    @available(iOS 8.0, *)
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let settingsCell = tableSource[indexPath.section].1[indexPath.row]
        if settingsCell.canDelete {
            let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "delete".localizedString, handler: { (action: UITableViewRowAction, indexPath: NSIndexPath) -> Void in
                let settingsCell = self.tableSource[indexPath.section].1[indexPath.row]
                if let cardInfo = settingsCell.userInfo["card_io_credit_card_info"] as? CardIOCreditCardInfo {
                    self.creditCards.remove(cardInfo)
                    self.tableView.reloadData()
                }
            })
            return [deleteAction]
        }
        return []
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        let settingsCell = tableSource[indexPath.section].1[indexPath.row]
        if settingsCell.canDelete {
            return UITableViewCellEditingStyle.Delete
        }
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let settingsCell = tableSource[indexPath.section].1[indexPath.row]
        return settingsCell.canDelete
    }

    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let settingsCell = tableSource[indexPath.section].1[indexPath.row]
        return settingsCell.canSelect
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let settingsCell = tableSource[indexPath.section].1[indexPath.row]
        if settingsCell.selectorsTarget != nil && settingsCell.cellSelector != nil {
            settingsCell.selectorsTarget!.performSelector(Selector(settingsCell.cellSelector!))
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return SMALL_CELL_HEIGHT
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if step == 2 && section == 1 {
            return 4 //second vehicle description cell
        }
        return BIG_CELL_HEIGHT
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerText = tableSource[section].0
        
        if headerText == "" {
            return nil
        }
        
        let sectionHeader = UIView()
        sectionHeader.backgroundColor = Styles.Colors.stone
        let headerTitle = UILabel()
        headerTitle.font = Styles.FontFaces.bold(12)
        headerTitle.textColor = Styles.Colors.petrol2
        headerTitle.text = headerText
        sectionHeader.addSubview(headerTitle)
        headerTitle.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(sectionHeader).offset(20)
            make.right.equalTo(sectionHeader).offset(-20)
            make.bottom.equalTo(sectionHeader).offset(-10)
        }
        return sectionHeader
        
    }
    
    
    //MARK: selector functions
    
    func formCallback(sender: AnyObject?) {
        if let timer = sender as? NSTimer {
            if let dict = timer.userInfo as? [String: String] {
                firstName = dict["first_name".localizedString] ?? firstName
                lastName = dict["last_name".localizedString] ?? lastName
                email = dict["email".localizedString] ?? email
                password = dict["password".localizedString] ?? password
            }
            timer.invalidate()
        }
    }
    
    func cellReturnCallback(sender: AnyObject?) {
        if let timer = sender as? NSTimer {
            if let dict = timer.userInfo as? [String: Int] {
                let nextTag = (dict["textFieldTag"] ?? 0) + 1
                if let nextTextField = tableView.viewWithTag(nextTag) as? UITextField {
                    nextTextField.becomeFirstResponder()
                } else {
                    tappedNextButton()
                }
            }
            timer.invalidate()
        }
    }
    
    //TODO: save the bottom values to somewhere in settings
    func vehicleDescriptionCallback(sender: AnyObject?) {
        if let timer = sender as? NSTimer {
            if let dict = timer.userInfo as? [String: String] {
                brand = dict["brand".localizedString] ?? brand
                plate = dict["license_plate".localizedString] ?? plate
                model = dict["model".localizedString] ?? model
                color = dict["color".localizedString] ?? color
                phone = dict["phone_number".localizedString] ?? phone
            }
            timer.invalidate()
        }
    }
    
    func addPaymentMethod() {
        let paymentVC = CardIOPaymentViewController(paymentDelegate: self)
        paymentVC.hideCardIOLogo = true
        paymentVC.keepStatusBarStyle = true
        paymentVC.guideColor = Styles.Colors.red2
        paymentVC.navigationBarStyle = .Black
        paymentVC.navigationBar.translucent = false
        //dark style:
        paymentVC.navigationBarTintColor = Styles.Colors.midnight1
        paymentVC.navigationBar.tintColor = Styles.Colors.stone
        
        paymentVC.collectPostalCode = true
        
        if let navVC = self.navigationController {
            navVC.pushViewController(paymentVC, animated: true)
        } else {
            self.presentViewController(paymentVC, animated: true, completion: nil)
        }
        
    }

    
    func presentWithVC(vc: UIViewController?) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if let rootVC = vc ?? appDelegate.window?.rootViewController {
            if let navVC = rootVC.navigationController {
                navVC.pushViewController(self, animated: true)
            } else {
                rootVC.presentViewControllerFromRight(0.3, viewController: self, completion: nil)
            }
        }
        
    }
    
    func dismiss() {
        
        if let navVC = self.navigationController {
            navVC.popViewControllerAnimated(true)
        } else {
            self.dismissViewControllerFromLeft(0.3, completion: nil)
        }
        
    }
    
    func passesValidation(shouldColorCells shouldColorCells: Bool = true) -> Bool {
        
        switch step {
        case 0:
            let failedValidation = firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty
            
            if failedValidation {
                //TODO: Localize these strings
                GeneralHelper.warnUserWithErrorMessage("Please make sure you have filled out your information.")
                
                if shouldColorCells {
                    redCells = []
                    if firstName.isEmpty { redCells.append("firstName") }
                    if lastName.isEmpty { redCells.append("lastName") }
                    if email.isEmpty { redCells.append("email") }
                    if password.isEmpty { redCells.append("password") }
                    tableView.reloadDataAnimated()
                }
                
                return false
            }
        case 1:
            let failedValidation = creditCards.count < 1
            
            if failedValidation {
                //TODO: Localize these strings
                GeneralHelper.warnUserWithErrorMessage("Please add at least one credit card to continue.")
                return false
            }
        case 2:
            let failedValidation = brand.isEmpty || plate.isEmpty || model.isEmpty || color.isEmpty || phone.isEmpty
            
            if failedValidation {
                //TODO: Localize these strings
                GeneralHelper.warnUserWithErrorMessage("Please make sure you have filled out the vehicle description.")
                
                if shouldColorCells {
                    redCells = []
                    if brand.isEmpty { redCells.append("brand") }
                    if plate.isEmpty { redCells.append("plate") }
                    if model.isEmpty { redCells.append("model") }
                    if color.isEmpty { redCells.append("color") }
                    if phone.isEmpty { redCells.append("phone") }
                    tableView.reloadDataAnimated()
                }
                
                return false
            }
        default: break
        }

        return true
    }
    
    //MARK: CardIOPaymentViewControllerDelegate functions
    func userDidCancelPaymentViewController(paymentViewController: CardIOPaymentViewController!) {
        paymentViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //TODO: this should send the credit card info to the parking panda backend
    func userDidProvideCreditCardInfo(cardInfo: CardIOCreditCardInfo!, inPaymentViewController paymentViewController: CardIOPaymentViewController!) {
        creditCards.append(cardInfo)
        self.tableView.reloadData()
        paymentViewController.dismissViewControllerAnimated(true, completion: nil)
    }

    //MARK: PPHeaderViewDelegate
    func tappedBackButton() {

        headerView.rightButtonText = "next".localizedString.uppercaseString

        switch step {
        case 0:
            dismiss()
        case 1, 2:
            step--
            self.tableView.reloadDataAnimated()
        default: break
        }

    }
    
    func tappedNextButton() {
        
        switch step {
        case 0:
            if passesValidation() {
                step++
                headerView.rightButtonText = "next".localizedString.uppercaseString
            }
            self.tableView.reloadDataAnimated()
        case 1:
            if passesValidation() {
                let description = [
                    "brand" : brand ?? "",
                    "plate" : plate ?? "",
                    "model" : model ?? "",
                    "color" : color ?? "",
                    "phone" : phone ?? "",
                ]
                Settings.setCarDescription(description)
                step++
                headerView.rightButtonText = "done".localizedString.uppercaseString
            }
            self.tableView.reloadDataAnimated()
        case 2:
            if passesValidation() {
                ParkingPandaOperations.createUser(email ?? "", password: password ?? "", firstName: firstName ?? "", lastName: lastName ?? "", phone: phone ?? "", completion: { (user, error) -> Void in
                    if user != nil {
                        //we have created a user and are logged in!
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            //these two actions will basically happen at the same time, which, really, is what we want!
                            self.dismiss()
                            self.delegate?.didCreateAccount()
                        })
                    } else {
                        //TODO: show error message
                    }
                })
            }
        default: break
        }
        
    }
    
}


protocol PPCreateUserViewControllerDelegate {
    func didCreateAccount()
}


