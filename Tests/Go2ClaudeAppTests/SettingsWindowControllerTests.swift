import AppKit
import Go2ClaudeCore
import SwiftUI
import XCTest
@testable import Go2Claude

@MainActor
final class SettingsWindowControllerTests: XCTestCase {
    func test_usesComfortableResizableDefaultContentSizeForCommandReferenceActions() {
        let controller = SettingsWindowController(rootView: makeSettingsView())

        let window = controller.window
        let contentHeight = window.map { $0.contentRect(forFrameRect: $0.frame).height } ?? 0
        let contentWidth = window.map { $0.contentRect(forFrameRect: $0.frame).width } ?? 0

        XCTAssertGreaterThan(contentWidth, 0)
        XCTAssertEqual(Double(contentWidth), 920, accuracy: 0.5)
        XCTAssertLessThan(contentHeight, 840)
        XCTAssertTrue(window?.styleMask.contains(.resizable) == true)
        XCTAssertEqual(window?.minSize.width ?? 0, 720, accuracy: 0.5)
        XCTAssertLessThanOrEqual(window?.minSize.height ?? 0, contentHeight)
    }

    func test_defaultContentHeightMatchesFittingHeightAllowanceWithoutMinimumFloor() {
        let rootView = makeSettingsView()
        let hostingController = NSHostingController(rootView: rootView)
        hostingController.view.setFrameSize(NSSize(width: 920, height: 1))
        hostingController.view.layoutSubtreeIfNeeded()

        let fittingHeight = hostingController.sizeThatFits(
            in: NSSize(width: 920, height: CGFloat.greatestFiniteMagnitude)
        ).height
        let legacyHeight = (hostingController.view.fittingSize.height + 16) * 0.9
        let controller = SettingsWindowController(rootView: rootView)
        let contentHeight = controller.window.map { $0.contentRect(forFrameRect: $0.frame).height } ?? 0

        XCTAssertEqual(contentHeight, fittingHeight + 16, accuracy: 1.5)
        XCTAssertLessThan(contentHeight, legacyHeight)
    }

    func test_defaultSettingsWindowAvoidsEmbeddingScrollView() {
        let controller = SettingsWindowController(rootView: makeSettingsView())

        let containsScrollView = containsScrollView(in: controller.window?.contentView)

        XCTAssertFalse(containsScrollView)
    }

    func test_windowUsesHostingViewAsContentViewOnInitialDisplay() {
        let controller = SettingsWindowController(rootView: makeSettingsView())

        guard
            let window = controller.window,
            let contentView = window.contentView
        else {
            return XCTFail("Expected window content view hierarchy")
        }

        XCTAssertTrue(String(describing: type(of: contentView)).contains("NSHostingView"))
        XCTAssertEqual(contentView.frame.origin.x, 0, accuracy: 0.5)
        XCTAssertEqual(contentView.frame.origin.y, 0, accuracy: 0.5)
        XCTAssertEqual(contentView.frame.width, window.frame.width, accuracy: 1.0)
        XCTAssertGreaterThan(contentView.frame.height, 0)
    }

    func test_missingClaudeNoticeStillFitsWithoutScrollView() {
        let state = SettingsWindowState()
        state.claudeInstallationStatus = .notInstalled

        let controller = SettingsWindowController(rootView: makeSettingsView(state: state))
        let containsScrollView = containsScrollView(in: controller.window?.contentView)
        let contentHeight = controller.window.map { $0.contentRect(forFrameRect: $0.frame).height } ?? 0

        XCTAssertFalse(containsScrollView)
        XCTAssertGreaterThan(contentHeight, 0)
        XCTAssertLessThanOrEqual(controller.window?.minSize.height ?? 0, contentHeight)
    }

    func test_installedClaudeStatusStillFitsWithoutScrollView() {
        let state = SettingsWindowState()
        state.claudeInstallationStatus = .installed(executablePath: "/opt/homebrew/bin/claude")

        let controller = SettingsWindowController(rootView: makeSettingsView(state: state))
        let containsScrollView = containsScrollView(in: controller.window?.contentView)
        let contentHeight = controller.window.map { $0.contentRect(forFrameRect: $0.frame).height } ?? 0

        XCTAssertFalse(containsScrollView)
        XCTAssertGreaterThan(contentHeight, 0)
        XCTAssertLessThanOrEqual(controller.window?.minSize.height ?? 0, contentHeight)
    }

    func test_windowHeightUpdatesWhenContentChangesAndShrinksBack() {
        let state = SettingsWindowState()
        let controller = SettingsWindowController(rootView: makeSettingsView(state: state))

        let initialHeight = controller.window.map { $0.contentRect(forFrameRect: $0.frame).height } ?? 0

        state.launchMessage = Array(repeating: "这是一条用于验证窗口会随内容自适应高度的提示信息。", count: 8).joined()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        let expandedHeight = controller.window.map { $0.contentRect(forFrameRect: $0.frame).height } ?? 0

        state.launchMessage = nil
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        let collapsedHeight = controller.window.map { $0.contentRect(forFrameRect: $0.frame).height } ?? 0

        XCTAssertGreaterThan(expandedHeight, initialHeight + 20)
        XCTAssertEqual(collapsedHeight, initialHeight, accuracy: 2.0)
    }

    func test_windowHeightUpdatePreservesWindowPositionAfterWindowMoves() {
        let state = SettingsWindowState()
        let controller = SettingsWindowController(rootView: makeSettingsView(state: state))

        guard let window = controller.window else {
            return XCTFail("Expected settings window")
        }

        let movedOrigin = NSPoint(x: 420, y: 360)
        window.setFrameOrigin(movedOrigin)
        let initialTopEdge = window.frame.maxY

        state.launchMessage = Array(repeating: "拖动窗口后不应在内容更新时丢失横向位置。", count: 8).joined()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        XCTAssertEqual(window.frame.origin.x, movedOrigin.x, accuracy: 1.0)
        XCTAssertEqual(window.frame.maxY, initialTopEdge, accuracy: 1.0)
    }

    private func makeSettingsView(state: SettingsWindowState = SettingsWindowState()) -> SettingsView {
        SettingsView(
            settings: AppSettings(),
            state: state,
            onRevealAppInFinder: {},
            onLaunchClaude: {},
            onOpenClaudeInstallGuide: {},
            onRefreshClaudeInstallationStatus: {},
            onRunReferenceCommand: { _ in true },
            onUseDevelopmentMode: {},
            onShowUsageTips: {}
        )
    }

    private func containsScrollView(in view: NSView?) -> Bool {
        guard let view else {
            return false
        }

        if view is NSScrollView {
            return true
        }

        return view.subviews.contains { containsScrollView(in: $0) }
    }
}
