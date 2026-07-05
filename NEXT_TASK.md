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
- **M8-4 ✅** (Documentation review — §4o): sửa 5 lỗi doc có bằng chứng. 0 code.
- **M8-5 ✅** (Production Readiness Milestone Review — §4p): M8 core nghiệm thu (tag `M8`); dead-code scan sạch.
- **M8-6 ✅** (Accessibility audit — §4q): audit code-level 10 view — app đã tốt sẵn; **sửa 1 lỗi thật** (`MessageRow` sender cho VoiceOver). Runtime = checklist USER trên Mac. 163 test / 2 skip / 0 fail.

## Current Milestone

**M8 NGHIỆM THU (tag `M8`) — 7/7 hạng mục code-complete.** Còn lại đều evidence-gated / chờ USER — **KHÔNG tự mở M9:**

1. **[USER] A11y runtime pass** (Mac): chạy checklist §4q (VoiceOver/keyboard/Dynamic Type/contrast). Lỗi → dán quan sát, tôi sửa diff nhỏ. Không lỗi → Accessibility đóng hoàn toàn.
2. **M7 provider-side optimization** — cần **key thường trực** (baseline qua-Gateway nhiều sample) → tối ưu token/latency/cost có số-trước-sau.
3. **Mở M9** (nếu roadmap có) — chờ USER xác nhận.

> **Nguyên tắc giữ nguyên:** mỗi phiên ĐÚNG MỘT task · Architecture Review trước code · chỉ đổi khi có bằng chứng · test chỉ THÊM/siết · ADR cũ bất biến · không số liệu giả.
> **Trigger nhỏ (Low, không chặn Production):** Keychain on-device check; `.atomic` fsync; Store-level dangling-path test; migration-discipline rule; reuse `limit:10` starvation — chỉ làm khi có bằng chứng/harness.

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
