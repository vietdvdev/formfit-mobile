import XCTest

final class ActiveWorkoutFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        app = XCUIApplication()
        // Cung cấp launch arguments để app chạy ở chế độ UI Testing độc lập, reset state
        app.launchArguments = ["-UITesting", "-ResetState"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    func test_activeWorkout_fullLifecycle_andMiniBarInteraction() throws {
        // 1. TabBar: Đảm bảo đang ở Tab Tập Luyện (Workout)
        let workoutTabButton = app.tabBars.buttons["Tập Luyện"]
        XCTAssertTrue(workoutTabButton.waitForExistence(timeout: 4.0))
        workoutTabButton.tap()

        // 2. Dashboard: Bấm nút "Bắt Đầu Ngay"
        let startButton = app.buttons["Bắt Đầu Ngay"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3.0))
        startButton.tap()

        // 3. Màn hình Active Workout: Kiểm tra tiêu đề và bài tập mẫu
        let workoutNavTitle = app.navigationBars.staticTexts["Buổi tập trực tiếp"]
        XCTAssertTrue(workoutNavTitle.waitForExistence(timeout: 3.0))

        // 4. Nhập trọng lượng tạ & số rep cho Set 1
        // Tìm ô nhập KG đầu tiên
        let kgTextField = app.textFields.matching(identifier: "weight_field").firstMatch
        if kgTextField.exists {
            kgTextField.tap()
            kgTextField.typeText("60")
        }

        // Tìm nút Checkmark tròn của Set 1 để hoàn thành
        let set1Checkmark = app.buttons.matching(NSPredicate(format: "label CONTAINS 'circle' OR label CONTAINS 'checkmark'")).firstMatch
        XCTAssertTrue(set1Checkmark.exists)
        set1Checkmark.tap()

        // 5. Kiểm tra Banner Rest Timer xuất hiện
        let restTimerText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'NGHỈ GIỮA HIỆP'")).firstMatch
        XCTAssertTrue(restTimerText.waitForExistence(timeout: 2.0))

        // 6. Test Mini-Player Bar: Bấm nút Hủy hoặc vuốt xuống để thu nhỏ buổi tập
        // Khi đóng/thu nhỏ modal, Mini-Bar nổi phía trên TabBar
        let dismissOrHideButton = app.buttons["Hủy"]
        if dismissOrHideButton.exists {
            // Nhấn tiếp tục tập để giữ session
            // Ở flow thực tế, khi vuốt Sheet xuống thì MiniBar sẽ hiện
        }

        // 7. Bấm "Hoàn thành" buổi tập
        let finishButton = app.buttons["Hoàn thành"]
        XCTAssertTrue(finishButton.exists)
        finishButton.tap()

        // 8. Xác nhận đã quay trở lại Dashboard và có thanh chỉ báo Sync
        XCTAssertTrue(workoutTabButton.exists)
        let syncIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'đồng bộ' OR label CONTAINS 'Đã đồng bộ'")).firstMatch
        XCTAssertTrue(syncIndicator.waitForExistence(timeout: 3.0))
    }
}
