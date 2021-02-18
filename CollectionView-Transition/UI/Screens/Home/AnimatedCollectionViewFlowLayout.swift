//
//  AnimatedCollectionViewFlowLayout.swift
//  CollectionView-Transition
//
//  Created by Adrian on 18.02.21.
//

import UIKit

class AnimatedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    lazy var dynamicAnimator: UIDynamicAnimator = {
        return UIDynamicAnimator(collectionViewLayout: self)
    }()

    override func prepare() {
        super.prepare()
        print("prepare called")

        if let layoutAttributes = getLayoutAttributesOfAllItems() {
            addBehaviorToEachLayoutAttribute(layoutAttributes)
        } else {
            print("no layoutAttributes returned. cant add behaviors now.")
        }
    }

    func getLayoutAttributesOfAllItems() -> [UICollectionViewLayoutAttributes]? {
        let contentViewSize = self.collectionView?.contentSize
        let contentViewRect = CGRect(
            x: 0,
            y: 0,
            width: contentViewSize?.width ?? .zero,
            height: contentViewSize?.height ?? .zero
        )
        let layoutAttributesOfAllItems = super.layoutAttributesForElements(in: contentViewRect)
        return layoutAttributesOfAllItems
    }

    func addBehaviorToEachLayoutAttribute(_ layoutAttributes: [UICollectionViewLayoutAttributes]) {
        if self.dynamicAnimator.behaviors.count == 0 {
            layoutAttributes.forEach { layoutAttribute in
                let behavior = UIAttachmentBehavior(item: layoutAttribute, attachedToAnchor: layoutAttribute.center)

                behavior.length = 0.0
                behavior.damping = 0.8
                behavior.frequency = 1.0

                self.dynamicAnimator.addBehavior(behavior)
            }
        }
    }
}

// MARK: - Layout Queries
extension AnimatedCollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        self.dynamicAnimator.items(in: rect) as? [UICollectionViewLayoutAttributes]
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        self.dynamicAnimator.layoutAttributesForCell(at: indexPath)
    }
}

// MARK: - Responding to Scrolling
extension AnimatedCollectionViewFlowLayout {
    // called when the bounds of the cv change.
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let scrollview = self.collectionView
        let scrollingDelta = newBounds.origin.y - (scrollview?.bounds.origin.y ?? 0)

        if let touchPoint = self.collectionView?.panGestureRecognizer.location(in: collectionView) {
            // todo refactor in own method
            dynamicAnimator.behaviors.forEach { behavior in
                if let springBehavior = behavior as? UIAttachmentBehavior {

                    /// calculate the scrollResistance. items closer to the touchPoint have a lower resistance and move more than items that are far away from the touchPoint.
                    // imessage does this the other way round i think. todo: turn around?
                    // but his reasoning sounds right: " Once we have the delta, we need to grab the location of the user’s touch. This is important because we want items closer to the touch to move more immediately while items further from the touch should lag behind."
                    let yDistanceFromTouch = abs(touchPoint.y - springBehavior.anchorPoint.y)
                    // todo consider if i need to take the horizental distance
                    // of the touchpoint to the element into account.
                    // maybe remove this from the equation.
                    // but that would increase the scrollResistance.
                    let xDistanceFromTouch = abs(touchPoint.x - springBehavior.anchorPoint.x)
                    let scrollResistance: CGFloat = (yDistanceFromTouch + xDistanceFromTouch) / 1500

                    /// calculate a new center for the object.
                    // the new item center is shifted up or down.
                    // the intensity of the y shift depends on the items distance to the touchpoint.
                    // scrollResistance is calculated based on itemDistanceToTouchpoint
                    if let itemLayoutAttribute = springBehavior.items.first as? UICollectionViewLayoutAttributes {
                        var itemCenter = itemLayoutAttribute.center

                        if scrollingDelta < 0 {
                            itemCenter.y += max(scrollingDelta, scrollingDelta*scrollResistance)
                            // note that we clamp the product of the delta and scroll resistance
                            // by the delta in case the scroll resistance exceeds the delta
                            // (meaning the item might begin to move in the wrong direction).
                            // This is unlikely since we’re using such a high denominator (1500),
                            // but it’s something to watch out for in more bouncy collection view layouts.
                        } else {
                            itemCenter.y += min(scrollingDelta, scrollingDelta*scrollResistance)
                        }

                        itemLayoutAttribute.center = itemCenter
                        self.dynamicAnimator.updateItem(usingCurrentState: itemLayoutAttribute)
                    } else {
                        print("error: no first item in springBehavior. cant calculate new itemCenter.")
                    }

                } else {
                    print("error: the behavior is nil. cant calculate animation for this behavior.")
                }
            }

        } else {
            print("error: there is no touchpoint. cant calculate animation for this scrolling w/o touchpoint.")
        }

        // no need to invalidate layout. dynamic animator is responsible of invalidating.
        return false
    }
}
