//
//  Term+CoreDataClass.swift
//  redaa
//
//  Created by Pierre on 2025/03/08.
//
//

import Foundation
import CoreData


public class Term: NSManagedObject {

}
//
//public enum WordType: String, Sendable, CaseIterable {
//    case v
//    case v1
//    case v5
//    case v5d
//    case v1d
//    case vs
//    case vk
//    case vz
//    case te_form
//    case masu_form
//    case adj_i = "adj-i"
//    
//    static let childrenMap: [WordType: [WordType]] = [
//        .v: [v1, v5, vs, vk],
//        .v1: [v1d],
//        .v5: [v5d]
//    ]
//    
//    public var children: [WordType] {
//        return WordType.childrenMap[self] ?? []
//    }
//    
//    public static func fromString(s: String) -> WordType? {
//        return self.allCases.first{ $0.rawValue == s }
//    }
//}
