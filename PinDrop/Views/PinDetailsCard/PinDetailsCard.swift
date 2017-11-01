//
//  PinDetailsView.swift
//  PinDrop
//
//  Created by Wuming Xie on 10/19/17.
//  Copyright © 2017 team11. All rights reserved.
//

import UIKit

@objc protocol PinDetailsCardDelegate: class {
    @objc optional func pinDetailsDidTapProfile()
    @objc optional func pinDetailsDidTapImage(pinDetailsCard: PinDetailsCard, imageTapped: UIImage?)
}

class PinDetailsCard: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var imageScrollView: UIScrollView!
    @IBOutlet weak var imagePageControl: UIPageControl!
    @IBOutlet weak var pinImageView: UIImageView!
    
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeAgoLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet weak var pinActionsView: PinActionsView!
    
    var pin: Pin!
    var delegate: PinDetailsCardDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
    }
    
    private func initSubviews() {
        UINib(nibName: "PinDetailsCard", bundle: nil).instantiate(withOwner: self, options: nil)
        contentView.frame = bounds
        addSubview(contentView)
        
        imageScrollView.contentInsetAdjustmentBehavior = .never
        
        profileImageView.layer.cornerRadius = profileImageView.bounds.size.width / 2.0
        profileImageView.clipsToBounds = true
        profileImageView.image = #imageLiteral(resourceName: "default_profile")
        
        profileView.isUserInteractionEnabled = true
        profileView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onProfileTap)))
    }
    
    func prepare(withPin pin: Pin) {
        self.pin = pin
        pinImageView.image = nil
        if let imageUrlStr = pin.imageUrlStr {
            ImageUtils.loadImage(forView: pinImageView, defaultImage: nil, url: URL(string: imageUrlStr)!)
        }
        
        if let userProfileUrlStr = pin.creator?.profileImageUrl {
            ImageUtils.loadImage(forView: profileImageView, defaultImage: #imageLiteral(resourceName: "default_profile"), url: URL(string: userProfileUrlStr)!)
        }
        
        titleLabel.text = pin.blurb
        timeAgoLabel.text = TimeUtils.getPrettyTimeAgoString(pin.createdAt!)
        messageLabel.text = pin.message
        nameLabel.text = pin.creator?.getFullName()

        pinImageView.isUserInteractionEnabled = true
        pinImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onImageTap)))
    }

    @objc private func onProfileTap() {
        delegate?.pinDetailsDidTapProfile?()
    }

    @objc private func onImageTap() {
        delegate?.pinDetailsDidTapImage?(pinDetailsCard: self, imageTapped: pinImageView.image)
    }
}
