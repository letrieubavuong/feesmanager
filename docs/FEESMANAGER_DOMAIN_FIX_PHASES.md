# FEESMANAGER — PHASE SỬA NGHIỆP VỤ, TRUY VẤN VÀ KIỂM THỬ

Nguồn kiểm toán: `letrieubavuong/feesmanager`, `main` tại `ea103f8a51a2d924aca269d5a8208955af0f4064` (28/09/2026). Schema thực tế `AppDatabase.schemaVersion = 15`. Các số dòng bên dưới áp dụng cho SHA này; tìm theo tên hàm nếu HEAD dịch chuyển. Đây là prompt triển khai, không phải tuyên bố các lỗi đã được sửa.

## Quy tắc chung cho Codex/Gemini — dán ở đầu MỖI phase

> Chỉ làm phase được giao. Đọc `AGENTS.md`, lần lượt `docs/TUITION2027_DOMAIN_CONSTITUTION.md`, `docs/DATABASE_SCHEMA.md`, `docs/ARCHITECTURE.md`, và `docs/MIGRATION_RULES.md` nếu đụng migration. Lấy SHA mới nhất trước khi sửa và đối chiếu mã ở những hàm được nêu dưới đây. Nếu Codex UI đang sửa repo, tạo branch riêng từ HEAD mới nhất; không push trực tiếp lên `main`, không đè thay đổi UI. Không đổi schema nếu phase không yêu cầu, không sửa `.g.dart` bằng tay, không đổi công thức học phí và không thêm nghiệp vụ ngoài scope. Viết test tái hiện lỗi trước; sửa đúng service/repository canonical; chạy test mục tiêu, `flutter analyze`, `flutter test`, `flutter build apk --debug` khi CI đã ổn, và Android integration trên Ubuntu/KVM. Khi UI bị ảnh hưởng, chạy luồng đó trên Android Emulator theo AGENTS.md. Gửi SHA, diff, test thực chạy, job Actions exact-SHA và giới hạn xác minh. Nếu test toàn repo đang đỏ vì nhánh UI, báo riêng lỗi nền và lỗi do phase; tuyệt đối không ghi PASS giả.

Các phase chạy tuần tự P1→P6. P6 gồm hai phần độc lập về nghiệp vụ nhưng gom vào một quality gate. Không gộp nhiều phase trong một commit.

## PHASE P1 — Chặn sửa điểm danh đã hoàn tất qua lối lưu nháp

**Prompt gửi Codex/Gemini:**

> Sửa lỗ hổng ghi điểm danh của buổi `DA_HOC` ở `lib/features/attendance/domain/attendance_service.dart`, hàm `AttendanceService.saveDraft` (ở SHA gốc khoảng dòng 104–205). Hiện hàm chỉ từ chối `HUY` và `NGHI_LE` (dòng 116–119), sau đó gọi `_repo.batchSave`; do đó caller có thể thay `CO_MAT` thành `TRE`, hoặc gửi `CHUA_DIEM_DANH` để xóa bản ghi, mà không tạo dòng `diem_danh_chinh_sua`. Ngay sau `getAttendanceForSession` và trước khi lập `toUpsert/toDeleteIds`, từ chối `sheet.session.trangThai == SessionStatus.DA_HOC` bằng lỗi nghiệp vụ rõ ràng, hướng người gọi sang `correctFinalizedAttendance`. Đừng chỉ ẩn nút ở UI; guard phải nằm trong service. Giữ `DU_KIEN` được lưu như hiện tại; giữ chặn `HUY/NGHI_LE` và giữ `finalizeSessionAttendance` idempotent.
>
> Thêm regression test trong `test/attendance/attendance_service_test.dart` hoặc test Phase 14B.2: tạo buổi `DA_HOC` có roster hợp lệ và một điểm danh `CO_MAT`; gọi `saveDraft` với `TRE` rồi với `CHUA_DIEM_DANH`, cả hai phải throw; đọc lại `diem_danh` xác nhận hàng cũ không đổi và `diem_danh_chinh_sua` không có hàng mới. Test riêng `DU_KIEN` vẫn lưu được và `correctFinalizedAttendance` vẫn tạo audit. Không thay repository bằng guard trong UI. Commit riêng `fix(attendance): protect finalized records from draft saves`.

**Nghiệm thu:** không có con đường `saveDraft` sửa/xóa điểm danh `DA_HOC`; correction có lý do và audit vẫn hoạt động.

## PHASE P2 — Sửa roster khi học sinh có phân ca nhiều thứ trong tuần

**Prompt gửi Codex/Gemini:**

> Sửa `RosterService._computeBaseChinhRoster` trong `lib/features/roster/domain/roster_service.dart`, đoạn khoảng dòng 454–570. Lỗi: `activeAssignments` lọc theo học sinh + khoảng ngày (dòng 503–510), rồi báo `MULTIPLE_ACTIVE_ASSIGNMENTS` nếu nhiều hơn một (dòng 521), dù các assignment ấy thuộc các lịch khác thứ. `ScheduleDomainService.assignStudent` cho phép phân ca thứ Hai và thứ Tư đồng thời nếu không trùng thời gian, nên roster buổi thứ Hai không được coi assignment thứ Tư là phân ca cạnh tranh.
>
> Trong chế độ `isMultiShift`, trước vòng lặp membership: lấy assignments của lớp một lần; lấy tập `idLichHoc` của chúng và tải schedule bằng `ScheduleRepository.getByIds` hoặc thêm API batch ở service (không query `getScheduleById` cho từng học sinh). Xây map `idLichHoc → ClassSchedule`. Với mỗi membership, lọc assignments đang hiệu lực trên `session.ngay`, sau đó chỉ giữ assignment có schedule thuộc **cùng lớp, cùng `referenceDate.weekday`**; giữ kiểm tra ranh giới schedule và membership như hiện có. Nếu schedule của assignment bị mất hoặc sai lớp, báo `INVALID_ASSIGNMENT` theo chính sách fail-closed, không âm thầm bỏ. Nếu còn hai assignment cho hai ca trong cùng thứ/ngày, vẫn báo `MULTIPLE_ACTIVE_ASSIGNMENTS`. Nếu không có assignment của thứ đang xét trong lớp nhiều ca, báo `UNASSIGNED_IN_MULTI_SHIFT`. Đối chiếu `session.idLichHoc` để thêm đúng một participant.
>
> Viết test ở `test/roster/roster_service_test.dart`: một học sinh có assignment thứ Hai và thứ Tư đồng thời, thứ Hai có hai ca; roster thứ Hai chỉ đưa học sinh vào ca thứ Hai được gán, roster thứ Tư đúng ca thứ Tư; không có `MULTIPLE_ACTIVE_ASSIGNMENTS`. Test thêm hai assignment trùng ngày ở hai ca thứ Hai vẫn bị chặn và assignment tham chiếu schedule mất/sai lớp fail-closed. Đừng sửa `ScheduleConflictService` để né lỗi roster. Commit riêng `fix(roster): scope active assignments to session weekday`.

**Nghiệm thu:** roster, attendance và credit eligibility cùng nhìn thấy đúng học sinh cho từng ca; số query không tăng theo số học sinh.

## PHASE P3 — Một kiểm tra độ phủ lịch trước khi chốt invoice và lập phiếu

**Prompt gửi Codex/Gemini:**

> Sửa hai kiểm tra không tương đương. (1) `InvoiceService._validateEarlyMonthBillingGap` tại `lib/features/tuition/domain/invoice_service.dart` khoảng dòng 52–72 hiện chỉ xét các buổi `CHINH` đã sinh, nên 2/12 buổi đều `DA_HOC` vẫn cho chốt. (2) `ParentTuitionSlipService.generateSlip` tại `lib/features/tuition/domain/parent_tuition_slip_service.dart` khoảng dòng 142–239 so `generatedChinhSessions.length < expectedSessionCount`, nên một buổi thiếu + một buổi thừa có thể cho qua. Tạo **một** domain read-only service/check dùng chung để đối soát tháng của lớp từ `lich_hoc` và `buoi_hoc`; không sao chép vòng lặp ngày vào hai nơi.
>
> Logic bắt buộc: liệt kê từng occurrence `(schedule.id, YYYY-MM-DD)` của lịch `lich_hoc` có hiệu lực và đúng `thu_trong_tuan` trong tháng. Tải buổi `CHINH` của lớp/tháng một lần, ghép theo `id_lich_hoc` và `ngay`; phát hiện thiếu, trùng, buổi không khớp lịch gốc, và tình trạng chưa `DA_HOC`. `HUY`/`NGHI_LE` là buổi đã sinh và đã giải quyết cho ngày đó, **không** đòi `DA_HOC`; vẫn không tính phí và credit. Nếu lịch được sửa giữa tháng, dùng khoảng hiệu lực thực của từng lịch; lịch cũ đã đóng vẫn được tính ở các ngày trước ngày đóng. Nếu chưa có lịch nhưng có buổi chính lịch sử, không tự xóa/đoán dữ liệu: trả kết quả thiếu lịch/không nhất quán. Không sửa DB schema hoặc tự động sinh buổi trong phương thức đọc.
>
> `InvoiceService.finalizeStudentInvoice` và `finalizeClassInvoices` phải gọi check chung và từ chối khi còn occurrence thiếu hoặc buổi cần học chưa hoàn thành; `ParentTuitionSlipService.generateSlip` dùng chính kết quả check đó để trả trạng thái lỗi phù hợp, rồi mới tính projected count. Test SQLite tại `test/tuition/invoice_service_test.dart` và `test/tuition/parent_tuition_slip_service_test.dart`: 2/12 đã học không được chốt; 1 thiếu + 1 thừa cùng tổng không được coi đủ; đủ 12 đã học được chốt; một ngày `HUY` hoặc `NGHI_LE` hợp lệ không bị tính phí và không chặn độ phủ; lịch đổi giữa tháng; buổi chính không khớp schedule bị báo. Không sửa `TuitionService.previewTuition` để dựng lịch dự kiến riêng. Commit riêng `fix(tuition): verify schedule occurrence coverage before billing`.

**Nghiệm thu:** không thể chốt từ bộ buổi sinh thiếu; phiếu và invoice dùng cùng một kết quả đối soát.

## PHASE P4 — Sửa điểm danh sau chốt: khóa an toàn và ghi rõ đường điều chỉnh

**Prompt gửi Codex/Gemini:**

> Kiểm tra `AttendanceService.correctFinalizedAttendance` (`lib/features/attendance/domain/attendance_service.dart`, khoảng dòng 313–464). Hàm hiện ghi audit điểm danh nhưng không xét invoice đã chốt và `buoi_du_ledger`. Sau khi sửa buổi vượt chuẩn `CO_MAT→NGHI_*`, ledger +1 có thể tồn tại dù điều kiện cộng credit không còn; `TuitionService.previewTuition` (khoảng dòng 228–231) sẽ báo `recordedEarned > potentialEarned`. Trong phase này **không** tự tạo cơ chế hoàn/giữ tiền hoặc tự viết lại invoice đã trả. Thiết lập chốt chặn fail-closed cho correction có thể làm thay đổi kết quả học phí/credit sau khi đã chốt hoặc đã ghi credit; thông báo rõ cần quy trình điều chỉnh riêng.
>
> Với từng học sinh có `oldStatus != newStatus`, lấy `idLopGoc` từ roster member và tháng từ `sheet.session.ngay.substring(0,7)`. Dùng **quy tắc bảo thủ, xác định được**: từ chối mọi thay đổi trạng thái nếu tồn tại invoice `hoc_phi_thang` của `(id_hoc_sinh,id_lop,thang)` với trạng thái `DA_CHOT`, `CON_NO` hoặc `DA_THANH_TOAN`, **hoặc** tồn tại dòng `buoi_du_ledger` tự động `VUOT_SO_BUOI_CHUAN`/`BU_TRU_NGHI_CO_PHEP` cho cùng học sinh–lớp trong tháng đó. Dùng `txn.query` với `limit: 1`, `ngay_hieu_luc >= '$month-01' AND ngay_hieu_luc < '$nextMonth-01'`; không dùng `LIKE` hoặc so ngày bằng chuỗi locale. Guard và ghi điểm danh/audit phải trong **cùng giao dịch SQLite** để không có race; thêm phương thức `InTxn` tối thiểu cho repository nếu cần. Không chặn thao tác không đổi giá trị và không chặn sửa buổi chưa có invoice/ledger liên quan. Ghi test: trước chốt được sửa và có audit; sau chốt bị chặn, attendance/invoice/ledger không đổi; credit đã reconcile dù chưa có invoice cũng bị chặn; lỗi ở giữa giao dịch rollback. Trình bày trong báo cáo rằng cơ chế điều chỉnh invoice/credit đã thanh toán cần phase nghiệp vụ riêng, không âm thầm tính lại tiền.
>
> Xem lại `correctFinalizedAttendance` có đang cho `CHUA_DIEM_DANH` và `HOC_BU` đúng theo roster không; giữ các guard hiện hữu. Commit riêng `fix(attendance): guard corrections against settled tuition and credits`.

**Nghiệm thu:** sửa attendance không thể để lại invoice/credit bất nhất; lịch sử trước chốt vẫn sửa có audit.

## PHASE P5 — Sửa số liệu dashboard và lịch hiển thị; chốt nghĩa báo cáo ngày

**Prompt gửi Codex/Gemini:**

> A. `DashboardService.getOverview` (`lib/features/dashboard/domain/dashboard_service.dart`, khoảng dòng 83–118): vòng lặp `monthMemberships` tăng `unfinalizedCount++` theo từng dòng membership. Thay bằng tập key kiểu `(idHocSinh, idLop)` hoặc record Dart và chỉ đếm duy nhất cặp đó khi lớp còn hoạt động, chưa có invoice finalized; không dùng nối chuỗi dễ va chạm. Test học sinh nghỉ rồi ghi danh lại cùng lớp trong tháng vẫn là **một** khoản chưa chốt; hai lớp khác nhau là hai.
>
> B. `ClassListOverviewService.getOverview` (`lib/features/classes/domain/class_list_overview_service.dart`, khoảng dòng 105–116): truy vấn `lich_hoc` hiện lấy mọi lịch. Thêm predicate `hieu_luc_tu <= todayStr AND (hieu_luc_den IS NULL OR hieu_luc_den >= todayStr)` cho **scheduleText hiện tại**. Cảnh báo thiếu sinh buổi tuần này phải tính lịch có occurrence trong tuần, không chỉ `schedulesByClass[id].isNotEmpty` tại hôm nay; lớp có lịch tương lai không được báo thiếu buổi tuần hiện tại. Test lịch đã đóng, lịch tương lai, lịch bắt đầu giữa tuần và lịch hiện tại.
>
> C. `ReportService.generateReport` (`lib/features/reports/domain/report_service.dart` khoảng dòng 55–58, 143–202): custom range lấy invoice theo cả tháng (`fromMonth..toMonth`) trong khi payment lấy đúng `fromDate..toDate`. **Không tự suy diễn định nghĩa tài chính**. Trong phase này thêm nhãn/phần mô tả phạm vi ngay read model/UI/PDF, thể hiện rõ “Học phí/công nợ theo tháng bao phủ khoảng chọn” và “Tiền thực thu trong khoảng ngày chọn”, hoặc đưa đề xuất nghiệp vụ cụ thể để chủ dự án quyết định trước khi đổi số. Test 10–15/09 có invoice 01/09 và payment 12/09 để chứng minh hai phạm vi không bị trình bày như cùng một khoảng. Không thay công thức debt canonical. Commit riêng `fix(read-models): dedupe workload and respect effective schedules`.

**Nghiệm thu:** dashboard không đếm trùng; lịch hiển thị đúng hiệu lực; báo cáo không gây hiểu nhầm ngày/tháng.

## PHASE P6 — Giảm truy vấn theo từng buổi và nghiệm thu Android exact-SHA

**Prompt gửi Codex/Gemini:**

> Chỉ tối ưu sau P1–P5, giữ kết quả nghiệp vụ bit-for-bit trên cùng dữ liệu. `ReportService.generateReport` (`lib/features/reports/domain/report_service.dart`, khoảng dòng 79–126) gọi `_attendanceService.getAttendanceForSession` tuần tự cho mỗi buổi; `SessionCreditService.getEligibleSessionsForStudentClassMonth` (`lib/features/session_credits/domain/session_credit_service.dart`, dòng 97–110) gọi roster từng buổi, `previewMonth` (dòng 145–174) gọi attendance và ledger từng buổi; `TuitionService.previewTuition` (`lib/features/tuition/domain/tuition_service.dart`, dòng 111–118) đọc attendance từng buổi. Thêm API đọc batch trong repository hiện hữu theo danh sách `sessionId`, chunk placeholder SQLite tối đa 500 như `AttendanceRepository.getBySessionIds`; lấy records và earned-ledger một lần mỗi batch rồi map theo ID. Với roster, ưu tiên batch read model trong `RosterService` tái dùng cùng logic canonical; không tự dựng roster riêng trong report/credit. Không chạy hàng trăm `Future.wait` để che N+1. Giữ fail-closed khi roster hỏng, khác nhau giữa thiếu attendance và `CO_MAT`, và thứ tự session `ngay, gio_bat_dau, id`.
>
> Viết test parity cùng bộ dữ liệu cho 1/12/13/14 buổi, hai ca một ngày, đổi ca, học bù, pause/resume, archived, credit đã/ chưa reconcile. Instrument số lệnh SQLite hoặc dùng fake repository đếm calls; chứng minh số query không tăng tuyến tính theo `số buổi × số học sinh`. Chạy Android Emulator UI/report/tuition, targeted tests, `flutter analyze`, `flutter test`, `flutter build apk --debug`, rồi kiểm hai job Ubuntu `build` và `android-integration-test` của đúng SHA commit. Nếu lỗi 77 widget tests cũ trên nhánh UI chưa được sửa, liệt kê thay vì tuyên bố phase xanh. Commit riêng `perf(domain): batch attendance and credit reads`.

**Nghiệm thu:** kết quả tiền/roster/report không đổi, số truy vấn giảm có số đo, exact-SHA CI xanh trước khi chốt.

## Bảng kiểm kết thúc cho người duyệt

| Phase | Bằng chứng tối thiểu |
| --- | --- |
| P1 | `saveDraft(DA_HOC)` từ chối update/delete, correction có audit |
| P2 | Hai thứ khác nhau hợp lệ; hai ca cùng thứ trùng bị chặn; không N+1 mới |
| P3 | Thiếu buổi theo occurrence bị chặn dù tổng số buổi bằng nhau |
| P4 | Correction sau invoice/credit không tạo trạng thái tài chính mâu thuẫn |
| P5 | Membership tái nhập không đếm trùng; lịch cũ/tương lai không hiện như hiện tại |
| P6 | Test parity + số query + Android Emulator + Ubuntu Actions exact-SHA |

Lưu ý: SHA gốc là điểm đối chiếu, không phải lệnh reset branch. Khi Codex UI push commit mới, rebase branch sửa nghiệp vụ lên HEAD mới và báo rõ xung đột nếu có.
