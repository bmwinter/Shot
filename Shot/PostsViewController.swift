//
//  PostsViewController.swift
//  Shot
//
//  Created by Brendan Winter on 11/8/16.
//  Copyright © 2016 TechFi Apps. All rights reserved.
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
    var noPostsDisplaying = false
    var imageView: UIImageView!
    var imageURLS = [String]()
    let tapRecognizer = UITapGestureRecognizer()
    var imageCount = 0
    
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
    
    var viewAppear = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (!viewAppear) {
            self.loadPostsWithoutSpinner()
        }
        
        
    }
    
    func loadPosts() {
        // activity indicator
        // load images
        // display My Posts
        
        SwiftSpinner.show("Retrieving posts...")
        retrievePosts()
        viewAppear = true
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
    
    func loadPostsWithoutSpinner() {
        
        retrievePosts()
        viewAppear = true
    }
    
    func retrievePosts() {
        
        let prefs = UserDefaults.standard
        let token = prefs.string(forKey: "token")
        let parameters: [String: String] = [
            "token": token!
        ]
        Alamofire.request(AppDelegate.getAppDelegate().baseURL + "/posts/post", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            
            if let result = response.result.value {
                
                let resultArray = result as! NSArray
                
                for r in 0..<resultArray.count {
                    
                    let resultDictionary = resultArray[r] as! NSDictionary
                    let media_url = resultDictionary.object(forKey: "media_url") as! String
                    if let timestamp = resultDictionary.object(forKey: "timestamp") {
                        
                        // check posted within 24 hours
                        if (self.activePost(timestamp: timestamp as! String)) {
                            self.imageURLS.append(media_url)
                        }
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
                    
                    if self.scrollView != nil {
                        OperationQueue.main.addOperation {
                            self.scrollView.stopPullToRefresh()
                        }
                    }
                    
                    SwiftSpinner.hide()
                    self.noPostsAvailable()
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
                
            } else {
                if self.scrollView != nil {
                    OperationQueue.main.addOperation {
                        self.scrollView.stopPullToRefresh()
                    }
                }
                
                SwiftSpinner.hide()
                self.noPostsAvailable()
                UIApplication.shared.applicationIconBadgeNumber = 0
                
            }
        }
        
    }
    
    func noPostsAvailable() {
        
        // no posts available
        
        
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
            
        let beatAnimator = BeatAnimator(frame: CGRect(x: 0, y: 0, width: 320, height: 80))
            scrollView.addPullToRefreshWithAction({
                OperationQueue().addOperation {
                    
                    self.checkNotificationSettings()
                    self.retrievePosts()
                    
                }
            }, withAnimator: beatAnimator)
        
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
    
    func loadImages() {
        
        // load all images first to add to cache
        // set current image
        
        // offset images to count backwards from imageURLS count to 0
        imageCount = self.imageURLS.count
        if self.imageURLS.count == 0 {
            imageCount = 0
        } else {
            imageCount = self.imageURLS.count - 1
        }
        
        for i in 0..<self.imageURLS.count {
            
            // show latest first
            let url = URL(string: self.imageURLS[i])
            imageView = UIImageView(frame: CGRect(x: 0,y: 0, width: view.frame.size.width, height: view.frame.size.height))
            imageView!.kf.setImage(with: url)
            imageView!.isUserInteractionEnabled = true
            
            if i == self.imageURLS.count - 1 {
                // add taps
                tapRecognizer.addTarget(self, action: #selector(PostsViewController.nextImage))
                imageView.addGestureRecognizer(tapRecognizer)
                
                self.view.addSubview(imageView!)
            }
            
        }
        
        
        
        SwiftSpinner.hide()
    }
    
    func nextImage() {

        if (imageCount > 0) {
            
            imageCount = imageCount - 1
            self.loadNextImage()
            
        } else {
            imageCount = self.imageURLS.count
            imageURLS = [String]()
            self.displayCameraAlert()
        }
        
        
        
    }
    
    func loadNextImage() {
        
        if (imageURLS.count > 0) {
            let url = URL(string: self.imageURLS[imageCount])
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
        
        if (checkNotificationSettings()) {
        
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
            // send to group members
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
        // display current post
        
        let subViews = self.view.subviews
        for subview in subViews{
            subview.removeFromSuperview()
        }
        
        self.loadPosts()
        
    }
    
    func post() {
        // create post
        // send to members
        
     
        
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
                
            } else {
                // nothing in storage, first time
            }
            
            if (members.count == 0) {
                self.alertError(error: "No members in group")
                SwiftSpinner.hide()
            } else {
            // end retrieve members
                
            Alamofire.upload(
                multipartFormData: { multipartFormData in
                    multipartFormData.append(image, withName: "file", fileName: "test.jpg", mimeType: "image/jpeg")
                    multipartFormData.append(token!.data(using: String.Encoding.utf8)!, withName: "token")

            },
                to: AppDelegate.getAppDelegate().baseURL + "/post",
                encodingCompletion: { encodingResult in
                    
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.responseJSON { response in
                            
                            // post to members
                            // sent post alert
                            // clear posts
                            
                            for member in members {
                                
                                if let result = response.result.value {
                                    
                                    let response = result as! NSDictionary
                                    let media_urlValue = response.object(forKey: "media_url")!
                                    let media_url = media_urlValue as! String
                                                                        
                                    let parameters: [String: String] = [
                                        "media_url": media_url,
                                        "member": member
                                    ]
                                    
                                    Alamofire.request(AppDelegate.getAppDelegate().baseURL + "/post/members", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
                                        
                                        if response.result.value != nil {
                                            
                                            SwiftSpinner.hide()
                                            self.alertPost()
                                        }
                                            
                                        else {// cannot connect to API
                                            SwiftSpinner.hide()

                                        }
                                    }
                                    
                                } else {
                                    SwiftSpinner.hide()
                                    self.alertError(error: "Cannot send post.")
                                    
                                }

                                
                            }
                            
                            
                            
                            
                            
                        }
                    case .failure(_):
                        
                        self.alertError(error: "Cannot send post.")
                        SwiftSpinner.hide()

                    }
                    
                }
                )
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
        
        if let testFriendGroups = NSKeyedUnarchiver.unarchiveObject(withFile: filePathGroups) {
            
            self.groups = testFriendGroups as! [String]
            
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
            
        } else { // testFriendGroups does not exist, redundant done in contacts
            
            self.alertError(error: "Please create a group first")
            
        }
        // end groups
        

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
            
            self.checkNotificationSettings()
            // clear post
            self.clearPosts()
        }
        
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
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