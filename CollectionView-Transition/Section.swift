//
//  Section.swift
//  CollectionView-Transition
//
//  Created by Adrian B. Haeske on 16.02.21.
//

import Foundation

struct Section: Hashable {
    let id: Int
    let title: String
    let items: [Vegetable]

    static let examples: [Section] =
    [
        Section(id: 1, title: "Green", items: Vegetable.examplesGreen),
        Section(id: 2, title: "Red", items: Vegetable.examplesRed),
        Section(id: 3, title: "Yellow", items: Vegetable.examplesYellow)
    ]
}
