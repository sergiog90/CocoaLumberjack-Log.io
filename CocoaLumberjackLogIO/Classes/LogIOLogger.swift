//
//  LogIOLogger.swift
//  CocoaLumberjackLogIO
//
//  Created by Sergio García on 03/10/2020.
//

import Foundation
import CocoaAsyncSocket
import CocoaLumberjack

private enum Config {
    static let registerNodePattern = "+input|%@|%@\0"
    static let unregisterNodePattern = "-input|%@|%@\0"
    static let messagePattern = "+msg|%@|%@|%@\0"
}

public class LogIOLogger: DDAbstractLogger {
    private let host: String
    private let port: UInt16
    private let node: String
    private let stream: String
    private let timeout: TimeInterval
    private var tag = 0

    private lazy var socket: GCDAsyncSocket = {
        return GCDAsyncSocket(delegate: self, delegateQueue: .main)
    }()

    public init(host: String, port: Int, node: String, stream: String, timeout: TimeInterval = 5) {
        self.host = host
        self.port = UInt16(port)
        self.node = node
        self.stream = stream
        self.timeout = timeout
        super.init()
        connect()
    }

    func connect() {
        tag = 0
        do {
            print("Connecting to \(host):\(port)")
            try socket.connect(toHost: host, onPort: port, withTimeout: timeout)
            connected()
        } catch let error {
            print("Could not connect \(error)")
        }
    }

    private func connected() {
        let registration = String(format: Config.registerNodePattern, stream, node)
        send(message: registration)
    }

    public func send(message input: String) {
        tag += 1
        print("\(tag) \(input)")
        let message = String(format: Config.messagePattern, stream, node, input)
        let data = message.data(using: .utf8)
        socket.write(data, withTimeout: timeout, tag: tag)
    }

    public override func log(message logMessage: DDLogMessage) {
        send(message: logMessage.message)
    }
}
