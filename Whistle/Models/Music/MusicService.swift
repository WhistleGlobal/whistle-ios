//
//  AudioService.swift
//  Whistle
//
//  Created by 박상원 on 2023/09/05.
//
import AVFoundation
import Combine
import Foundation

// MARK: - MusicError

enum MusicError: Error {
  case invalidFormat
  case invalidData
}

// MARK: - FileDownloadError

enum FileDownloadError: Error {
  case fileCopyFailed
}

// MARK: - MusicService

class MusicService {
  static let shared: MusicServiceProtocol = MusicService()
  private init() { }
}

// MARK: MusicServiceProtocol

extension MusicService: MusicServiceProtocol {
  func buffer(url: URL, samplesCount: Int) async throws -> [MusicNote] {
    var cur_url = url
    if url.absoluteString.hasPrefix("https://") {
      let data = try await downloadMusicAsync(from: url)
      cur_url = data
    }

    let file = try AVAudioFile(forReading: cur_url)
    guard
      let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: file.fileFormat.sampleRate,
        channels: file.fileFormat.channelCount,
        interleaved: false),
      let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
    else {
      throw MusicError.invalidFormat
    }

    try file.read(into: buf)
    guard let floatChannelData = buf.floatChannelData else {
      throw MusicError.invalidData
    }

    let frameLength = Int(buf.frameLength)
    let samples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))

    var result = [MusicNote]()

    let chunked = samples.chunked(into: samples.count / samplesCount)
    for (index, row) in chunked.enumerated() {
      var accumulator: Float = 0
      let newRow = row.map { $0 * $0 }
      accumulator = newRow.reduce(0, +)
      let power: Float = accumulator / Float(row.count)
      let decibels = 10 * log10f(power)

      result.append(MusicNote(index: index, magnitude: decibels, color: .gray))
    }

    return result
  }

  // 파일 임시 디렉토리 다운로드 함수
  func downloadMusicAsync(from url: URL) async throws -> URL {
    let session = URLSession.shared
    let (data, _) = try await session.data(from: url)

    let directory = FileManager.default.temporaryDirectory
    let fileName = "downloadedAudio.mp3" // 임시저장 파일 이름 지정
    let destinationURL = directory.appendingPathComponent(fileName)

    // 기존 파일이 있다면 삭제
    if FileManager.default.fileExists(atPath: destinationURL.path) {
      try FileManager.default.removeItem(at: destinationURL)
    }

    // 다운로드한 데이터를 파일로 저장
    do {
      try data.write(to: destinationURL)
      print("downloaded!")
      return destinationURL
    } catch {
      throw FileDownloadError.fileCopyFailed
    }
  }
}

// extension Service: ServiceProtocol {
//  func buffer(url: URL, samplesCount: Int, completion: @escaping ([AudioPreviewModel]) -> Void) {
//    DispatchQueue.global(qos: .userInteractive).async {
//      do {
//        var cur_url = url
//        if url.absoluteString.hasPrefix("https://") {
//          let data = try Data(contentsOf: url)
//
//          let directory = FileManager.default.temporaryDirectory
//          let fileName = "chunk.m4a)"
//          cur_url = directory.appendingPathComponent(fileName)
//
//          try data.write(to: cur_url)
//          print("cur_url: \(cur_url)")
//        }
//
//        let file = try AVAudioFile(forReading: cur_url)
//        if
//          let format = AVAudioFormat(
//            commonFormat: .pcmFormatFloat32,
//            sampleRate: file.fileFormat.sampleRate,
//            channels: file.fileFormat.channelCount,
//            interleaved: false),
//          let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length))
//        {
//          try file.read(into: buf)
//          guard let floatChannelData = buf.floatChannelData else { return }
//          let frameLength = Int(buf.frameLength)
//
//          let samples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
//          //        let samples2 = Array(UnsafeBufferPointer(start:floatChannelData[1], count:frameLength))
//
//          var result = [AudioPreviewModel]()
//
//          let chunked = samples.chunked(into: samples.count / samplesCount)
//          for (index, row) in chunked.enumerated() {
//            var accumulator: Float = 0
//            let newRow = row.map { $0 * $0 }
//            accumulator = newRow.reduce(0, +)
//            let power: Float = accumulator / Float(row.count)
//            let decibles = 10 * log10f(power)
//
//            result.append(AudioPreviewModel(index: index, magnitude: decibles, color: .gray))
//          }
//
//          DispatchQueue.main.async {
//            completion(result)
//          }
//        }
//      } catch {
//        print("Audio Error: \(error)")
//      }
//    }
//  }
// }