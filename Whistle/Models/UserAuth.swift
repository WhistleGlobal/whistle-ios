//
//  UserAuth.swift
//  Whistle
//
//  Created by ChoiYujin on 9/1/23.
//

// import GoogleSignIn
// import GoogleSignInSwift
import Alamofire
import SwiftUI

// MARK: - Provider

enum Provider: String {
  case apple
  case google
}

// MARK: - UserAuth

class UserAuth: ObservableObject {

  enum CodingKeys: String, CodingKey {
    case idToken
    case refreshToken
    case isAccess
    case provider
    case email
    case userName
    case imageUrl
    case userResponse
  }


  @AppStorage("idToken") var idToken: String?
  @AppStorage("refreshToken") var refreshToken: String?
  @AppStorage("isAccess") var isAccess = false
  @AppStorage("provider") var provider: Provider = .apple

  var email: String? = ""
  var userName = ""
  var imageUrl: String? = ""
  var userResponse = UserResponse(email: "")


  var url: URL? {
    switch provider {
    case .apple:
      return URL(string: "https://readywhistle.com/user/profile?provider=Apple")
    case .google:
      return URL(string: "https://readywhistle.com/user/profile?provider=Google")
    }
  }

  // loadData 및 refreshToken 메서드를 이 클래스로 이동
  func loadData(completion: @escaping () -> Void?) {
    guard let idToken else {
      log("id_Token nil")
      return
    }
    guard let url else {
      log("url nil")
      return
    }
    log("idToken \(idToken)")
    let headers: HTTPHeaders = ["Authorization": "Bearer \(idToken)"]
    AF.request(url, method: .get, headers: headers).responseDecodable(of: UserResponse.self) { response in
      switch response.result {
      case .success(let value):
        self.email = value.email
        self.userName = value.user_name ?? ""
        self.imageUrl = value.profile_img ?? ""
        self.isAccess = true
        completion()
      case .failure(let error):
        log(error)
      }
    }
  }

  func refresh() {
    guard let refreshToken else {
      log("refreshToken nil")
      return
    }
    guard let url = URL(string: "https://madeuse.com/auth/apple/refresh") else {
      log("url nil")
      return
    }
    let headers: HTTPHeaders = ["Content-Type": "application/x-www-form-urlencoded"]
    let parameters: Parameters = ["refresh_token": refreshToken]
    AF.request(url, method: .post, parameters: parameters, headers: headers).response { response in
      if let error = response.error {
        log("\(error.localizedDescription)")
        self.isAccess = false
        return
      }
      if let statusCode = response.response?.statusCode, statusCode == 401 {
        log("refresh_token expired or invalid")
      }
      guard let data = response.data else {
        log("data nil")
        return
      }
      do {
        if
          let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
          let idToken = jsonObject["id_token"] as? String
        {
          self.idToken = idToken
          print("New id_token: \(idToken)")
          print("New refresh_token: \(refreshToken)")
          self.loadData { }
        }
      } catch {
        log(error)
      }
    }
  }
}
