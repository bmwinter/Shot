//
//  GroupsViewController.swift
//  Shot
//
//  Created by Brendan Winter on 11/8/16.
//  Copyright © 2016 TechFi Apps. All rights reserved.
//

import Foundation
import Material

class GroupsTableViewController: UITableViewController {
    
    // friends: [[name, phone_number, active]
    var groups = [String]()
    var friends = [[[String]]]()
    var collapsed = [Bool]()
    
    var tField: UITextField!
    
    override func viewDidLoad() {
 
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        
        // groups
        var filePathGroups : String {
            let manager = FileManager.default
            let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
            return url!.appendingPathComponent("friendGroups").path
        }
        
        if let testFriendGroups = NSKeyedUnarchiver.unarchiveObject(withFile: filePathGroups) {
            
            self.groups = testFriendGroups as! [String]
            
            for g in groups {
                collapsed.append(false)
            }
            
        } else { // testFriendGroups does not exist, redundant done in contacts
            
            let groupListDefault = ["Friends"]
            self.saveGroupsList(groups: groupListDefault, filePath: filePathGroups)
            collapsed = [false]
        }
        // end groups
        
        // friends
        var filePath : String {
            let manager = FileManager.default
            let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
            return url!.appendingPathComponent("friends").path
        }
        
        if let array = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) {
            
            let storedContacts = array as! [[[String]]]
            
            self.friends = storedContacts
            //self.tableView.reloadData()
            
        } else {
            // nothing in storage, first time
        }
        // end friends
        
        
    }
    
    func saveGroupsList(groups: [String], filePath: String) {
        NSKeyedArchiver.archiveRootObject(self.groups, toFile: filePath)
    }
    
    func saveFriendsList(friends: [[[String]]], filePath: String) {
        NSKeyedArchiver.archiveRootObject(self.friends, toFile: filePath)
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
        pageTabBarItem.title = "GROUPS"
        pageTabBarItem.tintColor = .white
    }
}




//
// MARK: - View Controller DataSource and Delegate
//
extension GroupsTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends[section][0].count + 2
    }
    
    // Cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell? ?? UITableViewCell(style: .default, reuseIdentifier: "cell")
               
        // delete cell
        if (indexPath.row == tableView.numberOfRows(inSection: (indexPath as NSIndexPath).section) - 2) {
            
            // delete button
            cell.textLabel?.text = "delete"
            cell.textLabel?.textColor = UIColor(red: 255/255, green: 59/255, blue: 48/255, alpha: 1)
            cell.textLabel?.textAlignment = .center
            cell.accessoryView = nil
          
        }
        // add cell
        else if (indexPath.row == tableView.numberOfRows(inSection: (indexPath as NSIndexPath).section) - 1) {

            // add group button
            cell.textLabel?.text = "add group"
            cell.textLabel?.textColor = UIColor.black
            cell.textLabel?.textAlignment = .center
            cell.accessoryView = nil
            
        }
        // normal cell
        else {
            cell.textLabel?.text = friends[(indexPath as NSIndexPath).section][0][(indexPath as NSIndexPath).row]
            cell.textLabel?.textColor = UIColor.black
            cell.textLabel?.textAlignment = .left
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 15, height: 15))
            
            let activeContact = friends[(indexPath as NSIndexPath).section][2][(indexPath as NSIndexPath).row]
            
            if (activeContact == "true") {
                imageView.image = UIImage(named: "bullet_marked.png")
                cell.accessoryView = imageView
            } else {
                imageView.image = UIImage(named: "bullet_unmarked.png")
                cell.accessoryView = imageView
            }
            
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return collapsed[(indexPath as NSIndexPath).section] ? 0 : 44.0
    }
    
    // Header
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "header") as? CollapsibleTableViewHeader ?? CollapsibleTableViewHeader(reuseIdentifier: "header")
        
        header.titleLabel.text = groups[section]
        header.arrowLabel.text = ">"
        
        header.setCollapsed(collapsed[section])
        
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
        
        let totalRows = tableView.numberOfRows(inSection: (indexPath as NSIndexPath).section)
        
        // delete group
        if (totalRows == indexPath.row + 2)  {
            alertDeleteMessage(message: "Are you sure you want to delete this group?", section: indexPath.section)
        }
        // add group
        else if (totalRows == indexPath.row + 1)  {
            alertAddMessage()
        }
        // default
        else {
            
            let activeContact = friends[(indexPath as NSIndexPath).section][2][(indexPath as NSIndexPath).row]
            
            var filePath : String {
                let manager = FileManager.default
                let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
                return url!.appendingPathComponent("friends").path
            }
            
            if let array = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) {
                
                var storedContacts = array as! [[[String]]]
                
                if (activeContact == "false") {
                    storedContacts[(indexPath as NSIndexPath).section][2][(indexPath as NSIndexPath).row] = "true"

                } else {
                    storedContacts[(indexPath as NSIndexPath).section][2][(indexPath as NSIndexPath).row] = "false"
                }
                
                self.friends = storedContacts
                self.saveFriendsList(friends: storedContacts, filePath: filePath)
                self.tableView.reloadData()
                
            }
            
        }
        
        
        
    }
    
    
    func configurationTextField(textField: UITextField!)
    {
        textField.placeholder = "Enter an item"
        tField = textField
    }
    
    func handleCancel(alertView: UIAlertAction!)
    {
    }
    
    func alertDeleteMessage(message: String, section: Int) {
        let alertController = UIAlertController(title: "Message", message:
            message, preferredStyle: UIAlertControllerStyle.alert)
        let alertTitle = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { (action) in
            
            if (self.groups.count != 1) {
            
                // update local values
                self.friends.remove(at: section)
                self.groups.remove(at: section)
            
                // store local values
                var filePathGroups : String {
                    let manager = FileManager.default
                    let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
                    return url!.appendingPathComponent("friendGroups").path
                }
                var filePath : String {
                    let manager = FileManager.default
                    let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
                    return url!.appendingPathComponent("friends").path
                }
                self.saveGroupsList(groups: self.groups, filePath: filePathGroups)
                self.saveFriendsList(friends: self.friends, filePath: filePath)
            
                self.tableView.reloadData()
            } else {
                // one group left
            }
            
        }
        alertController.addAction(alertTitle)
        
        let cancelAction = UIAlertAction(title: "Dismiss", style: .cancel)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func alertAddMessage() {
        let alert = UIAlertController(title: "Enter group name", message: "", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: configurationTextField)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:handleCancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler:{ (UIAlertAction) in
            
            let groupTitle = self.tField.text!
            
            // add group
            
            // update local values
            var friendList = self.friends[0]
            var activeContacts = [String]()

            for i in 0..<friendList[0].count {
                activeContacts.append("false")
            }
            
            // apply to current section
            friendList[2] = activeContacts
            
            self.friends.append(friendList)
            self.groups.append(groupTitle)
            self.collapsed.append(false)

            // store local values
            var filePathGroups : String {
                let manager = FileManager.default
                let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
                return url!.appendingPathComponent("friendGroups").path
            }
            var filePath : String {
                let manager = FileManager.default
                let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
                return url!.appendingPathComponent("friends").path
            }
            self.saveGroupsList(groups: self.groups, filePath: filePathGroups)
            self.saveFriendsList(friends: self.friends, filePath: filePath)
            
            self.tableView.reloadData()
            
        }))
        self.present(alert, animated: true, completion: {
        })

    }

}

//
// MARK: - Section Header Delegate
//
extension GroupsTableViewController: CollapsibleTableViewHeaderDelegate {
    
    func toggleSection(_ header: CollapsibleTableViewHeader, section: Int) {
        
        let collapse = !collapsed[section]
        
        // Toggle collapse
        collapsed[section] = collapse
        header.setCollapsed(collapse)
        
        
        
        // Adjust the height of the rows inside the section
        tableView.beginUpdates()
        for i in 0 ..< friends[section][0].count {
            tableView.reloadRows(at: [IndexPath(row: i, section: section)], with: .automatic)
        }
        tableView.endUpdates()
        
    }
    
}

