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
}

// MARK: - CollectionView and Cell Creation
extension HomeViewController {
    func createAndConfigureCollectionView() {
        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: createCompositionalLayout()
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
}

// MARK: - CollectionView CompositionalLayout
extension HomeViewController {
    func createCompositionalLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            let section = self.sections[sectionIndex]
            return self.createVegetableSection(using: section)
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20
        layout.configuration = config
        return layout
    }

    /// creates a section of our compositional layout
    func createVegetableSection(using section: Section) -> NSCollectionLayoutSection {
        // item size should be full size of its parent
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )

        let layoutItem = NSCollectionLayoutItem(layoutSize: itemSize)

        // width of group should fill parent, but height estimated to 350
        let layoutGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(350)
        )
        let layoutGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: layoutGroupSize,
            subitems: [layoutItem]
        )

        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        return layoutSection
    }
}

// MARK: - CollectionView Data Source
extension HomeViewController {
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


