# FormFit Mobile

Ứng dụng theo dõi luyện tập thể hình thế hệ mới trên nền tảng **iOS (Swift Native & SwiftUI)** với mô hình **Offline-First**, trực quan hóa giải phẫu **3D RealityKit/SceneKit**, đồng bộ chỉ số **HealthKit / ActivityKit** và kết nối Huấn luyện viên trực tuyến (**PT Marketplace**).

---

## 📌 Tài liệu & Lộ trình
- 📋 Xem đặc tả chi tiết và kế hoạch triển khai: [ROADMAP.md](ROADMAP.md)

---

## 🛠️ Công Nghệ Chủ Đạo

### Mobile (iOS)
- **Framework & Ngôn ngữ:** Swift, SwiftUI (iOS 17+)
- **Kiến trúc:** MVVM + Clean Architecture / Repository Pattern
- **Lưu trữ Cục bộ:** SwiftData / CoreData (Offline-First)
- **Đồ họa 3D:** RealityKit / SceneKit (`.usdz`, `.glb` Draco)
- **Tích hợp iOS:** ActivityKit (Live Activities & Dynamic Island), HealthKit, StoreKit 2

### Backend & Cloud
- **Framework:** Laravel RESTful API
- **Cơ sở dữ liệu:** PostgreSQL / MySQL, Redis
- **Realtime & Queue:** WebSocket (Laravel Reverb / Socket.io)
- **Lưu trữ & CDN:** Cloudflare R2 / AWS S3

---

## 🚀 Các Giai Đoạn Triển Khai Chính
1. **Phase 1:** Nền tảng kiến trúc, Data Models & UI Design System
2. **Phase 2:** Core Workout (Offline-First) & Trình mô phỏng 3D Anatomy
3. **Phase 3:** Trải nghiệm iOS nâng cao (Live Activities, HealthKit, Dinh dưỡng, Before/After)
4. **Phase 4:** Backend API Laravel, Sync Engine, PT Marketplace & StoreKit 2
