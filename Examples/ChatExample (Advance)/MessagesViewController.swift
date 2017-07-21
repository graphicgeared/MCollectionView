//
//  MessagesViewController.swift
//  MCollectionViewExample
//
//  Created by YiLun Zhao on 2016-02-12.
//  Copyright © 2016 lkzhao. All rights reserved.
//

import UIKit
import MCollectionView
import ALTextInputBar

class MessageDataProvider: ArrayDataProvider<Message> {
  init() {
    super.init(data: TestMessages, identifierMapper: { (_, data) in
      return data.identifier
    })
  }
}

class MessageLayout: CollectionLayoutProvider<Message> {
  var lastMessage: Message?
  var lastFrame: CGRect?
  var maxWidth: CGFloat = 0
  override func prepare(size: CGSize) {
    super.prepare(size: size)
    maxWidth = size.width
    lastMessage = nil
    lastFrame = nil
  }
  override func frame(with message: Message, at: Int) -> CGRect {
    var yHeight: CGFloat = 0
    var xOffset: CGFloat = 0
    var cellFrame = MessageCell.frameForMessage(message, containerWidth: maxWidth)
    if let lastMessage = lastMessage, let lastFrame = lastFrame {
      if message.type == .image &&
        lastMessage.type == .image && message.alignment == lastMessage.alignment {
        if message.alignment == .left && lastFrame.maxX + cellFrame.width + 2 < maxWidth {
          yHeight = lastFrame.minY
          xOffset = lastFrame.maxX + 2
        } else if message.alignment == .right && lastFrame.minX - cellFrame.width - 2 > 0 {
          yHeight = lastFrame.minY
          xOffset = lastFrame.minX - 2 - cellFrame.width
          cellFrame.origin.x = 0
        } else {
          yHeight = lastFrame.maxY + message.verticalPaddingBetweenMessage(lastMessage)
        }
      } else {
        yHeight = lastFrame.maxY + message.verticalPaddingBetweenMessage(lastMessage)
      }
    }
    cellFrame.origin.x += xOffset
    cellFrame.origin.y = yHeight

    lastFrame = cellFrame
    lastMessage = message

    return cellFrame
  }
}

class MessagePresenter: WobblePresenter {
  var dataProvider: MessageDataProvider?
  var textInputBar: ALTextInputBar?
  weak var collectionView: CollectionView?
  var sendingMessage = false

  override func prepare(collectionView: CollectionView) {
    super.prepare(collectionView: collectionView)
    self.collectionView = collectionView
  }

  override func insert(view: UIView, at index: Int, frame: CGRect) {
    super.insert(view: view, at: index, frame: frame)
    guard let messages = dataProvider?.data, let collectionView = collectionView, let textInputBar = textInputBar else { return }
    if sendingMessage && index == messages.count - 1 {
      // we just sent this message, lets animate it from inputToolbarView to it's position
      view.frame = collectionView.convert(textInputBar.bounds, from: textInputBar)
      view.alpha = 0
      view.yaal.alpha.animateTo(1.0)
      view.yaal.bounds.animateTo(frame.bounds, stiffness: 400, damping: 40)
    } else if (collectionView.visibleFrame.intersects(frame)) {
      if messages[index].alignment == .left {
        let center = view.center
        view.center = CGPoint(x: center.x - view.bounds.width, y: center.y)
        view.yaal.center.animateTo(center, stiffness:250, damping: 20)
      } else if messages[index].alignment == .right {
        let center = view.center
        view.center = CGPoint(x: center.x + view.bounds.width, y: center.y)
        view.yaal.center.animateTo(center, stiffness:250, damping: 20)
      } else {
        view.alpha = 0
        view.yaal.scale.from(0).animateTo(1)
        view.yaal.alpha.animateTo(1)
      }
    }
  }
}

class MessagesViewController: UIViewController {

  var collectionView: CollectionView!

  var loading = false

  let textInputBar = ALTextInputBar()
  let keyboardObserver = ALKeyboardObservingView()

  let dataProvider = MessageDataProvider()
  let presenter = MessagePresenter()
  var provider: CollectionProvider<Message, MessageCell>!

  override var inputAccessoryView: UIView? {
    return keyboardObserver
  }

  override var canBecomeFirstResponder: Bool {
    return true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
    view.clipsToBounds = true
    collectionView = CollectionView(frame:view.bounds)
    collectionView.keyboardDismissMode = .interactive
    collectionView.delegate = self
    view.addSubview(collectionView)

    let button = UIButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
    button.setImage(UIImage(named:"ic_send")!, for: .normal)
    button.addTarget(self, action: #selector(send), for: .touchUpInside)
    button.sizeToFit()
    button.tintColor = .lightBlue
    textInputBar.rightView = button
    textInputBar.textView.tintColor = .lightBlue
    textInputBar.defaultHeight = 54
    textInputBar.delegate = self
    textInputBar.keyboardObserver = keyboardObserver
    textInputBar.frame = CGRect(x: 0, y: view.frame.height - textInputBar.defaultHeight, width: view.frame.width, height: textInputBar.defaultHeight)
    keyboardObserver.isUserInteractionEnabled = false
    view.addSubview(textInputBar)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameChanged(notification:)), name: NSNotification.Name(rawValue: ALKeyboardFrameDidChangeNotification), object: nil)
    
    presenter.textInputBar = textInputBar
    presenter.dataProvider = dataProvider
    provider = CollectionProvider(
      dataProvider: dataProvider,
      viewProvider: ClosureViewProvider(viewUpdater: { (view: MessageCell, data: Message, at: Int) in
        view.message = data
      }),
      layoutProvider: MessageLayout(),
      presenter: presenter
    )
    collectionView.provider = provider
  }

  func keyboardFrameChanged(notification: NSNotification) {
    if let userInfo = notification.userInfo {
      let frame = userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect
      textInputBar.frame.origin.y = frame.minY
      viewDidLayoutSubviews()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    textInputBar.frame.size.width = view.bounds.width
    let isAtBottom = collectionView.contentOffset.y >= collectionView.offsetFrame.maxY - 10
    collectionView.frame = view.bounds
    collectionView.contentInset = UIEdgeInsetsMake(topLayoutGuide.length + 30,
                                                   10,
                                                   max(textInputBar.defaultHeight, view.bounds.height - textInputBar.frame.minY) + 20,
                                                   10)
    collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(topLayoutGuide.length, 0, max(textInputBar.defaultHeight, view.bounds.height - textInputBar.frame.minY), 0)
    if !collectionView.hasReloaded {
      collectionView.reloadData() {
        return CGPoint(x: self.collectionView.contentOffset.x,
                       y: self.collectionView.offsetFrame.maxY)
      }
    }
    if isAtBottom {
      if collectionView.hasReloaded {
        collectionView.yaal.contentOffset.animateTo(CGPoint(x: collectionView.contentOffset.x,
                                                            y: collectionView.offsetFrame.maxY))
      } else {
        collectionView.yaal.contentOffset.setTo(CGPoint(x: collectionView.contentOffset.x,
                                                        y: collectionView.offsetFrame.maxY))
      }
    }
  }
}

// For sending new messages
extension MessagesViewController: ALTextInputBarDelegate {
  func send() {
    let text = textInputBar.text!
    textInputBar.text = ""

    dataProvider.data.append(Message(true, content: text))
    presenter.sendingMessage = true

    collectionView.reloadData()
    collectionView.scrollTo(edge: .bottom, animated:true)
    presenter.sendingMessage = false

    delay(1.0) {
      self.dataProvider.data.append(Message(false, content: text))
      self.collectionView.reloadData()
      self.collectionView.scrollTo(edge: .bottom, animated:true)
    }
  }
}

extension MessagesViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // PULL TO LOAD MORE
    // load more messages if we scrolled to the top
    if collectionView.hasReloaded,
      scrollView.contentOffset.y < 500,
      !loading {
      loading = true
      delay(0.5) { // Simulate network request
        let newMessages = TestMessages.map{ $0.copy() }
        self.dataProvider.data = newMessages + self.dataProvider.data
        let bottomOffset = self.collectionView.offsetFrame.maxY - self.collectionView.contentOffset.y
        self.collectionView.reloadData() {
          return CGPoint(x: self.collectionView.contentOffset.x,
                         y: self.collectionView.offsetFrame.maxY - bottomOffset)
        }
        self.loading = false
      }
    }
  }
}
