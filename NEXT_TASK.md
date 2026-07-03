# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M2 — User Experience** (DEVELOPMENT_PLAN.md §2/M2)

## Current Task

**M2-3 — Global Search v1: tìm mọi thứ từ một ô**

## Objective

"Search should locate: Projects, Deliverables, Knowledge… extremely fast" (BLUEPRINT/Search). `Store.search` đã có sẵn hai mode từ M1-2 — UI chỉ việc dùng: một ô search trong sidebar, gõ → kết quả nhóm theo loại (Projects khớp tên, Deliverables, Knowledge, Working Context), bấm → mở đúng chỗ (project → chuyển workspace; deliverable → sheet đọc — cả hai flow đã tồn tại từ M2-1/M2-2).

## Phạm vi

1. **Application:** mở rộng `ProjectDirectory`? KHÔNG — search là năng lực riêng: cân nhắc port mới `GlobalSearch` (một closure `search(query) -> [SearchHit]`) vs nhét vào ProjectDirectory. Một closure duy nhất → nghiêng về **thêm closure `search` vào ProjectDirectory** (đổi tên port? — KHÔNG đổi tên khi chưa có bằng chứng nhức nhối; ghi chú xem xét ở M2 review). Chốt trong phiên với Năm Câu Hỏi.
2. **SearchHit DTO** (Application): kind (project/deliverable/knowledge/workingContext), id, title, snippet — dịch từ `StoreSearchResult` + match tên project (list + filter tên tại composition/pure helper).
3. **Search xuyên project:** `StoreQuery(projectID: nil)` (đã hỗ trợ) + matchMode `.anyWord` (relevance); logic gộp "project name match + store results" là **hàm thuần testable** trong Application (bài học M2-2).
4. **UI:** ô search trong sidebar (`.searchable` hoặc TextField section); kết quả nhóm theo loại; chọn project-hit → selectProject; deliverable-hit → openDeliverable (tái dùng); knowledge/WC-hit → hiển thị snippet (sheet đơn giản).
5. **Không làm:** không index mới, không fuzzy, không search transcript (không persist), không đổi Store.

## Files cần tạo

- `Presentation/Search/SearchResultsView.swift` (giữ nhỏ).
- `Tests/ApplicationTests/GlobalSearchTests.swift` — hàm thuần gộp/dịch hit: project name match, dịch kind, thứ tự nhóm, query rỗng → rỗng.

## Files cần sửa

- `Application/ProjectDirectory.swift` (SearchHit + closure + hàm thuần gộp), `App/AppComposition/CompositionRoot.swift` (nối), `Presentation/Chat/ChatView.swift` + `ChatViewModel.swift` (search state + điều hướng kết quả).
- Docs cuối phiên.

## Checklist

- [ ] Không method Store mới; không cache kết quả ngoài view-state.
- [ ] Logic gộp/dịch hit là hàm thuần trong Application (test Linux được) — composition chỉ fetch.
- [ ] Deliverable hit hiển thị theo preview body, không lộ path nội bộ làm title chính.
- [ ] Application chỉ import OsirisCore; Presentation chỉ OsirisApplication (arch tests).
- [ ] `swift build` 0 warning; toàn bộ test pass offline.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M2-4 — Dashboard v1: operational awareness từ metrics/state có sẵn).

## Definition of Done

Gõ từ khóa → thấy kết quả nhóm loại từ mọi project; bấm điều hướng đúng; test hàm gộp; zero regression.

## Estimated Complexity

Thấp–Trung bình.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0.

## Risk

- UI diff tiếp tục phình khi nợ Mac chưa trả — view search tách file riêng, giữ nhỏ.
- `.searchable` behavior khác nhau iOS/macOS — dùng TextField đơn giản trong sidebar nếu rủi ro.

## Những phần tuyệt đối không được sửa

- Core (Store.search đủ dùng — thêm method là red flag).
- Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-38).
