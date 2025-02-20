//
//  FileManager.swift
//  redaa
//
//  Created by Pierre on 2025/02/16.
//

import Foundation

extension FileManager {
    func isDirectory(at url: URL) -> Bool {
        var isDir: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
}
