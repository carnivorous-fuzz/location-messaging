//
//  PinViewController.swift
//  Sweeper
//
//  Created by Wuming Xie on 10/14/17.
//  Copyright © 2017 team11. All rights reserved.
//

import UIKit

class PinDetailsViewController: UIViewController {
    
    @IBOutlet weak var pinCard: PinDetailsCard!
    @IBOutlet weak var pinCardHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentsTableView: UITableView!
    
    var pinAnnotation: PinAnnotation!
    fileprivate var comments: [PinComment] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        commentsTableView.contentInset = UIEdgeInsetsMake(pinCard.frame.height, 0, 0, 0)
        commentsTableView.tableFooterView = UIView()
        commentsTableView.rowHeight = UITableViewAutomaticDimension
        commentsTableView.estimatedRowHeight = 80
        commentsTableView.register(UINib(nibName: "PinCommentCell", bundle: nil) , forCellReuseIdentifier: "PinCommentCell")
        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        
        pinCard.prepare(withPin: pinAnnotation.pin)
        pinCard.pinActionsView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        PinService.sharedInstance.getComments(forPin: pinAnnotation.pin) { (comments, error) in
            if let comments = comments {
                if self.comments.count != comments.count {
                    self.comments = comments
                    self.commentsTableView.reloadData()
                    self.pinCard.pinActionsView.updateCommentsCount(animated: true, count: comments.count)
                }
            }
        }
        
        PinService.sharedInstance.commentedOnPin(pinAnnotation.pin) { (hasCommented) in
            if hasCommented {
                self.pinCard.pinActionsView.updateCommentIcon(toColor: UIColor.green)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let size = pinCard.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        if pinCard.frame.height != size.height {
            pinCardHeightConstraint.constant = size.height
            commentsTableView.contentInset = UIEdgeInsetsMake(pinCard.frame.height, 0, 0, 0)
            view.layoutIfNeeded()
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

extension PinDetailsViewController: PinActionsViewDelegate {
    func pinActionsDidLike(_ pinActionsView: PinActionsView) {
        
    }
    
    func pinActionsDidComment(_ pinActionsView: PinActionsView) {
        let navigationController = UIStoryboard.pinCommentNC
        let vc = navigationController.topViewController as! PinCommentViewController
        vc.commnentedPin = pinAnnotation.pin
        present(navigationController, animated: true, completion: nil)
    }
}