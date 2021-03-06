//
//  FriendsViewController.swift
//  Shot
//
//  Created by Brendan Winter on 11/8/16.
//  Copyright © 2016 TechFi Apps. All rights reserved.
//

import Foundation
import Alamofire
import Material
import Contacts
import Refresher

class FriendsTableViewController: UITableViewController {
    
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
                self.getContacts()
                self.tableView.reloadData()
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
        } else { // first time
            self.askForContactAccess()
            self.getContacts()
            prefs.setValue(true, forKey: "contactsSynced")
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
    
    func getContacts() {
        let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey] as [Any]
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch { }
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                contacts.append(contentsOf: containerResults)
            } catch { }
        }
        
        for contact in self.contacts {
            
            // get full name and check if nil
            if let name = CNContactFormatter.string(from: contact, style: .fullName) {
                
                // phone number
                if (contact.isKeyAvailable(CNContactPhoneNumbersKey)) {
                    for phoneNumberCN:CNLabeledValue in contact.phoneNumbers {
                        
                        // clean phone number
                        var phoneNumberClean = phoneNumberCN.value.stringValue.replacingOccurrences(of: "(", with: "")
                        phoneNumberClean = phoneNumberClean.replacingOccurrences(of: ")", with: "")
                        phoneNumberClean = phoneNumberClean.replacingOccurrences(of: "-", with: "")
                        phoneNumberClean = phoneNumberClean.replacingOccurrences(of: " ", with: "")
                        if let range = phoneNumberClean.range(of: " ") {
                            phoneNumberClean = phoneNumberClean.replacingCharacters(in: range, with: "")
                        }
                        if phoneNumberClean.range(of: "+1") == nil {
                            phoneNumberClean = "+1" + phoneNumberClean
                        }
                        
                        // add to array
                        self.names.append(name)
                        self.phoneNumbers.append(phoneNumberClean)
                        break
                    }
                }
            }
        }
        
        // input: [names], [phone_numbers]
        // output: "valid" [names], [phone_numbers]
        let parameters: [String: [String]] = [
            "names": self.names,
            "phone_numbers": self.phoneNumbers
        ]
        
        // clear array
        self.names = []
        self.phoneNumbers = []
        
        // check valid contacts
        Alamofire.request(AppDelegate.getAppDelegate().baseURL + "/contacts", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            
            if let result = response.result.value {
                let response = result as! NSDictionary
                let contacts = response.object(forKey: "contacts")! as! String
                let validUsers = self.convertToDictionary(text: contacts)!
                
                // create group to put users
                var filePathGroups : String {
                    let manager = FileManager.default
                    let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
                    return url!.appendingPathComponent("friendGroups").path
                }
                // populate friends for first time
                //if (NSKeyedUnarchiver.unarchiveObject(withFile: filePathGroups) == nil) {
                    let groupListDefault = ["Friends"]
                    self.saveGroupsList(groups: groupListDefault, filePath: filePathGroups)
                //}
                // reset friends storage to remove contacts
                var friendsSection = [[[String]]]()
                var filePath : String {
                    let manager = FileManager.default
                    let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
                    return url!.appendingPathComponent("friends").path
                }
                self.saveFriendsList(friends: friendsSection, filePath: filePath)
                // add users to NSKeyedArchive
                for user in validUsers {
                    self.updateContacts(phoneNumber: user.value as! String, name: user.key)
                }
            }
                
            // unable to connect to API
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
                } else { // no stored contacts
                    self.alertError(error: "An error has occurred. Please restart the app.")
                }
            }
        }
        OperationQueue.main.addOperation {
            self.tableView.stopPullToRefresh()
        }
    }
   
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
            }
        }
        return nil
    }

    func updateContacts(phoneNumber: String, name: String) {
        
        names.append(name)
        phoneNumbers.append(phoneNumber)
        activeContacts.append("false")
        var friendsSection = [[[String]]]()
        var friendSection = [[String]]()
        friendSection.append(names)
        friendSection.append(phoneNumbers)
        friendSection.append(activeContacts)
        friendsSection.append(friendSection)
        friends = friendsSection
        
        var filePath : String {
            let manager = FileManager.default
            let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
            return url!.appendingPathComponent("friends").path
        }
        self.saveFriendsList(friends: friendsSection, filePath: filePath)
        tableView.reloadData()
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
        pageTabBarItem.titleColor = .white
    }
}

//
// MARK: - View Controller DataSource and Delegate
//
extension FriendsTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !friends.isEmpty {
            return friends[0][0].count
        } else {
            return 0
        }
    }
    
    // Cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell? ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
        
        cell.textLabel?.text = friends[0][0][(indexPath as NSIndexPath).row]
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 15, height: 15))
        
        imageView.image = UIImage(named: "bullet_unmarked.png") // default to unmarked
        cell.accessoryView = imageView
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }
    
    // Header
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? CollapsibleTableViewHeader ?? CollapsibleTableViewHeader(reuseIdentifier: "header")
        
        //header.titleLabel.text = sections[section].name
        header.titleLabel.text = "Friends"
        header.arrowLabel.text = ""
        header.setCollapsed(true)
        
        header.section = section
        header.delegate = self
        
        return header
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44.0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

//
// MARK: - Section Header Delegate
//
extension FriendsTableViewController: CollapsibleTableViewHeaderDelegate {
    
    func toggleSection(_ header: CollapsibleTableViewHeader, section: Int) {
        let collapsed = true
        header.setCollapsed(collapsed)
        
        // Adjust the height of the rows inside the section
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}
