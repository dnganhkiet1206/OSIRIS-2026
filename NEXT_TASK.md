# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.

## Current Milestone

**M0 — Walking Skeleton** (DEVELOPMENT_PLAN.md §2)

## Current Task

**M0-4 — Kernel Decide v0: pha Decide thật sự quyết định**

## Mục tiêu

1. **Reuse check (Reuse Before Create):** pha Decide gọi `Store.search` trước khi execute; nếu tìm thấy kết quả khớp đủ mạnh cho goal → trả deliverable từ nguồn có sẵn, không execute gì cả (đường rẻ nhất trong resource order).
2. **Đường `.ai` sống:** hết reuse → Decide chọn `.ai` (hiện Kernel hardcode `.direct`, nghĩa là Gateway chưa bao giờ được gọi từ vòng đời thật). Strategy `.direct` chỉ còn cho trường hợp không cần AI (sẽ do Skill quyết định từ M1).
3. **Deliverable là file (AD-10):** pha Persist ghi deliverable ra đĩa qua `LocalStorage` (`deliverables/<projectID>/<timestamp>.md`) và cập nhật `ProjectState.deliverablePaths` (index phái sinh).
4. `DefaultExecutionEngine` truyền `preferredTier` từ plan vào `AIRequest` (đúng contract, dù Gateway chưa route theo tier — AD-31).

## Lý do cần làm

Đây là mảnh cuối để vòng đời 5 pha có ý nghĩa thật: Decide đang là stub luôn chọn `.direct` — toàn bộ Gateway vừa hoàn thiện ở M0-3 chưa được Kernel sử dụng. Sau M0-4, chuỗi `Goal → Decide (reuse? ai?) → Gateway (dry-run/placeholder) → Deliverable file → ProjectState` chạy trọn — sẵn sàng cho Chat UI (M0-5) nối vào.

## Các file cần tạo

- `Tests/CoreTests/KernelDecideTests.swift` — (a) goal trùng deliverable đã có → không gọi Gateway (CountingProvider đếm 0), trả từ reuse; (b) goal mới → Gateway được gọi đúng 1 lần; (c) deliverable file tồn tại trên đĩa sau Persist và path nằm trong ProjectState.

## Các file cần sửa

- `Core/Kernel/Kernel.swift` — pha Decide (search → reuse | .ai) và pha Persist (ghi file + index). Kernel nhận thêm `LocalStorage` (hoặc Store mở rộng? KHÔNG — cân nhắc kỹ: deliverable là FILE, nguồn sự thật là đĩa; đi qua LocalStorage trực tiếp, Store chỉ giữ index trong ProjectState. Không thêm method deliverable vào Store — tránh biến Store thành god object).
- `Core/Execution/DefaultExecutionEngine.swift` — truyền preferredTier.
- `Tests/CoreTests/KernelTests.swift` — cập nhật construction nếu Kernel init đổi.
- `App/AppComposition/CompositionRoot.swift` — inject LocalStorage cho Kernel.
- `Docs/PROJECT_STATE.md`, `CHANGELOG.md`, `NEXT_TASK.md` (bản mới cho M0-5) — cuối phiên.

## Dependency

- Đã có đủ: Store.search, LocalStorage, Gateway pipeline hoàn chỉnh, EventBus. Không thêm dependency ngoài, không network.

## Checklist

- [ ] Reuse hit → 0 provider call (chứng minh bằng CountingProvider).
- [ ] Reuse miss → đúng 1 provider call; deliverable file trên đĩa; path trong ProjectState.deliverablePaths.
- [ ] Heuristic reuse ĐƠN GIẢN (substring match qua Store.search hiện có) — không xây scoring engine; relevance là việc của M1.
- [ ] Không thêm method vào protocol `Store`; không tạo Deliverable Registry (AD-10).
- [ ] Execution vẫn không chứa quyết định nào (AD-25).
- [ ] `swift build` 0 error / 0 warning; toàn bộ test pass, offline.
- [ ] Self Review + Architecture Review + cập nhật docs + NEXT_TASK mới (M0-5).

## Definition of Done

Vòng đời 5 pha chạy trọn với Decide thật: reuse-first, AI-last; deliverable là file có index; test chứng minh cả hai nhánh; tài liệu cập nhật; NEXT_TASK M0-5 đã tạo.

## Estimated Complexity

Thấp–Trung bình — logic Decide ~30 dòng, Persist ~15 dòng, không contract mới.

## Estimated AI Cost

Dev session: nhỏ (PROJECT_STATE + NEXT_TASK + Kernel.swift + 2 test file). Runtime: 0 (Placeholder/dry-run).

## Các rủi ro

- Heuristic reuse quá tham (trả nhầm kết quả cũ cho goal khác) → giữ tiêu chí khớp chặt (goal text xuất hiện nguyên vẹn), thà miss còn hơn sai; nới lỏng ở M1 khi có relevance ranking.
- Kernel init thêm tham số → cập nhật đồng bộ KernelTests/CompositionRoot trong cùng commit.

## Những phần tuyệt đối không được sửa

- `DefaultAIGateway` pipeline và toàn bộ contract AIGateway/AIProvider/ResponseCache (vừa chốt ở M0-3).
- Protocol `Store` (không thêm method — deliverable đi qua LocalStorage).
- Không tích hợp provider thật (AD-31 — thuộc M0-6).
- 6 thành phần Core, cấu trúc thư mục, Package.swift targets, danh sách component bị cấm (SYSTEM_COMPONENTS.md §6).
