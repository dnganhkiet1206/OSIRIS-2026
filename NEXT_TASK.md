# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Nợ đang cháy (song song):**
> - **API key THƯỜNG TRỰC** → mở **M7 provider-side** (tối ưu token/latency/cost qua Gateway). Key một-lần đã thu sàn provider (§4j); cần key thường trực cho baseline qua-Gateway nhiều sample. Set env/secret, KHÔNG dán chat.
> - **CI macOS:** UI đã xác thực Mac thật (§4i, nợ High RETIRED). CI giữ chống regression; run đỏ → dán `error:`.

## Trạng thái

- **M7-0 ✅** (baseline nội bộ + provider sàn, quyết KHÔNG tối ưu — §4j). M7 provider-side HOÃN chờ key thường trực.
- **M8-0 ✅** (Core contract test coverage — §4k): 2 test canh property thật; từ chối resilience suy đoán (write đã atomic).
- **M8-1 ✅** (Security review — §4l): sửa Keychain thiếu `kSecAttrAccessible`; thêm test "error không lộ key/body".
- **M8-2 ✅** (Backup & Recovery review — §4m): audit 6 ưu tiên → **KHÔNG lỗ hổng**; backup = copy thư mục Store, không cần manager/engine; 0 dòng đổi. Ghi 3 trigger (fsync, Store-level dangling test, migration discipline).

## Current Task — CHỜ USER CHỌN task M8 kế (KHÔNG tự mở)

M8 Production Readiness còn các mảnh sau; **mỗi phiên làm ĐÚNG MỘT**, Architecture Review trước code, chỉ đổi khi có bằng chứng:

1. **Crash recovery (khôi phục tiến độ dở)** — write đã atomic (record-level, §4k); persist data-trước-index an toàn (§4m). Phần còn lại: một goal đang chạy mà app chết giữa chừng → lần mở lại có nối lại/nhận biết không? **Cần bằng chứng đây là vấn đề thật trước khi thêm code** (rất có thể kết luận "no-hole" như M8-2).
2. **Docs review** — rà tài liệu lệch thực tế (Linux làm được, thuần đọc/sửa doc).
3. **Accessibility audit** — cần Mac/simulator (UI).

> **Đã xong & ghi trigger:** Security (M8-1, §4l) · Backup&Recovery (M8-2, §4m). Các trigger nhỏ (Keychain on-device check; fsync durability; Store-level dangling-path test; migration-discipline rule) — chỉ làm khi có bằng chứng/harness, KHÔNG suy đoán.

## Store-resilience — trigger đã ghi (§4k), CHƯA làm
Chỉ thêm "loadAll skip file hỏng" khi có **bằng chứng file hỏng thật** (bit-rot, sync-conflict, encoding bug) — KHÔNG phải crash (atomic write đã chặn). Đến lúc đó: skip trong bulk-read, giữ `load` targeted vẫn throw; + test canh.

## Nguyên tắc sống còn (mọi task)

- **Chỉ đổi khi có bằng chứng.** Audit có thể kết luận "không cần đổi" — kết quả hợp lệ (M7-0, M8-0 đã làm đúng vậy).
- Architecture Review TRƯỚC code. Không Engine/abstraction không bằng chứng. Không nới arch test (chỉ THÊM/siết). ADR cũ bất biến (AD-01…AD-47).
- Test chỉ THÊM/siết, không sửa để code sai qua được ("sửa code, không sửa test").
- Không milestone nào chấp nhận số liệu giả.

## Những phần tuyệt đối không được sửa

- Core 6; ModuleManifest; matcher; 3 module; AutomationRule schema; ApprovalGate không tái tạo tới khi có risky action thật.
- Architecture Test rules; ADR cũ; hành vi đang có test.

## Definition of Done (task M8 kế)

Task được chọn xong trọn quy trình: Architecture Review ghi lại + thay đổi (nếu có) kèm bằng chứng + test giữ/thêm xanh + docs (PROJECT_STATE §4x + CHANGELOG) + NEXT_TASK mới. Dừng, không tự mở task sau.
