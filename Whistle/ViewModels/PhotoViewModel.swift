//
//  PhotoViewModel.swift
//  Whistle
//
//  Created by ChoiYujin on 9/5/23.
//

import Foundation
import Photos
import SwiftUI

class PhotoViewModel: ObservableObject {

  enum SelectedPhotos: Int {
    case all = 1
    case favorites = 0
  }

  @Published var photos: [Photo] = []
  @Published var albums: [AlbumModel] = []
  @Published var isPhotosEmpty = false
  @Published var isPhotoAccessAlertPresented = false

  func fetchPhotos() {
    photos.removeAll()
    let imgManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.deliveryMode = .highQualityFormat

    let fetchOptions = PHFetchOptions()
    fetchOptions.fetchLimit = 100
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)

    if fetchResult.count > 0 {
      for i in 0 ..< fetchResult.count {
        imgManager.requestImage(
          for: fetchResult.object(at: i),
          targetSize: CGSize(width: 400, height: 400),
          contentMode: .aspectFit,
          options: requestOptions)
        { image, _ in

          if let image {
            let photo = Photo(photo: image)

            DispatchQueue.main.async {
              self.photos.append(photo)
            }
          }
        }
      }
    } else {
      DispatchQueue.main.async {
        self.isPhotosEmpty = true
      }
    }
  }
    
  func listAlbums() {
    photos.removeAll()
    var albums = [AlbumModel]()
    let options = PHFetchOptions()
    let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
    userAlbums.enumerateObjects { object, _, _ in
      if let albumCollection = object as? PHAssetCollection {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)

        let assets = PHAsset.fetchAssets(in: albumCollection, options: fetchOptions)

        if let firstAsset = assets.firstObject {
          let imageManager = PHImageManager.default()
          let targetSize = CGSize(width: 300, height: 300)

          imageManager
            .requestImage(
              for: firstAsset,
              targetSize: targetSize,
              contentMode: .aspectFit,
              options: nil)
          { image, _ in
            if let thumbnailImage = image {
              let newAlbum = AlbumModel(
                name: albumCollection.localizedTitle ?? "",
                count: assets.count,
                collection: albumCollection,
                thumbnail: thumbnailImage)
              albums.append(newAlbum)
            }
          }
        } else {
          let newAlbum = AlbumModel(
            name: albumCollection.localizedTitle ?? "",
            count: assets.count,
            collection: albumCollection,
            thumbnail: nil)
          albums.append(newAlbum)
        }
      }
    }

    self.albums = albums
  }

  func fetchAlbumPhotos(albumName: String) {
    photos.removeAll()


    let fetchOptions = PHFetchOptions()
    fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
    let album = PHAssetCollection.fetchAssetCollections(
      with: .album,
      subtype: .any,
      options: fetchOptions).firstObject

    guard let targetAlbum = album else {
      return
    }

    let imgManager = PHImageManager.default()
    let requestOptions = PHImageRequestOptions()
    requestOptions.deliveryMode = .highQualityFormat

    let fetchResult: PHFetchResult = PHAsset.fetchAssets(in: targetAlbum, options: nil)

    if fetchResult.count > 0 {
      for i in 0 ..< fetchResult.count {
        imgManager.requestImage(
          for: fetchResult.object(at: i),
          targetSize: CGSize(width: 400, height: 400),
          contentMode: .aspectFit,
          options: requestOptions)
        { image, _ in
          if let image {
            let photo = Photo(photo: image)
            DispatchQueue.main.async {
              self.photos.append(photo)
            }
          }
        }
      }
    } else {
      DispatchQueue.main.async {
        self.isPhotosEmpty = true
      }
    }
  }

  func fetchPhotoByUUID(uuid: UUID) -> Photo? {
    photos.first { photo in
      photo.id == uuid
    }
  }
}
