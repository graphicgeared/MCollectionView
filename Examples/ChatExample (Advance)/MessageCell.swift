//
//  MessageTextCell.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-20.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MCollectionView

class MessageCell: DynamicView {
  var textLabel = UILabel()
  var imageView: UIImageView?

  var message: Message! {
    didSet {
      textLabel.text = message.content
      textLabel.textColor = message.textColor
      textLabel.font = UIFont.systemFont(ofSize: message.fontSize)

      layer.cornerRadius = message.roundedCornder ? 10 : 0

      if message.type == .image {
        imageView = imageView ?? UIImageView()
        imageView?.image = UIImage(named: message.content)
        imageView?.frame = bounds
        imageView?.contentMode = .scaleAspectFill
        imageView?.clipsToBounds = true
        imageView?.layer.cornerRadius = layer.cornerRadius
        addSubview(imageView!)
      } else {
        imageView?.removeFromSuperview()
        imageView = nil
      }

      if message.showShadow {
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 8
        layer.shadowColor = message.shadowColor.cgColor
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
      } else {
        layer.shadowOpacity = 0
        layer.shadowColor = nil
      }

      backgroundColor = message.backgroundColor
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(textLabel)
    textLabel.frame = frame
    textLabel.numberOfLines = 0
    layer.shouldRasterize = true
    layer.rasterizationScale = UIScreen.main.scale
    isOpaque = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    if message?.showShadow ?? false {
      layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }
    textLabel.frame = bounds.insetBy(dx: message.cellPadding, dy: message.cellPadding)
    imageView?.frame = bounds
  }

  static func sizeForText(_ text: String, fontSize: CGFloat, maxWidth: CGFloat, padding: CGFloat) -> CGSize {
    let maxSize = CGSize(width: maxWidth, height: 0)
    let font = UIFont.systemFont(ofSize: fontSize)
    var rect = text.boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [ NSFontAttributeName: font ], context: nil)
    rect.size = CGSize(width: ceil(rect.size.width) + 2 * padding, height: ceil(rect.size.height) + 2 * padding)
    return rect.size
  }

  static func frameForMessage(_ message: Message, containerWidth: CGFloat) -> CGRect {
    if message.type == .image {
      var imageSize = UIImage(named: message.content)!.size
      let maxImageSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: 120)
      if imageSize.width > maxImageSize.width {
        imageSize.height /= imageSize.width/maxImageSize.width
        imageSize.width = maxImageSize.width
      }
      if imageSize.height > maxImageSize.height {
        imageSize.width /= imageSize.height/maxImageSize.height
        imageSize.height = maxImageSize.height
      }
      return CGRect(origin: CGPoint(x: message.alignment == .right ? containerWidth - imageSize.width : 0, y: 0), size: imageSize)
    }
    if message.alignment == .center {
      let size = sizeForText(message.content, fontSize: message.fontSize, maxWidth: containerWidth, padding: message.cellPadding)
      return CGRect(x: (containerWidth - size.width)/2, y: 0, width: size.width, height: size.height)
    } else {
      let size = sizeForText(message.content, fontSize: message.fontSize, maxWidth: containerWidth - 50, padding: message.cellPadding)
      let origin = CGPoint(x: message.alignment == .right ? containerWidth - size.width : 0, y: 0)
      return CGRect(origin: origin, size: size)
    }
  }
}
