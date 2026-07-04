# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M6 — Automation** (DEVELOPMENT_PLAN.md §2/M6)

## Current Task

**M6-2 — Scheduled trigger interface + Automation UI (phần lớn PENDING thiết bị)**

## Cảnh báo phạm vi trung thực

M6-2 chạm hai vùng KHÔNG kiểm chứng được trên Linux: (1) iOS background scheduling để fire `.daily` — API nền tảng, không có scheduler OSIRIS; (2) SwiftUI Presentation cho automation. Cả hai chỉ `swiftc -parse` được, giống toàn bộ UI M0→M5 (nợ High). **Cân nhắc mạnh:** có thể task này nên HOÃN tới khi user chạy runbook (có Mac) — nếu không, ta chồng thêm UI/nền-tảng chưa compile lên nợ High đang lớn. Tự đánh giá đầu phiên: nếu giá trị kiểm chứng được (Linux) quá mỏng so với rủi ro, đề xuất user chạy runbook trước, HOẶC chuyển sang M6-3 (phần automation còn testable) thay vì M6-2.

## Phạm vi (NẾU tiến hành)

1. **Scheduled trigger = interface + adapter mỏng, KHÔNG scheduler component:** định nghĩa protocol `AutomationScheduler` (App layer) mà iOS impl dùng `BGTaskScheduler`/`UNUserNotificationCenter`; impl thật là adapter nền tảng (Xcode-only), KHÔNG phải component OSIRIS (như AnthropicProvider là adapter, AD-31). Fire = gọi `Automation.runNow`. KHÔNG timer trên Linux.
2. **Automation UI (Presentation):** màn hình list/create/toggle/run/delete rule qua port `Automation` có sẵn; sidebar thêm mục (sau Advanced?). ViewModel: **CẢNH BÁO trigger cứng M2-6** — ChatViewModel đã gánh 5 vai, task UI kế tiếp phải TÁCH; automation nên là ViewModel/surface RIÊNG, không nhồi vào ChatViewModel.
3. **Không làm:** scheduler engine/dispatcher; rule điều kiện phức tạp; risky-action/ApprovalGate (chờ external tools).

## Files (nếu tiến hành)

- `Application/` (AutomationScheduler protocol nếu cần), `Presentation/Automation*` (View + ViewModel riêng), `App/` (iOS scheduler adapter + wire), docs.

## Checklist

- [ ] Tự đánh giá đầu phiên: tiến M6-2 hay hoãn chờ runbook (ghi lập luận).
- [ ] Nếu tiến: scheduler thật là ADAPTER nền tảng, không component OSIRIS; 0 timer/scheduler trên Linux.
- [ ] Automation UI là surface RIÊNG (không mở rộng ChatViewModel — trigger cứng M2-6).
- [ ] Phần Linux-testable (nếu có) có test; phần thiết bị ghi PENDING trung thực.
- [ ] Zero regression 153 test; đủ review + docs + NEXT_TASK.

## Definition of Done

Hoặc: interface scheduler + UI automation qua `swiftc -parse`, phần thiết bị PENDING rõ, zero regression. Hoặc: quyết định hoãn có lập luận + chuyển task testable-hơn.

## Estimated Complexity

Trung bình — nhưng phần lớn không kiểm chứng được (rủi ro nợ High tăng).

## Estimated AI Cost

Dev session: trung bình. Runtime: 0.

## Risk

- **Chồng UI/nền-tảng chưa compile lên nợ High** — cân nhắc hoãn chờ runbook.
- Scheduler dễ phình thành component — v1 là adapter mỏng gọi `runNow`, không hơn.
- Nhồi automation vào ChatViewModel — vi phạm trigger cứng M2-6; phải tách.

## Những phần tuyệt đối không được sửa

- Core 6; ModuleManifest; matcher; 3 module; `AutomationRule` schema (M6-1 vừa chốt — mở rộng chỉ khi trigger design cho bằng chứng).
- Architecture Test rules (chỉ THÊM/siết); ADR cũ (AD-01…AD-47). ApprovalGate không tái tạo tới khi có risky action thật.
