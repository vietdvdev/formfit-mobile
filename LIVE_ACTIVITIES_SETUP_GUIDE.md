# HƯỚNG DẪN CẤU HÌNH LIVE ACTIVITIES & DYNAMIC ISLAND TRONG XCODE

Tài liệu này hướng dẫn các bước thiết lập Project Settings, `Info.plist`, và tạo Widget Extension Target (`FormFitWidgets`) cho tính năng **Rest Timer Live Activity**.

---

## 1. CẤU HÌNH INFO.PLIST CỦA MAIN APP TARGET (`FormFit`)

Mở file `Info.plist` (hoặc vào mục **Target FormFit $\rightarrow$ Info $\rightarrow$ Custom iOS Target Properties**) và thêm 2 keys bắt buộc sau:

| Key | Type | Value | Mục đích |
|---|---|---|---|
| `NSSupportsLiveActivities` | Boolean | `YES` | Kích hoạt hỗ trợ Live Activities cho ứng dụng trên iOS 16.1+ |
| `NSSupportsLiveActivitiesFrequentUpdates` | Boolean | `YES` | Cho phép cập nhật thường xuyên trên Dynamic Island mà không bị giới hạn budget |

Dạng mã nguồn XML trong `Info.plist`:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

---

## 2. TẠO TARGET WIDGET EXTENSION (`FormFitWidgets`) TRONG XCODE

Live Activities và Dynamic Island cần được đóng gói trong một **Widget Extension Target** riêng biệt:

1. Trong Xcode, trên thanh Menu chọn: **File $\rightarrow$ New $\rightarrow$ Target...**
2. Chọn template: **Widget Extension** $\rightarrow$ Bấm **Next**.
3. Điền thông tin cấu hình:
   - **Product Name**: `FormFitWidgets`
   - **Include Live Activity**: ☑️ **Tích chọn ô này** (Xcode sẽ tự động sinh file template Live Activity).
   - **Include Configuration Intent**: Bỏ chọn (chúng ta dùng `ActivityAttributes` và `AppIntents` hiện đại).
4. Bấm **Finish** $\rightarrow$ Khi hộp thoại hỏi *"Activate 'FormFitWidgets' scheme?"*, chọn **Activate**.

---

## 3. THIẾT LẬP TARGET MEMBERSHIP CHIA SẺ FILE

Các file sau đây cần được chia sẻ giữa cả 2 Target (**`FormFit`** và **`FormFitWidgets`**) để cả App chính và Widget Extension cùng nhận diện được Data Model và App Intents:

1. Chọn file **`RestTimerActivityAttributes.swift`** trong Xcode Navigator:
   - Ở cột bên phải (File Inspector $\rightarrow$ Target Membership):
   - ☑️ Tích chọn cả **FormFit** và **FormFitWidgets**.
2. Chọn file **`RestTimerIntents.swift`**:
   - Ở cột Target Membership:
   - ☑️ Tích chọn cả **FormFit** và **FormFitWidgets**.
3. Chọn file **`RestTimerLiveActivity.swift`**:
   - Chỉ cần thuộc về target: ☑️ **FormFitWidgets**.

---

## 4. KHỞI TẠO WIDGET BUNDLE TRONG `FormFitWidgetsBundle.swift`

Trong thư mục của target `FormFitWidgets`, đảm bảo file `FormFitWidgetsBundle.swift` khai báo như sau:

```swift
import WidgetKit
import SwiftUI

@main
struct FormFitWidgetsBundle: WidgetBundle {
    var body: some Widget {
        // Đăng ký Live Activity Widget của FormFit
        RestTimerLiveActivity()
    }
}
```

---

## 5. KIỂM THỬ TRÊN SIMULATOR HOẶC THIẾT BỊ THẬT
- **Trên thiết bị iPhone 14/15/16 Pro (có Dynamic Island)**:
  - Khi hoàn thành 1 set trong `ActiveWorkoutView`, Dynamic Island sẽ tự động nở ra hiển thị icon tạ màu cyan và số giây đếm ngược.
  - Chạm giữ (Long press) vào Dynamic Island để mở giao diện Expanded: Xem thông tin hiệp kế tiếp (`Next: Set 2 • 80kg x 10 reps`), xem thanh progress và bấm nút **+30s** hoặc **Skip Rest**.
- **Trên Màn hình khóa (Lock Screen)**:
  - Khóa màn hình hoặc kéo thanh thông báo xuống: Xuất hiện thẻ Live Activity nền tối cao cấp với thanh tiến trình đếm ngược liên tục.
