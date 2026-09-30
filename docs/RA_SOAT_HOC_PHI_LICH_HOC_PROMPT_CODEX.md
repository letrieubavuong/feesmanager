# Rà soát nghiệp vụ và prompt triển khai cho Codex

Ngày rà soát: 30/09/2026. Repository: https://github.com/letrieubavuong/feesmanager

Nguồn kiểm tra: branch `ui/class-detail-priority-20260928`, commit `9292c8f3fd3c2d66813741985294f530c5a7cffb`. Các nhận định dưới đây dựa trên mã nguồn tại commit này, không phải kết luận từ cơ sở dữ liệu trên điện thoại. Không chỉnh sửa code ứng dụng trong lượt rà soát này. Số dòng chỉ để đối chiếu commit, tên hàm là điểm neo chính khi code mới thay đổi.

## 1. Kết luận nghiệp vụ

### Chính sách học phí

Yêu cầu mới: một chính sách chung của trung tâm trong Cài đặt, áp dụng cho tất cả lớp/khối; lớp chỉ quản lý môn, học sinh, lịch và ca. Cấu hình gồm số buổi chuẩn tháng N, đơn giá buổi P, trần tháng C, quy tắc nghỉ có phép và ngày áp dụng. Không còn thao tác tạo/sửa chính sách riêng ở lớp.

Đây là thay đổi quy tắc nghiệp vụ, không chỉ di chuyển giao diện. Hiện code và hiến pháp miền vẫn quy định chính sách theo lớp. Bỏ giao diện mà không thay resolver sẽ khiến lớp mới thiếu chính sách và không tính được học phí.

Không xóa lịch sử chính sách cũ: hóa đơn đã chốt có liên kết tới chính sách cũ. Bỏ hoàn toàn việc quản lý chính sách riêng cho lớp từ nay về sau, giữ bản ghi cũ để giải thích hóa đơn cũ.

Miễn giảm hiện thuộc lần tham gia lớp (`tham_gia_lop`), không mặc nhiên thuộc hồ sơ học sinh. Giữ nơi lưu này trong đợt sửa để không làm mất miễn giảm; việc chuyển miễn giảm sang hồ sơ dùng chung mọi lớp là một thay đổi khác, chưa được yêu cầu rõ.

### Cách tính được đề xuất

Giữ quy tắc hiện có: tối đa N buổi chuẩn tính tiền, buổi vượt chuẩn được xử lý theo sổ buổi dư khi đủ điều kiện điểm danh, không tự cộng tiền lần nữa. Không tự bỏ cơ chế buổi dư.

Gọi q là số buổi hợp lệ của học sinh trong tháng sau khi lọc ngày tham gia, ngày rời lớp, lịch/ca, nghỉ lễ và buổi hủy. Tạm thu dùng buổi dự kiến; đối soát dùng điểm danh và quy tắc vắng mặt.

```text
buoiTinhPhi = min(q, N)
tienGoc = min(buoiTinhPhi * P, C)   // nếu không cấu hình C: dùng buoiTinhPhi * P
tienGiam = floor(tienGoc * phanTramGiam / 100)
phaiThu = tienGoc - tienGiam
daThu = tổng giao dịch thu tiền thực tế hợp lệ
conThu = max(phaiThu - daThu, 0)
thuDu = max(daThu - phaiThu, 0)
```

Đề xuất áp dụng giảm giá trên tiền gốc đã giới hạn trần, để người học đủ tháng được giảm trên trần tháng. Nếu C = N × P, công thức đúng với yêu cầu đơn giản trước đó: P × số buổi tính phí × (100% − % giảm). Khi C khác N × P, hai thứ tự tính có thể cho kết quả khác; phải ghi rõ quy tắc trên trong hướng dẫn, không để Codex tự chọn. Không bắt buộc C = N × P nếu trung tâm muốn trần độc lập, nhưng hiển thị giải thích khi lệch.

Ví dụ N=12, P=50.000, C=600.000, giảm 10%:

| Trường hợp | Số buổi tính tiền | Phải thu | Đã thu | Còn thu / thu dư |
|---|---:|---:|---:|---|
| Đầu tháng đủ 12 buổi hợp lệ | 12 | 540.000 | 0 | Còn thu 540.000 |
| Vào giữa tháng, còn 7 buổi | 7 | 315.000 | 200.000 | Còn thu 115.000 |
| Sau đó nghỉ có phép 1 buổi, cấu hình không tính phí | 6 | 270.000 | 315.000 | Thu dư 45.000 |

Không tính theo số ngày trong tháng và không lấy toàn bộ số buổi của lớp cho học sinh mới vào. Hai ca cùng lớp không đồng nghĩa học sinh phải trả tiền cho cả hai ca. Nghỉ lễ/hủy trùng lịch phải loại trước khi tính q; không vừa trừ một buổi tiền vừa dùng thêm một tín chỉ cho cùng sự kiện. Tín chỉ buổi dư và tiền thu dư là hai loại số dư khác nhau.

### Tạm thu và đối soát

Đầu tháng: sinh đủ buổi → tính dự kiến theo lịch và thời gian tham gia → tạo thông báo/QR → ghi thu một phần hoặc đủ, không cần điểm danh tương lai và không cần chốt cuối tháng.

Trong tháng: điểm danh, đổi lịch, nghỉ lễ, đổi ngày tham gia làm số dự kiến/đối soát cần làm mới; phiếu thu vẫn giữ đúng số tiền và thời gian thực tế đã ghi.

Cuối tháng: đối soát theo điểm danh → xác nhận số cuối kỳ → so với đã thu → hiển thị còn thu hoặc thu dư. Nếu sửa điểm danh sau khi đã xác nhận, đánh dấu cần đối soát lại và tạo lịch sử điều chỉnh; không âm thầm ghi đè hóa đơn đã xác nhận.

“Chốt học phí” hiện tại nên trở thành “Đối soát cuối tháng”. Đây là bước xác nhận cuối kỳ, không phải điều kiện để thu đầu tháng.

## 2. Những điểm sai đã kiểm tra trong code

| Vị trí / hàm | Hành vi hiện tại | Cần sửa |
|---|---|---|
| `lib/features/settings/presentation/tuition_policy_settings_page.dart`, `build` | Chọn lớp rồi đọc `classTuitionPoliciesProvider(_selectedClassId!)` | Một chính sách trung tâm; không chọn lớp |
| `lib/features/classes/presentation/class_form_bottom_sheet.dart`, `_showClassFormAndPolicy` (khoảng dòng 293–315) | Sau tạo lớp mở tiếp `showCreateTuitionPolicyBottomSheet(classId: ...)` | Tạo lớp xong kết thúc; không tạo chính sách lớp |
| `lib/features/classes/presentation/class_detail_page.dart`, `_changeClassTuitionPolicy` | Sửa chính sách theo `widget.classId` | Bỏ hành động; có thể dẫn đến Cài đặt chung |
| `lib/features/tuition/domain/tuition_policy_service.dart`, `getEffectivePolicyForDateStr`; repository `getEffectivePolicy` | Resolver bắt buộc `classId` | Resolver chính sách trung tâm có hiệu lực theo kỳ; giữ resolver lịch sử riêng cho hóa đơn cũ |
| `lib/features/tuition/domain/tuition_service.dart`, `previewTuition` | Lấy chính sách lớp tại ngày 01 rồi dùng `_creditService.previewMonth` | Tách tính dự kiến và đối soát, dùng chung calculator |
| `lib/features/session_credits/domain/session_credit_service.dart`, `getEligibleSessionsForStudentClassMonth` và bản nhiều học sinh (dòng 79–84, 130–135) | Chỉ lấy `CHINH + DA_HOC` | Đúng cho đối soát tín chỉ, không đủ cho tạm thu; tạo eligibility dự kiến riêng, không sửa mọi lọc thành DU_KIEN |
| `TuitionService.calculatePreviewFromResolvedData` (khoảng dòng 281–290) | Nhân tiền → giảm % → áp trần | Đưa công thức chung đã quyết định vào calculator duy nhất; kiểm thử khi C khác N×P |
| `lib/features/tuition/domain/class_month_tuition_overview_service.dart`, `getOverview` | Lấy chính sách lớp, candidates từ credit service chỉ DA_HOC | Thêm kết quả dự kiến riêng, tổng đã thu, còn thu/thu dư; không dùng đối soát chưa có buổi làm tạm thu 0 |
| `lib/features/tuition/domain/invoice_service.dart`, `_validateEarlyMonthBillingGap` (dòng 53–78), `finalizeStudentInvoice`, `finalizeClassInvoices` | Chặn khi còn bất kỳ buổi chính chưa DA_HOC của cả lớp | Giữ kiểm tra phù hợp cho xác nhận cuối kỳ; tạo luồng tạm thu không gọi guard này |
| `lib/features/payments/domain/payment_service.dart`, `recordPayment`, `updatePayment` | Chỉ cho thu/sửa khi hóa đơn là finalized | Cho thu dự kiến bằng chứng từ dự kiến có snapshot và FK ổn định |
| `lib/features/payments/domain/payment_settlement_rules.dart`, `evaluate`, `deriveStatus` | NHAP có payment bị coi là lỗi; totalPaid > amountDue bị coi là hỏng dữ liệu | Tách vòng đời chứng từ và tình trạng thanh toán; hỗ trợ thu dư hợp lệ sau điều chỉnh |
| `lib/features/tuition/domain/parent_tuition_slip_service.dart`, `generateSlip` | Có đếm buổi dự kiến nhưng nhánh chưa chốt trả `noInvoiceFinalized`, không phát QR dự kiến | Dùng kết quả dự kiến canonical, phát thông báo tạm thu và QR số còn cần thu |
| `lib/features/schedule/presentation/schedule_tab.dart`, `ScheduleFormBottomSheet`, `_submit` | Form chỉ có ngày từ; revise chỉ gửi effectiveDate | Thêm ngày đến, tách sửa khoảng chưa dùng và thay lịch từ mốc mới |
| `lib/features/schedule/domain/schedule_service.dart`, `reviseSchedule` (dòng 128) | Sửa tại ngày bắt đầu khi chưa có assignments mà chưa kiểm tra session/attendance | Không coi assignments rỗng là đủ an toàn; kiểm tra toàn bộ dữ liệu phụ thuộc |
| Cùng hàm `reviseSchedule` (khoảng dòng 160–240) | Chuyển phân ca, xóa buổi tương lai DU_KIEN; chưa sinh thay thế | Preview tác động; kiểm tra membership/conflict; apply nguyên tử và sinh lại đúng phạm vi |
| `ScheduleDomainService.closeSchedule` | Lịch đã có ngày đến khó sửa; assignment mở/vượt ngày đến làm thao tác bị chặn | Preview các phân ca cần đóng/cắt; sửa khoảng an toàn, bảo vệ lịch sử |
| `lib/features/schedule/presentation/schedule_controller.dart`, `revise` | Chỉ gọi reviseSchedule rồi tải lịch lớp | Trả kết quả tác động có cấu trúc, làm mới buổi/roster/học phí/home/nhắc giờ |
| `lib/features/sessions/domain/session_generation_service.dart`, `generateForClass` | Sinh từng dòng qua repository, có thể trả conflictCount/warnings; chưa có apply theo transaction sửa lịch | Dùng generation plan trong transaction thay lịch; không bỏ qua warnings rồi báo thành công |

Lưu ý: form sửa lịch đã có `_inlineError`. Vì vậy không kết luận “toàn bộ lỗi bị nuốt”. Vấn đề là thông báo dạng chuỗi và thiếu preview tác động; cần tái hiện đúng ca người dùng bị chặn, hiển thị tên lớp/học sinh, ngày/giờ và cách xử lý.

## 3. Prompt tổng cho Codex

Sao chép khối sau, đính kèm toàn bộ tài liệu này. Thực hiện các phase theo thứ tự.

```text
Bạn sửa repository feesmanager dựa trên báo cáo đính kèm. Không chỉ trả kế hoạch.
1. git fetch origin; kiểm tra working tree; không ghi đè thay đổi chưa commit. Làm trên branch mới từ đầu branch ui/class-detail-priority-20260928 đã cập nhật, không từ code cũ. Báo SHA thực tế.
2. Đọc AGENTS.md, lib/AGENTS.md, docs/TUITION2027_DOMAIN_CONSTITUTION.md, DATABASE_SCHEMA.md, MIGRATION_RULES.md, ARCHITECTURE.md theo thứ tự bắt buộc. Yêu cầu nghiệp vụ mới trong tài liệu này thay thế quy tắc cũ mâu thuẫn; cập nhật tài liệu miền trước implementation.
3. Áp dụng từng phase bên dưới. Mỗi phase phải commit riêng, test hành vi và nêu path + tên hàm đã sửa. Nếu code khác báo cáo, giải thích khác biệt rồi sửa đúng tại code hiện hành; không giả định tên hàm mới đã tồn tại.
4. Không reset DB, không xóa học sinh/điểm danh/phiếu thu/hóa đơn/chính sách lịch sử, không giả điểm danh DU_KIEN thành CO_MAT hoặc DA_HOC. Không sửa .g.dart bằng tay; dùng generator.
5. UI không chứa SQL hoặc công thức tiền. Domain là nguồn sự thật; repository hỗ trợ transaction; reads/preview không ghi credit/payment.
6. Sau mỗi thay đổi Dart/UI khi app đang chạy: hot reload ngay và kiểm tra màn hình liên quan. Nếu native/plugin/schema/generator cần restart, thực hiện đúng restart rồi kiểm tra DB đã nâng cấp. Hot reload không thay cho migration/restart.
7. Chỉ hoàn tất khi test nghiệp vụ, analyze, build debug/release và thao tác trên máy ảo đạt. Nếu thiếu Flutter/emulator, ghi rõ phần chưa kiểm chứng, không nói đã chạy.
```

## Phase 0 — Chốt định nghĩa và migration không mất lịch sử

```text
Cập nhật quy tắc chính sách chung, tạm thu và đối soát trong docs/TUITION2027_DOMAIN_CONSTITUTION.md, DATABASE_SCHEMA.md, MIGRATION_RULES.md, ARCHITECTURE.md.

Thiết kế một chính sách trung tâm có version/effective month; trường N, P, C, excusedAbsenceRule. Để giảm phức tạp, chính sách giá mới áp dụng từ ngày 01 của tháng được chọn; không âm thầm đổi giá giữa tháng. Lịch học vẫn có from/to theo ngày bình thường.

Trước migration, đọc schema thật trong lib/core/database/app_database.dart: bảng hóa đơn đang được InvoiceService truy vấn là hoc_phi_thang, không tự dùng tên hoa_don_thang trong phân tích cũ. Ghi mapping schema cũ/mới.

Tạo forward migration bảng center_tuition_policy và liên kết/snapshot cần thiết. Mỗi tháng chỉ có một version trung tâm hiệu lực; kiểm tra overlap. Lưu chính sách giá của chứng từ dự kiến/đối soát, không resolve theo setting hiện tại khi đọc chứng từ cũ.

Giữ chinh_sach_hoc_phi cũ và FK idChinhSachHocPhi của hóa đơn cũ. Thêm center policy reference nullable, legacy reference cho bản cũ; nếu cột legacy NOT NULL thì rebuild bảng trong migration có kiểm tra copy/FK/row-count. Không tạo class policy giả mỗi khi lớp mới xuất hiện để né migration.

Nếu chính sách lớp cũ khác nhau, không tự lấy policies.first làm giá chung. Cho trung tâm thiết lập chính sách chung hiện tại/future. Với kỳ lịch sử chưa đối soát, resolver legacy được dùng công khai có cảnh báo, hoặc cần người dùng chọn version hồi tố phù hợp; không áp giá hiện tại cho mọi tháng cũ.

Tách invoice lifecycle (PROVISIONAL/FINALIZED) khỏi payment status (UNPAID/PARTIAL/PAID/OVERPAID); mapping trạng thái cũ giữ ý nghĩa snapshot finalized. Bản NHAP cũ thành provisional. Dùng một chứng từ ổn định cho bộ student+class+month và bảng revision/snapshot nếu cần bảo toàn các lần tính. Giữ payment.invoiceId, id và createdAt khi cập nhật.

Kiểm thử migration từ DB cũ có policies khác nhau, finalized invoice, draft, partial payment, discounts, credit ledger. Sau upgrade mở lại app hai lần; FK check và các tổng tiền cũ phải giữ nguyên. Không yêu cầu người dùng cài lại/xóa dữ liệu.
```

## Phase 1 — Chính sách chung và calculator tiền duy nhất

```text
Sửa TuitionPolicyService.getEffectivePolicyForDateStr và TuitionPolicyRepository.getEffectivePolicy: thêm API getEffectiveCenterPolicyForMonth(month); thêm resolver historical policy theo snapshot/legacy. Không dùng classId để lấy giá mới.

Sửa TuitionPolicySettingsPage.build: bỏ selectedClass/dropdown/classTuitionPoliciesProvider; hiển thị cấu hình trung tâm đang hiệu lực và phiên bản sắp áp dụng. Lưu qua bottom sheet có N>0, P>=0, C>=0 hoặc null, discount 0..100, tháng áp dụng rõ ràng. Chặn interval overlap.

Sửa _showClassFormAndPolicy trong class_form_bottom_sheet.dart: kết thúc sau tạo lớp, bỏ bước showCreateTuitionPolicyBottomSheet theo classId. Bỏ _changeClassTuitionPolicy và nút giá riêng trong class_detail_page.dart. Nếu thiếu policy trung tâm: thông báo thiết lập tại Cài đặt, không tự tạo giá 0/default.

Trong tuition_service.dart thay khối tiền tại calculatePreviewFromResolvedData bằng pure calculator dùng chung. Ví dụ code định hướng, phải tích hợp model thật và test:

int feeForSessions({required int sessions, required int standardLimit,
  required int unitPrice, required int discountPercent, int? monthlyCap}) {
  if (sessions < 0 || standardLimit <= 0 || unitPrice < 0 ||
      discountPercent < 0 || discountPercent > 100 ||
      (monthlyCap != null && monthlyCap < 0)) {
    throw ArgumentError('Thông số học phí không hợp lệ');
  }
  final billed = sessions > standardLimit ? standardLimit : sessions;
  final gross = billed * unitPrice;
  final base = monthlyCap != null && gross > monthlyCap ? monthlyCap : gross;
  return base - (base * discountPercent ~/ 100);
}

Lưu gross/cappedBase/discountAmount/net nhất quán, không để tổng trước giảm trừ tiền giảm khác số net do cap. Dùng số nguyên đồng, không double. Cách làm tròn: tiền giảm floor, net=base-discount.

TuitionService, ClassMonthTuitionOverviewService, ParentTuitionSlipService, invoice và reports dùng chung calculator/resolver; UI không tính lại. SessionCreditService lấy N từ cùng version, không fallback 12 khi thiếu chính sách rồi cho kết quả tưởng đúng.

Test 12×50k cap600k giảm10%=540k; 7 buổi=315k; 0 buổi=0; giảm100%=0; cap400k và gross600k giảm10%=360k (phân biệt thứ tự cũ ra400k); không cap; N thay đổi theo version; lớp mới dùng được policy chung; hóa đơn cũ giữ giá cũ.
```

## Phase 2 — Sửa lịch có khoảng hiệu lực và preview xung đột

```text
Sửa ScheduleFormBottomSheet/_submit trong schedule_tab.dart, ClassScheduleController.revise, ScheduleDomainService.reviseSchedule/closeSchedule/createSchedule và SessionGenerationService.generateForClass.

Form cần ngày từ và ngày đến (null = chưa xác định), validate den>=tu, thông báo inclusive. Phân biệt “Sửa lịch chưa sử dụng” với “Thay lịch từ ngày ...”. Không biến việc sửa from 01/07 thành 02/08 thành sửa weekday tại cùng mốc.

Tạo API mới rõ ràng (đây là API đề xuất, không phải hàm đã có):
previewScheduleChange(scheduleId, newWeekday, newStart, newEnd,
                     newEffectiveFrom, newEffectiveTo, applyFrom)
 -> changePlan {conflicts, protectedSessions, assignmentsToSplit,
                sessionsToRemove, sessionsToCreate, affectedMonths, revisionToken}
applyScheduleChange(changePlan, revisionToken) -> result

Preview không mutate. Có session/attendance/adjustment/finalized snapshot thì bảo vệ lịch sử; không chỉ kiểm tra assignments.isEmpty như nhánh hiện tại dòng128. Khi không có dữ liệu sử dụng, cho sửa cả from/to. Khi có lịch sử, chỉ tạo version từ mốc an toàn; báo cụ thể buổi nào không thể sửa, đề xuất mốc sau buổi bảo vệ cuối cùng, không lặng lẽ đổi ngày thay người dùng.

Tại reviseSchedule: kiểm tra migrated assignments giao với membership và khoảng lịch mới. Cắt/đóng/split assignment theo giao khoảng; nếu giao rỗng đưa vào preview lỗi để người dùng xử lý, không tạo interval sai hoặc chuyển phân ca mất học sinh âm thầm.

Gọi ScheduleConflictService cho từng assignment bị thay đổi, kiểm tra overlap trong khoảng hiệu lực, loại chính assignment/version đang thay, không bỏ kiểm tra với các lịch còn lại. Trả conflict có reasonCode, tên học sinh/lớp, thứ/ngày và giờ hai lịch, hard/soft. UI hiển thị danh sách lỗi ngay trên bottom sheet; soft warning cho xác nhận rõ, hard conflict không lưu. Teacher/resource conflicts chỉ áp dụng nếu model hiện có nguồn xác định; không tự giả mọi lớp của trung tâm dùng chung một giáo viên.

Thay N+1 query attendance/adjustment mỗi session bằng batch dependency load. Apply kiểm tra token/updatedAt lần nữa và thực hiện một transaction: version lịch + split phân ca + xử lý DU_KIEN an toàn + sinh replacement. Session generation phải có plan và executor transaction-aware; không gọi db ngoài txn trong callback transaction, không tạo vòng DI ScheduleService <-> GenerationService. Trích planner thuần hoặc orchestration riêng.

Không xóa session đã điểm danh/được adjustment tham chiếu; không thay lịch sử DA_HOC. Session NGHI_LE/HUY phải giữ nguyên sự kiện nghỉ/hủy hoặc reapply holiday rules sau sinh; không biến thành DU_KIEN và tính tiền trở lại. Dữ liệu trùng phải trả lỗi rõ, không báo thành công nếu generation conflictCount>0 mà chưa xử lý.

Sinh lại đúng phạm vi tháng đã sinh/bị ảnh hưởng, giới hạn bởi ngày đến; chạy lại không tạo trùng. Sau apply refresh schedule, sessions, roster, attendance lists, projected tuition, dashboard và kế hoạch nhắc giờ. Bottom sheet chỉ đóng sau thành công đầy đủ.

Test đổi from 01/07->02/08 khi chưa dùng; case đã điểm danh tháng7 thì từ chối sửa lịch sử và cho tạo version mới; đổi thứ/giờ; thêm/bỏ den; den<tu; tự overlap với chính mình không bị báo sai; overlap thật hiện tên/ngày/giờ; ca/membership split đúng; holiday giữ nguyên; lỗi giữa transaction rollback tất cả; generation chạy hai lần không nhân đôi.
```

## Phase 3 — Tính dự kiến đầu tháng theo học sinh, không theo điểm danh tương lai

```text
Giữ SessionCreditService.getEligibleSessionsForStudentClassMonth chỉ DA_HOC cho đối soát credit. Không đổi lọc này thành DU_KIEN+DA_HOC rồi gọi credit reconciliation: sẽ phát sinh tín chỉ/điểm danh giả.

Thêm eligibility service dùng chung cho tuition với hai chế độ PROJECTED/ACTUAL. PROJECTED lấy CHINH DU_KIEN hoặc DA_HOC trong tháng, loại HUY/NGHI_LE, lọc membership inclusive và đúng assignment/ca trên ngày buổi. Dùng roster semantics thống nhất; chuyển ca chỉ tính một quyền học ở lớp gốc, không tính hai lần ca gốc+ca ghép. HOC_BU bù cho buổi đã tính tiền không thu lần nữa; PHAT_SINH giữ quy tắc hiện hành, không tự áp giá mới.

Tạo TuitionService.previewProjectedTuition(studentId,classId,month) và previewActualTuition(...) (API mới), cùng pure calculator. Kết quả phải có mode, policyVersion, eligibleSessions, excludedReasons, discount, amountDue và readiness. Bản ACTUAL xử lý trạng thái điểm danh theo quy tắc nghỉ có phép; tháng chưa đủ dữ liệu thì báo incomplete, không trả finalized0.

PROJECTED đếm các buổi thuộc ca học sinh từ max(joinDate,monthStart,scheduleStart) tới min(leaveDate,monthEnd,scheduleEnd). Không nhân đơn giá cả lớp, không lấy số ngày tháng. Nếu thiếu phân ca/sinh buổi/policy, trả lỗi có hành động sửa, không biến thành0. Trước khi tạo chứng từ tạm thu, ensure generation coverage qua canonical generator; preview thuần không tự sinh hoặc ghi DB.

Sửa ClassMonthTuitionOverviewService.getOverview: gọi eligibility nhiều học sinh theo batch, có projectedAmount, actual/readiness, paid, remaining, overpaid riêng. Không sử dụng eligibleSessionsByStudent chỉ DA_HOC để kết luận dự kiến đầu tháng0. Không nhân N+1 roster/policy/payment queries theo mọi học sinh; batch sessions/memberships/assignments/adjustments/attendance.

Ngày tham gia/ca/lịch/holiday/discount đổi phải invalidate dự kiến. Đã có finalized invoice thì luôn hiện finalized snapshot + cờ cần đối soát lại khi input thay đổi; không ghi đè snapshot qua preview.

Test học sinh vào15/08 chỉ còn7 buổi; trước/sau membership boundary; hai ca không thu double; 2 holidays trùng lịch loại2, holiday không trùng lịch không trừ; canceled session; zero eligible thật; thiếu assignment khác zero; điều chỉnh đổi ca cùng/khác lớp vẫn tính lớp gốc một lần; preview không ghi ledger.
```

## Phase 4 — Tạm thu, phiếu thu, thu dư và đối soát cuối tháng

```text
Sửa InvoiceService.finalizeStudentInvoice/finalizeClassInvoices: đây là xác nhận ACTUAL cuối kỳ, không dùng để thu PROJECTED. Đổi tên UI thành Đối soát cuối tháng. Guard _validateEarlyMonthBillingGap chỉ phục vụ readiness actual; đặt tên mô tả đúng, không còn EARLY_MONTH_BILLING_ENGINE_GAP cho thao tác tạm thu.

Thêm upsertProvisionalStatement(student,class,month): ghi snapshot dự kiến/version, khóa unique student+class+month, giữ id/createdAt và payments khi cập nhật. Preview/generation/policy readiness phải hợp lệ trước khi ghi. Tạo statement và record payment an toàn về transaction/idempotency; kiểm tra revision trong transaction để không thu dựa dữ liệu đã đổi. Không lồng transaction hoặc gọi service dùng db ngoài txn gây lock.

PaymentService.recordPayment/updatePayment: cho provisional statement hợp lệ chứa payment; giữ liên kết và validate student/class/month. Không chỉ xóa if(!isFinalizedSnapshot), vì PaymentSettlementRules.evaluate/getValidatedPaymentsInDateRange đang từ chối cùng dữ liệu ở bước đọc.

PaymentSettlementRules.evaluate/deriveStatus: bỏ invariant “NHAP không có payments” sau migration lifecycle. Tính signedBalance=amountDue-totalPaid, remaining=max(signedBalance,0), overpaid=max(-signedBalance,0). Giữ relationship validation và duplicate transaction checks. Cho OVERPAID hợp lệ khi amountDue giảm sau receipt; không coi đây là DB corruption. Khi nhập thu mới vượt số cần thu, vẫn cảnh báo/xác nhận theo policy, không tự đổi tiền receipt.

Cập nhật InvoicePaymentSummary, TuitionInvoice status mapping, getPaymentSummary/getPaymentSummariesForInvoices/getValidatedPaymentsInDateRange và report consumers. Lifecycle finalized không được suy ra từ PAID hay PARTIAL. Doanh thu thực thu là giao dịch thực tế, không phải dự kiến.

Cuối tháng actual fee F, paid A: còn thu=max(F-A,0), thu dư=max(A-F,0). Không sửa amount/date của receipt khi tính lại F. Hoàn tiền/chuyển kỳ sau cần hành động và giao dịch liên kết rõ ràng, không tự chuyển tiền sang lớp khác hoặc biến tiền dư thành buoi_du. Nếu chưa triển khai thao tác hoàn/chuyển, vẫn phải hiển thị số thu dư chính xác và nói rõ chưa xử lý.

Đối soát lại sau sửa điểm danh dùng revision audit, giữ finalized snapshot cũ và receipt. Credit mutations earned/consumed/reversal idempotent theo event; không chốt lại rồi ghi thêm -1 cùng buổi. Không tự rút tín chỉ/tiền trong preview.

Đối soát từng học sinh: readiness theo những buổi thuộc quyền học của em đó; không để ca không liên quan của cả lớp chặn em. Cả lớp: preview danh sách em sẵn sàng/em thiếu dữ liệu với lý do. Chốt tập được chọn sẵn sàng trong transaction; không âm thầm bỏ em lỗi rồi báo cả lớp thành công.

Test thu đầu tháng khi tất cả buổi DU_KIEN; thu200k/315k còn115k; sửa/đối soát fee270k sau thu315k ra thu dư45k; read report không throw; provisional update giữ FK/payment; double tap không double receipt; đối soát lặp không double credit; rollback giữa lớp; invoice cũ vẫn đọc đúng; sửa receipt ngày giữ giá trị người dùng nhập và audit.
```

## Phase 5 — QR, thông báo phụ huynh, refresh và hướng dẫn

```text
ParentTuitionSlipService.generateSlip: bỏ nhánh mặc định noInvoiceFinalized đối với provisional hợp lệ. Không tự đếm buổi rồi dùng formula riêng; gọi canonical projected/actual statement service. Finalized dùng snapshot; provisional thể hiện “Học phí dự kiến tháng ...”, số buổi dự kiến hợp lệ, nghỉ lễ đã loại, miễn giảm, phải thu dự kiến, đã thu và còn cần thu. Ngày tính/version giúp tránh nhầm thông báo cũ.

QR chỉ số còn cần thu, không tổng tiền nếu đã thu một phần. Nếu cònthu0 hoặc thudư>0 thì không tạo QR thu tiếp. Không có bank/policy/schedule/coverage/assignment thì hiển thị lỗi xử lý được, không QR0. Attendance tháng trước là thông tin đối chiếu riêng, không tự trừ lần hai vào tháng mới.

Sửa RecordPaymentBottomSheet (lib/features/payments/presentation/record_payment_bottom_sheet.dart), tuition_controller.dart, class detail và tuition pages: “Tạm thu đầu tháng”, “Đối soát cuối tháng”; phân biệt Dự kiến/Đã thu/Còn thu/Thu dư/Chưa đủ dữ liệu. Không gọi finalize trước record payment nữa. Không dùng từ còn nợ trên UI mới.

Sau payment/attendance/schedule/membership/discount/policy/holiday write, invalidate provider family đúng lớp/tháng và affected months; phải gồm classMonthTuitionOverviewProvider, tuitionPreviewControllerProvider, parent slip, invoice/payment summary, dashboard và report. Centralize invalidation sau domain commit thành công; lỗi transaction không invalidate để giả thành công. Dùng tên provider thực tế đang tồn tại, regenerate nếu thêm mới.

Cập nhật trang hướng dẫn hiện có: cấu hình chung; ngày áp dụng giá; thêm ngày tham gia; phân ca; sinh lịch; nghỉ lễ; tạm thu; điểm danh; đối soát; giải quyết còn thu/thu dư; sửa lịch có history. Ví dụ12buổi540k và7buổi315k có giảm10%. Giải thích buổi dư khác tiền thu dư, và không bắt buộc chốt trước khi thu.

Hot reload sau thay UI; test bottom sheets không overflow tại màn hình hẹp/font lớn, thông báo lỗi còn thấy sau validation, màn hình tự cập nhật không cần chuyển tab.
```

## Phase 6 — Kiểm chứng, build và bàn giao

```text
Chạy format/analyze, unit tests calculator/eligibility/payment/credit/schedule/migration, widget tests mới cần thiết cho form/routing. Chạy toàn suite theo AGENTS. Không xóa test cũ đang fail để đạt xanh; phân loại test cần cập nhật vì quy tắc mới và lỗi thật.

flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter devices
flutter run -d <emulator_id>

Máy ảo: cấu hình chung12/50k/600k -> tạo lớp không hỏi giá -> tạo lịch from/to -> phân2ca -> thêm học sinh15/08 giảm10% -> sinh7buổi hợp lệ -> dự kiến315k -> tạoQR -> thu200k -> còn115k -> hoàn tất điểm danh -> đối soát -> giữ receipt200k. Kiểm tra case thu315k rồi phí actual270k hiển thị dư45k. Sửa lịch preview conflict rõ và sinh lại, app không mất học sinh/attendance. Đóng mở app giữ kết quả và notifications theo lịch mới.

Upgrade test với bản DB cũ có dữ liệu trước khi dùng clean/new DB. Kiểm tra cả release popup thu tiền/QR và refresh sau attendance. Hot reload không xác nhận được behavior native trong release: phải build/cài release và test lại.

Commit từng phase, push branch sửa, cung cấp SHA, danh sách hàm sửa, migration, test thực chạy/kết quả, APK path và phần chưa kiểm chứng. Viết PR mô tả final behavior và validation, không merge tự động.
```

## 4. Thứ tự ưu tiên

1. Định nghĩa chính sách chung và bảo toàn dữ liệu.
2. Calculator + eligibility dự kiến (giải quyết phí0 khi chưa có điểm danh).
3. Tạm thu/QR/payment/thu dư (giải quyết không thu được đầu tháng).
4. Sửa lịch theo preview + transaction (tránh làm mất cơ sở tính học phí).
5. Đối soát, refresh, báo cáo và hướng dẫn; kiểm chứng nâng cấp và release.

Các phase được đánh số theo phụ thuộc triển khai; có thể viết test đặc tả toàn bộ từ đầu. Không phát hành app ở trạng thái chỉ bỏ guard mà chưa cập nhật settlement rules và reports.
