//
//  CustomPhotoView.swift
//  Whistle
//
//  Created by ChoiYujin on 9/5/23.
//

import Photos
import SwiftUI

// MARK: - PhotoCollectionView

struct PhotoCollectionView: View {
  @ObservedObject var photoCollection : PhotoCollection

  @Environment(\.displayScale) private var displayScale
  private static let itemSize = CGSize(width: UIScreen.width / 4, height: UIScreen.width / 4)

  private var imageSize: CGSize {
    CGSize(width: 800, height: 800)
  }

  let columns = [
    GridItem(.flexible(minimum: 40), spacing: 0),
    GridItem(.flexible(minimum: 40), spacing: 0),
    GridItem(.flexible(minimum: 40), spacing: 0),
    GridItem(.flexible(minimum: 40), spacing: 0),
  ]
  @Environment(\.dismiss) var dismiss
  @State var selectedImage: UIImage?

  var crop: Crop = .circle

  @State private var scale: CGFloat = 1
  @State private var lastScale: CGFloat = 0
  @State private var offset: CGSize = .zero
  @State private var lastStoredOffset: CGSize = .zero
  @State private var albumName = "최근 항목"
  @State var showAlbumList = false
  @GestureState private var isInteracting = false
  @EnvironmentObject var apiViewModel: APIViewModel

  var body: some View {
    VStack(spacing: 0) {
      if showAlbumList {
        VStack(spacing: 0) {
          HStack(spacing: 0) {
            Button {
              dismiss()
            } label: {
              Image(systemName: "xmark")
            }
            Spacer()
            Text("갤러리")
              .fontSystem(fontDesignSystem: .subtitle1_KO)
              .foregroundColor(.LabelColor_Primary)
            Spacer()
            Button {
              dismiss()
            } label: {
              Text("완료")
                .fontSystem(fontDesignSystem: .subtitle2_KO)
                .foregroundColor(.Info)
            }
          }
          .frame(height: 54)
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 16)
          .background(.white)
          Divider().frame(width: UIScreen.width)
          List(photoCollection.albums, id: \.name) { album in
            Button {
              Task {
                albumName = album.name
                await photoCollection.fetchAssetsInAlbum(albumName: album.name)
              }
              showAlbumList = false
            } label: {
              HStack(spacing: 16) {
                Image(uiImage: album.thumbnail ?? UIImage())
                  .resizable()
                  .frame(width: 64, height: 64)
                  .cornerRadius(8)
                  .overlay {
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(lineWidth: 1)
                      .foregroundColor(.Border_Default)
                      .frame(width: 64, height: 64)
                  }
                VStack(spacing: 0) {
                  Text("\(album.name)")
                    .fontSystem(fontDesignSystem: .subtitle1_KO)
                    .foregroundColor(.LabelColor_Primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                  Text("\(album.count)")
                    .fontSystem(fontDesignSystem: .body1)
                    .foregroundColor(.LabelColor_Secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }
              .listRowSeparator(.hidden)
              .frame(height: 80)
            }
          }
          .listStyle(.plain)
        }
        .padding(.horizontal, 16)
      } else {
        HStack(spacing: 0) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }
          Spacer()
          Text("갤러리")
            .fontSystem(fontDesignSystem: .subtitle1_KO)
            .foregroundColor(.LabelColor_Primary)
          Spacer()
          Button {
            guard let selectedImage else {
              dismiss()
              return
            }
            Task {
              let renderer = ImageRenderer(content: cropImageView(true))
              renderer.scale = 0.5
              renderer.proposedSize = .init(crop.size())
              guard let image = renderer.uiImage else {
                log("Fail to render image")
                return
              }
              await apiViewModel.uploadPhoto(image: image) { url in log(url) }
              await apiViewModel.requestMyProfile()
              dismiss()
            }
          } label: {
            Text("완료")
              .fontSystem(fontDesignSystem: .subtitle2_KO)
              .foregroundColor(.Info)
          }
        }
        .frame(height: 54)
        .frame(maxWidth: .infinity)
        .background(.white)
        .padding(.horizontal, 16)
        .zIndex(1)
        ZStack {
          scaledImageView()
            .frame(width: UIScreen.width, height: UIScreen.width)
          cropImageView()
            .frame(width: UIScreen.width, height: UIScreen.width)
        }
        .frame(width: UIScreen.width, height: UIScreen.width)
        .clipped()
        .zIndex(0)
        HStack(spacing: 8) {
          Button {
            photoCollection.fetchAlbumList()
            showAlbumList = true
          } label: {
            Text(albumName)
              .fontSystem(fontDesignSystem: .subtitle2_KO)
              .foregroundColor(.LabelColor_Primary)
            Image(systemName: "chevron.down")
          }
          Spacer()
        }
        .frame(height: 54)
        .frame(maxWidth: .infinity)
        .background(.white)
        .padding(.horizontal, 16)
        ScrollView {
          LazyVGrid(columns: columns, spacing: 0) {
            ForEach(photoCollection.photoAssets) { asset in
              Button {
                photoCollection.fetchPhotoByLocalIdentifier(localIdentifier: asset.phAsset?.localIdentifier ?? "") { photo in
                  selectedImage = photo?.photo
                }
              } label: {
                photoItemView(asset: asset)
              }
            }
          }
        }
        .ignoresSafeArea()
      }
    }
    .task {
      let authorized = await PhotoLibrary.checkAuthorization()
      guard authorized else {
        return
      }
      Task {
        do {
          try await photoCollection.load()
          photoCollection
            .fetchPhotoByLocalIdentifier(
              localIdentifier: photoCollection.photoAssets.first?.phAsset?
                .localIdentifier ?? "")
          { photo in
            selectedImage = photo?.photo
          }
        } catch let error {
          log(error)
        }
      }
    }
  }
}

extension PhotoCollectionView {

  private func photoItemView(asset: PhotoAsset) -> some View {
    PhotoItemView(asset: asset, cache: photoCollection.cache, imageSize: imageSize)
      .frame(width: Self.itemSize.width, height: Self.itemSize.height)
      .clipped()
      .onAppear {
        Task {
          await photoCollection.cache.startCaching(for: [asset], targetSize: imageSize)
        }
      }
      .onDisappear {
        Task {
          await photoCollection.cache.stopCaching(for: [asset], targetSize: imageSize)
        }
      }
  }

  @ViewBuilder
  func scaledImageView() -> some View {
    let cropSize = crop.size()
    GeometryReader {
      let size = $0.size
      if let selectedImage {
        Image(uiImage: selectedImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(size)
      }
    }
    .offset(offset)
    .scaleEffect(scale)
    .frame(cropSize)
    .overlay {
      Color.Dim_Default
    }
  }

  @ViewBuilder
  func cropImageView(_: Bool = true) -> some View {
    let cropSize = crop.size()
    GeometryReader {
      let size = $0.size
      if let selectedImage {
        Image(uiImage: selectedImage)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .overlay {
            GeometryReader { proxy in
              let rect = proxy.frame(in: .named("CROPVIEW"))
              Color.clear
                .onChange(of: isInteracting) { newValue in

                  withAnimation(.easeInOut(duration: 0.2)) {
                    if rect.minX > 0 {
                      offset.width = (offset.width - rect.minX)
                      haptics(.medium)
                    }
                    if rect.minY > 0 {
                      offset.height = (offset.height - rect.minY)
                      haptics(.medium)
                    }
                    if rect.maxX < size.width {
                      offset.width = (rect.minX - offset.width)
                      haptics(.medium)
                    }
                    if rect.maxY < size.height {
                      offset.height = (rect.minY - offset.height)
                      haptics(.medium)
                    }
                  }

                  if !newValue {
                    lastStoredOffset = offset
                  }
                }
            }
          }
          .frame(size)
      }
    }
    .offset(offset)
    .scaleEffect(scale)
    .coordinateSpace(name: "CROPVIEW")
    .gesture(
      DragGesture()
        .updating($isInteracting, body: { _, out, _ in
          out = true
        })
        .onChanged { value in
          let translation = value.translation
          offset = CGSize(
            width: translation.width + lastStoredOffset.width,
            height: translation.height + lastStoredOffset.height)
        })
    .gesture(
      MagnificationGesture()
        .updating($isInteracting, body: { _, out, _ in
          out = true
        })
        .onChanged { value in
          let updatedScale = value + lastScale
          scale = (updatedScale < 1 ? 1 : updatedScale)
        }
        .onEnded { _ in
          withAnimation(.easeInOut(duration: 0.2)) {
            if scale < 1 {
              scale = 1
              lastScale = 0
            } else {
              lastScale = scale - 1
            }
          }
        })
    .frame(cropSize)
    .cornerRadius(crop == .circle ? cropSize.height / 2 : 0)
  }

  func haptics(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
  }
}

// MARK: - Crop

enum Crop: Equatable {
  case circle
  case square
  case custom(CGSize)

  func name() -> String {
    switch self {
    case .circle:
      return "Circle"
    case .square:
      return "Square"
    case .custom(let cGSize):
      return "Custom \(Int(cGSize.width))x\(Int(cGSize.height))"
    }
  }

  func size() -> CGSize {
    switch self {
    case .circle:
      return .init(width: UIScreen.width, height: UIScreen.width)
    case .square:
      return .init(width: UIScreen.width, height: UIScreen.width)
    case .custom(let cGSzie):
      return cGSzie
    }
  }
}

// MARK: - PhotoItemView

struct PhotoItemView: View {
  var asset: PhotoAsset
  var cache: CachedImageManager?
  var imageSize: CGSize
  @State private var image: Image?
  @State private var imageRequestID: PHImageRequestID?

  var body: some View {
    Group {
      if let image {
        image
          .resizable()
          .scaledToFill()
      } else {
        ProgressView()
          .scaleEffect(0.5)
      }
    }
    .task {
      guard image == nil, let cache else { return }
      imageRequestID = await cache.requestImage(for: asset, targetSize: imageSize) { result in
        Task {
          if let result {
            image = result.image
          }
        }
      }
    }
  }
}
