//
//  Array+Extensions.swift
//  Insta
//
//  Created by Dawid Kolasinski on 01/10/2025.
//

import Foundation

extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
