//
//  MyFeedView.swift
//  Whistle
//
//  Created by ChoiYujin on 9/20/23.
//
//
// import AVFoundation
// import Kingfisher
// import SwiftUI
//
//// MARK: - MyFeedView
//
// struct MyFeedView: View {
//  @Environment(\.dismiss) var dismiss
//  @StateObject var apiViewModel = APIViewModel.shared
//  @StateObject private var tabbarModel = TabbarModel.shared
//  @StateObject private var toastViewModel = ToastViewModel.shared
//
//  @State var currentIndex = 0
//  @State var newID = UUID()
//  @State var playerIndex = 0
//  @State var showDialog = false
//  @State var showPlayButton = false
//  @State var timer: Timer? = nil
//  @State var players: [AVPlayer?] = []
//  @State var isRootStacked = false
//
//  var body: some View {
//    GeometryReader { proxy in
//      if apiViewModel.myFeed.isEmpty {
//        Color.black.ignoresSafeArea().overlay {
//          VStack(spacing: 16) {
//            HStack(spacing: 0) {
//              Button {
//                if !players.isEmpty {
//                  players[currentIndex]?.pause()
//                  players.removeAll()
//                }
//                dismiss()
//              } label: {
//                Image(systemName: "chevron.backward")
//                  .font(.system(size: 20))
//                  .foregroundColor(.white)
//                  .padding(.vertical, 16)
//                  .padding(.trailing, 16)
//              }
//              Spacer()
//            }
//            .padding(.top, 54)
//            .padding(.horizontal, 16)
//            Spacer()
//            Image(systemName: "photo")
//              .resizable()
//              .scaledToFit()
//              .frame(width: 60)
//              .foregroundColor(.LabelColor_Primary_Dark)
//            Text("콘텐츠가 없습니다")
//              .fontSystem(fontDesignSystem: .body1_KO)
//              .foregroundColor(.LabelColor_Primary_Dark)
//            Spacer()
//          }
//        }
//      } else {
//        TabView(selection: $currentIndex) {
//          ForEach(Array(apiViewModel.myFeed.enumerated()), id: \.element) { index, content in
//            if !players.isEmpty {
//              if let player = players[index] {
//                ContentPlayer(player: player)
//                  .onChange(of: tabbarModel.tabSelectionNoAnimation) { newValue in
//                    if newValue != .profile {
//                      player.pause()
//                    }
//                  }
//                  .frame(width: proxy.size.width)
//                  .onTapGesture(count: 2) {
//                    whistleToggle()
//                  }
//                  .onTapGesture {
//                    if player.rate == 0.0 {
//                      player.play()
//                      showPlayButton = true
//                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//                        withAnimation {
//                          showPlayButton = false
//                        }
//                      }
//                    } else {
//                      player.pause()
//                      showPlayButton = true
//                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//                        withAnimation {
//                          showPlayButton = false
//                        }
//                      }
//                    }
//                  }
//                  .onLongPressGesture {
//                    HapticManager.instance.impact(style: .medium)
//                    showDialog = true
//                  }
//                  .overlay {
//                    LinearGradient(
//                      colors: [.clear, .black.opacity(0.24)],
//                      startPoint: .center,
//                      endPoint: .bottom)
//                      .frame(maxWidth: .infinity, maxHeight: .infinity)
//                      .allowsHitTesting(false)
//                    if tabbarModel.tabWidth != 56 {
//                      MyContentLayer(
//                        currentVideoInfo: content,
//                        isRootStacked: $isRootStacked,
//                        showDialog: $showDialog,
//                        whistleAction: {
//                          whistleToggle()
//                        },
//                        stopCurrentPlayer: {
//                          players[currentIndex]?.pause()
//                          players.removeAll()
//                        })
//                    }
//                    playButton(toPlay: player.rate == 0)
//                      .opacity(showPlayButton ? 1 : 0)
//                      .allowsHitTesting(false)
//                  }
//                  .padding()
//                  .rotationEffect(Angle(degrees: -90))
//                  .ignoresSafeArea(.all, edges: .top)
//                  .tag(index)
//              } else {
//                Color.black
//                  .tag(index)
//                  .frame(width: proxy.size.width)
//                  .padding()
//                  .rotationEffect(Angle(degrees: -90))
//                  .ignoresSafeArea(.all, edges: .top)
////                KFImage.url(URL(string: content.thumbnailUrl ?? ""))
////                  .placeholder {
////                    Color.black
////                  }
////                  .resizable()
////                  .scaledToFill()
////                  .tag(index)
////                  .frame(width: proxy.size.width)
////                  .padding()
////                  .rotationEffect(Angle(degrees: -90))
////                  .ignoresSafeArea(.all, edges: .top)
//              }
//            }
//          }
////          .onReceive(apiViewModel.publisher) { id in
////            newID = id
////          }
////          .id(newID)
//        }
//        .rotationEffect(Angle(degrees: 90))
//        .frame(width: proxy.size.height)
//        .tabViewStyle(.page(indexDisplayMode: .never))
//        .frame(maxWidth: proxy.size.width)
//      }
//    }
//    .ignoresSafeArea(.all, edges: .top)
//    .navigationBarBackButtonHidden()
//    .background(.black)
//    .navigationDestination(isPresented: $isRootStacked) {
//      if UIDevice.current.userInterfaceIdiom == .phone {
//        switch UIScreen.main.nativeBounds.height {
//        case 1334: // iPhone SE 3rd generation
//          SEMemberProfileView(
//            userId: apiViewModel.myFeed[currentIndex].userId ?? 0)
//        default:
//          MemberProfileView(
//            userId: apiViewModel.myFeed[currentIndex].userId ?? 0)
//        }
//      }
//    }
//    .onAppear {
//      for _ in 0 ..< apiViewModel.myFeed.count {
//        players.append(nil)
//      }
//      players[currentIndex] = AVPlayer(url: URL(string: apiViewModel.myFeed[currentIndex].videoUrl ?? "")!)
//      playerIndex = currentIndex
//      guard let player = players[currentIndex] else {
//        return
//      }
//      player.seek(to: .zero)
//      player.play()
//    }
//    .onChange(of: currentIndex) { newValue in
//      if apiViewModel.myFeed.isEmpty {
//        return
//      }
//      guard let url = apiViewModel.myFeed[newValue].videoUrl else {
//        return
//      }
//      players[newValue] = AVPlayer(url: URL(string: url)!)
//      if playerIndex < players.count {
//        players[playerIndex]?.seek(to: .zero)
//        players[playerIndex]?.pause()
//        players[playerIndex] = nil
//      }
//      players[newValue]?.seek(to: .zero)
//      players[newValue]?.play()
//      playerIndex = newValue
//      apiViewModel.postFeedPlayerChanged()
//    }
//    .confirmationDialog("", isPresented: $showDialog) {
//      Button("삭제하기", role: .destructive) {
//        toastViewModel.cancelToastInit(message: "삭제되었습니다") {
//          Task {
//            if apiViewModel.myFeed.count - 1 != currentIndex { // 삭제하려는 컨텐츠가 배열 마지막이 아님
//              guard let contentId = apiViewModel.myFeed[currentIndex].contentId else { return }
//              apiViewModel.myFeed.remove(at: currentIndex)
//              players[currentIndex]?.pause()
//              players.remove(at: currentIndex)
//              if !players.isEmpty {
//                players[currentIndex] = AVPlayer(url: URL(string: apiViewModel.myFeed[currentIndex].videoUrl ?? "")!)
//                await players[currentIndex]?.seek(to: .zero)
//                players[currentIndex]?.play()
//              }
//              apiViewModel.postFeedPlayerChanged()
//              await apiViewModel.deleteContent(contentID: contentId)
//            } else {
//              guard let contentId = apiViewModel.myFeed[currentIndex].contentId else { return }
//              apiViewModel.myFeed.removeLast()
//              players.last??.pause()
//              players.removeLast()
//              currentIndex -= 1
//              apiViewModel.postFeedPlayerChanged()
//              await apiViewModel.deleteContent(contentID: contentId)
//            }
//          }
//        }
//      }
//      Button("닫기", role: .cancel) { }
//    }
//  }
// }
//
// extension MyFeedView {
//  @ViewBuilder
//  func userInfo(
//    contentId: Int?,
//    caption: String,
//    musicTitle: String,
//    isWhistled: Binding<Bool>,
//    whistleCount: Binding<Int>)
//    -> some View
//  {
//    VStack(spacing: 0) {
//      HStack(spacing: 0) {
//        Button {
//          players[currentIndex]?.pause()
//          players.removeAll()
//          dismiss()
//        } label: {
//          Image(systemName: "chevron.backward")
//            .font(.system(size: 20))
//            .foregroundColor(.white)
//            .padding(.vertical, 16)
//            .padding(.trailing, 16)
//        }
//        Spacer()
//      }
//      .padding(.top, 38)
//      Spacer()
//      HStack(spacing: 0) {
//        VStack(alignment: .leading, spacing: 12) {
//          Spacer()
//          HStack(spacing: 0) {
//            Group {
//              profileImageView(url: apiViewModel.myProfile.profileImage, size: 36)
//                .padding(.trailing, UIScreen.getWidth(8))
//              Text(apiViewModel.myProfile.userName)
//                .foregroundColor(.white)
//                .fontSystem(fontDesignSystem: .subtitle1)
//                .padding(.trailing, 16)
//            }
//          }
//          if !caption.isEmpty {
//            HStack(spacing: 0) {
//              Text(caption)
//                .fontSystem(fontDesignSystem: .body2_KO)
//                .foregroundColor(.white)
//            }
//          }
//          Label(musicTitle, systemImage: "music.note")
//            .fontSystem(fontDesignSystem: .body2_KO)
//            .foregroundColor(.white)
//            .padding(.top, 4)
//        }
//        .padding(.bottom, 4)
//        .padding(.leading, 4)
//        Spacer()
//        // MARK: - Action Buttons
//        VStack(spacing: 26) {
//          Spacer()
//          Button {
//            HapticManager.instance.impact(style: .medium)
//            Task {
//              if isWhistled.wrappedValue {
//                guard let contentId else { return }
//                await apiViewModel.whistleAction(contentID: contentId, method: .delete)
//                whistleCount.wrappedValue -= 1
//              } else {
//                guard let contentId else { return }
//                await apiViewModel.whistleAction(contentID: contentId, method: .post)
//                whistleCount.wrappedValue += 1
//              }
//              isWhistled.wrappedValue.toggle()
//              apiViewModel.postFeedPlayerChanged()
//            }
//          } label: {
//            VStack(spacing: 2) {
//              Image(systemName: isWhistled.wrappedValue ? "heart.fill" : "heart")
//                .font(.system(size: 26))
//                .frame(width: 36, height: 36)
//              Text("\(whistleCount.wrappedValue)")
//                .fontSystem(fontDesignSystem: .caption_KO_Semibold)
//            }
//            .frame(height: UIScreen.getHeight(56))
//          }
//          // 저장버튼 들어갈 자리
//          Button {
//            toastViewModel.toastInit(message: "클립보드에 복사되었습니다")
//            UIPasteboard.general.setValue(
//              "https://readywhistle.com/content_uni?contentId=\(apiViewModel.myFeed[currentIndex].contentId ?? 0)",
//              forPasteboardType: UTType.plainText.identifier)
//          } label: {
//            VStack(spacing: 2) {
//              Image(systemName: "square.and.arrow.up")
//                .font(.system(size: 26))
//                .frame(width: 36, height: 36)
//              Text("공유")
//                .fontSystem(fontDesignSystem: .caption_KO_Semibold)
//            }
//            .frame(height: UIScreen.getHeight(56))
//          }
//          Button {
//            showDialog = true
//          } label: {
//            VStack(spacing: 2) {
//              Image(systemName: "ellipsis")
//                .font(.system(size: 26))
//                .frame(width: 36, height: 36)
//              Text("더보기")
//                .fontSystem(fontDesignSystem: .caption_KO_Semibold)
//            }
//            .frame(height: UIScreen.getHeight(56))
//          }
//        }
//        .foregroundColor(.Gray10)
//      }
//    }
//    .padding(.bottom, UIScreen.getHeight(52))
//    .padding(.horizontal, UIScreen.getWidth(16))
//  }
// }
//
//// MARK: - Timer
//
// extension MyFeedView {
//  func whistleToggle() {
//    HapticManager.instance.impact(style: .medium)
//    timer?.invalidate()
//    if apiViewModel.myFeed[currentIndex].isWhistled {
//      timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
//        Task {
//          await apiViewModel.whistleAction(contentID: apiViewModel.myFeed[currentIndex].contentId ?? 0, method: .delete)
//        }
//      }
//      apiViewModel.myFeed[currentIndex].contentWhistleCount? -= 1
//    } else {
//      timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
//        Task {
//          await apiViewModel.whistleAction(contentID: apiViewModel.myFeed[currentIndex].contentId ?? 0, method: .post)
//        }
//      }
//      apiViewModel.myFeed[currentIndex].contentWhistleCount! += 1
//    }
//    apiViewModel.myFeed[currentIndex].isWhistled.toggle()
//  }
// }
//
////// MARK: - MyContentLayer
////
//// struct MyContentLayer: View {
////  @Environment(\.dismiss) var dismiss
////  @StateObject var currentVideoInfo = MyContent()
////  @StateObject var apiViewModel = APIViewModel.shared
////  @StateObject var toastViewModel = ToastViewModel.shared
////  @Binding var isRootStacked: Bool
////  @Binding var showDialog: Bool
////  var whistleAction: () -> Void
////  var stopCurrentPlayer: () -> Void
////
////  var body: some View {
////    VStack(spacing: 0) {
////      HStack(spacing: 0) {
////        Button {
////          stopCurrentPlayer()
////          dismiss()
////        } label: {
////          Image(systemName: "chevron.backward")
////            .font(.system(size: 20))
////            .foregroundColor(.white)
////            .padding(.vertical, 16)
////            .padding(.trailing, 16)
////        }
////        Spacer()
////      }
////      .padding(.top, 38)
////      Spacer()
////      HStack(spacing: 0) {
////        VStack(alignment: .leading, spacing: 12) {
////          Spacer()
////          HStack(spacing: 0) {
////            if currentVideoInfo.userName ?? "" != apiViewModel.myProfile.userName {
////              Button {
////                isRootStacked = true
////              } label: {
////                Group {
////                  profileImageView(url: currentVideoInfo.profileImg, size: 36)
////                    .padding(.trailing, UIScreen.getWidth(8))
////                  Text(currentVideoInfo.userName ?? "")
////                    .foregroundColor(.white)
////                    .fontSystem(fontDesignSystem: .subtitle1)
////                    .padding(.trailing, 16)
////                }
////              }
////            } else {
////              Group {
////                profileImageView(url: currentVideoInfo.profileImg, size: 36)
////                  .padding(.trailing, 12)
////                Text(currentVideoInfo.userName ?? "")
////                  .foregroundColor(.white)
////                  .fontSystem(fontDesignSystem: .subtitle1)
////                  .padding(.trailing, 16)
////              }
////            }
////          }
////          if (currentVideoInfo.caption?.isEmpty) != nil {
////            HStack(spacing: 0) {
////              Text(currentVideoInfo.caption ?? "")
////                .fontSystem(fontDesignSystem: .body2_KO)
////                .foregroundColor(.white)
////            }
////          }
////          Label(currentVideoInfo.musicTitle ?? "원본 오디오", systemImage: "music.note")
////            .fontSystem(fontDesignSystem: .body2_KO)
////            .foregroundColor(.white)
////            .padding(.top, 4)
////        }
////        .padding(.bottom, 4)
////        .padding(.leading, 4)
////        Spacer()
////        VStack(spacing: 28) {
////          Spacer()
////          Button {
////            whistleAction()
////          } label: {
////            VStack(spacing: 0) {
////              Image(systemName: currentVideoInfo.isWhistled ? "heart.fill" : "heart")
////                .font(.system(size: 30))
////                .contentShape(Rectangle())
////                .foregroundColor(.Gray10)
////                .frame(width: 36, height: 36)
////              Text("\(currentVideoInfo.contentWhistleCount ?? 0)")
////                .foregroundColor(.Gray10)
////                .fontSystem(fontDesignSystem: .subtitle3_KO)
////            }
////            .padding(.bottom, -4)
////          }
////          Button {
////            toastViewModel.toastInit(message: "클립보드에 복사되었어요")
////            UIPasteboard.general.setValue(
////              "https://readywhistle.com/content_uni?contentId=\(currentVideoInfo.contentId ?? 0)",
////              forPasteboardType: UTType.plainText.identifier)
////          } label: {
////            Image(systemName: "square.and.arrow.up")
////              .font(.system(size: 30))
////              .contentShape(Rectangle())
////              .foregroundColor(.Gray10)
////              .frame(width: 36, height: 36)
////          }
////          Button {
////            showDialog = true
////          } label: {
////            Image(systemName: "ellipsis")
////              .font(.system(size: 30))
////              .contentShape(Rectangle())
////              .foregroundColor(.Gray10)
////              .frame(width: 36, height: 36)
////          }
////        }
////      }
////    }
////    .padding(.bottom, UIScreen.getHeight(48))
////    .padding(.trailing, UIScreen.getWidth(12))
////    .padding(.leading, UIScreen.getWidth(16))
////  }
//// }