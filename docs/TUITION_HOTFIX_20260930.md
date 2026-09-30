# Tuition runtime hotfix — 30/09/2026

Base: feature/tuition-schedule-audit-20260930 at 87de5ccabdeffda0332809f78fc69c62c4928e15.

## Fixed

- TuitionService.calculatePreviewFromResolvedData copied caller-owned holidaySessions before sorting. The default const[] caused Unsupported operation: Cannot modify an unmodifiable list even with no holidays. Immutable nonempty lists also work without mutation.
- ClassMonthTuitionStudentRow centralizes known amount, paid state and collection label. An error/no preview does not mean paid; zero fee is labeled no charge, not received money.
- ClassTuitionTab uses canonical filter predicates, shows unknown as a dash, retains unresolved students in the action list and explains pendingReason in the details sheet. Collection actions require the currently supported finalized invoice, avoiding a guaranteed PaymentService rejection.
- Class overview checks planned sessions through canonical roster eligibility and marks actual reconciliation incomplete per student. It no longer treats an empty completed-session list while eligible planned sessions exist as a ready zero invoice.
- No schema migration, ledger/payment mutation or historical invoice rewrite in this hotfix.

## Verification

Flutter 3.47.5 / Dart 3.13.4. flutter analyze --no-pub: no issues. TuitionService + calculator tests: 12 passed. Focused performance/read-model regression: 4 passed (repeat after final readiness change required in handoff result).

The preexisting full performance widget test stalls during pumpAndSettle; the complete file was not certified. Android SDK/emulator unavailable here. No debug/release APK or Android hot reload verification claimed.

## Remaining business implementation — not completed by Phase 2 or this hotfix

Center policy schema exists, but TuitionInvoice still requires legacy policy ID and services still use preview.policy.id!. Center policy/legacy precedence and policy snapshot links must be completed before center-only finalization. Do not supply a center ID as a legacy foreign key.

Projected beginning-of-month statements, payment on provisional invoices, parent QR for the remaining projected balance, and overpaid monetary settlement are not yet implemented end-to-end. Do not merely remove payment guards; migrate all validators/models/reports and keep receipt/FK/history invariants. Follow RA_SOAT_HOC_PHI_LICH_HOC_PROMPT_CODEX.md phases R3–R5 after this correction.

## Codex update and Android verification

Fetch the fix branch, merge/cherry-pick onto your latest feature branch without discarding local changes. Run flutter pub get, flutter analyze, targeted tests, then flutter run -d <android_device>. Hot reload after UI edits; restart where needed. Reopen Tuition and Class tuition tabs: no unmodifiable-list error; unknown amounts show dash and pending reason, never green paid0. Verify real attendance and assigned shifts produce fee; partial/full payment filters agree. Then build debug/release and verify release menus. Keep database; do not uninstall/clear app data.
