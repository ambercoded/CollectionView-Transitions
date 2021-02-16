//
//  VegetableCell.swift
//  CollectionView-Transition
//
//  Created by Adrian B. Haeske on 16.02.21.
//

import UIKit

class VegetableCell: UICollectionViewCell, SelfConfiguringCell {
    static var reuseIdentifier: String = "VegetableCell"

    // the UI elements
    let name = UILabel()
    let imageView = UIImageView()

    // fill the uielements
    override init(frame: CGRect) {
        super.init(frame: frame)

        name.font = UIFont.preferredFont(forTextStyle: .title2)
        name.textColor = .label

        imageView.layer.cornerRadius = 5
        imageView.clipsToBounds = true // make sure that corner radius is applied
        imageView.contentMode = .scaleAspectFit

        // combine it into a stackView
        let stackView = UIStackView(arrangedSubviews: [name, imageView])
        stackView.translatesAutoresizingMaskIntoConstraints = false // do constraints by hand
        stackView.axis = .vertical // should be aligned vertically
        contentView.addSubview(stackView)

        // manual constraints
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        // custom spacing
        stackView.setCustomSpacing(10, after: name)
    }

    required init?(coder: NSCoder) {
        fatalError("We will not support creating a cell from storyboard. Thus, this is not required.")
    }

    func configure(with vegetable: Vegetable) {
        name.text = vegetable.name
        imageView.image = UIImage(named: vegetable.image)
    }


}
