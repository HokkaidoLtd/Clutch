//
//  main.swift
//  Clutch
//
//  Created by Anton Titkov on 18/10/2019.
//  Copyright © 2019 Kim-Jong Cracks. All rights reserved.
//

import Foundation
import CoreServices
import ArgumentParser
import PrivateMobileCoreServices

extension ClutchLogger.Level: EnumerableFlag {
	static public func help(for value: ClutchLogger.Level) -> ArgumentHelp? {
		switch value {
		case .info:
			return .init(visibility: .private)
		case .debug:
			return .init("Enable Debug logging")
		case .verbose:
			return .init("Enable Verbose logging")
		}
	}
}

@main
struct Clutch: ParsableCommand {
	static public var configuration = CommandConfiguration(
		commandName: "",
		abstract: "Clutch is a high-speed iOS decryption tool",
		version: "v3.0",
		subcommands: [
			ListCommand.self,
			DumpCommand.self,
			FrameworkCommand.self,
			InfoCommand.self
		],
		defaultSubcommand: ListCommand.self
	)

	struct Options: ParsableArguments {
		@Flag
		var logLevel: ClutchLogger.Level = .info
	}

	// Purely here to get ArgumentParser to show this in the general help
	@OptionGroup var options: Options

	/// Configures global options for all commands
	/// - Parameter options: the options to set
	static func configure(options: Options) {
		Logger.level = options.logLevel
	}
}

extension Clutch {
	// MARK: - List Command
	struct ListCommand: ParsableCommand {
		static var configuration = CommandConfiguration(
			commandName: "list",
			abstract: "Lists installed App Store applications on the device"
		)

		@OptionGroup var options: Options

		func run() throws {
			Clutch.configure(options: options)
			let manager = AppManager()

			guard manager.apps.count != 0 else {
				Logger.error("No apps installed")
				return
			}

			printAppTable(manager.apps)
		}

		private func printAppTable(_ apps: [LSApplicationProxy]) {
			let widths = apps
				.enumerated()
				.reduce((indexWidth: 0, nameWidth: 0, bundleIDWidth: 0)) {
					(
						max($0.indexWidth, String($1.offset).count),
						max($0.nameWidth, ($1.element.localizedName).count),
						max($0.indexWidth, ($1.element.bundleIdentifier).count)
					)
				}

			func pad(_ value: String, toWidth width: Int) -> String {
				value + String(repeating: " ", count: max(0, width - value.count))
			}

			apps
				.enumerated()
				.forEach { index, app in
					print(
						"""
						\(pad(String(index), toWidth: widths.indexWidth))  \
						\(pad(app.localizedName, toWidth: widths.nameWidth))  \
						\(pad(app.bundleIdentifier, toWidth: widths.bundleIDWidth))
						"""
					)
				}
		}
	}

	// MARK: - Dump Command
	struct DumpCommand: ParsableCommand {
		static var configuration = CommandConfiguration(
			commandName: "dump",
			abstract: "Dumps the specified application(s)"
		)

		@Argument(help: "Index, or bundleID, of the application(s) to lookup and dump")
		var search: [String]

		@OptionGroup var options: Options

		func run() throws {
			Clutch.configure(options: options)
			let apps = try AppManager().lookup(terms: search)

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

		@Argument(help: "Index, or bundleID, of the application(s) to lookup and dump.")
		var search: [String]

		@OptionGroup var options: Options

		func run() throws {
			Clutch.configure(options: options)
			let apps = try AppManager().lookup(terms: search)

			apps.forEach { app in
				FrameworkLoader(app).loadAll()

				app.frameworks
					.forEach { framework in
						let target = framework
							.appendingPathComponent(
								framework.deletingPathExtension().lastPathComponent
							)

						do {
							let executable = try Executable(url: target)
							try ARM64FrameworkDumper(executable).dump()
						} catch {
							Logger.error("Failed to dump framework: \(error)")
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

		@Argument(help: "Index, or bundleID, of the application(s) to lookup and dump")
		var search: [String]

		@OptionGroup var options: Options

		func run() throws {
			Clutch.configure(options: options)
			let apps = try AppManager().lookup(terms: search)

			apps.forEach { app in
				do {
					let executable = try Executable(url: app.bundleExecutableURL)

					Logger.log("\(app.localizedName) <\(app.bundleIdentifier): \(executable)>")
				} catch {
					Logger.error("Failed to parse executable: \(error)")
					return
				}
			}
		}
	}
}
