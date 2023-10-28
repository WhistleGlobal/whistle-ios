//
//  VideoEditorView.swift
//  Whistle
//
//  Created by 박상원 on 2023/09/11.
//

import AVKit
import BottomSheet
import PhotosUI
import SnapKit
import SwiftUI

// MARK: - VideoEditorView

struct VideoEditorView: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.dismiss) private var dismiss
  @StateObject var musicVM = MusicViewModel()
  @StateObject var editorVM = VideoEditorViewModel()
  @StateObject var videoPlayer = VideoPlayerManager()
  @StateObject var alertViewModel = AlertViewModel.shared

  @State var isInitial = true
  @State var goUpload = false
  @State var showMusicTrimView = false
  @State var showVideoQualitySheet = false
  @State var bottomSheetTitle = ""
  @State var bottomSheetPosition: BottomSheetPosition = .hidden
  @State var sheetPositions: [BottomSheetPosition] = [.hidden, .dynamic]

  var project: ProjectEntity?
  var selectedVideoURL: URL?

  var body: some View {
    GeometryReader { _ in
      ZStack {
        Color.Background_Default_Dark.ignoresSafeArea()
        VStack(spacing: 0) {
          CustomNavigationBarViewController(title: "새 게시물") {
            alertViewModel.stackAlert(
              title: "처음부터 시작하시겠어요?",
              content: "지금 돌아가면 해당 작업물이 삭제됩니다.",
              cancelText: "계속 수정",
              destructiveText: "처음부터 시작")
            {
              dismiss()
            }
          } nextButtonAction: {
            if let video = editorVM.currentVideo {
              if videoPlayer.isPlaying {
                videoPlayer.action(video)
              }
            }
            goUpload = true
          }
          .frame(height: UIScreen.getHeight(44))
          if let video = editorVM.currentVideo {
            NavigationLink(
              destination: DescriptionAndTagEditorView(
                video: video, editorVM: editorVM,
                videoPlayer: videoPlayer,
                musicVM: musicVM,
                isInitial: $isInitial),
              isActive: $goUpload)
            {
              EmptyView()
            }
          }
          ZStack(alignment: .top) {
            PlayerHolderView(editorVM: editorVM, videoPlayer: videoPlayer, musicVM: musicVM)
            if musicVM.isTrimmed {
              MusicInfo(musicVM: musicVM, showMusicTrimView: $showMusicTrimView) {
                showMusicTrimView = true
              } onDelete: {
                musicVM.removeMusic()
                editorVM.removeAudio()
              }
            }
          }
          .padding(.top, 4)

          ThumbnailsSliderView(
            currentTime: $videoPlayer.currentTime,
            video: $editorVM.currentVideo,
            isInitial: $isInitial,
            editorVM: editorVM,
            videoPlayer: videoPlayer)
          {
            videoPlayer.scrubState = .scrubEnded(videoPlayer.currentTime)
            editorVM.setTools()
          }
          helpText

          VideoEditorToolsSection(videoPlayer: videoPlayer, editorVM: editorVM)
        }
        .onAppear {
          if isInitial {
            setVideo()
          }
        }
      }
      .background(Color.Background_Default_Dark)
      .ignoresSafeArea()
      .navigationBarHidden(true)
      .navigationBarBackButtonHidden(true)
      .fullScreenCover(isPresented: $showMusicTrimView) {
        MusicTrimView(
          musicVM: musicVM,
          editorVM: editorVM,
          videoPlayer: videoPlayer,
          showMusicTrimView: $showMusicTrimView)
      }
      .onChange(of: scenePhase) { phase in
        saveProject(phase)
      }
      .onChange(of: editorVM.selectedTools) { newValue in
        switch newValue {
        //      case .speed:
        //        bottomSheetPosition = .dynamic
        //        bottomSheetTitle = "영상 속도"
        case .music:
          if let video = editorVM.currentVideo {
            if videoPlayer.isPlaying {
              videoPlayer.action(video)
            }
            videoPlayer.scrubState = .scrubEnded(video.rangeDuration.lowerBound)
          }
          bottomSheetPosition = .relative(1)
          sheetPositions = [.absolute(UIScreen.getHeight(400)), .hidden, .relative(1)]
          bottomSheetTitle = "음악 검색"
        case .audio:
          bottomSheetPosition = .dynamic
          sheetPositions = [.hidden, .dynamic]
          bottomSheetTitle = "볼륨 조절"
        //      case .filters: print("filters")
        //      case .corrections: print("corrections")
        //      case .frames: print("frames")
        case nil: print("nil")
        }
      }
      .bottomSheet(
        bottomSheetPosition: $bottomSheetPosition,
        switchablePositions: sheetPositions)
      {
        VStack(spacing: 0) {
          ZStack {
            Text(bottomSheetTitle)
              .fontSystem(fontDesignSystem: .subtitle1_KO)
              .hCenter()
            Text("취소")
              .fontSystem(fontDesignSystem: .subtitle2_KO)
              .contentShape(Rectangle())
              .hTrailing()
              .onTapGesture {
                bottomSheetPosition = .hidden
                editorVM.selectedTools = nil
              }
          }
          .foregroundStyle(.white)
          .padding(.horizontal, 16)
          .padding(.vertical, 6)
          Rectangle()
            .fill(Color.Border_Default_Dark)
            .frame(height: 1)
        }
      } mainContent: {
        switch editorVM.selectedTools {
        //      case .speed:
        //        if let toolState = editorVM.selectedTools, let video = editorVM.currentVideo {
        //          let isAppliedTool = video.isAppliedTool(for: toolState)
        //          VStack {
        //            VideoSpeedSlider(value: Double(video.rate), isChangeState: isAppliedTool) { rate in
        //              videoPlayer.pause()
        //              editorVM.updateRate(rate: rate)
        //              print("range: \(editorVM.currentVideo?.rangeDuration)")
        //            }
        //            Text("속도 설정")
        //              .fontSystem(fontDesignSystem: .subtitle2_KO)
        //              .foregroundColor(.white)
        //              .padding(.horizontal, UIScreen.getWidth(150))
        //              .padding(.vertical, UIScreen.getHeight(12))
        //              .background(RoundedRectangle(cornerRadius: 100).fill(Color.Blue_Default))
        //              .onTapGesture {
        //                bottomSheetPosition = .hidden
        //                editorVM.selectedTools = nil
        //              }
        //              .padding(.top, UIScreen.getHeight(36))
        //          }
        //        }
        case .music:
          MusicListView(
            musicVM: musicVM,
            editorVM: editorVM,
            videoPlayer: videoPlayer,
            bottomSheetPosition: $bottomSheetPosition,
            showMusicTrimView: $showMusicTrimView)
          {
            bottomSheetPosition = .relative(1)
          }
        case .audio:
          VolumeSliderSheetView(videoPlayer: videoPlayer, editorVM: editorVM, musicVM: musicVM) {
            bottomSheetPosition = .hidden
            editorVM.selectedTools = nil
          }
        //        case .filters: print("filters")
        //        case .corrections: print("corrections")
        //        case .frames: print("frames")
        //        case nil: print("nil")
        default: Text("")
        }
      }
      .onDismiss {
        editorVM.selectedTools = nil
      }
      .enableSwipeToDismiss()
      .enableTapToDismiss()
      .customBackground(
        glassMorphicView(cornerRadius: 24)
          .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(LinearGradient.Border_Glass)))
      .showDragIndicator(true)
      .dragIndicatorColor(Color.Border_Default_Dark)
    }
    .ignoresSafeArea(.keyboard)
  }
}

extension VideoEditorView {
  private var headerView: some View {
    HStack {
//      Button {
//        editorVM.updateProject()
//        dismiss()
//      } label: {
//        Image(systemName: "folder.fill")
//      }
//
//      Spacer()
      Button {
        editorVM.selectedTools = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          showVideoQualitySheet.toggle()
        }
      } label: {
        Image(systemName: "square.and.arrow.up.fill")
      }
    }
    .foregroundColor(.white)
    .frame(height: 50)
  }

  private var helpText: some View {
    Text("최대 15초까지 동영상을 올릴 수 있어요.")
      .foregroundStyle(Color.white)
      .fontSystem(fontDesignSystem: .body2_KO)
      .padding(.vertical, 32)
  }

  private func saveProject(_ phase: ScenePhase) {
    switch phase {
    case .background, .inactive:
      editorVM.updateProject()
    default:
      break
    }
  }

  private func setVideo() {
    if let selectedVideoURL {
      videoPlayer.loadState = .loaded(selectedVideoURL)
      editorVM.setNewVideo(selectedVideoURL)
    }

    if let project, let url = project.videoURL {
      videoPlayer.loadState = .loaded(url)
      editorVM.setProject(project)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        videoPlayer.setFilters(
          mainFilter: CIFilter(name: project.filterName ?? ""),
          colorCorrection: editorVM.currentVideo?.colorCorrection)
      }
    }
  }
}

// MARK: - MusicInfo

struct MusicInfo: View {
  @ObservedObject var musicVM: MusicViewModel
  @Binding var showMusicTrimView: Bool

  let onClick: () -> Void
  let onDelete: () -> Void

  var body: some View {
    if musicVM.isTrimmed {
      if let music = musicVM.musicInfo {
        HStack(spacing: 12) {
          Image(systemName: "music.note")
          Text(music.musicTitle)
            .frame(maxWidth: UIScreen.getWidth(90))
            .lineLimit(1)
            .truncationMode(.tail)
            .fontSystem(fontDesignSystem: .body1)
            .contentShape(Rectangle())
            .onTapGesture {
              showMusicTrimView = true
            }
          Divider()
            .overlay { Color.white }
          Button {
            onDelete()
          } label: {
            Image(systemName: "xmark")
              .contentShape(Rectangle())
              .padding(.vertical, 8)
              .padding(.trailing, 16)
          }
        }
        .foregroundStyle(.white)
        .fixedSize()
        .padding(.vertical, 6)
        .padding(.leading, 16)
        .background(glassMorphicView(cornerRadius: 8))
        .padding(.top, 8)
      }
    } else {
      HStack {
        Image(systemName: "music.note")
        Text("음악 추가")
          .frame(maxWidth: UIScreen.getWidth(90))
          .lineLimit(1)
          .truncationMode(.tail)
          .fontSystem(fontDesignSystem: .body1)
          .contentShape(Rectangle())
      }
      .foregroundStyle(.white)
      .fixedSize()
      .padding(.horizontal, 16)
      .padding(.vertical, 6)
      .background(glassMorphicView(cornerRadius: 8))
      .onTapGesture {
        onClick()
      }
      .padding(.top, 8)
    }
  }
}
