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
- **M8-6 ✅** (Accessibility audit — §4q): audit 10 view; sửa `MessageRow` sender cho VoiceOver.
- **Provider identity/localization ✅ (ĐÓNG kiến trúc)** — 2 lớp: (§4r) CONTENT preamble +2 luật; (§4s) TRANSPORT preamble nay đi qua **system channel** mọi provider (Anthropic `system`…), refactor nhỏ nhất (default method → 21 test double 0 sửa). 0 `if provider==`, 0 component mới. **[USER] test lại key thật** — nếu còn lệch chỉ tinh chỉnh chữ preamble (data), không đổi kiến trúc. 164 test / 2 skip / 0 fail.

- **M9-0 ✅** (Product Experience Architecture Review — §4t): audit 10 câu, KHÔNG code. Design System rỗng · 0 animation · 0 app icon/brand · card/button duplicate · spacing/radius ad-hoc; responsive cấu trúc OK. Giải pháp nhỏ nhất = `Shared/DesignSystem` data + ViewModifier, KHÔNG framework.
- **BUG FIX ✅ (offline placeholder leak — §4u):** placeholder echo nguyên prompt (preamble+context) → persist→retrieve→echo loop. Fix nhỏ nhất tại nguồn (placeholder trả câu offline cố định, không echo) + regression test. Vòng lặp đứt. **Caveat: rác đã persist trước fix còn tồn — xoá project/store offline để dọn.** 165 test / 2 skip / 0 fail.
- **M9-1 ✅ (Design System Foundation — §4v):** Design Language V1 (USER): dark-only palette hex. Tạo `Shared/DesignSystem/` (`OsirisColor`+`Radius`+`.osirisCard()` = data + 1 ViewModifier) + `Shared` vào app target (`project.yml`). Áp: dark-only ở root + **card-surface** (`.osirisCard()`: ProjectResumeView container/rows + ChatView bubble). Scope tối thiểu (USER chốt Q2). A11y: tertiary #6D6D6D→#7C7C7C (AA, USER duyệt Q1). **Tinh chỉnh sau Design Review (Rec-2):** rollback text-color migration về semantic (tránh 2 ngôn ngữ thị giác) + gỡ root `.background` (partial) — palette catalog vẫn khai báo, text/nền rollout sau. **Dark-only = Product Decision** (di trú Light = adaptive token+`@AppStorage`). **+ BLUEPRINT §2/#11 Incremental Product Evolution.** Verify = CI (0 SPM target chạm → suite không đổi; macOS compile). Swift.org chặn policy → không test Swift local.

## Current Milestone

**M9 — Product Experience & UI/UX.** M9-0 (Review) + M9-1 (Design System Foundation) xong. **M9-2 CHỜ USER XÁC NHẬN — KHÔNG tự mở.**

### Đề xuất M9-2 (bước Consistency tiếp — chờ USER chọn hướng)
Hai ứng viên, đều đúng "Consistency over Creativity", chọn 1:
1. **Rollout palette-màu** sang các view còn lại (Dashboard/Settings/Search/Advanced/Automation/ExecutionStatus/Sidebar) — thay `.secondary`/`.tertiary`/`.quaternary`/`.accentColor` semantic sang `OsirisColor` token. Diff cơ học, đưa toàn app lên palette V1. (M9-1 cố ý chưa sweep — Q2.)
2. **Spacing scale** — literals 2/4/6/8/12/16 rải rác nhiều view → `enum Spacing` (data) + áp nơi lặp thật. Chuẩn hóa whitespace theo Design Language ("whitespace rộng").

> **Ràng buộc M9 (giữ):** KHÔNG redesign · KHÔNG animation (ưu tiên #5, milestone riêng) · reusable chỉ khi có bằng chứng duplication · KHÔNG engine/manager/framework · a11y bất khả xâm phạm (M8-6) · Presentation Xcode-only → verify CI macOS.
> **Nhắc USER (chưa xong, cần Mac/key):** verify M9-1 mắt thường trên iPhone (palette/card/bubble) · test lại provider contract key thật (§4r+§4s) · a11y runtime pass (§4q).
> **Thứ tự M9 (KHÔNG làm ngược):** Consistency → Clarity → Responsive → Accessibility → Animation → Polish.

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
