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
}
