//
//  MainView.swift
//  Whistle
//
//  Created by ChoiYujin on 9/4/23.
//

import _AVKit_SwiftUI
import BottomSheet
import SwiftUI

// MARK: - MainFeedView

struct MainFeedView: View {

  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var universalRoutingModel: UniversalRoutingModel
  @StateObject private var apiViewModel = APIViewModel.shared
  @StateObject private var feedPlayersViewModel = MainFeedPlayersViewModel.shared
  @StateObject private var toastViewModel = ToastViewModel.shared
  @StateObject private var feedMoreModel = MainFeedMoreModel.shared
  @StateObject private var tabbarModel = TabbarModel.shared
  @State var index = 0
  @State var searchText = ""
  @State var searchHistory: [String] = []
  @State var text = ""
  @State var scopeSelection = 0
  @State var searchQueryString = ""
  @State var isSearching = false

  var body: some View {
    ZStack {
      Color.black
      if !apiViewModel.mainFeed.isEmpty {
        MainFeedPageView(index: $index)
        VStack(spacing: 0) {
          HStack {
            Spacer()
            NavigationLink {
              MainSearchView()
            } label: {
              Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundColor(.white)
            }
            .id(UUID())
          }
          .frame(height: 28)
          .padding(.horizontal, 16)
          .padding(.top, 54)
          Spacer()
        }
      }
    }
    .toolbar {
      if feedMoreModel.showSearch {
        ToolbarItem(placement: .topBarLeading) {
          FeedSearchBar(
            searchText: $searchQueryString,
            isSearching: $isSearching,
            submitAction: { },
            cancelTapAction: dismiss)
            .simultaneousGesture(TapGesture().onEnded {
              //                      tapSearchBar?()
            })
            .frame(width: UIScreen.width - 32)
        }
      }
    }
    .background(Color.black.edgesIgnoringSafeArea(.all))
    .edgesIgnoringSafeArea(.all)
    .bottomSheet(
      bottomSheetPosition: $feedMoreModel.bottomSheetPosition,
      switchablePositions: [.hidden, .absolute(242)])
    {
      VStack(spacing: 0) {
        HStack {
          Color.clear.frame(width: 28)
          Spacer()
          Text(CommonWords().more)
            .fontSystem(fontDesignSystem: .subtitle1)
            .foregroundColor(.white)
          Spacer()
          Button {
            feedMoreModel.bottomSheetPosition = .hidden
          } label: {
            Text(CommonWords().cancel)
              .fontSystem(fontDesignSystem: .subtitle2)
              .foregroundColor(.white)
          }
        }
        .frame(height: 24)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        Rectangle().frame(width: UIScreen.width, height: 1).foregroundColor(Color.Border_Default_Dark)
        Button {
          feedMoreModel.bottomSheetPosition = .hidden
          toastViewModel.cancelToastInit(message: ToastMessages().postHidden) {
            Task {
              let currentContent = apiViewModel.mainFeed[feedPlayersViewModel.currentVideoIndex]
              await apiViewModel.actionContentHate(contentID: currentContent.contentId ?? 0, method: .post)
              feedPlayersViewModel.removePlayer {
                index -= 1
              }
            }
          }
        } label: {
          bottomSheetRowWithIcon(systemName: "eye.slash.fill", text: CommonWords().hide)
        }
        Rectangle().frame(height: 0.5).padding(.leading, 52).foregroundColor(Color.Border_Default_Dark)
        Button {
          feedMoreModel.bottomSheetPosition = .hidden
          feedPlayersViewModel.stopPlayer()
          feedMoreModel.showReport = true
        } label: {
          bottomSheetRowWithIcon(systemName: "exclamationmark.triangle.fill", text: CommonWords().reportAction)
        }

        Spacer()
      }
      .frame(height: 242)
    }
    .enableSwipeToDismiss(true)
    .enableTapToDismiss(true)
    .enableContentDrag(true)
    .enableAppleScrollBehavior(false)
    .dragIndicatorColor(Color.Border_Default_Dark)
    .customBackground(
      glassMorphicView(cornerRadius: 24)
        .overlay {
          RoundedRectangle(cornerRadius: 24)
            .stroke(lineWidth: 1)
            .foregroundStyle(
              LinearGradient.Border_Glass)
        })
    .onDismiss {
      tabbarModel.showTabbar()
    }
    .onChange(of: feedMoreModel.bottomSheetPosition) { newValue in
      if newValue == .hidden {
        tabbarModel.showTabbar()
      } else {
        tabbarModel.hideTabbar()
      }
    }
    .task {
      let updateAvailable = await apiViewModel.checkUpdateAvailable()
      if updateAvailable {
        await apiViewModel.requestVersionCheck()
        feedMoreModel.showUpdate = apiViewModel.versionCheck.forceUpdate
        if feedMoreModel.showUpdate {
          return
        }
      }
      //      if apiViewModel.myProfile.userName.isEmpty {
      //        await apiViewModel.requestMyProfile()
      //      }
      if apiViewModel.mainFeed.isEmpty {
        if universalRoutingModel.isUniversalContent {
          apiViewModel.requestUniversalFeed(contentID: universalRoutingModel.contentId) {
            universalRoutingModel.isUniversalContent = false
            feedPlayersViewModel.currentPlayer?.seek(to: .zero)
            feedPlayersViewModel.currentPlayer?.play()
          }
        } else {
          apiViewModel.requestMainFeed { value in
            switch value.result {
            case .success:
              LaunchScreenViewModel.shared.mainFeedDownloaded()
            case .failure:
              WhistleLogger.logger.debug("MainFeed Download Failure")
              apiViewModel.requestMainFeed { _ in }
            }
          }
        }
      }
    }
    .fullScreenCover(isPresented: $feedMoreModel.showReport, onDismiss: {
      feedPlayersViewModel.currentPlayer?.play()
    }) {
      MainFeedReportReasonSelectionView(
        goReport: $feedMoreModel.showReport,
        contentId: apiViewModel.mainFeed[feedPlayersViewModel.currentVideoIndex].contentId ?? 0,
        userId: apiViewModel.mainFeed[feedPlayersViewModel.currentVideoIndex].userId ?? 0)
    }
    .onAppear {
      feedMoreModel.isRootStacked = false
      tabbarModel.showTabbar()
      if feedPlayersViewModel.currentVideoIndex != 0 {
        feedPlayersViewModel.currentPlayer?.seek(to: .zero)
        if BlockList.shared.userIds.contains(apiViewModel.mainFeed[feedPlayersViewModel.currentVideoIndex].userId ?? 0) {
          return
        }
        feedPlayersViewModel.currentPlayer?.play()
      }
    }
    .onDisappear {
      feedMoreModel.isRootStacked = true
      feedPlayersViewModel.stopPlayer()
    }
    .onChange(of: tabbarModel.tabSelection) { selection in
      if selection == .main, !feedMoreModel.isRootStacked {
        feedPlayersViewModel.currentPlayer?.play()
        return
      }
      feedPlayersViewModel.stopPlayer()
    }
  }
}

// MARK: - MainFeedMoreModel

class MainFeedMoreModel: ObservableObject {
  static let shared = MainFeedMoreModel()
  private init() { }
  @Published var showSearch = false
  @Published var showReport = false
  @Published var showUpdate = false
  @Published var isRootStacked = false
  @Published var bottomSheetPosition: BottomSheetPosition = .hidden
}
