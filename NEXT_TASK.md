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
- **M8-2 ✅** (Backup & Recovery review — §4m): audit 6 ưu tiên → **KHÔNG lỗ hổng**; backup = copy thư mục Store; 0 dòng đổi. Ghi 3 trigger.
- **M8-3 ✅** (Crash Recovery review — §4n): **TÌM & SỬA 1 lỗ hổng thật** — reuse trả process-note WC thay vì deliverable. Fix A + Fix B + regression test.
- **M8-4 ✅** (Documentation review — §4o): sửa 5 lỗi doc có bằng chứng (harness compile-được, SYSTEM_COMPONENTS phản ánh AD-46/47, RUNBOOK count). 0 code, 0 doc mới. 163 test / 2 skip / 0 fail.

## Current Task — CHỜ USER CHỌN task M8 kế (KHÔNG tự mở)

M8 Production Readiness còn các mảnh sau; **mỗi phiên làm ĐÚNG MỘT**, Architecture Review trước code, chỉ đổi khi có bằng chứng:

1. **Accessibility audit** — cần Mac/simulator (UI). Chưa có harness → phần lớn PHẢI trên thiết bị; Linux chỉ rà được code (VoiceOver label/Dynamic Type trong SwiftUI source).
2. **M8 nghiệm thu** — nếu USER thấy đủ, đóng M8 (tag) và cân nhắc: M7 provider-side (cần key thường trực) là mảnh mở lớn nhất còn lại.

> **Đã xong & ghi trigger:** Security (M8-1) · Backup&Recovery (M8-2) · Crash Recovery (M8-3) · Docs (M8-4). Trigger nhỏ (Keychain on-device check; fsync durability; Store-level dangling-path test; migration-discipline rule; reuse `limit:10` starvation) — chỉ làm khi có bằng chứng/harness, KHÔNG suy đoán.

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
