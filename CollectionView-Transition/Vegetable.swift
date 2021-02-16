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
    let weight: Double = Double.random(in: 88..<500)
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

    static let examplesGreenMultiplied: [Vegetable] = {
        var array = [Vegetable]()
        let greenVegetableNames = ["Cucumber", "Pea", "Broccoli"]

        for i in 0..<15 {
            for j in 0..<3 {
                let vegetable = Vegetable(id: UUID(), name: greenVegetableNames[j])
                array.append(vegetable)
            }
        }
        return array
    }()

    static let examplesRedMultiplied: [Vegetable] = {
        var array = [Vegetable]()
        let vegetableNames = ["Red Pepper", "Chili", "Beetroot", "Tomato"]

        for i in 0..<15 {
            for j in 0..<4 {
                let vegetable = Vegetable(id: UUID(), name: vegetableNames[j])
                array.append(vegetable)
            }
        }
        return array
    }()

    static let examplesYellowMultiplied: [Vegetable] = {
        var array = [Vegetable]()
        let vegetableNames = ["Corn", "Potato"]

        for i in 0..<15 {
            for j in 0..<2 {
                let vegetable = Vegetable(id: UUID(), name: vegetableNames[j])
                array.append(vegetable)
            }
        }
        return array
    }()
}
