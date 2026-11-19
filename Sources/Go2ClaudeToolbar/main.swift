import AppKit

let application = NSApplication.shared
let appDelegate = ToolbarAppDelegate()

application.setActivationPolicy(.accessory)
application.delegate = appDelegate
application.run()
