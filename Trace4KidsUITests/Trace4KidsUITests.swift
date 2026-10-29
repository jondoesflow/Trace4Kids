import XCTest

final class Trace4KidsUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-TraceDemo"] + arguments
        app.launch()
        return app
    }

    private func screenshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testTraceFlow() {
        let app = launch(["-TraceEmpty"])
        XCTAssertTrue(app.buttons["pickPicture"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["keepTracing"].exists)
        screenshot(app, "01-home")

        app.buttons["samplePicture"].tap()
        XCTAssertTrue(app.buttons["lock"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.otherElements["moveHint"].exists || app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Pinch'")).count > 0)
        screenshot(app, "02-trace")

        app.buttons["lines"].tap()
        sleep(2)
        screenshot(app, "03-lines")
        app.buttons["lines"].tap()

        app.buttons["lock"].tap()
        XCTAssertFalse(app.buttons["lines"].exists, "Tools hide while locked")
        screenshot(app, "04-locked")

        app.buttons["home"].tap()
        XCTAssertTrue(app.buttons["keepTracing"].waitForExistence(timeout: 5))
        screenshot(app, "05-home-saved")

        app.buttons["keepTracing"].tap()
        XCTAssertTrue(app.buttons["lock"].waitForExistence(timeout: 5))
        screenshot(app, "06-welcome-back")
    }

    func testTracingIsKeptAfterRelaunch() {
        var app = launch(["-TraceEmpty"])
        app.buttons["samplePicture"].tap()
        XCTAssertTrue(app.buttons["lock"].waitForExistence(timeout: 10))
        app.buttons["lock"].tap()
        app.buttons["home"].tap()
        XCTAssertTrue(app.buttons["keepTracing"].waitForExistence(timeout: 5))
        app.terminate()

        app = launch([])
        XCTAssertTrue(app.buttons["keepTracing"].waitForExistence(timeout: 10))
    }

    func testHowTo() {
        let app = launch(["-TraceEmpty"])
        app.buttons["howTo"].tap()
        XCTAssertTrue(app.navigationBars["How to trace"].waitForExistence(timeout: 5))
        screenshot(app, "07-how-to")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["pickPicture"].waitForExistence(timeout: 5))
    }
}
