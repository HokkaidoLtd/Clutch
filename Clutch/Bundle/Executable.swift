//
//  Executable.swift
//  Clutch
//
//  Created by Anton Titkov on 18/10/2019.
//  Copyright © 2019 Kim-Jong Cracks. All rights reserved.
//

import Foundation
import MachO.swap

// MARK: Executable struct
struct Executable {
	enum Error: Swift.Error {
		case notMachO
		case not64Bit
		case notSingleArchitecture
		case failedToLoad
		case failedToParseLoadCommands
		case unknownCodesignMagic(_ message: String)
	}

	struct ArchHeader {
		var offset: Int
		var size: Int
		var header: mach_header_64
		var isPIEEnabled: Bool
	}

	struct DumpingLoadCommands {
		struct LoadCommand<Command> {
			var offset: Int
			var command: Command
		}

		var ldid: LoadCommand<linkedit_data_command>        // LC_CODE_SIGNATURE load header (for resign)
		var crypt: LoadCommand<encryption_info_command_64>  // LC_ENCRYPTION_INFO load header (for crypt*)
		var text: LoadCommand<segment_command_64>           // __TEXT segment
	}

	struct CodeSignatureDirectory {
		var offset: Int
		var directory: code_directory
	}

	// MARK: Variables
	let executableURL: URL

	let shouldSwap: Bool

	let magic: UInt32

	let commands: DumpingLoadCommands

	let codeSignatureDirectory: CodeSignatureDirectory

	let arch: ArchHeader

	let data: Data

	// MARK: init
	init(url: URL) throws {
		executableURL = url

		do {
			data = try Data(contentsOf: executableURL)
		} catch {
			Logger.error("Failed to load executable: \(error)")
			throw Error.failedToLoad
		}

		magic = data.read(at: 0)
		Logger.verbose("magic number found: \(magic.hexString)")

		switch magic {
		case MH_MAGIC, MH_CIGAM:
			throw Error.not64Bit
		case FAT_MAGIC, FAT_CIGAM:
			throw Error.notSingleArchitecture
		case MH_MAGIC_64, MH_CIGAM_64:
			shouldSwap = magic == MH_CIGAM_64
			arch = try Self.archHeader(at: 0, in: data)
		default:
			Logger.error("Found unknown magic number: \(magic.hexString)")
			throw Error.notMachO
		}

		commands = try Self.parseCommands(for: arch, in: data, swap: shouldSwap)
		codeSignatureDirectory = try Self.codeDirectory(from: arch.offset + Int(commands.ldid.command.dataoff), in: data)
	}

	private static func archHeader(at offset: Int, in data: Data) throws -> ArchHeader {
		let machHeader: mach_header_64 = data.read(at: offset)

		return .init(
			offset: offset,
			size: MemoryLayout<mach_header_64>.size,
			header: machHeader,
			isPIEEnabled: (machHeader.flags & UInt32(MH_PIE)) != 0
		)
	}

	private static func swap(_ arg: UInt32, _ shouldSwap: Bool) -> UInt32 {
		print("shouldSwap? \(shouldSwap). \(shouldSwap ? _OSSwapInt32(arg) : arg)")
		return shouldSwap ? _OSSwapInt32(arg) : arg
	}

	private static func parseCommands(for arch: ArchHeader, in data: Data, swap shouldSwap: Bool) throws -> DumpingLoadCommands {
		Logger.info("Parsing load commands")

		typealias Command = DumpingLoadCommands.LoadCommand

		var ldid: Command<linkedit_data_command>?
		var crypt: Command<encryption_info_command_64>?
		var text: Command<segment_command_64>?

		var startOfCommand = MemoryLayout<mach_header_64>.size

		Logger.verbose("ncmds: \(Self.swap(arch.header.ncmds, shouldSwap))")

		for _ in 0..<Self.swap(arch.header.ncmds, shouldSwap) {
			let cmd: UInt32 = data.read(at: startOfCommand)
			let cmdsize: UInt32 = data.read(at: startOfCommand + MemoryLayout<UInt32>.size)

			Logger.verbose("cmd: \(cmd), cmdsize: \(cmdsize)")

			switch cmd {
			case UInt32(LC_CODE_SIGNATURE):
				ldid = .init(offset: startOfCommand, command: data.read(at: startOfCommand))
				Logger.verbose("FOUND CODE SIGNATURE: dataoff \(ldid!.command.dataoff) | datasize \(ldid!.command.datasize)")
			case UInt32(LC_ENCRYPTION_INFO_64):
				crypt = .init(offset: startOfCommand, command: data.read(at: startOfCommand))
				Logger.verbose("FOUND ENCRYPTION INFO: cryptoff \(crypt!.command.cryptoff) | cryptsize \(crypt!.command.cryptsize) | cryptid \(crypt!.command.cryptid)")
			case UInt32(LC_SEGMENT_64):
				let segment: segment_command_64 = data.read(at: startOfCommand)

				let segname = withUnsafePointer(to: segment.segname) {
					$0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: segment.segname)) {
						String(cString: $0)
					}
				}

				if segname == "__TEXT" {
					Logger.verbose("FOUND __TEXT SEGMENT")
					text = .init(offset: startOfCommand, command: segment)
				}
			default:
				break
			}

			startOfCommand += Int(cmdsize)

			if let crypt, let ldid, let text {
				// If we've found everything, break out of the search
				Logger.verbose("breaking out of search - \(crypt) \(ldid), \(text)")
				break
			}
		}

		guard let crypt, let ldid, let text else {
			Logger.error("dumping binary: some load commands were not found")
			Logger.error("crypt: \(String(describing: crypt)), signature: \(String(describing: ldid)), __text: \(String(describing: text))")
			throw Error.failedToParseLoadCommands
		}

		guard crypt.command.cmdsize != 0 || ldid.command.cmdsize != 0 || text.command.cmdsize != 0 else {
			Logger.error("dumping binary: some load commands were not found")
			Logger.error("crypt: \(crypt.command.cmdsize != 0), signature: \(ldid.command.cmdsize != 0), __text: \(text.command.cmdsize != 0)")
			throw Error.failedToParseLoadCommands
		}

		return .init(ldid: ldid, crypt: crypt, text: text)
	}

	private static func codeDirectory(from offset: Int, in data: Data) throws -> CodeSignatureDirectory {
		Logger.info("Parsing code signing blobs")

		var blobStart = offset
		let codesignblob: super_blob = data.read(at: blobStart)

		// check the codesign blob for validity
		guard codesignblob.magic == CSMAGIC_EMBEDDED_SIGNATURE else {
			Logger.error("codesign magic: \(codesignblob.magic.hexString) is unrecognized")
			throw Error.unknownCodesignMagic("codesign magic: \(codesignblob.magic.hexString) is unrecognized")
		}

		var codeSignBlobStart = 0
		var directory = code_directory()
		blobStart += MemoryLayout.size(ofValue: codesignblob)

		for _ in 0..<codesignblob.count {
			let blobIndex: blob_index = data.read(at: blobStart)
			blobStart += MemoryLayout.size(ofValue: blobIndex)
			Logger.debug("blob: \(blobIndex)")

			if blobIndex.type == CSSLOT_CODEDIRECTORY {
				codeSignBlobStart = offset + Int(blobIndex.offset)
				directory = data.read(at: codeSignBlobStart)
				Logger.debug("directory: \(directory)")
				Logger.verbose("Found CSSLOT_CODEDIRECTORY")

				break
			}
		}

		return .init(offset: blobStart, directory: directory)
	}

	func spawn(disableASLR: Bool, suspend: Bool) -> pid_t {
		Logger.info("Spawning binary")
		var pid: pid_t   = 0
		var attr         = posix_spawnattr_t(nil as OpaquePointer?)
		var flags: Int32 = 0

		posix_spawnattr_init(&attr)

		if disableASLR {
			flags |= 0x0100
		}

		if suspend {
			flags |= POSIX_SPAWN_START_SUSPENDED
		}

		posix_spawnattr_setflags(&attr, Int16(flags))

		Logger.debug("Spawning with flags: \(flags.hexString)")

		_ = executableURL.path.withCString {
			posix_spawnp(&pid, $0, nil, &attr, nil, nil)
		}

		posix_spawnattr_destroy(&attr)

		return pid
	}
}

// MARK: Printing support
extension Executable: CustomStringConvertible {
	var description: String {
		"Executable(executableURL: \(executableURL), shouldSwap: \(shouldSwap), magic: \(magic.hexString), arch: \(arch), dumpingLoadCommands: \(commands)"
	}
}

extension Executable.ArchHeader: CustomStringConvertible {
	var description: String {
		"arch_header(offset: \(offset.hexString), size: \(size), header: \(header), isPIEEnabled: \(isPIEEnabled))"
	}
}

extension mach_header: CustomStringConvertible {
	public var description: String {
		"mach_header(magic: \(magic.hexString), cputype: \(cputype), cpusubtype: \(cpusubtype), filetype: \(filetype), ncmds: \(ncmds), sizeofcmds: \(sizeofcmds), flags: \(flags.hexString))"
	}
}
