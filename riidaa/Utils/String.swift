//
//  String.swift
//  riidaa
//
//  Created by Pierre on 2025/04/04.
//

import Foundation

extension String: @retroactive Identifiable {
    public var id: String {self}
}
