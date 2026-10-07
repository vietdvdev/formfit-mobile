# HƯỚNG DẪN KIỂM THỬ GÓI THUÊ BAO FORMFIT PRO TRÊN XCODE SIMULATOR (STOREKIT 2)

Tài liệu này hướng dẫn cách cấu hình và thực hiện kiểm thử toàn bộ luồng mua gói thuê bao định kỳ (Auto-Renewable Subscription) cục bộ trên máy tính thông qua **StoreKit Configuration File (`Products.storekit`)** mà **không cần tạo App Store Connect** hay kết nối tài khoản Sandbox.

---

## PHẦN 1: THIẾT LẬP STOREKIT CONFIGURATION TRONG XCODE

File cấu hình đã được tạo sẵn tại đường dẫn:  
📂 `FormFit/Core/StoreKit/Products.storekit`

### 1. Chi tiết sản phẩm trong nhóm `FormFitProGroup`:
* **Gói Tháng (Monthly)**:
  - **Product ID**: `com.formfit.subscription.monthly`
  - **Reference Name**: FormFit Pro Monthly
  - **Price**: `$9.99` / tháng
  - **Subscription Period**: `1 Month`
  - **Introductory Offer**: `7-day Free Trial` (Miễn phí 1 tuần đầu)
* **Gói Năm (Annual)**:
  - **Product ID**: `com.formfit.subscription.annual`
  - **Reference Name**: FormFit Pro Annual
  - **Price**: `$79.99` / năm (Tiết kiệm ~33%)
  - **Subscription Period**: `1 Year`

### 2. Kích hoạt File cấu hình vào Run Scheme trong Xcode:
1. Mở Xcode, chọn target **FormFit**.
2. Trên thanh menu Xcode: Chọn **Product** $\rightarrow$ **Scheme** $\rightarrow$ **Edit Scheme...** (hoặc bấm `Cmd + <`).
3. Chọn mục **Run (Debug)** ở thanh bên trái $\rightarrow$ Chuyển sang tab **Options**.
4. Tìm dòng **StoreKit Configuration**:
   - Nhấp vào menu xổ xuống (mặc định là *None*).
   - Chọn file **`Products.storekit`**.
5. Bấm **Close** và tiến hành chạy app trên Simulator (`Cmd + R`).

---

## PHẦN 2: CÁC KỊCH BẢN KIỂM THỬ THỰC TẾ TRÊN SIMULATOR

Khi app đang chạy trên Simulator, mở menu Xcode: **Debug $\rightarrow$ StoreKit $\rightarrow$ Manage Transactions...** để mở cửa sổ **StoreKit Transaction Manager**.

### 🧪 Kịch bản 1: Mua thành công Gói Tháng có Dùng thử 7 ngày (Free Trial)
1. Mở màn hình Paywall trong app FormFit (bấm vào vương miện Pro ở Tab Hồ Sơ).
2. Chọn gói **FormFit Pro Gói Tháng** $\rightarrow$ Nút CTA đổi thành *"Bắt Đầu Dùng Thử 7 Ngày Miễn Phí"*.
3. Bấm vào nút CTA $\rightarrow$ Xuất hiện hộp thoại thanh toán StoreKit của hệ thống Simulator với nội dung *"Subscribe to FormFit Pro Monthly for Free for 1 week"*.
4. Bấm **Subscribe** $\rightarrow$ Nhập mật khẩu giả lập (nếu có yêu cầu).
5. **Kiểm tra kết quả**:
   - `SubscriptionManager.isProUser` đổi thành `true`.
   - Indicator trạng thái trên Paywall chuyển sang icon tích xanh `checkmark.seal.fill` với nhãn *"Tài Khoản FormFit Pro"*.
   - Mở cửa sổ *StoreKit Transaction Manager* trong Xcode: Thấy 1 transaction mới với trạng thái **Subscribed** kèm tag **Introductory Offer**.

---

### 🧪 Kịch bản 2: Tua nhanh thời gian (Time Rate Acceleration) để kiểm tra Tự động Gia hạn & Hết hạn
1. Trong Xcode, mở: **Debug $\rightarrow$ StoreKit $\rightarrow$ Time Rate**.
2. Chọn tốc độ tua nhanh:
   - **1 Second = 1 Day**: 1 ngày trôi qua trong 1 giây (1 tuần dùng thử sẽ hết trong 7 giây).
   - **1 Second = 1 Hour**: Hoặc tốc độ tùy chọn để quan sát.
3. **Kiểm tra kết quả**:
   - Sau 7 giây (tương đương 7 ngày Free Trial): Xcode tự động tạo tiếp một transaction gia hạn mới trừ tiền `$9.99`.
   - Vòng lặp `Transaction.updates` trong hàm `listenForTransactions()` của `SubscriptionManager` ngay lập tức bắt được sự kiện gia hạn và tự động gọi `transaction.finish()`.
   - Người dùng vẫn giữ nguyên quyền `isProUser == true`.

---

### 🧪 Kịch bản 3: Giả lập Hoàn tiền (Refund Transaction) & Thu hồi quyền Pro
1. Trong cửa sổ **StoreKit Transaction Manager** trên Xcode:
   - Chuột phải vào giao dịch vừa mua thành công $\rightarrow$ Chọn **Refund Transaction**.
2. Quay lại Simulator:
   - `Transaction.updates` lập tức nhận được bản ghi bị thu hồi (`revocationDate != nil`).
   - Hàm `updateSubscriptionStatus()` tự động loại bỏ gói khỏi danh sách sở hữu.
3. **Kiểm tra kết quả**:
   - Thuộc tính `SubscriptionManager.isProUser` tự động chuyển về `false`.
   - Các tính năng Pro trong app tự động khóa lại ngay tức thì mà không cần tắt app mở lại.

---

### 🧪 Kịch bản 4: Giả lập Lỗi thẻ thanh toán (Billing Retry / Failed Purchase)
1. Trong Xcode, mở file `Products.storekit`.
2. Bấm vào icon Cài đặt (bánh răng) ở thanh menu của file `Products.storekit` $\rightarrow$ Tích chọn mục **Billing Retry**.
3. Thực hiện mua lại gói trên Simulator:
   - Hệ thống giả lập giao dịch rơi vào trạng thái nợ thẻ / thất bại thanh toán.
   - Hàm `purchase(_:)` không cấp quyền Pro và báo lỗi phù hợp.

---

### 🧪 Kịch bản 5: Kiểm tra Khôi phục giao dịch (Restore Purchases)
1. Xóa app FormFit khỏi Simulator để làm mới bộ nhớ tạm cục bộ.
2. Cài lại app và vào Paywall. Lúc này trạng thái là Free (`isProUser == false`).
3. Bấm nút **"Khôi phục" (Restore Purchases)** ở góc trên bên phải Paywall.
4. Hệ thống gọi `AppStore.sync()` và đọc lại các transaction đã lưu trong file `Products.storekit`.
5. **Kiểm tra kết quả**: Xuất hiện thông báo *"Kích hoạt thành công!"* và `isProUser` chuyển lại thành `true`.
