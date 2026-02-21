//
//  CarefulWhisperUITests.swift
//  CarefulWhisperUITests
//
//  Created by 906 on 2/20/26.
//

import XCTest

final class CarefulWhisperUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Verify onboarding screen appears for new users
        // The app should show the onboarding view with "CarefulWhisper" title
        let exists = app.staticTexts["CarefulWhisper"].waitForExistence(timeout: 5)
        XCTAssertTrue(exists || app.tabBars.count > 0, "App should show either onboarding or main tab view")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
