//
//  HomeViewController.swift
//  CollectionView-Transition
//
//  Created by Adrian B. Haeske on 16.02.21.
//

import UIKit

class HomeViewController: UIViewController {
    let sections = Section.examples
    var collectionView: UICollectionView!

    var dataSource: UICollectionViewDiffableDataSource<Section, Vegetable>?

    override func viewDidLoad() {
        super.viewDidLoad()
        createAndConfigureCollectionView()
    }

    func createAndConfigureCollectionView() {
        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: UICollectionViewFlowLayout()
        )
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
    }
}

