//
//  Dumper.swift
//  Clutch
//
//  Created by NinjaLikesCheez on 27/09/2021.
//  Copyright © 2021 Kim-Jong Cracks. All rights reserved.
//

import Foundation

protocol Dumper {
	var executable: Executable { get }
	
	init(_ executable: Executable)
	
	func dump(to destination: URL) throws
}

extension Dumper {
	func preflight() throws {
		guard executable.arch.header.cputype == Device.cputype else {
			Logger.error("Device cputype mismatch. TODO plz")
			
			throw DumperError.incompatibleCPU(
				"Device cpu type: \(Device.cputype) doesn't match binary: \(executable.arch.header.cputype)"
			)
		}
		
		guard executable.arch.header.cpusubtype == Device.cpusubtype else {
			Logger.error("Device subtype mismatch. TODO plz")
			throw DumperError.incompatibleCPU(
				"Device cpu subtype: \(Device.cpusubtype) doesn't match binary: \(executable.arch.header.cpusubtype)"
			)
		}
	}
	
	func create(folder: URL) throws {
		do {
			try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
		} catch {
			throw DumperError.filesystemError("Failed to create path: \(error)")
		}
	}
}

enum DumperError: Error {
	case incompatibleCPU(_ message: String)
	case filesystemError(_ message: String)
	case failed(_ message: String)
	case dumpingFailed(_ message: String)
}
