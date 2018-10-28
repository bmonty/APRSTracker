//
//  PreferencesViewController.swift
//  MontyAPRS
//
//  Created by Benjamin Montgomery on 10/27/18.
//  Copyright © 2018 Benjamin Montgomery. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the size for each view
        self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        // Update the window title with the active tabview title
        self.parent?.view.window?.title = self.title!
    }
}
