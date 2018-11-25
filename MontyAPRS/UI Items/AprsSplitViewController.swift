//
//  AprsSplitViewController.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 11/22/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import AppKit

/**
 * A custom split view to create a drawer at the bottom of the app window to
 * show raw incoming APRS packets.
 */
class AprsSplitView: NSSplitView {

    let unfoldLess = NSImage(named: "unfold-less")
    let unfoldMore = NSImage(named: "unfold-more")

    var isExpanded: Bool = false
    var expandPos: CGFloat = CGFloat(0)
    var iconRect: NSRect?

    override var dividerThickness: CGFloat {
        get {
            return CGFloat(25)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        setup()
    }

    private func setup() {
        isVertical = false
        delegate = self
    }

    override func addArrangedSubview(_ view: NSView) {
        super.addArrangedSubview(view)

        // make the view at index zero as large as possible, collapses the view
        // at index 1
        if arrangedSubviews.count > 1 {
            setPosition(maxPossiblePositionOfDivider(at: 0), ofDividerAt: 0)
        }
    }

    override func drawDivider(in rect: NSRect) {
        NSColor.controlBackgroundColor.drawSwatch(in: rect)

        var currentIcon: NSImage
        if rect.maxY < maxPossiblePositionOfDivider(at: 0) {
            currentIcon = unfoldLess!
        } else {
            currentIcon = unfoldMore!
        }

        let tempRect = NSRect(x: rect.minX + 5, y: rect.minY + 3, width: 18, height: 18)
        currentIcon.draw(in: tempRect)

        iconRect = self.convert(tempRect, to: superview)
    }

    override func resetCursorRects() {
        super.resetCursorRects()

        if iconRect != nil {
            let cursorRect = NSRect(x: 0, y: frame.maxY - iconRect!.maxY,
                                    width: iconRect!.width + 5,
                                    height: iconRect!.height)
            addCursorRect(cursorRect, cursor: .arrow)
        }
    }

    override func mouseDown(with event: NSEvent) {
        if let testRect = iconRect {
            let convertedPoint = convert(event.locationInWindow, to: self)
            if testRect.contains(convertedPoint) {
                if isExpanded {
                    setPosition(maxPossiblePositionOfDivider(at: 0), ofDividerAt: 0)
                    isExpanded = false
                } else {
                    setPosition(expandPos, ofDividerAt: 0)
                    isExpanded = true
                }
                return
            }
        }

        super.mouseDown(with: event)
    }

}

extension AprsSplitView: NSSplitViewDelegate {

    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        let index = arrangedSubviews.firstIndex(of: subview)!

        if index > 0 {
            return true
        }

        return false
    }

    func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        let maxPos = maxPossiblePositionOfDivider(at: 0)

        // enforce minimum bottom view size at 80 above the collapsed sposition
        if proposedPosition > (maxPos - 50) {
            return maxPossiblePositionOfDivider(at: 0)
        }

        // isExpanded is true because all conditions past here are "expanded"
        isExpanded = true

        // enforce maximum bottom view size at 120 above the collapsed position
        if proposedPosition < (maxPos - 140) {
            expandPos = maxPos - 140
            return maxPos - 140
        }

        expandPos = proposedPosition
        return proposedPosition
    }

}
