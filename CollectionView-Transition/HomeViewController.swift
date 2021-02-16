//
//  HomeViewController.swift
//  CollectionView-Transition
//
//  Created by Adrian B. Haeske on 16.02.21.
//

import UIKit

class HomeViewController: UIViewController {
    let sections = Section.examplesMultiplied
    var collectionView: UICollectionView!

    var dataSource: UICollectionViewDiffableDataSource<Section, Vegetable>?

    // required for waterfall layout
    var currentSnapshot: NSDiffableDataSourceSnapshot<Section, Vegetable>!

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
            collectionViewLayout: twoColumnWaterfallLayout()
        )
        // collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleWidth] // waterfall
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


    func twoColumnWaterfallLayout() -> UICollectionViewLayout {
            let sectionProvider = { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
                guard let self = self else { return nil }

                var leadingGroupHeight = CGFloat(0.0)
                var trailingGroupHeight = CGFloat(0.0)
                var leadingGroupItems = [NSCollectionLayoutItem]()
                var trailingGroupItems = [NSCollectionLayoutItem]()

                let items = self.currentSnapshot.itemIdentifiers

                let totalHeight = items.reduce(0) { $0 + CGFloat($1.weight) }
                let columnHeight = CGFloat(totalHeight / 2.0)

                // could get a bit fancier and balance the columns if they are too different height-wise -  here is just a simple take on this

                var runningHeight = CGFloat(0.0)
                for index in 0..<self.currentSnapshot.numberOfItems {
                    let item = items[index]
                    let isLeading = runningHeight < columnHeight
                    let layoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(CGFloat(item.weight)))
                    let layoutItem = NSCollectionLayoutItem(layoutSize: layoutSize)

                    runningHeight += CGFloat(item.weight)

                    if isLeading {
                        leadingGroupItems.append(layoutItem)
                        leadingGroupHeight += CGFloat(item.weight)
                    } else {
                        trailingGroupItems.append(layoutItem)
                        trailingGroupHeight += CGFloat(item.weight)
                    }
                }

                let leadingGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(leadingGroupHeight))
                let leadingGroup = NSCollectionLayoutGroup.vertical(layoutSize: leadingGroupSize, subitems:leadingGroupItems)

                let trailingGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(trailingGroupHeight))
                let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: trailingGroupSize, subitems: trailingGroupItems)

                let containerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(max(leadingGroupHeight, trailingGroupHeight)))
                let containerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: containerGroupSize, subitems: [leadingGroup, trailingGroup])

                let section = NSCollectionLayoutSection(group: containerGroup)
                return section
            }
            let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
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
        layoutItem.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)

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

        currentSnapshot = snapshot // req for waterfall
        dataSource?.apply(snapshot)
    }
}


