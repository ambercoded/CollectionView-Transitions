//
//  AnimatedSlidingCollectionViewFlowLayout.swift
//  CollectionView-Transition
//
//  Created by Adrian on 18.02.21.
//

import UIKit

class AnimatedSlidingCollectionViewFlowLayout: UICollectionViewFlowLayout {

    lazy var dynamicAnimator: UIDynamicAnimator = {
        return UIDynamicAnimator(collectionViewLayout: self)
    }()

    var visibleIndexPathsSet = Set<IndexPath>()
    var latestDelta: CGFloat = 0

    // animator parameters for bounciness
    let maximumYAxisShift: CGFloat = 10.0
    var negativeMaximumYAxisShift: CGFloat { maximumYAxisShift * -1 }
    let scrollReactionResistance: CGFloat = 2000.0

    // spring parameters for bounciness
    let attachmentLength: CGFloat = 0.0
    let frictionTorque: CGFloat? = nil
    let springDamping: CGFloat = 0.5
    let oscillationFrequency: CGFloat = 1.0

    override func prepare() {
        super.prepare()
        // print("prepare called")
        // todo: cpu usage like 20-50% as long as dynamic animator is working
        // (as long as spring effetc is active). consider shortening
        let visibleRect = CGRect(
            origin: self.collectionView?.bounds.origin ?? CGPoint.zero,
            size: self.collectionView?.frame.size ?? CGSize.zero
        ).insetBy(dx: -0, dy: -0) // make it larger than the collectionView by 100

        // determine which items are visible
        let itemsInVisibleRectArray = super.layoutAttributesForElements(in: visibleRect) ?? []
        let itemsIndexPathsInVisibleRectSet = Set(itemsInVisibleRectArray.map{ $0.indexPath })

        /// find and remove all behaviors that are no longer visible
        // get all noLongerVisibleBehaviors
        let noLongerVisibleBehaviors = self.dynamicAnimator.behaviors.filter
        { behavior in
            guard let behavior = behavior as? UIAttachmentBehavior else { return false }
            guard let attribute = behavior.items.first as? UICollectionViewLayoutAttributes else { return false }
            let currentlyVisible = itemsIndexPathsInVisibleRectSet.contains(attribute.indexPath)
            return !currentlyVisible
        }

        // remove all noLongerVisibleBehaviors
        noLongerVisibleBehaviors.forEach
            { behavior in
                self.dynamicAnimator.removeBehavior(behavior)
                guard let behavior = behavior as? UIAttachmentBehavior else { return }
                guard let attribute = behavior.items.first as? UICollectionViewLayoutAttributes else { return }
                self.visibleIndexPathsSet.remove(attribute.indexPath)
        }

        // find all items that just became visible
        let newlyVisibleItems = itemsInVisibleRectArray.filter
        { item in
            let currentlyVisible = self.visibleIndexPathsSet.contains(item.indexPath)
            return !currentlyVisible
        }

        let touchLocation = self.collectionView?.panGestureRecognizer.location(in: self.collectionView)

        // add dynamic behavior to each newly visible item
        for item in newlyVisibleItems
        {
            var center = item.center
            let springBehavior = UIAttachmentBehavior(item: item, attachedToAnchor: center)
            //let springBehavior = UIAttachmentBehavior.slidingAttachment(with: item, attachmentAnchor: center, axisOfTranslation: CGVector(dx: 0, dy: 1))

            springBehavior.length = attachmentLength
            springBehavior.damping = springDamping
            springBehavior.frequency = oscillationFrequency
            if let frictionTorque = frictionTorque {
                springBehavior.frictionTorque = frictionTorque
            }
            //springBehavior.attachmentRange = UIFloatRange(minimum: -500, maximum: 500)

            // calculate new center y coordinate for the item after dragging
            // intensity of animation depends on the items distance to the tap location

            if let touchLocation = touchLocation, CGPoint.zero != touchLocation
            {
                let yDistanceFromTouch = abs(touchLocation.y - springBehavior.anchorPoint.y)
                let xDistanceFromTouch = abs(touchLocation.x - springBehavior.anchorPoint.x)
                let scrollResistance = (yDistanceFromTouch + xDistanceFromTouch) / scrollReactionResistance

                if self.latestDelta < 0.0 {
                    var amountOfYShift = max(self.latestDelta, self.latestDelta * scrollResistance)
                    if amountOfYShift < negativeMaximumYAxisShift { amountOfYShift = negativeMaximumYAxisShift }
                    center.y += amountOfYShift
                } else {
                    var amountOfYShift = min(self.latestDelta, self.latestDelta * scrollResistance)
                    if amountOfYShift > maximumYAxisShift { amountOfYShift = maximumYAxisShift }
                    center.y += amountOfYShift
                }
                item.center = center
            }

            self.dynamicAnimator.addBehavior(springBehavior)
            self.visibleIndexPathsSet.insert(item.indexPath)
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]?
    {
        guard let attributes = self.dynamicAnimator.items(in: rect) as? [UICollectionViewLayoutAttributes] else { return nil }
        return attributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes?
    {
        return self.dynamicAnimator.layoutAttributesForCell(at: indexPath)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool
    {
        let scrollView = self.collectionView
        let delta = newBounds.origin.y - (scrollView?.bounds.origin.y ?? 0)
        self.latestDelta = delta
        let touchLocation = self.collectionView?.panGestureRecognizer.location(in: self.collectionView)

        for springBehavior in self.dynamicAnimator.behaviors
        {
            guard let springBehavior = springBehavior as? UIAttachmentBehavior, let touchLocation = touchLocation else { continue }
            let yDistanceFromTouch = abs(touchLocation.y - springBehavior.anchorPoint.y)
            let xDistanceFromTouch = abs(touchLocation.x - springBehavior.anchorPoint.x)
            let scrollResistance: CGFloat = (yDistanceFromTouch + xDistanceFromTouch) / scrollReactionResistance

            guard let item = springBehavior.items.first as? UICollectionViewLayoutAttributes else { continue }
            var center = item.center
            if self.latestDelta < 0.0 {
                var amountOfYShift = max(self.latestDelta, self.latestDelta * scrollResistance)
                if amountOfYShift < negativeMaximumYAxisShift { amountOfYShift = negativeMaximumYAxisShift }
                center.y += amountOfYShift
            } else {
                var amountOfYShift = min(self.latestDelta, self.latestDelta * scrollResistance)
                if amountOfYShift > maximumYAxisShift { amountOfYShift = maximumYAxisShift }
                center.y += amountOfYShift
            }

            item.center = center
            self.dynamicAnimator.updateItem(usingCurrentState: item)
        }

        return false
    }
}
