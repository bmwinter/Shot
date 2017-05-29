//
//  SignupViewController.swift
//  Shot
//
//  Created by Brendan Winter on 11/3/16.
//  Copyright © 2016 TechFi Apps. All rights reserved.
//

import UIKit
import Material
import Alamofire
import SwiftSpinner

class SignupViewController: UIViewController, UITextFieldDelegate {
    
    let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
    let darkBlackColor = UIColor(red: 38/255, green: 35/255, blue: 36/255, alpha: 1)
    let darkGrayColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)
    let lightGrayColor = UIColor(red: 243/255, green: 243/255, blue: 243/255, alpha: 1)
    private var firstNameField: TextField!
    private var lastNameField: TextField!
    private var phoneNumberField: TextField!
    private var smsCodeField: TextField!
    private var smsCodeButton: UIButton!
    private var signupButton: UIButton!
    
    private let constant: CGFloat = 50
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        preparePageTabBarItem()
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        preparePageTabBarItem()
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 50))
        label.text = "SIGN-UP"
        label.textAlignment = NSTextAlignment.center
        label.textColor = .white
        label.backgroundColor = darkBlackColor
        self.view.addSubview(label)
        
        prepareFirstNameField()
        prepareLastNameField()
        preparePhoneNumberField()
        
        signupButton = UIButton(type: .system) // let preferred over var here
        signupButton.frame = CGRect(x: constant, y: 6.5 * constant, width: view.width - (2 * constant), height: constant)
        signupButton.addTarget(self, action: #selector(SignupViewController.sendSMSCode), for: UIControlEvents.touchUpInside)
        signupButton.setTitle("SIGN-UP", for: UIControlState.normal)
        signupButton.backgroundColor = Color.white
        signupButton.backgroundColor = darkBlackColor
        signupButton.tintColor = UIColor.white
        signupButton.cornerRadius = 0
        signupButton.borderColor = darkBlackColor
        signupButton.borderWidth = 1
        view.addSubview(signupButton)
    }
    
    @objc
    internal func handleResignResponderButton(button: UIButton) {
        firstNameField?.resignFirstResponder()
        lastNameField?.resignFirstResponder()
        phoneNumberField?.resignFirstResponder()
    }
    
    private func prepareFirstNameField() {
        
        firstNameField = TextField(frame: CGRect(x: constant, y: 2 * constant, width: view.width - (2 * constant), height: constant))
        firstNameField.placeholder = "first name"
        firstNameField.placeholderNormalColor = darkBlackColor
        firstNameField.placeholderActiveColor = darkGrayColor
        firstNameField.dividerNormalColor = lightGrayColor
        firstNameField.dividerActiveColor = lightGrayColor
        firstNameField.backgroundColor = lightGrayColor
        firstNameField.layer.borderColor = darkBlackColor.cgColor
        firstNameField.layer.borderWidth = 1.0
        firstNameField.returnKeyType = .next
        firstNameField.tag = 0
        firstNameField.delegate = self
        firstNameField.becomeFirstResponder()
        view.addSubview(firstNameField)
    }
    
    private func prepareLastNameField() {
        
        lastNameField = TextField(frame: CGRect(x: constant, y: 3.5 * constant, width: view.width - (2 * constant), height: constant))
        lastNameField.placeholder = "last name"
        lastNameField.leftViewMode = UITextFieldViewMode.always
        lastNameField.placeholderNormalColor = darkBlackColor
        lastNameField.placeholderActiveColor = darkGrayColor
        lastNameField.dividerNormalColor = lightGrayColor
        lastNameField.dividerActiveColor = lightGrayColor
        lastNameField.backgroundColor = lightGrayColor
        lastNameField.layer.borderColor = darkBlackColor.cgColor
        lastNameField.layer.borderWidth = 1.0
        lastNameField.returnKeyType = .next
        lastNameField.tag = 1
        lastNameField.delegate = self
        view.addSubview(lastNameField)
    }
    
    private func preparePhoneNumberField() {
        
        // create phone number text field
        phoneNumberField = TextField(frame: CGRect(x: constant, y: 5 * constant, width: view.width - (2 * constant), height: constant))
        phoneNumberField.text = "+1"
        phoneNumberField.keyboardType = UIKeyboardType.numberPad
        phoneNumberField.placeholderNormalColor = darkBlackColor
        phoneNumberField.placeholderActiveColor = darkGrayColor
        phoneNumberField.dividerNormalColor = lightGrayColor
        phoneNumberField.dividerActiveColor = lightGrayColor
        phoneNumberField.backgroundColor = lightGrayColor
        phoneNumberField.layer.borderColor = darkBlackColor.cgColor
        phoneNumberField.layer.borderWidth = 1.0
        phoneNumberField.tag = 2
        phoneNumberField.delegate = self
        view.addSubview(phoneNumberField)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        // Try to find next responder
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        // Do not add a line break
        return false
    }
    
    private func prepareSMSCodeField() {
        
        smsCodeField = TextField(frame: CGRect(x: constant, y: 4 * constant, width: view.width - (2 * constant), height: constant))
        smsCodeField.placeholder = "sms code"
        smsCodeField.keyboardType = UIKeyboardType.numberPad
        smsCodeField.placeholderNormalColor = darkBlackColor
        smsCodeField.placeholderActiveColor = darkGrayColor
        smsCodeField.dividerNormalColor = lightGrayColor
        smsCodeField.dividerActiveColor = lightGrayColor
        smsCodeField.backgroundColor = lightGrayColor
        smsCodeField.layer.borderColor = darkBlackColor.cgColor
        smsCodeField.layer.borderWidth = 1.0
        view.addSubview(smsCodeField)

        smsCodeButton = UIButton(type: .system) // let preferred over var here
        smsCodeButton.frame = CGRect(x: constant, y: 5.5 * constant, width: view.width - (2 * constant), height: constant)
        smsCodeButton.backgroundColor = Color.white
        smsCodeButton.setTitle("CONFIRM", for: UIControlState.normal)
        smsCodeButton.addTarget(self, action: #selector(SignupViewController.verifySMSAndRegister), for: UIControlEvents.touchUpInside)
        smsCodeButton.backgroundColor = darkBlackColor
        smsCodeButton.tintColor = UIColor.white
        smsCodeButton.cornerRadius = 0
        smsCodeButton.borderColor = darkBlackColor
        smsCodeButton.borderWidth = 1
        view.addSubview(smsCodeButton)
    }
    
    func sendSMSCode() {
        
        let phoneNumberText = phoneNumberField.text!
        if (firstNameField.text == "") {
            alertError(error: "Must enter first name.")
        }
        else if (lastNameField.text == "") {
            alertError(error: "Must enter last name.")
        }
        else if (phoneNumberField.text == "" || phoneNumberField.text == "+1") {
            alertError(error: "Must enter phone number.")
        }
        else if (!validate(value: phoneNumberText)) {
            alertError(error: "Invalid phone number. Must include +1.")
        }
        else {
            let parameters: [String: String] = [
                "phone_number": phoneNumberText
            ]
            Alamofire.request(AppDelegate.getAppDelegate().baseURL + "/user/verify", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                if response.result.value != nil {
                    self.smsCodeSentAlert(phone_number: phoneNumberText)
                    self.firstNameField.removeFromSuperview()
                    self.lastNameField.removeFromSuperview()
                    self.phoneNumberField.removeFromSuperview()
                    self.signupButton.removeFromSuperview()
                    self.prepareSMSCodeField()
                } else {
                    self.alertError(error: "An error has occurred. Please restart the app.")
                }
            }
        }
    }
    
    func verifySMSAndRegister() {
        
        // retrieve text field values
        let phoneNumberText = phoneNumberField.text!
        let firstNameText = firstNameField.text!
        let lastNameText = lastNameField.text!
        
        // check if sms code value blank
        guard let smsCodeText = smsCodeField.text else {
            alertError(error: "Must enter SMS code.")
            return
        }
        
        // call /user/verify/enter
        let parameters: [String: String] = [
            "phone_number": phoneNumberText,
            "code": smsCodeText
        ]
        Alamofire.request(AppDelegate.getAppDelegate().baseURL + "/user/verify/enter", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            
            guard let result = response.result.value else {
                self.alertError(error: "Invalid SMS code.")
                return
            }
            
            let JSON = result as! NSDictionary
            if (JSON.object(forKey: "error") != nil)  {
                self.alertError(error: "Please try again in 5 minutes.")
                return
            }
            
            // store to defaults
            let requestId = JSON.object(forKey: "request_id")!
            let prefs = UserDefaults.standard
            prefs.setValue(phoneNumberText, forKey: "phone_number")
            
            // device token
            let deviceToken = prefs.string(forKey: "token")!
            let full_name = firstNameText + " " + lastNameText
            let parameters_register = [
                "name": full_name,
                "phone_number": phoneNumberText,
                "token": requestId,
                "device_token": deviceToken
            ]
            
            // register user
            Alamofire.request(AppDelegate.getAppDelegate().baseURL + "/user/register", method: .post, parameters: parameters_register, encoding: JSONEncoding.default).responseJSON { response in
    
                if response.result.value != nil {
                    prefs.setValue("true", forKey: "loggedIn")
                    self.displayApplication() // display app
                } else {
                    self.alertError(error: "Cannot register for account")
                    return
                }
            }
        }
    }
    
    func displayApplication() {
        
        let vc = ShotPageTabBarController(viewControllers: [PostsViewController(), GroupsTableViewController(), FriendsTableViewController()], selectedIndex: 2)
        self.present(vc, animated: true, completion: nil)
    }
    
    func alertError(error: String) {
        
        let alertController = UIAlertController(title: "Error", message:
            error, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func smsCodeSentAlert(phone_number: String) {
        
        let message = "Text message has been sent to \(phone_number)"
        let alertController = UIAlertController(title: "Message", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func validate(value: String) -> (Bool) {

        // check for 10 digit phone number plus country code
        let phoneRegex = "[+][0-9]{11}" //+12223334444
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        if phoneTest.evaluate(with: value) {
            return (true)
        }
        return (false)
    }

    func preparePageTabBarItem() {
        pageTabBarItem.title = "SIGN-UP"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
}
