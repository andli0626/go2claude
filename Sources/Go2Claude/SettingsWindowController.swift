import AppKit
import Combine
import SwiftUI

private struct HostedSettingsRoot: View {
    let content: SettingsView

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

final class SettingsWindowController: NSWindowController {
    private static let defaultContentWidth: CGFloat = 920
    private static let minimumContentWidth: CGFloat = 720
    private static let minimumContentHeight: CGFloat = 320
    private static let verticalPaddingAllowance: CGFloat = 16

    private let hostingView: NSHostingView<HostedSettingsRoot>
    private var cancellables = Set<AnyCancellable>()
    private var lastMeasuredContentWidth: CGFloat = 920
    private var measuredRootView: SettingsView

    init(rootView: SettingsView) {
        measuredRootView = rootView
        hostingView = NSHostingView(rootView: HostedSettingsRoot(content: rootView))
        hostingView.autoresizingMask = [.width, .height]
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.defaultContentWidth, height: Self.minimumContentHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Go2Claude 设置"
        window.contentView = hostingView
        window.minSize = NSSize(width: Self.minimumContentWidth, height: Self.minimumContentHeight)
        window.contentMinSize = NSSize(width: Self.minimumContentWidth, height: Self.minimumContentHeight)
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)

        window.delegate = self
        var adaptiveRootView = rootView
        adaptiveRootView.onContentHeightChange = { [weak self] in
            DispatchQueue.main.async {
                self?.updateWindowHeight()
            }
        }
        measuredRootView = adaptiveRootView
        hostingView.rootView = HostedSettingsRoot(content: adaptiveRootView)
        updateWindowHeight(preserveTopEdge: false)
        bindContentHeightUpdates(for: rootView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func bindContentHeightUpdates(for rootView: SettingsView) {
        Publishers.MergeMany(
            rootView.state.$launchMessage.map { _ in () }.eraseToAnyPublisher(),
            rootView.state.$claudeInstallationStatus.map { _ in () }.eraseToAnyPublisher(),
            rootView.state.$shouldRefreshClaudeInstallationStatusWhenActive.map { _ in () }.eraseToAnyPublisher(),
            rootView.state.$isWaitingForClaudeInstallation.map { _ in () }.eraseToAnyPublisher(),
            rootView.settings.$commandTemplate.map { _ in () }.eraseToAnyPublisher()
        )
        .dropFirst(5)
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateWindowHeight()
            }
        }
        .store(in: &cancellables)
    }

    private func updateWindowHeight(preserveTopEdge: Bool = true) {
        guard let window else {
            return
        }

        let contentWidth = max(window.contentView?.bounds.width ?? Self.defaultContentWidth, Self.minimumContentWidth)
        let targetContentHeight = max(measuredContentHeight(for: contentWidth), Self.minimumContentHeight)
        let currentFrame = window.frame
        let targetContentRect = NSRect(x: 0, y: 0, width: contentWidth, height: targetContentHeight)
        var targetFrame = window.frameRect(forContentRect: targetContentRect)

        if preserveTopEdge {
            targetFrame.origin.x = currentFrame.origin.x
            targetFrame.origin.y = currentFrame.maxY - targetFrame.height
        } else {
            targetFrame.origin = currentFrame.origin
        }

        window.setFrame(targetFrame, display: true)
        lastMeasuredContentWidth = contentWidth
    }

    private func measuredContentHeight(for width: CGFloat) -> CGFloat {
        let measuringController = NSHostingController(rootView: measuredRootView)
        measuringController.view.setFrameSize(NSSize(width: width, height: 1))
        measuringController.view.invalidateIntrinsicContentSize()
        measuringController.view.needsLayout = true
        measuringController.view.layoutSubtreeIfNeeded()
        let fittingSize = measuringController.sizeThatFits(
            in: NSSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        )

        return fittingSize.height + Self.verticalPaddingAllowance
    }
}

extension SettingsWindowController: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        guard let window else {
            return
        }

        let contentWidth = window.contentView?.frame.width ?? Self.defaultContentWidth
        let currentContentHeight = window.contentRect(forFrameRect: window.frame).height
        let expectedContentHeight = max(measuredContentHeight(for: contentWidth), Self.minimumContentHeight)
        let widthChanged = abs(contentWidth - lastMeasuredContentWidth) > 0.5
        let heightDrifted = abs(currentContentHeight - expectedContentHeight) > 1.0

        guard widthChanged || heightDrifted else {
            return
        }

        updateWindowHeight()
    }
}
