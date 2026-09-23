# DATABASE SCHEMA DESIGN

This document describes the canonical SQLite database structure for Tuition2027.

## 1. `hoc_sinh`

Purpose: canonical student master table.

Columns:
- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `ho_ten TEXT NOT NULL`
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

## 2. `lop`

Purpose: canonical class master table.

Columns:
- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `ten_lop TEXT NOT NULL`
- `khoi INTEGER NULL`
- `mon_hoc TEXT NULL`
- `si_so_toi_da INTEGER NULL`
- `ghi_chu TEXT NULL`
- `da_luu_tru INTEGER NOT NULL DEFAULT 0`
- `created_at TEXT NOT NULL`
- `updated_at TEXT NOT NULL`

## 3. `tham_gia_lop`

Purpose: class membership history per student.

Columns:
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

## 4. `lich_hoc`

Purpose: recurring schedule rule per class.

Columns:
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

## 5. `phan_ca_hoc_sinh`

Purpose: student shift assignment to recurring schedule.

Columns:
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

## 6. `buoi_hoc`

Purpose: dated actual/planned sessions.

Columns:
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

## 7. `diem_danh`

Purpose: attendance record per student/session.

Columns:
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

## 8. `don_nghi_hoc`

Purpose: leave request records.

Columns:
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

## 9. `dieu_chinh_buoi_hoc`

Purpose: one-off session adjustments (Đổi ca, Học bù, Phát sinh).

Columns:
- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `id_lop_goc INTEGER NOT NULL`
- `id_buoi_hoc_goc INTEGER NULL`
- `id_buoi_hoc_tham_gia INTEGER NOT NULL`
- `loai TEXT NOT NULL`
- `ly_do TEXT NULL`
- `created_at TEXT NOT NULL`

## 10. `buoi_du_ledger`

Purpose: session credit ledger entries.

Columns:
- `id INTEGER PRIMARY KEY AUTOINCREMENT`
- `id_hoc_sinh INTEGER NOT NULL`
- `id_lop INTEGER NOT NULL`
- `id_buoi_hoc INTEGER NULL`
- `ngay_hieu_luc TEXT NOT NULL`
- `delta INTEGER NOT NULL`
- `ly_do TEXT NOT NULL`
- `ghi_chu TEXT NULL`
- `created_at TEXT NOT NULL`

## 11. `chinh_sach_hoc_phi`

Purpose: monthly tuition policies per class.

Columns:
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

## 12. `hoc_phi_thang`

Purpose: monthly tuition invoice snapshots.

Columns:
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

## 13. `thanh_toan` (Database v12)

Purpose: actual payment transaction records.

Columns:
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

Constraints:
- Foreign keys: `id_hoc_sinh -> hoc_sinh(id) ON DELETE RESTRICT`, `id_lop -> lop(id) ON DELETE RESTRICT`, `id_hoc_phi_thang -> hoc_phi_thang(id) ON DELETE RESTRICT`
- `so_tien > 0`
- `phuong_thuc IN ('TIEN_MAT', 'CHUYEN_KHOAN', 'KHAC')`
- Partial UNIQUE index on non-empty `ma_giao_dich`

## 14. `rang_buoc_lich_hoc_sinh` (Database v13)

Purpose: student availability constraints (hard blocks, soft preferences, and other center class commitments).

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
- Foreign key: `id_hoc_sinh -> hoc_sinh(id) ON DELETE RESTRICT`
- `loai IN ('HARD_BLOCK', 'SOFT_PREFERENCE', 'OTHER_CENTER')`
- `kieu IN ('DINH_KY', 'MOT_LAN')`
- `gio_ket_thuc > gio_bat_dau`
- `travel_buffer_phut >= 0`
- `trang_thai IN ('HOAT_DONG', 'DA_HUY')`
