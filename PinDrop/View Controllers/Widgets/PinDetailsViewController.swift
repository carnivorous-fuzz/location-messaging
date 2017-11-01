//
//  PinViewController.swift
//  PinDrop
//
//  Created by Wuming Xie on 10/14/17.
//  Copyright © 2017 team11. All rights reserved.
//

import UIKit

@objc protocol PinDetailsViewControllerDelegate {
    @objc optional func onNextPin(pinDetailsViewController: PinDetailsViewController)
    @objc optional func onEndTour(pinDetailsViewController: PinDetailsViewController)
}

class PinDetailsViewController: UIViewController {
    
    @IBOutlet weak var pinCard: PinDetailsCard!
    @IBOutlet var pinCardHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentsTableView: UITableView!
    
    var pin: Pin!
    var hasNext: Bool?
    var delegate: PinDetailsViewControllerDelegate?
    fileprivate var comments: [PinComment] = []
    fileprivate var likes = 0
    fileprivate var liked: PinLike?
    fileprivate var likeEditedTo: Bool?
    fileprivate var imageVC: FullScreenImageViewController?

    override func loadView() {
        super.loadView()
        NSLayoutConstraint.deactivate([pinCardHeightConstraint])
        if hasNext != nil {
            addBarButtonItemToDetailsView(hasNext: hasNext!)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        commentsTableView.tableFooterView = UIView()
        commentsTableView.rowHeight = UITableViewAutomaticDimension
        commentsTableView.estimatedRowHeight = 20

        commentsTableView.register(UINib(nibName: "PinCommentCell", bundle: nil) , forCellReuseIdentifier: "PinCommentCell")
        commentsTableView.delegate = self
        commentsTableView.dataSource = self

        pinCard.prepare(withPin: pin)
        pinCard.delegate = self
        pinCard.pinActionsView.delegate = self
    }

    func addBarButtonItemToDetailsView(hasNext: Bool) {
        let endButton = UIBarButtonItem(title: "End", style: .plain, target: self, action: #selector(endTour))
        endButton.tintColor = UIConstants.Theme.red
        navigationItem.leftBarButtonItem = endButton

        if hasNext {
            let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextPin))
            nextButton.tintColor = UIConstants.Theme.green
            navigationItem.rightBarButtonItem = nextButton
        }
    }

    @objc func endTour() {
        dismiss(animated: true, completion: {
            self.delegate?.onEndTour?(pinDetailsViewController: self)
        })
    }
    @objc func nextPin() {
        dismiss(animated: true, completion: {
            self.delegate?.onNextPin?(pinDetailsViewController: self)
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let pinService = PinService.sharedInstance
        pinService.getComments(forPin: pin) { (comments, error) in
            if let comments = comments {
                if self.comments.count != comments.count {
                    self.comments = comments
                    self.commentsTableView.reloadData()
                    self.pinCard.pinActionsView.updateCommentsCount(animated: true, count: comments.count)
                }
            }
        }

        pinService.commentedOnPin(pin) { (hasCommented) in
            if hasCommented {
                self.pinCard.pinActionsView.updateCommentIcon(toColor: UIColor.green)
            }
        }

        pinService.likesOnPin(pin) { (count) in
            self.likes = count
            self.pinCard.pinActionsView.updateLikesCount(animated: false, count: self.likes)
        }

        pinService.likedPin(pin) { (pinLike) in
            self.liked = pinLike
            self.pinCard.pinActionsView.updateLikeIcon(animated: false, liked: self.liked != nil)
        }
        
        let visited = pin.visited ?? false
        if !visited && pin.creator != User.currentUser {
            pinService.markAsViewed(by: User.currentUser!, with: pin)
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(pinLikeLiveQueryNotificationHandler),
                                               name: PinLike.pinLikeLiveQueryNotification,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: PinLike.pinLikeLiveQueryNotification, object: nil)
        if likeEditedTo != nil && likeEditedTo! != (liked != nil) {
            let pinLike = PinLike()
            pinLike.user = User.currentUser
            pinLike.likedPin = pin
            
            if likeEditedTo! {
                pinLike.saveInBackground()
            } else {
                liked!.deleteInBackground()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        commentsTableView.contentInset = UIEdgeInsetsMake(pinCard.frame.height, 0, 0, 0)
    }

    @objc private func pinLikeLiveQueryNotificationHandler(_ notification: Notification) {
        if let pinId = PinLike.getPinIdFromNotification(notification), pinId == pin.objectId!,
            let type = PinLike.getEventTypeFromNotification(notification) {
            likes += type == .like ? 1 : -1
            pinCard.pinActionsView.updateLikesCount(animated: true, count: likes)
        }
    }

    @objc fileprivate func dismissFullscreenImage(sender: UITapGestureRecognizer) {
        imageVC?.dismiss(animated: true, completion: nil)
    }
    @objc fileprivate func scaleImage(sender: UIPinchGestureRecognizer) {
        if let view = sender.view {
            UIView.animate(withDuration: 0.1, animations: {
                  view.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
            })
        }
    }
}

extension PinDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = commentsTableView.dequeueReusableCell(withIdentifier: "PinCommentCell", for: indexPath) as! PinCommentCell
        let comment = comments[indexPath.row]
        cell.prepare(withComment: comment)
        return cell
    }
}

extension PinDetailsViewController: PinDetailsCardDelegate {
    func pinDetailsDidTapProfile() {
        let profileNC = UIStoryboard.profileNC
        let profileVC = profileNC.topViewController as! ProfileViewController
        profileVC.user = pin.creator
        show(profileVC, sender: nil)
    }

    func pinDetailsDidTapImage(pinDetailsCard: PinDetailsCard, imageTapped: UIImage?) {
        if let imageTapped = imageTapped {
            imageVC = UIStoryboard.pinImageFullScreenVC
            let fullScreenImage = UIImageView(image: imageTapped)
            fullScreenImage.frame = UIScreen.main.bounds
            fullScreenImage.backgroundColor = .black
            fullScreenImage.contentMode = .scaleAspectFit
            fullScreenImage.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(scaleImage))
            fullScreenImage.addGestureRecognizer(tap)
            fullScreenImage.addGestureRecognizer(pinch)

            imageVC!.view.addSubview(fullScreenImage)
            imageVC!.navigationController?.isNavigationBarHidden = true
            present(imageVC!, animated: true, completion: nil)
        }
    }
}

extension PinDetailsViewController: PinActionsViewDelegate {
    func pinActionsDidLike(_ pinActionsView: PinActionsView) {
        likeEditedTo = likeEditedTo == nil ? !(liked != nil) : !likeEditedTo!
        pinCard.pinActionsView.updateLikeIcon(animated: true, liked: likeEditedTo!)
    }
    
    func pinActionsDidComment(_ pinActionsView: PinActionsView) {
        let navigationController = UIStoryboard.pinCommentNC
        let vc = navigationController.topViewController as! PinCommentViewController
        vc.commnentedPin = pin
        present(navigationController, animated: true, completion: nil)
    }
}
