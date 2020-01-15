//
//  AudioCommentViewController.swift
//  LambdaTimeline
//
//  Created by Niranjan Kumar on 1/14/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation

class AudioCommentViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    // MARK: - Properties
    
    var postController = PostController()
    
    
    // Recording
    var audioRecorder: AVAudioRecorder?
    
    private lazy var timeFormatter: DateComponentsFormatter = {
        let formatting = DateComponentsFormatter()
        formatting.unitsStyle = .positional // 00:00  mm:ss
        // NOTE: DateComponentsFormatter is good for minutes/hours/seconds
        // DateComponentsFormatter not good for milliseconds, use DateFormatter instead)
        formatting.zeroFormattingBehavior = .pad
        formatting.allowedUnits = [.minute, .second]
        return formatting
    }()
    
    // MARK: - Playback
    
    var audioPlayer: AVAudioPlayer?
    var timer: Timer?
    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeLabel.font.pointSize,
                                                          weight: .regular)
        timeRemainingLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeRemainingLabel.font.pointSize,
                                                                   weight: .regular)
    }
    
    // MARK: - Actions

    @IBAction func recordButtonTapped(_ sender: Any) {
        recordToggle()
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        playPause()
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        
    }
    
    
    // MARK: - Recording & Playback
    
    func play() {
        audioPlayer?.play()
        startTimer()
        updateViews()
    }
    
    func pause() {
        audioPlayer?.pause()
        cancelTimer()
        updateViews()
    }
    
    func playPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    private func startTimer() {
        cancelTimer()
        timer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(updateTimer(timer:)), userInfo: nil, repeats: true)
    }
    
    @objc private func updateTimer(timer: Timer) {
        updateViews()
    }
    
    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Record
    
    var recordURL: URL?
    
    var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }
    
    func record() {
        // Path to save in the Documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        // Filename (ISO8601 format for time) .caf
        let name = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withInternetDateTime])
        
        // 2020-1-14.caf
        let file = documentsDirectory.appendingPathComponent(name).appendingPathExtension("caf")
        
        //        print("record URL: \(file)")
        
        // 44.1 Khz is CD quality audio
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        
        // Start a recording
        audioRecorder = try! AVAudioRecorder(url: file, format: format) // FIXME: error handling
        recordURL = file
        audioRecorder?.delegate = self
        audioRecorder?.record()
        updateViews()
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        updateViews()
    }
    
    func recordToggle() {
        if isRecording {
            stopRecording()
        } else {
            record()
        }
    }
    private func updateViews() {
        let playButtonTitle = isPlaying ? "Pause" : "Play"
        playButton.setTitle(playButtonTitle, for: .normal)
        
        let elapsedTime = audioPlayer?.currentTime ?? 0
        timeLabel.text = timeFormatter.string(from: elapsedTime)
        timeRemainingLabel.text = timeFormatter.string(from: (audioPlayer?.duration ?? 0) - elapsedTime)
        
        timeSlider.minimumValue = 0
        timeSlider.maximumValue = Float(audioPlayer?.duration ?? 0)
        timeSlider.value = Float(elapsedTime)
        
        let recordButtonTitle = isRecording ? "Stop Recording" : "Record"
        recordButton.setTitle(recordButtonTitle, for: .normal)
    }
}

// MARK: - Extensions

extension AudioCommentViewController: AVAudioPlayerDelegate {
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Audio playback error: \(error)")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updateViews()
    }
}

extension AudioCommentViewController: AVAudioRecorderDelegate {
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Record error: \(error)")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        // TODO: Create player with new file URL
        
        if let recordURL = recordURL {
            audioPlayer = try! AVAudioPlayer(contentsOf: recordURL) // FIXME: make safer
            updateViews()
        }
    }
}
