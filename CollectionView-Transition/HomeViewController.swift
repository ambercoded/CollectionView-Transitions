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

        collectionView.register(
            VegetableCell.self,
            forCellWithReuseIdentifier: VegetableCell.reuseIdentifier
        )

        createDataSource()
        reloadData()
    }

    func configure<T: SelfConfiguringCell>(
        _ cellType: T.Type,
        with vegetable: Vegetable,
        for indexPath: IndexPath
    ) -> T {
        // let the collectionView dequeue a cell of that type
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: cellType.reuseIdentifier,
            for: indexPath
        ) as? T else {
            fatalError("Unable to dequeue \(cellType). Should never fail.")
        }

        cell.configure(with: vegetable)
        return cell
    }

    // MARK: - Data Source
    func createDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Vegetable>(
            collectionView: collectionView,
            cellProvider: { collectionView, indexPath, vegetable in
                return self.configure(VegetableCell.self, with: vegetable, for: indexPath)
            }
        )
    }

    func reloadData() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Vegetable>()
        snapshot.appendSections(sections)

        for section in sections {
            snapshot.appendItems(section.items, toSection: section)
        }
        dataSource?.apply(snapshot)
    }
}

