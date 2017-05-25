//
//  FriendsTableViewController_Backup.swift
//  Shot
//
//  Created by Brendan Winter on 5/20/17.
//  Copyright © 2017 TechFi Apps. All rights reserved.
//

import Foundation
import Alamofire
import Material
import Contacts
import SwiftSpinner
import Refresher

class FriendsTableViewController_Backup: UITableViewController {
    
    let lightGrayColor = UIColor(red: 243/255, green: 243/255, blue: 243/255, alpha: 1)
    
    var contactStore = CNContactStore()
    var contacts: [CNContact] = []
    var names: [String] = []
    var phoneNumbers: [String] = []
    var activeContacts: [String] = []
    var groups: [String] = []
    var friends: [[[String]]] = [[[]]]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let beatAnimator = BeatAnimator(frame: CGRect(x: 0, y: 0, width: 320, height: 80))
        tableView.addPullToRefreshWithAction({
            OperationQueue().addOperation {
                
                self.askForContactAccess()
                self.retrieveContacts()
                
            }
        }, withAnimator: beatAnimator)
        
        let prefs = UserDefaults.standard
        let contactsSynced = prefs.bool(forKey: "contactsSynced")
        
        if contactsSynced { // check contacts synced
            
            // display synced contacts
            var filePath : String {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                return url!.appendingPathComponent("friends").path
            }
            if let array = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) {
                let contactsList = array as! [[[String]]]
                self.friends = contactsList
                self.tableView.reloadData()
            }
            
            
        } else{ // first time
            
            SwiftSpinner.show("Loading contacts")
            self.askForContactAccess()
            self.retrieveContacts()
            prefs.setValue(true, forKey: "contactsSynced")
            SwiftSpinner.hide()
            
        }
        
    }
    
    
    func askForContactAccess() {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        switch authorizationStatus {
        case .denied, .notDetermined:
            self.contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                if !access {
                    if authorizationStatus == CNAuthorizationStatus.denied {
                        DispatchQueue.main.async(execute: { () -> Void in
                            let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                            let alertController = UIAlertController(title: "Contacts", message: message, preferredStyle: UIAlertControllerStyle.alert)
                            let dismissAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (action) -> Void in
                            }
                            alertController.addAction(dismissAction)
                            self.present(alertController, animated: true, completion: nil)
                        })
                    }
                }
            })
            break
        default:
            break
        }
    }
    
    // REFACTOR
    //    func retrieveActiveContacts() {
    //
    //        let keysToFetch = [
    //            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
    //            CNContactPhoneNumbersKey
    //            ] as [Any]
    //
    //        // Get all the containers
    //        var allContainers: [CNContainer] = []
    //        do {
    //            allContainers = try contactStore.containers(matching: nil)
    //        } catch {
    //        }
    //
    //        // Iterate all containers and append their contacts to our results array
    //        for container in allContainers {
    //            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
    //            do {
    //                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
    //                contacts.append(contentsOf: containerResults)
    //            } catch {
    //            }
    //        }
    //
    //
    //        for contact in self.contacts {
    //
    //            // name
    //            let name: String? = CNContactFormatter.string(from: contact, style: .fullName)
    //            names.append(name!)
    //
    //            // phone number
    //            var phoneNumberActive = ""
    //            if (contact.isKeyAvailable(CNContactPhoneNumbersKey)) {
    //                for phoneNumber:CNLabeledValue in contact.phoneNumbers {
    //                    phoneNumberActive = phoneNumber.value.stringValue
    //
    //                    break
    //                }
    //            }
    //            phoneNumbers.append(phoneNumberActive)
    //
    //        }
    //
    //        print("phone numbers: \(phoneNumbers)")
    //
    //        let data = JSONSerialization.dataWithJSONObject(phoneNumbers, options: nil)
    //        let phoneNumbersJSON = NSString(data: data!, encoding: NSUTF8StringEncoding)
    //
    //        let parameters: [String: String] = [
    //            "phone_numbers": phoneNumbersJSON
    //        ]
    //
    //        Alamofire.request(AppDelegate.getAppDelegate().baseURL + "/contacts", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
    //
    //            if let result = response.result.value {
    //
    //                let response = result as! NSDictionary
    //                print(response)
    //            }
    //        }
    //
    //
    //
    //
    //    }
    
    func retrieveContacts() {
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey
            ] as [Any]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
        }
        
        // Add contacts to array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                contacts.append(contentsOf: containerResults)
            } catch {
            }
        }
        
        for contact in self.contacts {
            let name: String? = CNContactFormatter.string(from: contact, style: .fullName)
            
            if (name != nil) {
                
                // phone number
                var phoneNumber = ""
                if (contact.isKeyAvailable(CNContactPhoneNumbersKey)) {
                    for phoneNumberCN:CNLabeledValue in contact.phoneNumbers {
                        phoneNumber = phoneNumberCN.value.stringValue
                        
                        // checks user against MongoDb
                        self.checkUser(phoneNumber: phoneNumber, name: name!)
                        break
                    }
                }
            }
            
        }
        
        
        
        
        
        // Cannot connect to API
        //                else {
        //
        //                    var filePath : String {
        //                        let manager = FileManager.default
        //                        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        //                        return url!.appendingPathComponent("friends").path
        //                    }
        //
        //                    if let array = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) {
        //
        //                        let contactsList = array as! [[[String]]]
        //                        self.friends = contactsList
        //                        self.tableView.reloadData()
        //
        //                        OperationQueue.main.addOperation {
        //                            self.tableView.stopPullToRefresh()
        //                        }
        //                    }
        //
        //                        // No stored contacts
        //                    else {
        //                        OperationQueue.main.addOperation {
        //                            self.tableView.stopPullToRefresh()
        //                        }
        //
        //                        self.alertError(error: "An error has occurred. Please restart the app.")
        //                    }
        //
        //                }
        //}
        
        
        
    }
    
    
    
    func checkUser(phoneNumber: String, name: String) {
        
        var phoneNumberClean = phoneNumber.replacingOccurrences(of: "(", with: "")
        phoneNumberClean = phoneNumberClean.replacingOccurrences(of: ")", with: "")
        phoneNumberClean = phoneNumberClean.replacingOccurrences(of: "-", with: "")
        phoneNumberClean = phoneNumberClean.replacingOccurrences(of: " ", with: "")
        
        // space character exists
        if let range = phoneNumberClean.range(of: " ") {
            phoneNumberClean = phoneNumberClean.replacingCharacters(in: range, with: "")
        }
        
        if phoneNumberClean.range(of: "+1") == nil {
            phoneNumberClean = "+1" + phoneNumberClean
        }
        
        let parameters: [String: String] = [
            "phone_number": phoneNumberClean
        ]
        
        Alamofire.request(AppDelegate.getAppDelegate().baseURL + "/contact", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            
            if let result = response.result.value {
                let response = result as! NSDictionary
                let userId = response.object(forKey: "user")!
                let validUser = userId as! String
                
                print("valid user: \(validUser)")
                
                if (validUser == "true") {
                    
                    var filePathGroups : String {
                        let manager = FileManager.default
                        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
                        return url!.appendingPathComponent("friendGroups").path
                    }
                    
                    if let testFriendGroups = NSKeyedUnarchiver.unarchiveObject(withFile: filePathGroups) {
                        
                    } else { // testFriendGroups does not exist
                        
                        let groupListDefault = ["Friends"]
                        self.saveGroupsList(groups: groupListDefault, filePath: filePathGroups)
                    }
                    
                    
                    var filePath : String {
                        let manager = FileManager.default
                        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
                        return url!.appendingPathComponent("friends").path
                    }
                    
                    if let array = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) {
                        
                        let storedContacts = array as! [[[String]]]
                        self.friends = storedContacts
                        
                        for storedContact in storedContacts {
                            
                            // add if it doesn't exist in storage
                            if (!storedContact[1].contains(phoneNumberClean))
                            {
                                self.updateContacts(phoneNumber: phoneNumberClean, name: name)
                            }
                        }
                        
                        
                        
                    } else {
                        // nothing in storage, first time
                        self.updateContacts(phoneNumber: phoneNumberClean, name: name)
                    }
                    
                    self.tableView.reloadData()
                    
                    OperationQueue.main.addOperation {
                        self.tableView.stopPullToRefresh()
                    }
                }
                
            }
                
                // Cannot connect to API
            else {
                
                var filePath : String {
                    let manager = FileManager.default
                    let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
                    return url!.appendingPathComponent("friends").path
                }
                
                if let array = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) {
                    
                    let contactsList = array as! [[[String]]]
                    self.friends = contactsList
                    
                    self.tableView.reloadData()
                    
                    OperationQueue.main.addOperation {
                        self.tableView.stopPullToRefresh()
                    }
                }
                    
                    // No stored contacts
                else {
                    self.alertError(error: "An error has occurred. Please restart the app.")
                }
                
            }
            
        }
        
    }
    
    func updateContacts(phoneNumber: String, name: String) {
        
        self.names.append(name)
        self.phoneNumbers.append(phoneNumber)
        self.activeContacts.append("false")
        
        print("names \(self.names)")
        print("phone numbers: \(self.phoneNumbers)")
        
        
        var friendsSection = [[[String]]]()
        var friendSection = [[String]]()
        
        friendSection.append(self.names)
        friendSection.append(self.phoneNumbers)
        friendSection.append(self.activeContacts)
        
        friendsSection.append(friendSection)
        
        self.friends = friendsSection
        
        var filePath : String {
            let manager = FileManager.default
            let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
            return url!.appendingPathComponent("friends").path
        }
        self.saveFriendsList(friends: friendsSection, filePath: filePath)
        
    }
    
    func saveGroupsList(groups: [String], filePath: String) {
        NSKeyedArchiver.archiveRootObject(groups, toFile: filePath)
    }
    
    func saveFriendsList(friends: [[[String]]], filePath: String) {
        NSKeyedArchiver.archiveRootObject(friends, toFile: filePath)
    }
    
    
    func alertError(error: String) {
        let alertController = UIAlertController(title: "Error", message:
            error, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    func getAppDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        preparePageTabBarItem()
    }
    init() {
        super.init(nibName: nil, bundle: nil)
        preparePageTabBarItem()
    }
    
    func preparePageTabBarItem() {
        pageTabBarItem.title = "FRIENDS"
        pageTabBarItem.tintColor = .white
    }
    
    
}
