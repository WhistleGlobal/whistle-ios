//
//  MyContentPlayerView.swift
//  Whistle
//
//  Created by ChoiYujin on 10/30/23.
//

import _AVKit_SwiftUI
import AVFoundation
import Combine
import Kingfisher
import SwiftUI

// MARK: - MyContentPlayerView

struct MyContentPlayerView: View {
  @AppStorage("showGuide") var showGuide = true
  @Environment(\.scenePhase) var scenePhase
  @StateObject var apiViewModel = APIViewModel.shared
  @StateObject var feedPlayersViewModel = MyFeedPlayersViewModel.shared
  @StateObject private var toastViewModel = ToastViewModel.shared
  @StateObject private var feedMoreModel = MyFeedMoreModel.shared
  @StateObject private var tabbarModel = TabbarModel.shared

  @State var newId = UUID()
  @State var timer: Timer? = nil
  @State var viewTimer: Timer? = nil
  @State var showPlayButton = false
  @State var viewCount: ViewCount = .init()
  @State var processedContentId: Set<Int> = []
  @State var uploadingThumbnail = Image("noVideo")
  @State var uploadProgress = 0.0
  @State var isUploading = false
  @Binding var currentContentInfo: MyContent?
  @Binding var index: Int
  let lifecycleDelegate: ViewLifecycleDelegate?
  let dismissAction: DismissAction

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Array(apiViewModel.myFeed.enumerated()), id: \.element) { index, content in
        ZStack {
          Color.clear.overlay {
            if let url = apiViewModel.myFeed[index].thumbnailUrl {
              KFImage.url(URL(string: url))
                .placeholder {
                  Color.black
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if let player = feedPlayersViewModel.currentPlayer, index == feedPlayersViewModel.currentVideoIndex {
              ContentPlayer(player: player)
                .frame(width: UIScreen.width, height: UIScreen.height)
                .onTapGesture(count: 2) {
                  whistleToggle(content: content, index)
                }
                .onAppear {
                  let dateFormatter = DateFormatter()
                  dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                  let dateString = dateFormatter.string(from: .now)
                  if let index = viewCount.views.firstIndex(where: { $0.contentId == content.contentId }) {
                    viewCount.views[index].viewDate = dateString
                  } else {
                    viewCount.views.append(.init(contentId: content.contentId ?? 0, viewDate: dateString))
                  }
                }
                .onDisappear {
                  if let index = viewCount.views.firstIndex(where: { $0.contentId == content.contentId }) {
                    let viewDate = viewCount.views[index].viewDate.toDate()
                    var nowDate = Date.now
                    nowDate.addTimeInterval(3600 * 9)
                    let viewTime = nowDate.timeIntervalSince(viewDate ?? Date.now)
                    viewCount.views[index].viewTime = "\(Int(viewTime))"
                  }
                }
                .onTapGesture {
                  if player.rate == 0.0 {
                    player.play()
                    showPlayButton = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                      withAnimation {
                        showPlayButton = false
                      }
                    }
                  } else {
                    player.pause()
                    showPlayButton = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                      withAnimation {
                        showPlayButton = false
                      }
                    }
                  }
                }
                .onLongPressGesture {
                  HapticManager.instance.impact(style: .medium)
                  feedMoreModel.showDialog = true
                }
                .overlay {
                  if tabbarModel.tabWidth != 56 {
                    MyContentLayer(
                      currentVideoInfo: content,
                      showDialog: $feedMoreModel.showDialog,
                      whistleAction: {
                        whistleToggle(content: content, index)
                      },
                      dismissAction: dismissAction)
                  }
                }
              playButton(toPlay: player.rate == 0)
                .opacity(showPlayButton ? 1 : 0)
                .allowsHitTesting(false)
            }
            if BlockList.shared.userIds.contains(content.userId ?? 0) {
              KFImage.url(URL(string: content.thumbnailUrl ?? ""))
                .placeholder {
                  Color.black
                }
                .resizable()
                .scaledToFill()
                .blur(radius: 30)
                .overlay {
                  VStack {
                    Image(systemName: "eye.slash.fill")
                      .font(.system(size: 44))
                      .foregroundColor(.Gray10)
                      .padding(.bottom, 26)
                    Text("차단된 계정의 콘텐츠입니다.")
                      .fontSystem(fontDesignSystem: .subtitle1_KO)
                      .foregroundColor(.LabelColor_Primary_Dark)
                      .padding(.bottom, 12)
                    Text("차단된 계정의 모든 콘텐츠는 \n회원님의 피드에 노출되지 않습니다.")
                      .fontSystem(fontDesignSystem: .body2_KO)
                      .foregroundColor(.LabelColor_Secondary_Dark)
                  }
                }
            }
            if showGuide {
              VStack {
                Spacer()
                Button {
                  showGuide = false
                } label: {
                  Text("닫기")
                    .fontSystem(fontDesignSystem: .subtitle2_KO)
                    .foregroundColor(Color.LabelColor_Primary_Dark)
                    .frame(width: UIScreen.width - 32, height: 56)
                    .background {
                      glassMorphicView(cornerRadius: 12)
                        .overlay {
                          RoundedRectangle(cornerRadius: 12)
                            .stroke(lineWidth: 1)
                            .foregroundStyle(
                              LinearGradient.Border_Glass)
                        }
                    }
                }
                .padding(.bottom, 32)
              }
              .frame(width: UIScreen.width, height: UIScreen.height)
              .ignoresSafeArea()
              .ignoresSafeArea(.all, edges: .top)
              .background {
                Color.clear.overlay {
                  Image("gestureGuide")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .ignoresSafeArea(.all, edges: .top)
                }
                .ignoresSafeArea()
                .ignoresSafeArea(.all, edges: .top)
              }
            }
          }
          .overlay(alignment: .topLeading) {
            if isUploading {
              uploadingThumbnail
                .resizable()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                  ZStack {
                    RoundedRectangle(cornerRadius: 8)
                      .fill(.black.opacity(0.48))
                    RoundedRectangle(cornerRadius: 8)
                      .strokeBorder(Color.Border_Default_Dark)
                    CircularProgressBar(progress: UploadProgressViewModel.shared.progress, width: 2)
                      .padding(8)
                    Text("\(Int(uploadProgress * 100))%")
                      .foregroundStyle(Color.white)
                      .fontSystem(fontDesignSystem: .body2_KO)
                  }
                }
                .padding(.top, 70)
                .padding(.leading, 16)
                .onDisappear {
                  DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                    toastViewModel.toastInit(message: "영상이 게시되었습니다.")
                  }
                }
            }
          }
          .ignoresSafeArea()
        }
        .frame(width: UIScreen.width, height: UIScreen.height)
        .ignoresSafeArea()
        .onReceive(apiViewModel.publisher) { id in
          newId = id
        }
        .id(newId)
      }
    }
    .navigationBarBackButtonHidden()
    .onAppear {
      if index == 0 {
        WhistleLogger.logger.debug("onAppear index == 0")
        lifecycleDelegate?.onAppear()
      } else {
        WhistleLogger.logger.debug("onAppear index == \(index)")
        lifecycleDelegate?.onAppear()
        feedPlayersViewModel.currentPlayer?.seek(to: .zero)
        feedPlayersViewModel.currentPlayer?.play()
      }
    }
    .onDisappear {
      lifecycleDelegate?.onDisappear()
    }
    .ignoresSafeArea()
    .onChange(of: tabbarModel.tabSelectionNoAnimation) { newValue in
      if newValue == .main {
        feedPlayersViewModel.currentPlayer?.seek(to: .zero)
        feedPlayersViewModel.currentPlayer?.play()
        return
      }
      feedPlayersViewModel.stopPlayer()
      apiViewModel.addViewCount(viewCount, notInclude: processedContentId) { viewCountList in
        var tempSet: Set<Int> = []
        for view in viewCountList {
          tempSet.insert(view.contentId)
        }
        processedContentId = processedContentId.union(tempSet)
      }
    }
    .onChange(of: scenePhase) { newValue in
      switch newValue {
      case .background:
        apiViewModel.addViewCount(viewCount, notInclude: processedContentId) { viewCountList in
          var tempSet: Set<Int> = []
          for view in viewCountList {
            tempSet.insert(view.contentId)
          }
          processedContentId = processedContentId.union(tempSet)
        }
      default:
        break
      }
    }
    .onReceive(UploadProgressViewModel.shared.isUploadingSubject) { value in
      switch value {
      case true:
        withAnimation {
          isUploading = value
        }
      case false:
        withAnimation {
          isUploading = value
        }
      }
    }
    .onReceive(UploadProgressViewModel.shared.thumbnailSubject) { value in
      uploadingThumbnail = value
    }
    .onReceive(UploadProgressViewModel.shared.progressSubject) { value in
      uploadProgress = value
    }
  }

}

extension MyContentPlayerView {
  func whistleToggle(content: MyContent, _ index: Int) {
    HapticManager.instance.impact(style: .medium)
    timer?.invalidate()
    if apiViewModel.myFeed[index].isWhistled {
      timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
        Task {
          await apiViewModel.whistleAction(contentID: content.contentId ?? 0, method: .delete)
        }
      }
      apiViewModel.myFeed[index].contentWhistleCount! -= 1
    } else {
      timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
        Task {
          await apiViewModel.whistleAction(contentID: content.contentId ?? 0, method: .post)
        }
      }
      apiViewModel.myFeed[index].contentWhistleCount! += 1
    }
    apiViewModel.myFeed[index].isWhistled.toggle()
  }
}
