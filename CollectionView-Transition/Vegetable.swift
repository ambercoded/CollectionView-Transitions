//
//  Vegetable.swift
//  CollectionView-Transition
//
//  Created by Adrian B. Haeske on 16.02.21.
//

import Foundation

struct Vegetable: Hashable {
    let id: UUID
    let name: String
    var image: String {
        name
    }

    static let examplesGreen =
    [
        Vegetable(id: UUID(), name: "Cucumber"),
        Vegetable(id: UUID(), name: "Pea"),
        Vegetable(id: UUID(), name: "Broccoli")
    ]

    static let examplesRed =
    [
        Vegetable(id: UUID(), name: "Red Pepper"),
        Vegetable(id: UUID(), name: "Chili"),
        Vegetable(id: UUID(), name: "Beetroot"),
        Vegetable(id: UUID(), name: "Tomato")
    ]

    static let examplesYellow =
    [
        Vegetable(id: UUID(), name: "Corn"),
        Vegetable(id: UUID(), name: "Potato")
    ]
}
