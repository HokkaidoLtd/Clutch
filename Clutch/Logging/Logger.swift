//
//  Logger.swift
//  Clutch
//
//  Created by NinjaLikesCheez on 27/09/2021.
//  Copyright © 2021 Kim-Jong Cracks. All rights reserved.
//

import Foundation

// TODO: when target is iOS 14 - use the new Logger thing
var Logger = ClutchLogger.main

public struct ClutchLogger {
	static let main = ClutchLogger()

	public enum Level {
		case info
		case debug
		case verbose
	}

	public var level: Level = .info

	// MARK: - regular logging
	public func log(_ message: String) {
		print(message)
	}

	public func info(_ message: String) {
		let message = "[+] \(message)"
		log(message)
	}

	public func warn(_ message: String) {
		let message = "[!] \(message)"
		log(message)
	}

	public func error(_ message: String) {
		let message = "[-] \(message)"
		log(message)
	}

	public func fatal(_ message: String) -> Never {
		let message = "[FATAL] \(message)"
		log(message)
		exit(1)
	}

	// MARK: - level'd logging
	public func verbose(_ message: String) {
		guard level == .verbose || level == .debug else { return }

		let message = "[V] \(message)"
		log(message)
	}

	public func debug(_ message: String) {
		guard level == .debug else { return }

		let message = "[D] \(message)"
		log(message)
	}
}
