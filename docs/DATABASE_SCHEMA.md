# TUITION2027 - CANONICAL SQLITE SCHEMA

> Business contract revision: 2026-09-30. This document specifies the new target behavior: center-wide pricing, beginning-of-month provisional collection, and end-of-month reconciliation. New APIs/schema below are requirements, not a claim that they are already implemented. Update `TUITION2027_DOMAIN_CONSTITUTION.md` consistently before implementation. Preserve legacy invoice/policy/payment history.

## 1. Purpose

This document defines the logical canonical SQLite schema for the rebuilt Tuition2027 data core.

It is the persistence counterpart of `TUITION2027_DOMAIN_CONSTITUTION.md`.

Names below are canonical. Do not introduce parallel aliases for the same concept.

## 2. General conventions

### IDs

Use integer local primary keys for SQLite operational relationships.

Later cloud sync may add stable sync identifiers without replacing local relational keys.

### Dates

Date only: `YYYY-MM-DD`.

Month: `YYYY-MM`.

Time of day: `HH:mm`.

### Timestamps

Use ISO-8601 timestamps for `created_at`, `updated_at`, and finalized/audit timestamps.

### Soft delete/archive

Students/classes use archive flags rather than destructive deletion after history exists.

## 3. `hoc_sinh`

Purpose: person/profile data only.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `ho_ten TEXT NOT NULL`
- `ngay_sinh TEXT NULL`
- `gioi_tinh TEXT NULL`
- `ten_phu_huynh TEXT NULL`
- `sdt_phu_huynh TEXT NULL`
- `sdt_hoc_sinh TEXT NULL`
- `email TEXT NULL`
- `truong_dang_hoc TEXT NULL`
- `khoi INTEGER NULL`
- `dia_chi TEXT NULL`
- `facebook TEXT NULL`
- `ghi_chu TEXT NULL`
- `zalo_user_id TEXT NULL`
- `zalo_display_name TEXT NULL`
- `zalo_link_status TEXT NOT NULL DEFAULT 'CHUA_LIEN_KET'`
- `da_luu_tru INTEGER NOT NULL DEFAULT 0`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Constraints:

- `da_luu_tru IN (0,1)`
- parent phone is NOT UNIQUE

Indexes:

- name
- normalized parent phone if a separate normalized lookup column is used

Must not contain:

- class membership
- join date
- global credit balance
- current debt

## 4. `lop`

School name suggestions are stored in `truong_hoc(id, ten UNIQUE COLLATE NOCASE, created_at)` from schema v16. Existing nonempty `hoc_sinh.truong_dang_hoc` values are copied into this catalog on upgrade. The student's school remains a text snapshot so removing a suggestion never erases historical student data.

Purpose: class identity/metadata.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `ten_lop TEXT NOT NULL`
- `khoi INTEGER NULL`
- `mon_hoc TEXT NULL`
- `si_so_toi_da INTEGER NULL`
- `ghi_chu TEXT NULL`
- `da_luu_tru INTEGER NOT NULL DEFAULT 0`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Optional uniqueness on active class naming should be a product decision; do not rely on class name as identity.

Do not store current class size as truth.

## 5. `tham_gia_lop`

Purpose: membership intervals.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `id_lop INTEGER NOT NULL`
- `tu_ngay TEXT NOT NULL`
- `den_ngay TEXT NULL`
- `ly_do_ket_thuc TEXT NULL`
- `mien_giam_phan_tram INTEGER NOT NULL DEFAULT 0`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Foreign keys:

- `id_hoc_sinh -> hoc_sinh.id`
- `id_lop -> lop.id`

Constraints:

- `den_ngay IS NULL OR den_ngay >= tu_ngay`
- `mien_giam_phan_tram BETWEEN 0 AND 100`
- unique `(id_hoc_sinh, id_lop, tu_ngay)`
- partial unique open interval `(id_hoc_sinh, id_lop) WHERE den_ngay IS NULL`

Indexes:

- `(id_lop, tu_ngay, den_ngay)`
- `(id_hoc_sinh, tu_ngay, den_ngay)`

## 6. Tuition policy storage

### 6.1 Legacy `chinh_sach_hoc_phi` — retain historical references

Existing class-specific policy data and invoice foreign keys must remain readable. Existing columns include id, id_lop, hieu_luc_tu/den, so_buoi_chuan_thang, hoc_phi_moi_buoi, hoc_phi_thang_toi_da, quy_tac_nghi_co_phep, ghi_chu, created_at, updated_at. Existing v17 absence vocabulary is `buTruBuoiDu`, `tinhPhi`, `khongTinhPhi`.

This is no longer the operational policy source for new center-policy periods. Do not drop this table, delete referenced rows, or create per-class policies for newly created classes.

### 6.2 Proposed `center_tuition_policy` — NOT YET IMPLEMENTED

One effective policy applies to all classes/grades. Proposed physical name is an implementation target; verify the actual database before choosing the next migration version.

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `effective_from_month TEXT NOT NULL` — YYYY-MM
- `effective_to_month TEXT NULL` — inclusive, YYYY-MM; null=open-ended
- `standard_sessions INTEGER NOT NULL`
- `unit_price INTEGER NOT NULL` — integer VND
- `monthly_cap INTEGER NULL` — integer VND
- `excused_absence_rule TEXT NOT NULL`
- `note TEXT NULL`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Constraints: N>0; P>=0; C null or>=0; valid month format; end>=start; recognized absence rule. Unique effective start and at most one open policy; interval overlap prevention must cover finite intervals too. Do not add id_lop or a new-class pricing override.

Policy boundaries are monthly. Store the selected version and pricing snapshot in statements; old snapshots do not resolve today's settings. Different legacy class prices require explicit setup, not automatic choice of the first record.

## 7. `lich_hoc`

Purpose: recurring class schedule.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_lop INTEGER NOT NULL`
- `thu_trong_tuan INTEGER NOT NULL`
- `gio_bat_dau TEXT NOT NULL`
- `gio_ket_thuc TEXT NOT NULL`
- `hieu_luc_tu TEXT NOT NULL`
- `hieu_luc_den TEXT NULL`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Constraints:

- weekday between 1 and 7, Monday..Sunday
- end time > start time
- effective end >= start

Suggested uniqueness:

`(id_lop, thu_trong_tuan, gio_bat_dau, hieu_luc_tu)`

## 8. `phan_ca_hoc_sinh`

Purpose: student assignment to a recurring schedule/shift.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `id_lop INTEGER NOT NULL`
- `id_lich_hoc INTEGER NOT NULL`
- `tu_ngay TEXT NOT NULL`
- `den_ngay TEXT NULL`
- `nguon TEXT NULL`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

The referenced schedule must belong to `id_lop`.

Assignment must not silently outlive membership or schedule validity. Intervals are inclusive and may start after membership start; exact equality with join date is not required. Schedule revisions preview and atomically trim/split assignments to the intersection of the valid intervals; an empty intersection needs explicit resolution.

Indexes:

- `(id_hoc_sinh, tu_ngay, den_ngay)`
- `(id_lich_hoc, tu_ngay, den_ngay)`

## 9. `buoi_hoc`

Purpose: actual/planned dated session.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_lop INTEGER NOT NULL`
- `id_lich_hoc INTEGER NULL`
- `ngay TEXT NOT NULL`
- `gio_bat_dau TEXT NOT NULL`
- `gio_ket_thuc TEXT NOT NULL`
- `loai TEXT NOT NULL`
- `trang_thai TEXT NOT NULL DEFAULT 'DU_KIEN'`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Canonical type:

- `CHINH`
- `HOC_BU`
- `PHAT_SINH`

Canonical status:

- `DU_KIEN`
- `DA_HOC`
- `HUY`
- `NGHI_LE`

Suggested uniqueness:

`(id_lop, ngay, gio_bat_dau)`

Indexes:

- `(id_lop, ngay)`
- `(id_lich_hoc, ngay)`

## 10. `don_nghi_hoc`

Purpose: requested/approved leave interval.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `id_lop INTEGER NOT NULL`
- `tu_ngay TEXT NOT NULL`
- `den_ngay TEXT NOT NULL`
- `ly_do TEXT NULL`
- `trang_thai TEXT NOT NULL DEFAULT 'CHO_DUYET'`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Statuses:

- `CHO_DUYET`
- `DA_DUYET`
- `TU_CHOI`

Approved leave may influence attendance draft, not replace attendance records.

## 11. `dieu_chinh_buoi_hoc`

Purpose: one-off session participation exception.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `id_lop_goc INTEGER NOT NULL`
- `id_buoi_hoc_goc INTEGER NULL`
- `id_buoi_hoc_tham_gia INTEGER NOT NULL`
- `loai TEXT NOT NULL`
- `ly_do TEXT NULL`
- `created_at TEXT NOT NULL`

Types:

- `DOI_CA`
- `HOC_BU`
- `PHAT_SINH`

Does not modify recurring schedule assignment.

## 12. `diem_danh`

Purpose: final attendance record per student/session.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_buoi_hoc INTEGER NOT NULL`
- `id_hoc_sinh INTEGER NOT NULL`
- `id_lop_goc INTEGER NOT NULL`
- `trang_thai TEXT NOT NULL`
- `loai_tham_gia TEXT NOT NULL DEFAULT 'CHINH'`
- `id_buoi_vang_goc INTEGER NULL`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Statuses:

- `CO_MAT`
- `TRE`
- `NGHI_CO_PHEP`
- `NGHI_KHONG_PHEP`
- `HOC_BU`

Participation types:

- `CHINH`
- `DOI_CA`
- `HOC_BU`

Unique:

`(id_buoi_hoc, id_hoc_sinh)`

Missing row is `CHUA_DIEM_DANH` in application state, not a persisted attendance status.

## 13. Superseded logical proposal: `lich_can`

This older logical proposal is not an instruction to create a second schedule-constraint table. Section18 `rang_buoc_lich_hoc_sinh` describes the implemented v13 constraint vocabulary. Verify the actual repository/schema before migration; if a real legacy lich_can exists, retain/map it explicitly without dropping history. New domain consumers use one canonical constraint repository.

## 14. `buoi_du_ledger`

Purpose: auditable session-credit ledger.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `id_lop INTEGER NOT NULL`
- `id_buoi_hoc INTEGER NULL`
- `ngay_hieu_luc TEXT NOT NULL`
- `delta INTEGER NOT NULL`
- `ly_do TEXT NOT NULL`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`

Reasons:

- `VUOT_SO_BUOI_CHUAN` (requires `id_buoi_hoc NOT NULL` and `delta = 1`)
- `BU_TRU_NGHI_CO_PHEP` (requires `id_buoi_hoc NOT NULL` and `delta = -1`)
- `DIEU_CHINH_THU_CONG` (requires `delta != 0`)
- `MIGRATION` (requires `delta != 0`)

Balance:

`SUM(delta)` grouped by student + class.

Prevent duplicate automated events with a partial unique index such as:

`(id_hoc_sinh, id_lop, id_buoi_hoc, ly_do) WHERE id_buoi_hoc IS NOT NULL`

## 15. `hoc_phi_thang` — legacy fields and revised target

Purpose: monthly tuition invoice/snapshot.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `id_lop INTEGER NOT NULL`
- `thang TEXT NOT NULL`
- `id_chinh_sach_hoc_phi INTEGER NOT NULL` in legacy schema; revised target nullable for center-policy statements, keeping legacy FK for historical rows
- `so_buoi_eligible INTEGER NOT NULL`
- `so_buoi_du_kien INTEGER NOT NULL DEFAULT 0`
- `so_buoi_tinh_phi INTEGER NOT NULL`
- `credit_opening INTEGER NOT NULL`
- `credit_earned INTEGER NOT NULL`
- `credit_used INTEGER NOT NULL`
- `credit_closing INTEGER NOT NULL`
- `tong_truoc_giam INTEGER NOT NULL`
- `giam_phan_tram INTEGER NOT NULL DEFAULT 0`
- `giam_so_tien INTEGER NOT NULL DEFAULT 0`
- `so_tien_phai_thu INTEGER NOT NULL`
- `trang_thai TEXT NOT NULL`
- `chot_luc TEXT NULL`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Legacy statuses (preserve and migrate explicitly): `NHAP`, `DA_CHOT`, `DA_THANH_TOAN`, `CON_NO`.

Proposed additive target fields — NOT YET IMPLEMENTED:

- `id_center_tuition_policy INTEGER NULL` -> center_tuition_policy.id
- `lifecycle TEXT NOT NULL` -> PROVISIONAL / FINALIZED
- `settlement_status TEXT NOT NULL` -> UNPAID / PARTIAL / PAID / OVERPAID
- `revision INTEGER NOT NULL` and `needs_reconciliation INTEGER NOT NULL DEFAULT 0`
- pricing snapshot: standard_sessions, unit_price, monthly_cap, excused_absence_rule
- separately identified projected and reconciled amounts/counts; reconciled values may be null until verified
- `calculated_at`, `reconciled_at` and source revision/fingerprint for stale-plan checks

An active statement references exactly one policy source (legacy or center); historical snapshot pricing must be reconstructable. Rebuild legacy NOT NULL/CHECK constraints via forward migration if necessary, copying all data and checking FK integrity. Never use a fake legacy policy ID for a new center statement.

Map NHAP -> PROVISIONAL; DA_CHOT/DA_THANH_TOAN/CON_NO -> FINALIZED. Derive settlement status from canonical payments. Do not infer finalization from paid status.

Store immutable revisions/snapshots with explicit provenance in a child table such as hoc_phi_thang_revision; unique(statement_id,revision), foreign key ON DELETE RESTRICT. Its exact DDL must be documented alongside the migration. Retain prior finalized amounts and details during correction.

Unique:

`(id_hoc_sinh, id_lop, thang)`

Once finalized, historical snapshots do not silently change. Corrections create an explicit auditable revision. One stable monthly statement ID owns payment links; provisional updates and final reconciliation must not delete/reinsert it.

Money formula: gross=min(q,N)*P; cappedBase=min(gross,C) when C exists; discount=floor(cappedBase*d/100); due=cappedBase-discount. Store gross, capped base and discount with consistent meaning. q differs between projected schedule eligibility and actual attendance eligibility; future attendance is never invented.

## 16. `thanh_toan`

Purpose: actual received money.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `id_lop INTEGER NOT NULL`
- `id_hoc_phi_thang INTEGER NULL`
- `thang TEXT NOT NULL`
- `so_tien INTEGER NOT NULL`
- `ngay_thanh_toan TEXT NOT NULL`
- `phuong_thuc TEXT NOT NULL`
- `ma_giao_dich TEXT NULL`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`

Methods:

- `TIEN_MAT`
- `CHUYEN_KHOAN`
- `KHAC`

Constraints:

- amount > 0
- partial unique `ma_giao_dich` when non-empty

A valid provisional statement may have receipts before final reconciliation. Receipt identity, received amount and actual payment date remain stable when fees change. Receipt edits need an audit trail/updated timestamp in the revised schema.

Derived balance is not stored as independent truth here. For valid receipts A and active amount F: remaining=max(F-A,0), overpaid=max(A-F,0). Overpayment after a fee reduction is a legitimate business state, not automatically corruption. Duplicate transaction IDs and relationship mismatches remain errors.

Refunds/carry-forward require separate explicit monetary records linked to their source and destination; do not represent them as negative receipt rows under the existing CHECK(amount>0), or as buoi_du_ledger entries. Their DDL and accounting rules need a dedicated migration before enabling those actions.

## 17. `thong_bao`

Purpose: notification delivery/audit record, not business truth.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NULL`
- `id_lop INTEGER NULL`
- `loai TEXT NOT NULL`
- `kenh TEXT NOT NULL`
- `nguoi_nhan TEXT NULL`
- `noi_dung TEXT NOT NULL`
- `trang_thai TEXT NOT NULL`
- `scheduled_at TEXT NULL`
- `sent_at TEXT NULL`
- `error_message TEXT NULL`
- `created_at TEXT NOT NULL`

Examples of type:

- absence
- urgent notice
- tuition reminder
- exam/grade notice

## 18. `rang_buoc_lich_hoc_sinh` (Database Version 13)

Purpose: student schedule availability constraints, hard blocks, soft preferences, and external center commitments.

Columns:
- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `loai TEXT NOT NULL`
- `kieu TEXT NOT NULL`
- `thu_trong_tuan INTEGER NULL`
- `ngay_cu_the TEXT NULL`
- `gio_bat_dau TEXT NOT NULL`
- `gio_ket_thuc TEXT NOT NULL`
- `hieu_luc_tu TEXT NULL`
- `hieu_luc_den TEXT NULL`
- `travel_buffer_phut INTEGER NOT NULL DEFAULT 0`
- `ten_nguon TEXT NULL`
- `ghi_chu TEXT NULL`
- `trang_thai TEXT NOT NULL DEFAULT 'HOAT_DONG'`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Constraints:
- Foreign key: `FOREIGN KEY (id_hoc_sinh) REFERENCES hoc_sinh(id) ON DELETE RESTRICT`
- `CHECK (loai IN ('HARD_BLOCK', 'SOFT_PREFERENCE', 'OTHER_CENTER'))`
- `CHECK (kieu IN ('DINH_KY', 'MOT_LAN'))`
- `CHECK (trang_thai IN ('HOAT_DONG', 'DA_HUY'))`
- `CHECK ((gio_bat_dau GLOB '[0-1][0-9]:[0-5][0-9]' OR gio_bat_dau GLOB '2[0-3]:[0-5][0-9]') AND (gio_ket_thuc GLOB '[0-1][0-9]:[0-5][0-9]' OR gio_ket_thuc GLOB '2[0-3]:[0-5][0-9]') AND gio_ket_thuc > gio_bat_dau)`
- `CHECK ((ngay_cu_the IS NULL OR (ngay_cu_the GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]' AND CAST(substr(ngay_cu_the, 6, 2) AS INTEGER) BETWEEN 1 AND 12 AND CAST(substr(ngay_cu_the, 9, 2) AS INTEGER) BETWEEN 1 AND 31)) AND (hieu_luc_tu IS NULL OR (hieu_luc_tu GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]' AND CAST(substr(hieu_luc_tu, 6, 2) AS INTEGER) BETWEEN 1 AND 12 AND CAST(substr(hieu_luc_tu, 9, 2) AS INTEGER) BETWEEN 1 AND 31)) AND (hieu_luc_den IS NULL OR (hieu_luc_den GLOB '[0-9][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]' AND CAST(substr(hieu_luc_den, 6, 2) AS INTEGER) BETWEEN 1 AND 12 AND CAST(substr(hieu_luc_den, 9, 2) AS INTEGER) BETWEEN 1 AND 31)))`
- `CHECK ((kieu = 'DINH_KY' AND thu_trong_tuan BETWEEN 1 AND 7 AND ngay_cu_the IS NULL AND hieu_luc_tu IS NOT NULL AND (hieu_luc_den IS NULL OR hieu_luc_den >= hieu_luc_tu)) OR (kieu = 'MOT_LAN' AND ngay_cu_the IS NOT NULL AND thu_trong_tuan IS NULL AND hieu_luc_tu IS NULL AND hieu_luc_den IS NULL))`
- `CHECK (travel_buffer_phut >= 0)`

Indexes:
- `idx_rang_buoc_student_status ON rang_buoc_lich_hoc_sinh (id_hoc_sinh, trang_thai)`
- `idx_rang_buoc_student_date ON rang_buoc_lich_hoc_sinh (id_hoc_sinh, ngay_cu_the)`

## 19. Migration support tables

### `import_run`

Tracks importer execution and source fingerprint.

### `migration_issue`

Tracks ambiguity/errors for manual review.

These are support tables, not core business entities.

## 20. Recommended views/read models

Views may improve reporting, but must remain derived.

Examples:

### `v_so_buoi_du`

Group ledger by student + class and sum delta.

### `v_thanh_toan_thang`

Group payment totals by student + class + month.

### `v_cong_no_thang`

Expose signedBalance=statementAmount-paymentTotal, remainingToCollect=max(signedBalance,0), overpaid=max(-signedBalance,0), and lifecycle/mode. A single positive-debt total must not hide overpayment or mix projected with finalized fees.

Do not update these views as independent sources of truth.

## 21. Foreign-key deletion policy

Default for historical entities should be restrictive/no-action rather than cascading deletion.

Students/classes with history are archived.

Cascade may be acceptable only for truly owned ephemeral children with no historical/audit value, and must be justified explicitly.

## 22. Schema change policy

Every schema change requires:

- forward migration
- migration test
- data-integrity check
- compatibility assessment
- updated schema document

Never patch production schema ad hoc from a screen/service.

## 23. Schema documentation and rollout boundary

This file contains legacy implemented fields and explicitly marked proposed changes. It does not certify that a migration has run. Read app_database.dart and existing migrations to determine the actual version; do not reuse v13 as the current version or assume v17 is the latest.

Update the domain constitution before implementation. Record the final implemented DDL, indexes, constraints, migration version and tests after each schema change. Preserve student/class IDs, memberships/discounts, schedule/attendance history, credit ledger and all payment totals. Schedule changes protect historical references and regenerate only safe planned sessions atomically.
