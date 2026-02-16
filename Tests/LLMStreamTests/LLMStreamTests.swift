import Testing
import Foundation
import WebKit
import SwiftUI
@testable import LLMStream

@MainActor private func makeCoordinator(openExternalURL: @escaping @MainActor (URL) -> Void) -> Coordinator {
    #if os(iOS)
    let parent = MarkdownLatexViewiOS(
        content: "",
        height: .constant(0),
        configuration: .default,
        onUrlClicked: { _ in }
    )
    #else
    let parent = MarkdownLatexViewMacOS(
        content: "",
        height: .constant(0),
        configuration: .default,
        onUrlClicked: { _ in }
    )
    #endif

    return Coordinator(parent, openExternalURL: openExternalURL)
}

@MainActor @Test func navigationPolicyCancelsAndOpensForActivatedLinks() async throws {
    let expectedURL = try #require(URL(string: "https://example.com"))
    var openedURL: URL?
    let coordinator = makeCoordinator { url in
        openedURL = url
    }

    let policy = coordinator.navigationPolicy(for: expectedURL, navigationType: .linkActivated)

    #expect(policy == .cancel)
    #expect(openedURL == expectedURL)
}

@MainActor @Test func navigationPolicyAllowsNonActivatedNavigation() async throws {
    let url = try #require(URL(string: "https://example.com"))
    var didOpenURL = false
    let coordinator = makeCoordinator { _ in
        didOpenURL = true
    }

    let policy = coordinator.navigationPolicy(for: url, navigationType: .other)

    #expect(policy == .allow)
    #expect(didOpenURL == false)
}

@MainActor @Test func navigationPolicyAllowsMissingURL() async throws {
    var didOpenURL = false
    let coordinator = makeCoordinator { _ in
        didOpenURL = true
    }

    let policy = coordinator.navigationPolicy(for: nil, navigationType: .linkActivated)

    #expect(policy == .allow)
    #expect(didOpenURL == false)
}

@Test func heightUpdateRegulatorThrottlesFrequentIncrease() {
    var regulator = HeightUpdateRegulator(minimumUpdateInterval: 0.1)
    let base = Date(timeIntervalSince1970: 1_000)

    #expect(regulator.shouldApplyHeight(100, at: base) == true)
    #expect(regulator.shouldApplyHeight(120, at: base.addingTimeInterval(0.02)) == false)
    #expect(regulator.shouldApplyHeight(140, at: base.addingTimeInterval(0.12)) == true)
}

@Test func heightUpdateRegulatorAllowsImmediateDecrease() {
    var regulator = HeightUpdateRegulator(minimumUpdateInterval: 0.1)
    let base = Date(timeIntervalSince1970: 2_000)

    #expect(regulator.shouldApplyHeight(200, at: base) == true)
    #expect(regulator.shouldApplyHeight(80, at: base.addingTimeInterval(0.01)) == true)
}
