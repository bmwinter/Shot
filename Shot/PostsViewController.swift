//
//  PostsViewController2.swift
//  Shot
//
//  Created by Brendan Winter on 5/25/17.
//  Copyright © 2017 TechFi Apps. All rights reserved.
//

import Foundation
import AVFoundation
import Alamofire
import Material
import SwiftSpinner
import Kingfisher
import UIDropDown

class PostsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var scrollView: UIScrollView!
    var imageView: UIImageView!
    var imageURLS = [String]()
    var currentImageIndex = 0
    let tapRecognizer = UITapGestureRecognizer()
    var noPostsDisplaying = false
    var viewAppear = false
    var groups = [String]()
    var selectedGroup = ""
    var selectedGroupIndex = -1
    var drop: UIDropDown!
    var label: UILabel!
    var imageViewPost: UIImageView!
    let darkBlackColor = UIColor(red: 38/255, green: 35/255, blue: 36/255, alpha: 1)
    let darkGrayColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 1)
    let lightGrayColor = UIColor(red: 243/255, green: 243/255, blue: 243/255, alpha: 1)
    private let constant: CGFloat = 50
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // retrieve and display posts
        if (!viewAppear) {
            //SwiftSpinner.show("Retrieving posts...")
            retrievePosts()
            viewAppear = true
        }
    }
    
    func retrievePosts() {
        
        let prefs = UserDefaults.standard
        let token = prefs.string(forKey: "token")!
        let parameters: [String: String] = [
            "token": token
        ]
        Alamofire.request(AppDelegate.getAppDelegate().baseURL + "/posts/post", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            
            // check for posts
            guard let result = response.result.value else {
                self.displayNoPosts()
                return
            }
                        
            // add posts to media_url array
            let resultArray = result as! NSArray
            for r in 0..<resultArray.count {
                let resultDictionary = resultArray[r] as! NSDictionary
                let media_url = resultDictionary.object(forKey: "media_url") as! String
                let timestamp = resultDictionary.object(forKey: "timestamp")
                    
                // check posted within 24 hours
                if (self.activePost(timestamp: timestamp as! String)) {
                    self.imageURLS.append(media_url)
                }
            }
            
            if self.imageURLS.count > 0 {
                if self.scrollView != nil {
                    OperationQueue.main.addOperation {
                        self.scrollView.stopPullToRefresh()
                    }
                }
                self.loadImages()
                UIApplication.shared.applicationIconBadgeNumber = 0
                
            } else {
                self.noPostsDisplaying = false
                self.displayNoPosts()
            }
        }
        
    }
    
    func activePost(timestamp: String) -> Bool {
        
        let oneDayAgo =  NSDate(timeIntervalSinceNow: -86400)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from: timestamp) {
            let compareDate = oneDayAgo.compare(date)
            var lessThanDayOld = false
            
            switch compareDate {
            case ComparisonResult.orderedAscending:
                lessThanDayOld = true
            case ComparisonResult.orderedDescending:
                lessThanDayOld = false
            default:
                lessThanDayOld = false
            }
            
            return lessThanDayOld
        }
        
        return false
    }
    
    func displayNoPosts() {
        
        if self.scrollView != nil {
            OperationQueue.main.addOperation {
                self.scrollView.stopPullToRefresh()
            }
        }
        SwiftSpinner.hide()
        noPostsAvailable()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func noPostsAvailable() {
        
        if noPostsDisplaying == false {
            
            self.label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            self.label.center = CGPoint(x: self.view.frame.size.width/2, y: self.view.frame.size.height/2 - 30)
            self.label.textAlignment = .center
            self.label.text = "no posts available"
            
            let newPostButton = UIButton(type: .system)
            newPostButton.frame = CGRect(x: self.view.frame.width - (self.view!.width - self.constant), y: self.view.frame.height - 2*self.constant, width: (self.view!.width - (2 * self.constant)), height: self.constant)
            newPostButton.backgroundColor = Color.white
            newPostButton.setTitle("NEW PICTURE", for: UIControlState.normal)
            newPostButton.addTarget(self, action: #selector(PostsViewController.displayCamera), for: UIControlEvents.touchUpInside)
            newPostButton.backgroundColor = self.darkBlackColor
            newPostButton.tintColor = UIColor.white
            newPostButton.cornerRadius = 0
            newPostButton.borderColor = self.darkBlackColor
            newPostButton.borderWidth = 1
    
            self.scrollView = UIScrollView(frame: view.bounds)
            self.scrollView.contentSize = view.bounds.size
            self.scrollView.alwaysBounceVertical = true
            self.scrollView.addSubview(self.label)
            self.scrollView.addSubview(newPostButton)
            self.view.addSubview(scrollView)
            
            self.noPostsDisplaying = true
            
            // pull to refresh fetches new images
            let beatAnimator = BeatAnimator(frame: CGRect(x: 0, y: 0, width: 320, height: 80))
            scrollView.addPullToRefreshWithAction({
                OperationQueue().addOperation {
                    if (self.checkNotificationSettings()) {
                        self.retrievePosts()
                    }
                }
            }, withAnimator: beatAnimator)
        }
    }
    
    
    func loadImages() {
        
        // cache all images in order to show latest first
        currentImageIndex = self.imageURLS.count - 1
      
        for i in 0...self.imageURLS.count - 1 {
            let url = URL(string: self.imageURLS[i])
            imageView = UIImageView(frame: CGRect(x: 0,y: 0, width: view.frame.size.width, height: view.frame.size.height))
            imageView!.kf.setImage(with: url)
            imageView!.isUserInteractionEnabled = true
            
            // set tap gesture to top image
            if i == currentImageIndex {
                tapRecognizer.addTarget(self, action: #selector(PostsViewController.nextImage))
                imageView.addGestureRecognizer(tapRecognizer)
                scrollView = UIScrollView(frame: view.bounds)
                scrollView.contentSize = view.bounds.size
                scrollView.alwaysBounceVertical = true
                scrollView.addSubview(imageView!)
                view.addSubview(scrollView)
            }
        }
        SwiftSpinner.hide()
    }
    
    func nextImage() {
        
        // checks to start new loop through image stack
        if (currentImageIndex > 0) {
            currentImageIndex = currentImageIndex - 1
            loadNextImage()
        } else {
            
            // reset to beginning of image stack
            currentImageIndex = self.imageURLS.count - 1
            displayCameraAlert()
        }
    }
    
    func loadNextImage() {
        
        if (imageURLS.count > 0) {
            let url = URL(string: imageURLS[currentImageIndex])
            imageView!.kf.setImage(with: url)
        }
    }
    
    func displayCameraAlert() {
        
        let alertController = UIAlertController(title: "Message", message:
            "Your turn!", preferredStyle: UIAlertControllerStyle.alert)
        let alertTitle = UIAlertAction(title: "Okay", style: UIAlertActionStyle.default) { (action) in
            self.displayCamera()
            self.loadNextImage()
        }
        alertController.addAction(alertTitle)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            self.clearPosts() // removes current posts and calls loadPosts()
        }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func displayCamera() {
        
        // check for permissions for notifications
        if (checkNotificationSettings()) {
            
            // check for permissions for camera
            let authStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
            switch(authStatus) {
                
            case .authorized:
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
                    imagePicker.allowsEditing = false
                    self.present(imagePicker, animated: true, completion: nil)
                }
                
            case .denied:
                let alertController = UIAlertController(title: "Error", message:
                    "Please enable Camera permission via Settings.", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default,handler: nil))
                let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.openURL(settingsUrl)
                    }
                }
                alertController.addAction(settingsAction)
                
                self.present(alertController, animated: true, completion: nil)
                
            case .restricted:
                let alertController = UIAlertController(title: "Error", message:
                    "Please enable Camera permission via Settings.", preferredStyle: UIAlertControllerStyle.alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                self.present(alertController, animated: true, completion: nil)
                
            case .notDetermined:
                let mediaType = AVMediaTypeVideo
                AVCaptureDevice.requestAccess(forMediaType: mediaType) {
                    (granted) in
                    if granted == true {
                        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
                            let imagePicker = UIImagePickerController()
                            imagePicker.delegate = self
                            imagePicker.sourceType = UIImagePickerControllerSourceType.camera;
                            imagePicker.allowsEditing = false
                            self.present(imagePicker, animated: true, completion: nil)
                        }
                    } else { // Deny selected
                        let alertController = UIAlertController(title: "Error", message:
                            "Please enable Camera permission via Settings.", preferredStyle: UIAlertControllerStyle.alert)
                        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
                        
                        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                            guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                                return
                            }
                            
                            if UIApplication.shared.canOpenURL(settingsUrl) {
                                UIApplication.shared.openURL(settingsUrl)
                            }
                        }
                        alertController.addAction(settingsAction)
                        self.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        self.dismiss(animated: true, completion: nil)
        
        // preview post
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        if (image != nil) {
            
            let previewImageView = UIImageView(frame: CGRect(x: 0,y: 0, width: view.frame.size.width, height: view.frame.size.height))
            previewImageView.image = image!
            view.addSubview(previewImageView)
            
            imageViewPost = previewImageView
            
            // select group
            prepareGroupDropdown()
            
            // send to post members or cancel post
            preparePostButtons()
        }
    }
    
    func preparePostButtons() {
        
        let cancelButton = UIButton(type: .system)
        cancelButton.frame = CGRect(x: constant/2, y: self.view.frame.height - 2*constant, width: (self.view!.width - (2 * constant))/2, height: constant)
        cancelButton.backgroundColor = Color.white
        cancelButton.setTitle("CANCEL", for: UIControlState.normal)
        // cancel action, display CameraViewController
        cancelButton.addTarget(self, action: #selector(PostsViewController.cancelPreview), for: UIControlEvents.touchUpInside)
        cancelButton.backgroundColor = self.darkBlackColor
        cancelButton.tintColor = UIColor.white
        cancelButton.cornerRadius = 0
        cancelButton.borderColor = self.darkBlackColor
        cancelButton.borderWidth = 1
        self.view.addSubview(cancelButton)
        
        let sendButton = UIButton(type: .system)
        sendButton.frame = CGRect(x: self.view.frame.width - (self.view!.width - (2 * constant))/2 - constant/2, y: self.view.frame.height - 2*constant, width: (self.view!.width - (2 * constant))/2, height: constant)
        sendButton.backgroundColor = Color.white
        sendButton.setTitle("SEND", for: UIControlState.normal)
        sendButton.addTarget(self, action: #selector(PostsViewController.post), for: UIControlEvents.touchUpInside)
        sendButton.backgroundColor = self.darkBlackColor
        sendButton.tintColor = UIColor.white
        sendButton.cornerRadius = 0
        sendButton.borderColor = self.darkBlackColor
        sendButton.borderWidth = 1
        self.view.addSubview(sendButton)
    }
    
    func cancelPreview() {
        noPostsDisplaying = false
        clearPosts()
    }
    
    func clearPosts() {
        let subViews = self.view.subviews
        for subview in subViews{
            subview.removeFromSuperview()
        }
        loadImages()
    }
    
    func post() {
        
        SwiftSpinner.show("Sending post...")
        if (self.selectedGroupIndex != -1) {
            let prefs = UserDefaults.standard
            let token = prefs.string(forKey: "token")
            let image = UIImageJPEGRepresentation(imageViewPost.image!, 0.1)!
            
            // retrieve members
            var members = [String]()
            var filePath : String {
                let manager = FileManager.default
                let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
                return url!.appendingPathComponent("friends").path
            }
            if let array = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) {
                
                let storedContacts = array as! [[[String]]]
                let active = storedContacts[self.selectedGroupIndex][2] // retrive selected contacts in group
                
                // get user phone numbers for active contacts only
                for index in 0..<active.count {
                    if (active[index] == "true") {
                        members.append(storedContacts[self.selectedGroupIndex][1][index])
                    }
                }
            }
            if (members.count == 0) {
                self.alertError(error: "No members in group")
                SwiftSpinner.hide()
                return
            } else {
                
                // upload image
                Alamofire.upload(
                    multipartFormData: { multipartFormData in
                        multipartFormData.append(image, withName: "file", fileName: "test.jpg", mimeType: "image/jpeg")
                        multipartFormData.append(token!.data(using: String.Encoding.utf8)!, withName: "token") },
                    to: AppDelegate.getAppDelegate().baseURL + "/post",
                    encodingCompletion: { encodingResult in
                        
                        switch encodingResult {
                        case .success(let upload, _, _):
                            upload.responseJSON { response in
                               
                                // send image to each member
                                for member in members {
                                    guard let result = response.result.value else {
                                        SwiftSpinner.hide()
                                        self.alertError(error: "Cannot send post.")
                                        return
                                    }
                                    
                                    // send image to members
                                    let media_url = (result as! NSDictionary).object(forKey: "media_url")! as! String
                                    let parameters: [String: String] = [
                                        "media_url": media_url,
                                        "member": member
                                    ]
                                    Alamofire.request(AppDelegate.getAppDelegate().baseURL + "/post/members", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                                        if (response.result.value != nil) {
                                            self.alertPost()
                                        }
                                        SwiftSpinner.hide()
                                    }
                                }
                            }
                        case .failure(_):
                            self.alertError(error: "Cannot send post.")
                            SwiftSpinner.hide()
                        }
                })
            }
        } else {
            self.alertError(error: "Please select a group")
            SwiftSpinner.hide()
        }
    }
    
    func prepareGroupDropdown() {
        
        // groups
        var filePathGroups : String {
            let manager = FileManager.default
            let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
            return url!.appendingPathComponent("friendGroups").path
        }
        
        guard let friendGroups = NSKeyedUnarchiver.unarchiveObject(withFile: filePathGroups) else {
            self.alertError(error: "Please create a group first")
            return
        }
        
        self.groups = friendGroups as! [String]
        drop = UIDropDown(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - constant, height: 40))
            drop.tableHeight = 300
            drop.layer.cornerRadius = 0
            drop.backgroundColor = darkBlackColor
            drop.textColor = UIColor.white
            drop.center = CGPoint(x: self.view.frame.midX, y: constant)
            drop.placeholder = "Select your group..."
            drop.options = self.groups
            drop.didSelect { (option, index) in
                self.selectedGroup = option
                self.selectedGroupIndex = index
            }
            self.view.addSubview(drop)
    }
    
    func alertError(error: String) {
        let alertController = UIAlertController(title: "Error", message:
            error, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func alertErrorNoPosts(error: String) {
        let alertController = UIAlertController(title: "Error", message:
            error, preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelAction = UIAlertAction(title: "Dismiss", style: .cancel) {
            (action) in
            self.displayCameraAlert()
        }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func alertPost() {
        let alertController = UIAlertController(title: "Message", message:
            "Post sent individually to everyone in selected group.", preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "Dismiss", style: .cancel) {
            (action) in
            if (self.checkNotificationSettings()) {
                self.clearPosts()
            }
        }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func checkNotificationSettings() -> Bool {
        let isRegisteredForRemoteNotifications = UIApplication.shared.isRegisteredForRemoteNotifications
        if !isRegisteredForRemoteNotifications {
            let alertController = UIAlertController (title: "Notifications", message: "Please enable notifications via Settings", preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.openURL(settingsUrl)
                }
            }
            alertController.addAction(settingsAction)
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
            return false
        } else {
            return true
        }
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
        pageTabBarItem.title = "POSTS"
        pageTabBarItem.tintColor = .white
    }
    
}
