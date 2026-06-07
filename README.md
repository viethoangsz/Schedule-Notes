# 📱 Schedule Notes

Ứng dụng ghi chú và quản lý lịch trình cá nhân hoạt động hoàn toàn **offline**.

## ✨ Tính năng

- 📝 **Ghi chú**: Tạo, chỉnh sửa, xóa, ghim và tìm kiếm ghi chú
- 📅 **Lịch trình**: Quản lý công việc theo ngày với mức độ ưu tiên
- 🔔 **Thông báo**: Nhắc nhở đúng giờ khi có lịch hẹn
- 🌙 **Dark Mode**: Tự động theo theme hệ thống
- 💾 **Offline**: Mọi dữ liệu lưu cục bộ bằng SQLite

## 🏗️ Công nghệ

| Thư viện | Vai trò |
|----------|---------|
| `sqflite` | Lưu trữ dữ liệu SQLite cục bộ |
| `provider` | Quản lý state |
| `flutter_local_notifications` | Thông báo cục bộ |
| `timezone` | Xử lý múi giờ cho notification |
| `intl` | Định dạng ngày tháng |
| Material Design 3 | Giao diện người dùng |

## 📁 Cấu trúc thư mục

```
lib/
├── main.dart                          # Entry point, khởi tạo app
├── models/
│   ├── note.dart                      # Model ghi chú
│   └── task.dart                      # Model công việc
├── database/
│   └── database_helper.dart           # Quản lý SQLite
├── services/
│   ├── note_service.dart              # CRUD ghi chú
│   ├── task_service.dart              # CRUD công việc
│   └── notification_service.dart     # Local notifications
├── providers/
│   ├── note_provider.dart             # State management ghi chú
│   └── task_provider.dart             # State management công việc
├── screens/
│   ├── main_navigation.dart           # Bottom Navigation
│   ├── home/
│   │   └── home_screen.dart           # Trang chủ
│   ├── notes/
│   │   ├── notes_screen.dart          # Danh sách ghi chú
│   │   └── note_editor_screen.dart    # Tạo/sửa ghi chú
│   ├── tasks/
│   │   ├── tasks_screen.dart          # Danh sách lịch trình
│   │   └── task_form_screen.dart      # Tạo/sửa công việc
│   └── settings/
│       └── settings_screen.dart       # Cài đặt
├── widgets/
│   ├── note_card.dart                 # Card ghi chú
│   ├── task_card.dart                 # Card công việc
│   └── empty_state.dart              # UI trạng thái trống
└── utils/
    ├── app_theme.dart                 # Material Design 3 theme
    └── date_utils.dart               # Tiện ích ngày tháng
```

## 🚀 Hướng dẫn chạy

### Yêu cầu

- Flutter SDK >= 3.0.0 (chạy `flutter --version` để kiểm tra)
- Android Studio hoặc VS Code
- Thiết bị Android hoặc Emulator

### Cài đặt và chạy

```bash
# 1. Di chuyển vào thư mục project
cd schedule_notes

# 2. Cài đặt dependencies
flutter pub get

# 3. Kiểm tra thiết bị kết nối
flutter devices

# 4. Chạy ứng dụng (debug mode)
flutter run

# 5. Chạy với hot reload tự động
flutter run --hot
```

### Build APK

```bash
# Build APK debug
flutter build apk --debug

# Build APK release (cần signing config)
flutter build apk --release

# APK sẽ nằm tại:
# build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (cho Google Play)

```bash
flutter build appbundle --release
```

## ⚙️ Cấu hình Signing cho Release APK

1. Tạo keystore:
```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

2. Tạo file `android/key.properties`:
```properties
storePassword=<your_store_password>
keyPassword=<your_key_password>
keyAlias=key
storeFile=<path_to_key.jks>
```

3. Cập nhật `android/app/build.gradle` để dùng signing config.

## 📱 Quyền cần thiết (Android)

| Quyền | Mục đích |
|-------|---------|
| `POST_NOTIFICATIONS` | Gửi thông báo (Android 13+) |
| `SCHEDULE_EXACT_ALARM` | Đặt lịch thông báo chính xác |
| `RECEIVE_BOOT_COMPLETED` | Khôi phục lịch sau khi reboot |
| `VIBRATE` | Rung khi có thông báo |

## 🐛 Troubleshooting

**Lỗi: "MissingPluginException"**
```bash
flutter clean && flutter pub get && flutter run
```

**Notification không hoạt động trên Android 12+:**
- Vào Settings > Apps > Schedule Notes > Permissions
- Bật quyền "Alarms & Reminders"

**Database lỗi:**
```bash
# Xóa data ứng dụng trên thiết bị và chạy lại
flutter clean
flutter run
```

## 📈 Hướng phát triển

- [ ] Widget màn hình chính (home screen widget)
- [ ] Export/Import dữ liệu (JSON/CSV)
- [ ] Nhắc nhở lặp lại (hàng ngày/tuần)
- [ ] Tags/categories cho ghi chú
- [ ] Tìm kiếm công việc
- [ ] Backup lên Google Drive
- [ ] Giao diện tablet (responsive)
