# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M6 — Automation** (DEVELOPMENT_PLAN.md §2/M6) — thiết kế đã chốt tại M6-0 (AD-47)

## Current Task

**M6-1 — Automation-as-data v1: `AutomationRule` bền vững + "run now" qua Kernel hiện có**

## Objective

Hiện thực thiết kế đã chốt ở M6-0 (AD-47, câu 4): automation = DATA + vòng đời Kernel hiện có, KHÔNG engine. Lát cắt testable-offline: một **rule** (mô tả goal cần chạy) được lưu bền qua Store (sống sót restart — State Over Chat), và "chạy ngay" = nạp goal của rule vào Kernel hiện có → ra deliverable y như goal thủ công. Phần trigger-theo-lịch là iOS background → chỉ định nghĩa interface, PENDING thiết bị (như UI M0-M5).

## Phạm vi

1. **`AutomationRule` = record thứ 4 của Store (schema TỐI THIỂU — AD-28):** chỉ trường bắt buộc để chạy được: `id`, `name`, `goalText`, `projectID`, `enabled`. KHÔNG thêm trigger-schedule fields cho tới khi trigger model có bằng chứng (iOS design). Rule là platform data → Store là nơi lưu duy nhất (AD-32); arch rule mới: `AutomationRule(` chỉ construct trong Core/Store (như memory records AD-41).
2. **Store CRUD tối thiểu:** `saveAutomationRule` / `automationRules(for:)` / xóa; persist qua LocalStorage layout mới `automation-rules/<id>`; test restart chứng minh sống sót.
3. **"Run now" = Application port** (pattern ProjectDirectory/ProviderSettings — closure struct, không cạnh import mới): list/create/run rule; "run" gọi `ChatService.submit(rule.goalText, rule.projectID)` — tái dùng Kernel, KHÔNG execution path mới. Test: rule chạy ra deliverable == goal thủ công cùng nội dung.
4. **Trigger theo lịch:** CHỈ định nghĩa `AutomationTrigger` enum (vd `.manual`, `.daily`) như data; KHÔNG scheduler thật (iOS background — PENDING thiết bị, ghi runbook). `.manual` là case duy nhất chạy được offline v1.
5. **Không làm:** scheduler/dispatcher/engine; điều kiện phức tạp (rule engine); UI automation (Presentation — sau khi Core+App xong, hoặc PENDING Mac); risky action/ApprovalGate (đã xóa — chờ external tools M6+).

## Files cần tạo/sửa

- `Core/Store/` (AutomationRule type + Store protocol methods + FileBackedStore impl), `Application/` (Automation port), CompositionRoot (wire), Tests (Store persistence + run-now e2e + arch rule), docs.

## Checklist

- [ ] Schema tối thiểu (5 trường); không field trigger-schedule chưa có bằng chứng.
- [ ] Rule chỉ construct trong Core/Store (arch rule mới, 20 rule).
- [ ] Persist qua Store duy nhất (AD-32); test restart.
- [ ] "Run now" tái dùng Kernel — 0 execution path mới; test deliverable == manual goal.
- [ ] Trigger = data enum; scheduler thật PENDING thiết bị (không giả trên Linux).
- [ ] Zero regression 146 test; đủ review + docs + NEXT_TASK.

## Definition of Done

Tạo rule → sống sót restart (test) → "run now" ra deliverable đúng (test) qua Kernel hiện có; 0 engine mới; trigger-lịch khoanh vùng PENDING; zero regression.

## Estimated Complexity

Trung bình — chạm Store (record type thứ 4) + Application port; vùng đã có khuôn (memory records, closure-port).

## Estimated AI Cost

Dev session: trung bình. Runtime: 0 (test offline).

## Risk

- Schema phình sớm (thêm trigger fields đoán trước) — giữ 5 trường, mở rộng khi iOS trigger design rõ (AD-28).
- "Automation engine" cám dỗ — v1 chỉ là record + Kernel hiện có; scheduler thật là iOS API, không phải component OSIRIS.

## Những phần tuyệt đối không được sửa

- Core 6 (Store thêm record type thứ 4 = mở rộng data có lập luận, không phải component mới); matcher; 3 module.
- Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-47). ApprovalGate đã xóa — KHÔNG tái tạo cho tới khi có risky action thật (AD-47).
