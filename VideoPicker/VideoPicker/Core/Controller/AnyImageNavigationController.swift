//
//  AnyImageNavigationController.swift
//  AnyImageKit
//
//  Created by 刘栋 on 2019/12/3.
//  Copyright © 2019-2022 AnyImageKit.org. All rights reserved.
//

import SnapKit
import UIKit

// MARK: - AnyImageNavigationController

open class AnyImageNavigationController: UINavigationController {

  private var hasOverrideGeneratingDeviceOrientation = false

  open weak var trackDelegate: ImageKitDataTrackDelegate?

  open var tag = 0

  open var enableForceUpdate = false

  open override var childForStatusBarHidden: UIViewController? {
    topViewController
  }

  open override var childForStatusBarStyle: UIViewController? {
    topViewController
  }

  open override var shouldAutorotate: Bool {
    topViewController?.shouldAutorotate ?? false
  }

  open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    topViewController?.supportedInterfaceOrientations ?? [.portrait]
  }

  open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    topViewController?.preferredInterfaceOrientationForPresentation ?? .portrait
  }
}

// MARK: DataTrackObserver

extension AnyImageNavigationController: DataTrackObserver {

  func track(page: AnyImagePage, state: AnyImagePageState) {
    trackDelegate?.dataTrack(page: page, state: state)
  }

  func track(event: AnyImageEvent, userInfo: [AnyImageEventUserInfoKey: Any]) {
    trackDelegate?.dataTrack(event: event, userInfo: userInfo)
  }
}

extension AnyImageNavigationController {

  func beginGeneratingDeviceOrientationNotifications() {
    if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
      hasOverrideGeneratingDeviceOrientation = true
      UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
  }

  func endGeneratingDeviceOrientationNotifications() {
    if UIDevice.current.isGeneratingDeviceOrientationNotifications, hasOverrideGeneratingDeviceOrientation {
      UIDevice.current.endGeneratingDeviceOrientationNotifications()
      hasOverrideGeneratingDeviceOrientation = false
    }
  }
}
