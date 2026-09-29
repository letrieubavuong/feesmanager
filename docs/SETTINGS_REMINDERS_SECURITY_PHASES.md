# Hoàn thiện Cài đặt: nhắc giờ dạy và khóa ứng dụng

PR giao diện/danh mục trường: #4, nhánh `settings/compact-center-schools-20260928`.
Hai phase dưới đây phải thực hiện trên máy có Flutter SDK và Android Emulator.
Đọc `AGENTS.md`, domain constitution, schema, migration rules, architecture trước khi sửa.
Không đưa nút cài đặt vào UI khi cơ chế thực thi chưa hoạt động.

## Phase 1 — Nhắc giờ dạy trước 5 hoặc 10 phút

**Nguồn dữ liệu:** `lich_hoc` là quy tắc định kỳ; `buoi_hoc` là buổi
thực tế/dự kiến. Dùng `ScheduleDomainService` để lấy lịch có hiệu lực,
`SessionRepository.getByDateRange` để lấy buổi đã tạo, loại lớp lưu trữ
và buổi `HUY`/`NGHI_LE`. Buổi thực tế đã sửa giờ hoặc đổi lịch phải
ưu tiên hơn lịch định kỳ; không tạo buổi học mới chỉ để nhắc.

**Các hàm cần xây dựng:**
- `TeachingReminderSettingsController.load/save`: tắt, trước 5 phút,
  trước 10 phút; lưu trạng thái bền vững.
- `TeachingReminderPlanner.buildUpcoming(now, horizon)`: lập danh sách
  lần dạy trong 30 ngày tiếp theo, hợp nhất lịch định kỳ và buổi thực tế,
  tính thời điểm nhắc theo múi giờ thiết bị; bỏ thời điểm đã qua.
- `TeachingReminderScheduler.sync(reminders)`: dùng ID ổn định theo
  lớp/buổi/ngày/giờ, hủy thông báo cũ và cập nhật thông báo mới, tránh
  trùng khi mở app nhiều lần.
- Gọi `sync` sau khi thêm/sửa/đóng lịch, tạo/sửa/hủy buổi học, đổi
  cài đặt nhắc, khởi động app, đổi múi giờ và sau khi cấp lại quyền.
- UI Cài đặt: nhãn **Nhắc giờ dạy** và segmented control
  `Tắt | Trước 5 phút | Trước 10 phút`, hiển thị rõ khi quyền thông báo
  chưa được cấp; không báo “Đã bật” nếu hệ điều hành chặn.

**Triển khai Android:** đọc tài liệu chính thức của
`flutter_local_notifications` tại
https://pub.dev/packages/flutter_local_notifications;
dùng `zonedSchedule`, timezone local và `androidScheduleMode` phù hợp;
xử lý quyền thông báo Android 13+, quyền lịch chính xác Android 12+/14,
reschedule sau reboot theo hướng dẫn plugin. Kiểm tra Android 12, 13,
14+, khi đổi giờ buổi học, hủy buổi, tắt nhắc và khởi động lại thiết bị.
Không xin quyền khi người dùng chưa bật nhắc.

**Kiểm tra:** test planner cho lịch thứ/giờ, buổi hủy, giờ thay đổi,
trùng quy tắc với buổi thực tế và ngày qua tháng; test đồng bộ số thông
báo không tăng sau hai lần chạy; trên emulator xác nhận thông báo đến
đúng 5/10 phút trước buổi học.

## Phase 2 — Mở khóa bằng PIN hoặc vân tay

**Thiết kế bảo mật:** plugin `local_auth`
(https://pub.dev/packages/local_auth) xác thực sinh trắc học thiết bị;
`flutter_secure_storage`
(https://pub.dev/packages/flutter_secure_storage) lưu salt và
verifier của PIN, tuyệt đối không lưu PIN thô trong SQLite,
SharedPreferences, log hoặc bản sao lưu văn bản. Dùng KDF có salt để
xác minh PIN, so sánh kết quả theo thời gian hằng, giới hạn số lần sai
và lưu thời hạn khóa. Thiết bị không hỗ trợ sinh trắc học vẫn mở được bằng
PIN. Không bật khóa nếu chưa xác nhận PIN hai lần.

**Các hàm cần xây dựng:**
- `AppLockRepository.setPin/verifyPin/removePin`: tạo, so sánh và xóa
  verifier; xử lý lỗi secure storage; kiểm tra PIN 4–6 chữ số.
- `AppLockController.enablePin/enableBiometrics/unlock/lock`: lưu lựa
  chọn, xác nhận sinh trắc học khả dụng trước khi bật; luôn giữ PIN dự
  phòng nếu người dùng bật vân tay.
- `AppLockGate`: chặn `AppShell` từ lúc app khởi chạy khi đã bật khóa,
  không dựng dữ liệu nhạy cảm phía sau màn hình khóa; khóa lại khi app
  về background theo thời gian chờ đã chọn. Không tự khóa khi mở prompt
  vân tay.
- UI Cài đặt: `Khóa bằng PIN`, `Dùng vân tay` (chỉ hiện khi khả dụng),
  đổi PIN và tắt khóa với bước xác thực hiện tại.

**Android:** theo README `local_auth_android`, dùng
`FlutterFragmentActivity`, quyền `USE_BIOMETRIC`, theme hỗ trợ
`Theme.AppCompat` cho phiên bản cần thiết. Không tuyên bố vân tay hoạt
động trên Web nếu plugin không hỗ trợ. Trên Windows sử dụng khả năng
xác thực hệ điều hành nếu phù hợp; PIN ứng dụng phải hoạt động cả
Android, Windows và Web với lưu trữ an toàn tương ứng, nếu Web không
có cơ chế phù hợp thì không bật tùy chọn khóa trên Web.

**Kiểm tra:** khởi động lạnh đã bật PIN, sai PIN liên tiếp, đúng PIN,
đóng/mở app, đổi PIN, sinh trắc học thành công/thất bại/hủy, thiết bị
không đăng ký vân tay, mất quyền hoặc đổi dữ liệu sinh trắc học. Chạy
emulator và Hot Restart/full relaunch cho thay đổi native.

## Cổng chất lượng chung

Chạy `dart format .`, `flutter analyze`, test mục tiêu, `flutter test`,
build APK. Trên emulator, Hot Reload sau thay đổi UI; cấu hình plugin,
manifest và màn hình khóa lúc khởi động cần Hot Restart/full relaunch.
Không merge PR cho đến khi xác thực cả luồng bật/tắt và mở lại ứng dụng.
