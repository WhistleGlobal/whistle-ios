//
//  CameraCell.swift
//  AnyImageKit
//
//  Created by 蒋惠 on 2019/10/21.
//  Copyright © 2019-2022 AnyImageKit.org. All rights reserved.
//

import UIKit

// MARK: - CameraCell

final class CameraCell: UICollectionViewCell {
  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = 12
    layer.masksToBounds = true
  }

  private lazy var imageView: UIImageView = {
    let view = UIImageView(frame: .zero)
    view.contentMode = .scaleAspectFill
    return view
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.color(hex: 0xDEDFE0)
    setupView()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupView() {
    contentView.addSubview(imageView)
    imageView.snp.makeConstraints { maker in
      maker.center.equalToSuperview()
      maker.width.height.equalTo(self.snp.width).multipliedBy(0.5)
    }
  }
}

// MARK: PickerOptionsConfigurable

extension CameraCell: PickerOptionsConfigurable {
  func update(options: PickerOptionsInfo) {
    imageView.image = options.theme[icon: .camera]
    updateChildrenConfigurable(options: options)
  }
}
