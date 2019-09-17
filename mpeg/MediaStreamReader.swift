//
//  MediaStreamReader.swift
//  mpeg
//
//  Created by Mackode - Bartlomiej Makowski on 14/09/2019.
//  Copyright © 2019 pl.mackode. All rights reserved.
//

import Foundation

/**
 
 */
class MediaStreamReader: NSObject, StreamDelegate {
    var mediaFileUrl = Bundle.main.url(forResource: "bjork-all-is-full-of-love", withExtension: "mpg")
    var inputStream: InputStream

    override init() {
        self.inputStream = InputStream.init(url: mediaFileUrl!)!
        super.init()

        self.inputStream.delegate = self
        self.inputStream.schedule(in: RunLoop.current, forMode: .default)
    }

    func start() {
        self.inputStream.open()
    }

    func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case [], .openCompleted, .errorOccurred, .endEncountered, .hasSpaceAvailable:
            break
        case .hasBytesAvailable:
            self.read()
        default:
            break
        }
    }

    func read() {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024 * 5)
        let numberOfBytesRead = self.inputStream.read(buffer, maxLength: 1024 * 5)

        if numberOfBytesRead < 0, let error = self.inputStream.streamError {
            print(error)
        }
    }

}
