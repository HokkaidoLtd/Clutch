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
	
	struct LoadCommand<Command> {
		var offset: Int
		var command: Command
	}
	
	struct DumpingLoadCommands {
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
	
	var commands = DumpingLoadCommands(
		ldid: .init(offset: 0, command: .init()),
		crypt: .init(offset: 0, command: .init()),
		text: .init(offset: 0, command: .init())
	)
	
	var codeSignatureDirectory = CodeSignatureDirectory(offset: 0, directory: .init())

	var arch: ArchHeader = .init(offset: 0, size: 0, header: .init(), isPIEEnabled: false)
	
	public let data: Data
	
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
			arch = try readHeader(at: 0)
		default:
			Logger.error("Found unknown magic number: \(magic.hexString)")
			throw Error.notMachO
		}

		commands = try getDumpingLoadCommands()
		codeSignatureDirectory = try getCodeDirectory(from: commands.ldid.command)
	}
	
	private func readHeader(at offset: Int) throws -> ArchHeader {
		guard [MH_MAGIC_64, MH_CIGAM_64].contains(magic) else {
			throw Error.not64Bit
		}
		
		let machHeader = data.getMachHeader(at: offset)
		
		return .init(
			offset: offset,
			size: MemoryLayout<mach_header_64>.size,
			header: machHeader,
			isPIEEnabled: (machHeader.flags & UInt32(MH_PIE)) != 0
		)
	}
	
	private func swap(_ arg: UInt32) -> UInt32 {
		shouldSwap ? _OSSwapInt32(arg) : arg
	}
	
	private func getDumpingLoadCommands() throws -> DumpingLoadCommands {
		Logger.info("Parsing load commands")
		
		var ldid  = commands.ldid
		var crypt = commands.crypt
		var text  = commands.text
		var startOfCommand = MemoryLayout<mach_header_64>.size
		
		for _ in 0..<swap(arch.header.ncmds) {
			let cmd: Int32 = data.read(at: startOfCommand)
			let cmdsize: Int32 = data.read(at: startOfCommand + MemoryLayout<UInt32>.size)
			
			switch cmd {
			case LC_CODE_SIGNATURE:
				ldid.command = data.getLinkeditDataCommand(at: startOfCommand)
				ldid.offset = startOfCommand
				
				Logger.verbose("FOUND CODE SIGNATURE: dataoff \(ldid.command.dataoff) | datasize \(ldid.command.datasize)")
			case LC_ENCRYPTION_INFO_64:
				crypt.command = data.getCryptCommand(at: startOfCommand)
				crypt.offset = startOfCommand
				
				Logger.verbose("FOUND ENCRYPTION INFO: cryptoff \(crypt.command.cryptoff) | cryptsize \(crypt.command.cryptsize) | cryptid \(crypt.command.cryptid)")
			case LC_SEGMENT_64:
				let segment = data.getSegementCommand(at: startOfCommand)
				
				let segname = withUnsafePointer(to: segment.segname) {
					$0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout.size(ofValue: segment.segname)) {
						String(cString: $0)
					}
				}
				
				if segname == "__TEXT" {
					Logger.verbose("FOUND __TEXT SEGMENT")
					text.command = segment
					text.offset = startOfCommand
				}
			default:
				break
			}
			
			startOfCommand += Int(cmdsize)
			
			if crypt.command.cmdsize != 0 && ldid.command.cmdsize != 0 && text.command.cmdsize != 0 {
				break
			}
		}
		
		guard crypt.command.cmdsize != 0 || ldid.command.cmdsize != 0 || text.command.cmdsize != 0 else {
			Logger.error("dumping binary: some load commands were not found")
			Logger.error("crypt: \(crypt.command.cmdsize != 0), signature: \(ldid.command.cmdsize != 0), __text: \(text.command.cmdsize != 0)")
			throw Error.failedToParseLoadCommands
		}
		
		return .init(ldid: ldid, crypt: crypt, text: text)
	}
	
	private func getCodeDirectory(from ldid: linkedit_data_command) throws -> CodeSignatureDirectory {
		Logger.info("Parsing code signing blobs")
		
		var blobStart    = arch.offset + Int(ldid.dataoff)
		let codesignblob = data.getSuperBlob(at: blobStart)
		
		// check the codesign blob for validity
		guard codesignblob.magic == CSMAGIC_EMBEDDED_SIGNATURE else {
			Logger.error("codesign magic: \(codesignblob.magic.hexString) is unrecognized")
			throw Error.unknownCodesignMagic("codesign magic: \(codesignblob.magic.hexString) is unrecognized")
		}

		var codeSignBlobStart = 0
		var directory = code_directory()
		blobStart += MemoryLayout.size(ofValue: codesignblob)
		
		for _ in 0..<codesignblob.count {
			let blobIndex = data.getBlobIndex(at: blobStart)
			blobStart += MemoryLayout.size(ofValue: blobIndex)
			Logger.debug("blob: \(blobIndex)")
			
			if blobIndex.type == CSSLOT_CODEDIRECTORY {
				codeSignBlobStart = arch.offset + Int(ldid.dataoff) + Int(blobIndex.offset)
				directory = data.getCodeDirectory(at: codeSignBlobStart)
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
