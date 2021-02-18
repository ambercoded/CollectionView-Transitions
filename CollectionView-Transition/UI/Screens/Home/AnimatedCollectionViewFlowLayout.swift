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

    var visibleIndexPathsSet = Set<IndexPath>()
    var latestDelta: CGFloat = 0

    override func prepare() {
        super.prepare()

        // tiling for performance
        //let visibleRect = getVisibleRect()
        //let visibleItems = getIndexPathsOfItems(in: visibleRect)
        //cleanUpNoLongerVisibleBehaviors(visibleItems: visibleItems)

        if let layoutAttributes = getLayoutAttributesOfAllItems() {
            addSnapAttachmentBehaviorToEachLayoutAttribute(layoutAttributes)
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

    // center attachment but movement restricted to vertical axis
    func addSlidingAttachmentBehaviorToEachLayoutAttribute(_ layoutAttributes: [UICollectionViewLayoutAttributes]) {
        if self.dynamicAnimator.behaviors.count == 0 {
            layoutAttributes.forEach { layoutAttribute in
                let slidingBehavior = UIAttachmentBehavior.slidingAttachment(
                    with: layoutAttribute,
                    attachmentAnchor: layoutAttribute.center,
                    axisOfTranslation: CGVector(dx: 0, dy: 1)
                )
                slidingBehavior.length = 0.0
                slidingBehavior.damping = 0.8
                slidingBehavior.frequency = 1.0
                self.dynamicAnimator.addBehavior(slidingBehavior)
            }
        }
    }

    // center attachment but movement restricted to vertical axis
    func addSnapAttachmentBehaviorToEachLayoutAttribute(_ layoutAttributes: [UICollectionViewLayoutAttributes]) {
        if self.dynamicAnimator.behaviors.count == 0 {
            layoutAttributes.forEach { layoutAttribute in
                let behavior = UISnapBehavior(item: layoutAttribute, snapTo: layoutAttribute.center)
                //behavior.length = 0.0
                behavior.damping = 1.0
                //behavior.frequency = 1.0
                self.dynamicAnimator.addBehavior(behavior)
            }
        }
    }

    // center attachment without axis restriction (results in circular motion)
    func addCircularAttachmentBehaviorToEachLayoutAttribute(_ layoutAttributes: [UICollectionViewLayoutAttributes]) {
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
            dynamicAnimator.behaviors.forEach { behavior in
                if let springBehavior = behavior as? UIAttachmentBehavior {
                    calculateSpringAnimation(
                        springBehavior: springBehavior,
                        touchPoint: touchPoint,
                        scrollingDelta: scrollingDelta
                    )
                } else if let snapBehavior = behavior as? UISnapBehavior {
                    calculateSnapAnimationConstantSnapPoint(
                        behavior: snapBehavior,
                        touchPoint: touchPoint,
                        scrollingDelta: scrollingDelta
                    )
                } else {
                    print("error: the behavior is nil. cant calculate animation for this behavior.")
                }
            }
        } else {
            print("error: there is no touchpoint. cant calculate animation for this scrolling w/o touchpoint.")
        }
        return false // no need to invalidate layout. dynamic animator is responsible of invalidating.
    }

    // MARK: - THE ITEM ANIMATION
    func calculateSnapAnimationConstantSnapPoint(
        behavior: UISnapBehavior,
        touchPoint: CGPoint,
        scrollingDelta: CGFloat
    ) {
        // in theory:
        // DONT move the snap point. instead: move the center.
        // the further away from the touchpoint, the further the center should be moved
        // thus: calculate new center and then replace the old center with the new.
        let yDistanceFromTouch = abs(touchPoint.y - behavior.snapPoint.y)
        let xDistanceFromTouch = abs(touchPoint.x - behavior.snapPoint.x)
        let scrollResistance: CGFloat = (yDistanceFromTouch + xDistanceFromTouch) / 1000

        // get the items center.
        let behaviorCenterRect = CGRect(x: behavior.snapPoint.x, y: behavior.snapPoint.y, width: 10, height: 10)
        if let dynamicItem = dynamicAnimator.items(in: behaviorCenterRect).first {
            var itemCenter = dynamicItem.center

            if scrollingDelta < 0 {
                 itemCenter.y += max(scrollingDelta, scrollingDelta*scrollResistance)
                //itemCenter.y += scrollingDelta
                // note that we clamp the product of the delta and scroll resistance
                // by the delta in case the scroll resistance exceeds the delta
                // (meaning the item might begin to move in the wrong direction).
                // This is unlikely since we’re using such a high denominator (1500),
                // but it’s something to watch out for in more bouncy collection view layouts.
            } else {
                itemCenter.y += min(scrollingDelta, scrollingDelta*scrollResistance)
                //itemCenter.y += scrollingDelta
            }

            // change the items center
            dynamicItem.center = itemCenter
            // let the animator apply the new item center
            self.dynamicAnimator.updateItem(usingCurrentState: dynamicItem)
        } else {
            print("\(behaviorCenterRect). error: no first item in snapBehavior. cant calculate new itemCenter.")
        }
    }

    // MARK: - ALTERNATIVE ITEM ANIMATIONS
    func calculateSpringAnimation(
        springBehavior: UIAttachmentBehavior,
        touchPoint: CGPoint,
        scrollingDelta: CGFloat
    ) {
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
        if let dynamicItem = springBehavior.items.first { // todo: was before "as? UICollectionViewLayoutAttributes"
            var itemCenter = dynamicItem.center

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

            dynamicItem.center = itemCenter
            self.dynamicAnimator.updateItem(usingCurrentState: dynamicItem)
        } else {
            print("error: no first item in springBehavior. cant calculate new itemCenter.")
        }
    }
}



































// MARK: - TILING FOR PERFORMANCE
extension AnimatedCollectionViewFlowLayout {
    func getVisibleRect() -> CGRect {
        return CGRect(
            origin: self.collectionView?.bounds.origin ?? CGPoint.zero,
            size: self.collectionView?.frame.size ?? CGSize.zero
        ).insetBy(dx: -100, dy: -100) // make it larger than the collectionView by 100 to catch overlapping. this assures that we dont accidently remove a behavior from an item that is still visible
    }

    func removeBehaviorsFromItemsThatAreNoLongerVisible() {
        // todo
//        let visibleRect = getVisibleRect()
//        let visibleItems = dynamicAnimator.items(in: visibleRect)
//
//        let noLongerVisibleBehaviors = self.dynamicAnimator.behaviors.filter { behavior in
//            // check for each of the dynamic animators behaviors if they are visible or not
//            let isCurrentlyVisible = visibleItems.contains(where: behavior.)
//        }


    }

    func getIndexPathsOfItems(in visibleRect: CGRect) -> Set<IndexPath> {
        // determine which items are visible
        let itemsInVisibleRect = super.layoutAttributesForElements(in: visibleRect) ?? []
        let indexPathsOfItemsInVisibleRect = Set(itemsInVisibleRect.map{ $0.indexPath })
        return indexPathsOfItemsInVisibleRect
    }

    func cleanUpNoLongerVisibleBehaviors(visibleItems: Set<IndexPath>) {
        let noLongerVisibleBehaviors = getAllNoLongerVisibleBehaviors(visibleItems: visibleItems)
        removeFromDynamicAnimator(noLongerVisibleBehaviors)
    }

    private func getAllNoLongerVisibleBehaviors(visibleItems: Set<IndexPath>) -> [UIDynamicBehavior] {
//        let noLongerVisibleBehaviors = self.dynamicAnimator.behaviors.filter
//        { behavior in
//             guard let behavior = behavior as? UISnapBehavior else { return false } // ? was UIAttachmentBehavior
//             guard let attribute = behavior.items.first as? UICollectionViewLayoutAttributes else { return false }
//            let currentlyVisible = visibleItems.contains(attribute.indexPath)
//            return !currentlyVisible
//        }
//        return noLongerVisibleBehaviors
        return []
    }

    private func removeFromDynamicAnimator(_ behaviors: [UIDynamicBehavior]) {
        behaviors.forEach
        { behavior in
            self.dynamicAnimator.removeBehavior(behavior)
            guard let behavior = behavior as? UIAttachmentBehavior else { return }
            guard let attribute = behavior.items.first as? UICollectionViewLayoutAttributes else { return }
            self.visibleIndexPathsSet.remove(attribute.indexPath)
        }
    }

}
