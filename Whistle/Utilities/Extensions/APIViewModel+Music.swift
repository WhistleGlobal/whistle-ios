//
//  APIViewModel+Music.swift
//  Whistle
//
//  Created by 박상원 on 2023/09/11.
//

import Alamofire
import Foundation
import SwiftyJSON

extension APIViewModel: MusicProtocol {
  func requestMusicList() async -> [Music] {
    await withCheckedContinuation { continuation in
      AF.request(
        "\(domainUrl)/content/music-list",
        method: .get,
        headers: contentTypeJson)
        .validate(statusCode: 200...500)
        .response { response in
          switch response.result {
          case .success(let data):
            do {
              guard let data else {
                return
              }
              let json = try JSON(data: data)
              log("\(json)")
              let decoder = JSONDecoder()
              let musicList = try decoder.decode([Music].self, from: data)
              print("musicList: \(musicList[0].musicURL)")

              continuation.resume(returning: musicList)
            } catch {
              log("Error parsing JSON: \(error)")
              log("music list를 불러올 수 없습니다.")
              continuation.resume(returning: [])
            }
          case .failure(let error):
            log("Error: \(error)")
            continuation.resume(returning: [])
          }
        }
    }
  }
}
