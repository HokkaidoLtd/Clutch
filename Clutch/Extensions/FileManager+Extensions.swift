//
//  FileManager+Extensions.swift
//  Clutch
//
//  Created by NinjaLikesCheez Hedderwick on 22/10/2020.
//  Copyright © 2020 Kim-Jong Cracks. All rights reserved.
//

import Foundation

extension FileManager {
	func isDirectory(url: URL) -> Bool {
		var isDir = ObjCBool(false)
		
		return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
	}
	
	func copyFile(from origin: URL, to dest: URL, shouldReplace replace: Bool = false) throws {
		if replace && self.fileExists(atPath: dest.path) {
			try self.removeItem(at: dest)
		}
		
		try self.copyItem(at: origin, to: dest)
	}
	
	func createTemporaryPath() throws -> URL {
		let temporaryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
		
		if !FileManager.default.isDirectory(url: temporaryURL) {
			try FileManager.default.createDirectory(at: temporaryURL, withIntermediateDirectories: true, attributes: nil)
		}
		
		return temporaryURL
	}
}
