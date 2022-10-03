//
//  Data+Extensions.swift
//  Clutch
//
//  Created by NinjaLikesCheez Hedderwick on 22/10/2020.
//  Copyright © 2020 Kim-Jong Cracks. All rights reserved.
//

import Foundation
import MachO.loader

extension Data {
	/// Literally here so I don't have to has (x as NSData) everywhere. I'm so lazy
	func  getBytes(_ buffer: UnsafeMutableRawPointer, length: Int) {
		(self as NSData).getBytes(buffer, length: length)
	}
	
	func getBytes(_ buffer: UnsafeMutableRawPointer, range: NSRange) {
		(self as NSData).getBytes(buffer, range: range)
	}
	
	func read<T: Numeric>(at offset: Int) -> T {
		var object = T(exactly: 0)!
		self.getBytes(&object, range: .makeRange(start: offset, for: object))
		return object
	}
}

extension Data {
	func getMachHeader(at offset: Int) -> mach_header_64{
		var header = mach_header_64()
		self.getBytes(&header, range: .makeRange(start: offset, for: header))
		return header
	}
	
	func getLinkeditDataCommand(at offset: Int) -> linkedit_data_command {
		var linkedit = linkedit_data_command()
		self.getBytes(&linkedit, range: .makeRange(start: offset, for: linkedit))
		return linkedit
	}
	
	func getCryptCommand(at offset: Int) -> encryption_info_command_64 {
		var cryptCommand = encryption_info_command_64()
		self.getBytes(&cryptCommand, range: .makeRange(start: offset, for: cryptCommand))
		return cryptCommand
	}
	
	func getSegementCommand(at offset: Int) -> segment_command_64 {
		var segment = segment_command_64()
		self.getBytes(&segment, range: .makeRange(start: offset, for: segment))
		return segment
	}
	
	func getSuperBlob(at offset: Int) -> super_blob {
		var blob = super_blob()
		self.getBytes(&blob, range: .makeRange(start: offset, for: blob))
		return blob
	}
	
	func getCodeDirectory(at offset: Int) -> code_directory {
		var directory = code_directory()
		self.getBytes(&directory, range: .makeRange(start: offset, for: directory))
		return directory
	}
	
	func getBlobIndex(at offset: Int) -> blob_index {
		var index = blob_index()
		self.getBytes(&index, range: .makeRange(start: offset, for: index))
		return index
	}
}

fileprivate extension NSRange {
	static func makeRange<T>(start offset: Int, for object:  T) -> NSRange {
		.init(location: offset, length: MemoryLayout<T>.size)
	}
}
