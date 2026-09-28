# FEESMANAGER — PHASE VÀ PROMPT GEMINI SỬA UI/UX ANDROID

Đối chiếu nguồn: `letrieubavuong/feesmanager`, `main` tại `ea103f8a51a2d924aca269d5a8208955af0f4064` ngày 28/09/2026. Trước mỗi phase lấy HEAD mới nhất; đường dẫn và tên widget là điểm neo, không reset về SHA cũ. Đây là công việc **chỉ trên Android UI**. Không gộp với sáu phase sửa nghiệp vụ.

## Lệnh chung — dán ở đầu MỖI prompt

> Đọc `AGENTS.md`, `docs/TUITION2027_DOMAIN_CONSTITUTION.md`, `docs/DATABASE_SCHEMA.md`, `docs/ARCHITECTURE.md`. Chỉ được chỉnh `lib/app/design_system/`, `lib/app/common_widgets/`, `lib/app/navigation/`, `lib/features/*/presentation/`, `lib/l10n/*.arb` và test widget/presentation liên quan. Có thể chỉnh hàm `build`, helper dựng widget và state **trình bày** trong các thư mục này. **CẤM** sửa hoặc thêm hàm nghiệp vụ, controller/use case, domain service, repository, model, SQLite/migration, Firebase, tính tiền, roster, điểm danh, trạng thái invoice/payment, schema, generated `.g.dart`, Android native, web và Windows. Không đổi chữ ký API hoặc dữ liệu truyền sang các lớp trên. Nếu một yêu cầu chỉ làm được bằng sửa nghiệp vụ, dừng đúng phần đó và báo blocker; không lén sửa domain.
>
> Làm trên branch UI riêng từ HEAD mới nhất; không push thẳng lên `main`, không đè branch Codex sửa nghiệp vụ. Trước khi sửa, chạy Android Emulator và `flutter run` để app đang hiển thị. **Sau mỗi thay đổi có ý nghĩa trong một file/widget, lưu file → bấm Hot Reload ngay → quan sát đúng màn hình vừa sửa → ghi một dòng nhật ký thay đổi/Hot Reload/kết quả.** Không để đến cuối phase mới Hot Reload. Nếu Hot Reload không áp dụng đúng (theme root, localization/codegen hoặc trạng thái khởi tạo), vẫn thực hiện Hot Reload trước, sau đó Hot Restart hoặc full relaunch và nói rõ lý do. Kiểm ở điện thoại nhỏ khoảng 320–360 dp, VI/EN, Light/Dark; xem bàn phím, cuộn, vùng chạm, overflow. Chỉ chạy targeted widget tests trong lúc lặp; chạy `flutter analyze` và test liên quan khi phase ổn. Không tuyên bố PASS nếu chưa thật sự chạy emulator.
>
> Giữ bottom navigation **đúng 4 mục**: Trang chủ, Lớp học, Học sinh, Học phí. Màn nested giữ Back + Global Menu. Form tạo/sửa lớp vẫn là Modal Bottom Sheet, không chuyển thành dialog/trang riêng. Luồng dirty-form không được mất dữ liệu. Dùng `Theme.of(context).colorScheme`, `AppSemanticColors`, `AppLocalizations` thay cho màu/chữ cứng. Giữ widget `UiKeys` dùng cho integration tests, hoặc cập nhật test UI nếu vị trí đổi. Mỗi phase một commit; gửi danh sách file diff, nhật ký Hot Reload, ảnh/trạng thái nhìn thấy trên emulator, targeted test, `flutter analyze`, SHA và giới hạn.

## UI-01 — Hệ màu Light/Dark và palette thật sự hoạt động

**Prompt cho Gemini:**

> Sửa lớp trình bày màu ở `lib/app/design_system/app_theme.dart`. Hiện `AppTheme.createTheme` có nhánh High Contrast, còn các palette khác dùng chung màu xanh; `AppColors` cuối file là hằng màu dark, được nhiều page dùng làm `Scaffold.backgroundColor`, text và surface. Đây là nguyên nhân Light/Emerald/Indigo không thể nhất quán. Lấy `AppPaletteInfo.fromPalette(palette).primaryColor` đã định nghĩa ở `app_palettes.dart` (Physics Blue `#1976D2`, Emerald `#00875A`, Indigo `#3F51B5`, Amber `#FF8F00`, Slate `#455A64`, Ocean Cyan `#00838F`, Burgundy `#880E4F`) làm seed cho `ColorScheme.fromSeed(seedColor: ..., brightness: brightness)` hoặc ánh xạ tương đương đảm bảo contrast; giữ nhánh High Contrast riêng, tên và persistence palette hiện tại. Cung cấp semantic colors cho cả Light/Dark. Trong các page ưu tiên `dashboard_page.dart`, `class_list_page.dart`, `class_detail_page.dart`, `student_list_page.dart`, `student_detail_page.dart`, `attendance_page.dart`, `global_tuition_page.dart`, `class_tuition_tab.dart`, `record_payment_bottom_sheet.dart`, thay **chỉ tham chiếu màu UI** `AppColors.background/surface/textPrimary/textSecondary/border/primary` bằng `Theme.of(context).colorScheme` hoặc semantic extension theo vai trò. Không thay model, provider nghiệp vụ hoặc thứ tự dữ liệu.
>
> Làm từng widget/page, Hot Reload ngay và nhìn lại màn hình. Bắt đầu với Dashboard → Classes → Student Detail → Attendance → Tuition → Payment Sheet. Kiểm Physics Blue Light/Dark, Emerald Light/Dark, High Contrast; kiểm chữ và ô nhập không trùng màu nền. Không thay toàn bộ repo bằng một regex vì role màu khác nhau. Giữ các màu trạng thái success/warning/error theo semantic role. Nếu root theme đổi cần Hot Restart để thấy palette mới, ghi sau bước Hot Reload. Test widget theme VI/EN và viewport 320 dp; không sửa business tests. Commit `fix(ui): honor palette and brightness across android screens`.

**Nghiệm thu:** đổi palette và Light/Dark làm nền, card, chữ, icon, bottom nav, dialog, sheet thay cùng nhau; không có dark text trên dark card hoặc white text trên light card.

## UI-02 — Điều hướng màn Chi tiết lớp dễ dùng trên điện thoại

**Prompt cho Gemini:**

> Chỉ chỉnh `lib/features/classes/presentation/class_detail_page.dart` và widget menu UI trong `lib/app/navigation/` nếu cần. AppBar hiện có Back + Global Menu + 4 IconButton (sửa, mức học phí, đơn nghỉ, lưu trữ), đoạn khoảng dòng 69–130. `DefaultTabController(length: 7)` và TabBar có 7 tab cuộn ngang ở khoảng dòng 178–207. Giữ Back và Global Menu, giữ chính xác 7 nội dung/tab và route hiện có. Trên màn hẹp: AppBar chỉ giữ hành động **Sửa lớp** thường dùng và một menu overflow có nhãn văn bản cho “Mức học phí”, “Đơn nghỉ học”, “Ngừng hoạt động/Kích hoạt lại”; không xóa quyền truy cập hành động nào. TabBar vẫn cuộn ngang nhưng thêm dấu hiệu tab tiếp theo (ví dụ tab mép phải lộ một phần hoặc nhãn hướng dẫn một lần); nhãn gọn, nghĩa không đổi. Không đưa thêm mục xuống bottom nav.
>
> Sau khi sửa AppBar Hot Reload ngay trên Class Detail 320–360 dp: Back, Global Menu, Sửa, overflow đều bấm được; chọn thao tác từ overflow mở đúng sheet/page và archive vẫn đòi xác nhận hiện có. Sau thay đổi TabBar Hot Reload ngay; vuốt/bấm tab thứ 7 và quay lại tab đầu, không mất state quan trọng. Kiểm text scale 1.5, VI/EN, Light/Dark, class archived. Chỉ sửa callback UI để chuyển chỗ nút, không sửa `_handleArchiveToggle`, controller/domain hoặc business guard. Targeted widget tests cho tất cả action. Commit `fix(ui): simplify class detail actions and tab discovery`.

**Nghiệm thu:** không overflow AppBar; tất cả 7 tab và 4 hành động vẫn truy cập được; thao tác phổ biến thấy ngay.

## UI-03 — Trang chủ ưu tiên việc phải làm hôm nay

**Prompt cho Gemini:**

> Chỉ chỉnh `lib/features/dashboard/presentation/dashboard_page.dart` và widget hiển thị phụ thuộc. `build` hiện sắp: greeting → 4 KPI → quick actions → lịch hôm nay → warnings → recent activities (khoảng dòng 58–115). Dùng **cùng `DashboardOverview` đang có**, không đổi `DashboardService`, không đổi số KPI, công thức hoặc task enabled. Bố trí lại: đầu trang là card “Buổi tiếp theo/đang diễn ra” hoặc trạng thái rỗng từ `overview.todaySessions` hiện có, kèm CTA tới điểm danh khi chính dữ liệu hiện có cho phép; sau đó “Cần xử lý” (pending attendance/unfinalized tuition/warnings) theo các `DashboardTask` hiện có; tiếp là timeline hôm nay; cuối mới đến KPI tổng và recent activities. Đừng tự xác định trạng thái buổi bằng một thuật toán mới ở UI; chỉ dùng status/thời gian/read model đã có. Nếu dữ liệu không đủ để chọn buổi tiếp theo an toàn, chỉ đưa danh sách hôm nay lên đầu, không bịa CTA.
>
> Giảm trùng lặp giữa KPI “buổi cần điểm danh”, task “điểm danh ngay” và warning bằng cách cho một card dẫn hành động, còn KPI chỉ là số liệu. Giữ các hành động Sinh buổi, Chốt học phí, Xuất PDF như hiện có. Sau mỗi lần đổi thứ tự card/CTA Hot Reload ngay, kiểm lần lượt dữ liệu rỗng, một buổi, nhiều buổi, có cảnh báo; nhìn first viewport 360 dp xem thầy biết “bấm gì tiếp” không cần cuộn. Kiểm VI/EN, Light/Dark, text scale. Widget tests về vị trí tương đối và callback; không sửa dashboard service. Commit `fix(ui): prioritize today's teaching actions on dashboard`.

**Nghiệm thu:** first viewport nêu rõ buổi hoặc việc cấp bách; KPI vẫn có nhưng không đẩy hành động chính xuống sâu.

## UI-04 — Form tạo lớp và thu tiền: lỗi tại trường, sheet an toàn

**Prompt cho Gemini:**

> A. `lib/features/classes/presentation/class_form_bottom_sheet.dart`: ô `siSoToiDa` khoảng dòng 160–169 chưa validator; `_save` khoảng dòng 249–252 dùng `int.tryParse` khiến nhập `abc` thành `null`. Chỉ thêm validator UI: rỗng cho phép `null` như cũ; không rỗng thì chỉ chấp nhận số nguyên dương theo giới hạn hiện có của model/DB (nếu không có giới hạn, `>0`); hiển thị lỗi ngay dưới ô và giữ nguyên ký tự nhập. `_formKey.validate` đã ở đầu `_save`, nên không đổi `ClassService.saveClass` hoặc schema. Sau sửa Hot Reload ngay, thử rỗng, `abc`, `0`, số hợp lệ và đóng/mở bàn phím trên 320 dp.
>
> B. Cũng ở `_save` khoảng dòng 266–287: sau `Navigator.of(context).pop(true)`, mã mở sheet học phí bằng `context` của sheet vừa đóng. Chuyển quyết định mở sheet tiếp sang **caller còn mounted** (`ClassListPage` và nơi gọi form tạo lớp). `ClassFormBottomSheet` chỉ trả kết quả UI có `savedClassId` nếu tạo mới; callback/caller nhận kết quả rồi từ context màn cha hiển thị Snackbar và **lời mời** “Thiết lập học phí” rõ ràng, cho phép chọn tiếp tục hoặc làm sau. Không tạo class lần hai, không tự tạo policy, không làm thay đổi business rule bắt buộc policy. Form sửa lớp lưu xong chỉ đóng sheet và cập nhật chi tiết. Vì kết quả `bool?` đang được vài nơi dùng, rà tất cả caller UI và đổi kiểu trả kết quả chỉ trong presentation; giữ hành vi dirty form và `UiKeys`. Hot Reload sau thay đổi sheet, rồi sau từng caller; nếu navigation stack cần Hot Restart thì ghi lý do.
>
> C. `lib/features/payments/presentation/record_payment_bottom_sheet.dart`: giữ SafeArea, keyboard inset, anti-double-submit, lý do sửa và lỗi lưu. Chỉ cải thiện nhãn/summary: hiển thị học sinh/lớp/tháng/số còn nợ nếu caller đã cung cấp; nếu không có dữ liệu, đừng query domain mới. Ô số tiền có bàn phím số, lỗi validation tại ô và số `0` không được trông như giá trị hợp lệ. Không thay `PaymentService`, `PaymentController` hay tính tiền. Hot Reload ngay và kiểm keyboard + nút Lưu trên 320 dp. Commit `fix(ui): clarify class creation and payment form feedback`.

**Nghiệm thu:** nhập sai sĩ số không bị lưu thành rỗng; tạo lớp thành công không phụ thuộc `BuildContext` đã đóng; sheet không mất dữ liệu khi bàn phím mở hoặc lỗi lưu.

## UI-05 — Tìm kiếm và trang Học phí không nhấp nháy / chọn lớp cũ

**Prompt cho Gemini:**

> `student_list_page.dart` gọi `StudentListController.search` ở mỗi `onChanged` khoảng dòng 98–102; controller invalidate và query SQLite mỗi ký tự. **Không sửa controller**. Thêm `Timer` debounce 250–350 ms ngay ở State của page, hủy timer trong `dispose`, bấm X gọi search rỗng ngay, submit bàn phím gọi ngay; đồng bộ `suffixIcon` với `setState` để X hiện/ẩn đúng. Chỉ trình bày/tần suất gọi API, không đổi query hay kết quả. Hot Reload sau mỗi thay đổi; thử gõ nhanh tiếng Việt có dấu, xóa, đổi tab rồi quay lại, bàn phím mở. Widget test fake controller bảo đảm một truy vấn sau chuỗi gõ nhanh và truy vấn ngay khi clear.
>
> `global_tuition_page.dart` khoảng dòng 56–100 dùng `_selectedClassId ??= classes.first.id`, nhưng không sửa nếu lớp chọn đã biến mất sau archive/filter. Trong `build`, tạo tập ID của `classes`; nếu selection hiện tại không thuộc tập thì dùng `classes.first.id` cho `DropdownButton.value` và chỉ cập nhật `_selectedClassId` theo cách UI an toàn, không `setState` đồng bộ giữa build. Với danh sách rỗng cho empty state hiện có. Hot Reload ngay; thử chọn lớp B, lớp B không còn trong danh sách sau refresh, không assertion và có lớp hợp lệ được chọn. Không đổi `classListControllerProvider` hoặc invoice. Commit `fix(ui): stabilize student search and tuition class selection`.

**Nghiệm thu:** ô tìm kiếm không reload liên tục từng ký tự; dropdown không giữ ID không còn trong items.

## UI-06 — VI/EN, màn hình nhỏ và Android nghiệm thu cuối

**Prompt cho Gemini:**

> Rà các file presentation đã chỉnh trong UI-01..05 và các nút chính của `attendance_page.dart`, `class_tuition_tab.dart`, `record_payment_bottom_sheet.dart`, `class_detail_page.dart`, `dashboard_page.dart`. Thay các chuỗi hiển thị hard-code như “Làm mới”, “Lịch sử chỉnh sửa”, “Số tiền thanh toán (đ)”, “Chưa điểm danh hết”, lỗi/success Snackbar bằng key VI/EN ở đúng hai file `lib/l10n/app_vi.arb` và `lib/l10n/app_en.arb`. Không dịch mã trạng thái DB, tên lớp/học sinh do người dùng nhập hoặc nội dung dữ liệu lịch sử. Chạy `flutter gen-l10n` nếu cần; không sửa file generated thủ công. Hot Reload **ngay sau mỗi nhóm màn hình**, rồi Hot Restart nếu l10n mới chưa được nạp.
>
> Trên Android Emulator kiểm ma trận: màn 320 dp và 360 dp; font scale 1.0/1.5; VI/EN; Light/Dark và Emerald; bàn phím ở form lớp và thu tiền; 7 tab chi tiết lớp; Home có và không có buổi; danh sách 0/20/50 học sinh; Học phí với lớp trống và lớp nhiều học sinh. Không chỉ xem `flutter test`: chụp màn hình từng trạng thái để người duyệt thấy chữ, màu, vùng chạm và overflow. Chạy targeted widget tests, `flutter analyze`, `flutter test`, `flutter build apk --debug`, Android integration trên Ubuntu/KVM exact-SHA. Báo số test PASS/FAIL thực tế; nếu CI đỏ từ sửa UI đồng thời thì sửa xung đột UI trong scope, không chỉnh domain. Commit `fix(ui): complete localization and android visual acceptance`.

**Nghiệm thu:** không tràn, không chữ chìm, không form bị bàn phím che; VI/EN nhất quán ở luồng chính; có ảnh Android Emulator và Hot Reload log.

## Những vấn đề KHÔNG thuộc các phase UI này

- Sai số dashboard do membership lặp: sửa ở phase nghiệp vụ P5 của tài liệu `FEESMANAGER_DOMAIN_FIX_PHASES.md`, không sửa bằng phép đếm trong widget.
- Chốt invoice khi thiếu buổi, roster nhiều thứ, correction/credit: thuộc phase nghiệp vụ P1–P4, không chỉnh trong UI.
- Tốc độ `ReportService`/`SessionCreditService` do N+1: thuộc nghiệp vụ P6; UI chỉ xử lý trạng thái loading/error, không viết lại SQL.
- Kết luận màu sắc/overflow chỉ được chốt sau khi kiểm trực tiếp Android Emulator; ảnh mockup hoặc đọc code không thay thế nghiệm thu.

## Checklist báo cáo từng phase

1. Branch, base SHA, commit SHA, danh sách file thay đổi; xác nhận không có file domain/data/controller/SQLite đổi.
2. Các lần Hot Reload sau từng widget, màn hình nhìn thấy và kết quả; các lần Hot Restart/full relaunch kèm lý do.
3. Test target thực chạy và trạng thái `flutter analyze`; không dùng báo cáo cũ.
4. Ảnh Android 320/360 dp, VI/EN, Light/Dark cho phần đã sửa.
5. Lỗi nền từ HEAD trước phase và lỗi mới tách riêng; exact-SHA Actions nếu đã push branch/PR.
