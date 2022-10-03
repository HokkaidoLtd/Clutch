//
//  main.swift
//  Clutch
//
//  Created by Anton Titkov on 18/10/2019.
//  Copyright © 2019 Kim-Jong Cracks. All rights reserved.
//

import Foundation
import CoreServices
import os
import ArgumentParser

@main struct Clutch: ParsableCommand {
	static public var configuration = CommandConfiguration(
		commandName: "",
		abstract: "Clutch is a high-speed iOS app decryption tool",
		version: "v0.1",
		subcommands: [
			ListCommand.self, DumpCommand.self, FrameworkCommand.self, InfoCommand.self
		]
	)

	struct LoggerOptions: ParsableArguments {
		@Flag(help: "Enable debug logging")
		var debug = false

		@Flag(help: "Enable verbose logging")
		var verbose = false
	}

	/// Configures the logging levels for a run
	/// - Note: This _must_ be called for each command to configure logging
	/// - Parameter options: configuration struct for logger options
	static func configureLogging(_ options: LoggerOptions) {
		if options.verbose {
			Logger.level = .verbose
		} else if options.debug {
			Logger.level = .debug
		}
	}
}

extension Clutch {
	// MARK: - List Command
	struct ListCommand: ParsableCommand {
		static var configuration = CommandConfiguration(
			commandName: "list",
			abstract: "Lists installed App Store applications on the device"
		)

		@OptionGroup
		var loggingOptions: LoggerOptions

		func run() throws {
			Clutch.configureLogging(loggingOptions)

			let manager = AppManager()

			guard manager.apps.count != 0 else {
				Logger.error("[!] No apps installed")
				return
			}

			for (index, app) in manager.apps.enumerated() {
				Logger.log("\(index) \(app.localizedName ?? "Unknown Name") <\(app.bundleIdentifier ?? "Unknown Bundle ID")>")
			}
		}
	}

	// MARK: - Dump Command
	struct DumpCommand: ParsableCommand {
		static var configuration = CommandConfiguration(
			commandName: "dump",
			abstract: "Dumps the specified application(s)"
		)

		@OptionGroup
		var loggingOptions: LoggerOptions

		@Argument(help: "Index, or bundleID, of the application(s) to lookup and dump")
		var search: [String]

		func run() throws {
			Clutch.configureLogging(loggingOptions)

			let manager = AppManager()
			let apps = try manager.lookup(terms: search)

			try apps.forEach { app in
				let executable = try Executable(url: app.bundleExecutableURL)

				try ARM64Dumper(executable).dump()
			}
		}
	}

	// MARK: - Framework Command
	struct FrameworkCommand: ParsableCommand {
		static var configuration = CommandConfiguration(
			commandName: "framework",
			abstract: "Dumps the framework(s) for a specified app"
		)

		@OptionGroup
		var loggingOptions: LoggerOptions

		@Argument(help: "Index, or bundleID, of the application(s) to lookup and dump")
		var search: [String]

		func run() throws {
			Clutch.configureLogging(loggingOptions)

			let manager = AppManager()
			let apps = try manager.lookup(terms: search)

			apps.forEach { app in
				FrameworkLoader(app).loadAll()

				for framework in app.frameworks {
					let target = framework.appendingPathComponent(framework.lastPathComponent.replacingOccurrences(of: ".framework", with: "").replacingOccurrences(of: ".dylib", with: ""))

					do {
						let exectuable = try Executable(url: target)
						try ARM64FrameworkDumper(exectuable).dump()
					} catch {
						Logger.error("ERROR: \(error)")
					}
				}
			}
		}
	}

	// MARK: - Info Command
	struct InfoCommand: ParsableCommand {
		static var configuration = CommandConfiguration(
			commandName: "info",
			abstract: "Prints app(s) information"
		)

		@OptionGroup
		var loggingOptions: LoggerOptions

		@Argument(help: "Index, or bundleID, of the application(s) to lookup and dump")
		var search: [String]

		func run() throws {
			Clutch.configureLogging(loggingOptions)

			let manager = AppManager()
			let apps = try manager.lookup(terms: search)

			apps.forEach { app in
				do {
					let executable = try Executable(url: app.bundleExecutableURL)

					Logger.log("\(app.localizedName ?? "Unknown App Name") <\(app.bundleIdentifier ?? "Unknown Bundle ID"): \(executable)>")
				} catch {
					Logger.error("Failed to parse exectuable: \(error)")
					return
				}
			}
		}
	}
}
