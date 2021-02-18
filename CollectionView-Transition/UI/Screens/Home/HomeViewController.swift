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

    override func viewDidLoad() {
        super.viewDidLoad()
        createAndConfigureCollectionView()
    }

    // only needed until i use tiling. else layout is not shown until invalidated by eg rotating
    override func viewDidAppear(_ animated: Bool) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - CollectionView and Cell Creation
extension HomeViewController {
    func createAndConfigureCollectionView() {
        collectionView = UICollectionView(
            frame: view.bounds,
            collectionViewLayout: createAnimatedLayout()
        )
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self // springy
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


// MARK: - SpringyLayout
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func createAnimatedLayout() -> UICollectionViewFlowLayout {
        let layout = AnimatedCollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        return layout
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // understanding index paths and sections:
        // [0, 2] means section 1 and the third item in that section

        let sectionIndex = indexPath.section
        let section = sections[sectionIndex]

        let itemIndex = indexPath.item
        let item = section.items[itemIndex]

        let itemWeightInGrams = item.weight
        return CGSize(width: itemWeightInGrams, height: itemWeightInGrams)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - CollectionView Delegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("tapped item at indexPath: \(indexPath)")
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



