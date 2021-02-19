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
    let enableLimitForShiftOnYAxis = false
    let yAxisShiftLimit: CGFloat = 5
    var yAxisShiftLimitNegative: CGFloat { yAxisShiftLimit * -1 }
    let scrollReactionResistance: CGFloat = 1500.0

    // spring parameters for bounciness
    let attachmentLength: CGFloat = 0.0
    let frictionTorque: CGFloat? = nil
    let springDamping: CGFloat = 0.8
    let oscillationFrequency: CGFloat = 1.0

    override func prepare() {
        super.prepare()
        // print("prepare called")
        // todo: cpu usage like 20-50% as long as dynamic animator is working
        // (as long as spring effetc is active). consider shortening
        let visibleRect = CGRect(
            origin: self.collectionView?.bounds.origin ?? CGPoint.zero,
            size: self.collectionView?.frame.size ?? CGSize.zero
        ).insetBy(dx: -100, dy: -100) // make it larger than the collectionView by 100

        // determine which items are visible
        let itemsInVisibleRectArray = super.layoutAttributesForElements(in: visibleRect) ?? []
        let itemsIndexPathsInVisibleRectSet = Set(itemsInVisibleRectArray.map{ $0.indexPath })

        /// find and remove all behaviors that are no longer visible
        // get all noLongerVisibleBehaviors
        let noLongerVisibleBehaviors = self.dynamicAnimator.behaviors.filter { behavior in
            guard let behavior = behavior as? UIAttachmentBehavior else { return false }
            guard let attribute = behavior.items.first as? UICollectionViewLayoutAttributes else { return false }
            let currentlyVisible = itemsIndexPathsInVisibleRectSet.contains(attribute.indexPath)
            return !currentlyVisible
        }

        // remove all noLongerVisibleBehaviors
        noLongerVisibleBehaviors.forEach { behavior in
                self.dynamicAnimator.removeBehavior(behavior)
                guard let behavior = behavior as? UIAttachmentBehavior else { return }
                guard let attribute = behavior.items.first as? UICollectionViewLayoutAttributes else { return }
                self.visibleIndexPathsSet.remove(attribute.indexPath)
        }

        // find all items that just became visible
        let newlyVisibleItems = itemsInVisibleRectArray.filter { item in
            let currentlyVisible = self.visibleIndexPathsSet.contains(item.indexPath)
            return !currentlyVisible
        }

        let touchLocation = self.collectionView?.panGestureRecognizer.location(in: self.collectionView)

        // add dynamic behavior to each newly visible item
        for item in newlyVisibleItems {
            // IMPORTANT! The center coordinate and needs to be rounded, else there are animation problems.
            // thus, when setting the anchor and center, i have to make sure that it is rounded first, so that there is no rounding done when animating (which triggers unwanted 0.0000001 movement on the x-axis and triggers an oscillation)
            // change item center to roundedCenter
            var centerRounded = CGPoint(x: CGFloat.rounded(item.center.x)(), y: CGFloat.rounded(item.center.y)())
            // i also have to round the center of the item itself when it is first layed out (not only the anchor)
            if item.center != centerRounded {
                item.center = centerRounded
            }

            // set spring anchor to ROUNDED Center. avoids that the animation engine rounds decimals which results
            // in unwanted x and y "movement" and thus oscillation along the x-axis.
            let springBehavior = UIAttachmentBehavior(item: item, attachedToAnchor: centerRounded)

            // configure spring behavior
            springBehavior.length = attachmentLength
            springBehavior.damping = springDamping
            springBehavior.frequency = oscillationFrequency
            if let frictionTorque = frictionTorque {
                springBehavior.frictionTorque = frictionTorque
            }

            // calculate new center y coordinate for the item after dragging
            // intensity of animation depends on the items distance to the tap location
            if let touchLocation = touchLocation, CGPoint.zero != touchLocation {
                let yDistanceFromTouch = abs(touchLocation.y - springBehavior.anchorPoint.y)
                let xDistanceFromTouch = abs(touchLocation.x - springBehavior.anchorPoint.x)
                let scrollResistance = (yDistanceFromTouch + xDistanceFromTouch) / scrollReactionResistance

                if self.latestDelta < 0.0 {
                    var amountOfYShift = max(self.latestDelta, self.latestDelta * scrollResistance)
                    let animationLimiterShouldKickIn = enableLimitForShiftOnYAxis && amountOfYShift < yAxisShiftLimitNegative
                    if animationLimiterShouldKickIn { amountOfYShift = yAxisShiftLimitNegative }
                    centerRounded.y += amountOfYShift
                } else {
                    var amountOfYShift = min(self.latestDelta, self.latestDelta * scrollResistance)
                    if enableLimitForShiftOnYAxis && amountOfYShift > yAxisShiftLimit {
                        amountOfYShift = yAxisShiftLimit
                    }
                    centerRounded.y += amountOfYShift
                }
                item.center = centerRounded
            }

            self.dynamicAnimator.addBehavior(springBehavior)
            self.visibleIndexPathsSet.insert(item.indexPath)
        }
    }

    // MARK: - ANIMATION CALCULATION HELPER
    func calculateAndApplyNewCenterCoordinateAfterDragging(for item: UIDynamicItem, with touchLocation: CGPoint) {

    }

    func animationLimiterShouldKickIn() -> Bool {
        return false
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.dynamicAnimator.items(in: rect) as? [UICollectionViewLayoutAttributes]
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.dynamicAnimator.layoutAttributesForCell(at: indexPath)
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
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
            //var center = item.center
            var centerRounded = CGPoint(x: CGFloat.rounded(item.center.x)(), y: CGFloat.rounded(item.center.y)())

            if self.latestDelta < 0.0 {
                var amountOfYShift = max(self.latestDelta, self.latestDelta * scrollResistance)
                if enableLimitForShiftOnYAxis {
                    if amountOfYShift < yAxisShiftLimitNegative { amountOfYShift = yAxisShiftLimitNegative }
                }
                centerRounded.y += amountOfYShift
            } else {
                var amountOfYShift = min(self.latestDelta, self.latestDelta * scrollResistance)
                if enableLimitForShiftOnYAxis {
                    if amountOfYShift > yAxisShiftLimit { amountOfYShift = yAxisShiftLimit }
                }
                centerRounded.y += amountOfYShift
            }

            item.center = centerRounded
            self.dynamicAnimator.updateItem(usingCurrentState: item)
        }

        return false
    }
}
