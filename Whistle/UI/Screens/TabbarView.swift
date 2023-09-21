//
//  TabbarView.swift
//  Whistle
//
//  Created by ChoiYujin on 8/30/23.
//

import SwiftUI

// MARK: - TabbarView

struct TabbarView: View {

  @StateObject var tabbarModel: TabbarModel = .init()
  @State var isFirstProfileLoaded = true
  @EnvironmentObject var apiViewModel: APIViewModel
  @EnvironmentObject var userAuth: UserAuth

  var body: some View {
    ZStack {
      NavigationStack {
        MainView()
          .environmentObject(apiViewModel)
          .environmentObject(tabbarModel)
          .opacity(tabbarModel.tabSelection == .main ? 1 : 0)
      }
      .tint(.black)
      switch tabbarModel.tabSelection {
      case .main:
        Color.clear
      case .upload:
        // FIXME: - uploadview로 교체하기
        Color.pink.opacity(0.4).ignoresSafeArea()
      case .profile:
        NavigationStack {
          ProfileView(isFirstProfileLoaded: $isFirstProfileLoaded)
            .environmentObject(apiViewModel)
            .environmentObject(tabbarModel)
            .environmentObject(userAuth)
        }
      }
      VStack {
        Spacer()
        glassMorphicTab(width: tabbarModel.tabWidth)
          .overlay {
            if tabbarModel.tabWidth != 56 {
              tabItems()
            } else {
              HStack(spacing: 0) {
                Spacer().frame(minWidth: 0)
                Button {
                  withAnimation {
                    tabbarModel.tabWidth = UIScreen.width - 32
                  }
                } label: {
                  Circle()
                    .foregroundColor(.Dim_Default)
                    .frame(width: 48, height: 48)
                    .overlay {
                      Circle()
                        .stroke(lineWidth: 1)
                        .foregroundStyle(LinearGradient.Border_Glass)
                    }
                    .padding(4)
                    .overlay {
                      Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.White)
                        .frame(width: 20, height: 20)
                    }
                }
              }
            }
          }
          .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
              .onEnded { value in
                if value.translation.width > 50 {
                  log("right swipe")
                  withAnimation {
                    tabbarModel.tabWidth = 56
                  }
                }
              })
      }
      .padding(.horizontal, 16)
      .opacity(tabbarModel.tabbarOpacity)
    }
  }
}

extension TabbarView {
  @ViewBuilder
  func tabItems() -> some View {
    RoundedRectangle(cornerRadius: 100)
      .foregroundColor(Color.Dim_Default)
      .frame(width: (UIScreen.width - 32) / 3 - 6)
      .offset(x: tabbarModel.tabSelection.rawValue * ((UIScreen.width - 32) / 3))
      .padding(3)
      .overlay {
        Capsule()
          .stroke(lineWidth: 1)
          .foregroundStyle(LinearGradient.Border_Glass)
          .padding(3)
          .offset(x: tabbarModel.tabSelection.rawValue * ((UIScreen.width - 32) / 3))
      }
      .foregroundColor(.clear)
      .frame(height: 56)
      .frame(maxWidth: .infinity)
      .overlay {
        Button {
          Task {
            withAnimation {
              tabbarModel.tabSelection = .main
            }
          }
        } label: {
          Color.clear.overlay {
            Image(systemName: "house.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 24, height: 24)
          }
          .frame(width: (UIScreen.width - 32) / 3, height: 56)
        }
        .foregroundColor(.white)
        .padding(3)
        .offset(x: -1 * ((UIScreen.width - 32) / 3))
        Button {
          withAnimation {
            tabbarModel.tabSelection = .upload
          }

        } label: {
          Color.clear.overlay {
            Image(systemName: "plus")
              .resizable()
              .scaledToFit()
              .frame(width: 20, height: 20)
              .foregroundColor(.white)
          }
          .frame(width: (UIScreen.width - 32) / 3, height: 56)
        }
        .foregroundColor(.white)
        .padding(3)
        Button {
          profileTabClicked()
        } label: {
          Color.clear.overlay {
            Image(systemName: "person.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 20, height: 20)
              .foregroundColor(.white)
          }
          .frame(width: (UIScreen.width - 32) / 3, height: 56)
        }
        .foregroundColor(.white)
        .padding(3)
        .offset(x: (UIScreen.width - 32) / 3)
      }
      .frame(height: 56)
      .frame(maxWidth: .infinity)
  }
}

// MARK: - TabClicked Actions
extension TabbarView {
  var profileTabClicked: () -> Void {
    {
      withAnimation(.default) {
        tabbarModel.tabSelection = .profile
      }
      if isFirstProfileLoaded {
        Task {
          await apiViewModel.requestMyFollow()
        }
        Task {
          await apiViewModel.requestMyWhistlesCount()
        }
        Task {
          await apiViewModel.requestMyBookmark()
        }
        Task {
          await apiViewModel.requestMyPostFeed()
        }
        isFirstProfileLoaded = false
      }
    }
  }
}

// MARK: - TabSelection

public enum TabSelection: CGFloat {
  case main = -1.0
  case upload = 0.0
  case profile = 1.0
}

// MARK: - TabbarModel

class TabbarModel: ObservableObject {
  @Published var tabSelection: TabSelection = .main
  @Published var tabbarOpacity = 1.0
  @Published var tabWidth = UIScreen.width - 32
}
