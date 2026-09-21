# TUITION2027 - CANONICAL SQLITE SCHEMA

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

## 6. `chinh_sach_hoc_phi`

Purpose: effective-dated class tuition policy.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_lop INTEGER NOT NULL`
- `hieu_luc_tu TEXT NOT NULL`
- `hieu_luc_den TEXT NULL`
- `so_buoi_chuan_thang INTEGER NOT NULL DEFAULT 12`
- `hoc_phi_moi_buoi INTEGER NOT NULL DEFAULT 0`
- `hoc_phi_thang_toi_da INTEGER NULL`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Constraints:

- standard sessions > 0
- fees >= 0
- effective end >= start when present

Avoid overlapping active policies for the same class.

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

Assignment must not silently outlive membership.

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

## 13. `lich_can`

Purpose: recurring or one-off student constraints/preferences.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `loai TEXT NOT NULL`
- `muc_do TEXT NOT NULL`
- `thu_trong_tuan INTEGER NULL`
- `ngay_cu_the TEXT NULL`
- `gio_bat_dau TEXT NOT NULL`
- `gio_ket_thuc TEXT NOT NULL`
- `hieu_luc_tu TEXT NULL`
- `hieu_luc_den TEXT NULL`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

Types:

- `HOC_CHINH_KHOA`
- `HOC_MON_KHAC`
- `LOP_KHAC_TRUNG_TAM`
- `BAN_CA_NHAN`
- `DI_CHUYEN`
- `NGUYEN_VONG`

Severity:

- `CUNG`
- `MEM`

Use either weekday-based recurrence or specific date according to the domain rule.

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

- `VUOT_SO_BUOI_CHUAN`
- `BU_TRU_NGHI_CO_PHEP`
- `DIEU_CHINH_THU_CONG`
- `MIGRATION`

Balance:

`SUM(delta)` grouped by student + class.

Prevent duplicate automated events with a partial unique index such as:

`(id_hoc_sinh, id_lop, id_buoi_hoc, ly_do) WHERE id_buoi_hoc IS NOT NULL`

## 15. `hoc_phi_thang`

Purpose: monthly tuition invoice/snapshot.

Suggested columns:

- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `id_lop INTEGER NOT NULL`
- `thang TEXT NOT NULL`
- `id_chinh_sach_hoc_phi INTEGER NOT NULL`
- `so_buoi_eligible INTEGER NOT NULL`
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

Statuses:

- `NHAP`
- `DA_CHOT`
- `DA_THANH_TOAN`
- `CON_NO`

Unique:

`(id_hoc_sinh, id_lop, thang)`

Once finalized, historical amounts do not silently change. Corrections must be explicit adjustments/re-finalization flow.

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

Debt is not stored here.

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

## 18. Migration support tables

### `import_run`

Tracks importer execution and source fingerprint.

### `migration_issue`

Tracks ambiguity/errors for manual review.

These are support tables, not core business entities.

## 19. Recommended views/read models

Views may improve reporting, but must remain derived.

Examples:

### `v_so_buoi_du`

Group ledger by student + class and sum delta.

### `v_thanh_toan_thang`

Group payment totals by student + class + month.

### `v_cong_no_thang`

Invoice due minus payment totals.

Do not update these views as independent sources of truth.

## 20. Foreign-key deletion policy

Default for historical entities should be restrictive/no-action rather than cascading deletion.

Students/classes with history are archived.

Cascade may be acceptable only for truly owned ephemeral children with no historical/audit value, and must be justified explicitly.

## 21. Schema change policy

Every schema change requires:

- forward migration
- migration test
- data-integrity check
- compatibility assessment
- updated schema document

Never patch production schema ad hoc from a screen/service.
