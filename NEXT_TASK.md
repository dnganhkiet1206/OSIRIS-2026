# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M2 — User Experience** (DEVELOPMENT_PLAN.md §2/M2)

## Current Task

**M2-2 — Project Resume v1: mở project là thấy ngay trạng thái**

## Objective

"The user should resume work instantly" (BLUEPRINT/Projects). Hiện chọn project chỉ reset transcript trống — người dùng mù về những gì đã làm. M2-2: mở project → thấy goal gần nhất, các task đã hoàn thành, deliverables (đọc lại nội dung được) — tất cả từ Store (State Over Chat: nguồn sự thật là ProjectState, không phải transcript chat).

## Phạm vi

1. **Application:** mở rộng `ProjectDirectory` (port đã có — thêm closures, không type mới nếu tránh được): `overview(projectID) -> ProjectOverview` (DTO: name, currentGoal?, completedTasks (giới hạn N gần nhất), deliverables [(path, preview ngắn)]) + `deliverableContent(path) -> String?` (đọc full khi user bấm). Composition nối xuống Store hiện có (`projectState(for:)` + `deliverableContent(at:)` — KHÔNG API Store mới nếu đủ; nếu cần preview rẻ → đọc content và cắt tại composition, không thêm method Store).
2. **UI:** chọn project → detail hiển thị Resume header (goal gần nhất + đếm deliverables) phía trên transcript trống + danh sách deliverables bấm được (sheet đọc nội dung). Giữ diff Presentation nhỏ (nợ High Mac chưa trả).
3. **Không làm:** không lưu/khôi phục transcript chat (State Over Chat — transcript là UI tạm; lịch sử thật = ProjectState + deliverables); không Search (M2-3); không Dashboard (M2-4).

## Files cần tạo

- `Presentation/Projects/ProjectResumeView.swift` (header + deliverable list + sheet đọc).
- `Tests/ApplicationTests/ProjectOverviewTests.swift` — overview đúng dữ liệu từ Store; project rỗng → overview rỗng an toàn; preview bị cắt đúng.

## Files cần sửa

- `Application/ProjectDirectory.swift` (+overview/deliverableContent closures + DTO).
- `App/AppComposition/CompositionRoot.swift` (nối closures mới).
- `Presentation/Chat/ChatView.swift` + `ChatViewModel.swift` (hiển thị resume khi đổi project).
- Docs cuối phiên.

## Dependency

- Store đã có đủ API (projectState, deliverableContent). Không network, offline.

## Checklist

- [ ] Không method Store mới trừ khi chứng minh cần (composition cắt preview được).
- [ ] Không nguồn sự thật thứ hai (overview = đọc-through, không cache ngoài view-state).
- [ ] Application vẫn chỉ import OsirisCore; Presentation chỉ OsirisApplication (arch tests).
- [ ] Transcript chat KHÔNG persist (State Over Chat) — resume đến từ ProjectState.
- [ ] `swift build` 0 warning; toàn bộ test pass offline.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M2-3 — Global Search).

## Definition of Done

Chọn project → thấy goal gần nhất + deliverables, đọc lại được nội dung deliverable; test overview ở tầng Application; zero regression.

## Estimated Complexity

Thấp–Trung bình.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0.

## Risk

- Diff Presentation phình khi nợ Mac chưa trả — giữ view mới nhỏ, tách file riêng.

## Những phần tuyệt đối không được sửa

- Core (M2 là UX; Store API hiện tại đủ — thêm method Store là red flag cần lập luận).
- Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-38).
