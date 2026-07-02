# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.

## Current Milestone

**M0 — Walking Skeleton** (DEVELOPMENT_PLAN.md §2)

## Current Task

**M0-4B — Execution materialize + Store là persister duy nhất cho deliverable**

## Mục tiêu

1. **`Store.saveDeliverable(content:projectID:) -> String`** (AD-32): Store là nơi duy nhất ghi deliverable file (`deliverables/<projectID>/<UUID>.md` qua LocalStorage); trả về path.
2. **Kernel Persist cập nhật index:** path vào `ProjectState.deliverablePaths` (Kernel orchestrate qua Store — không I/O trực tiếp, giữ AD-33).
3. **Deliverable tham gia `Store.search`** (thêm `Kind.deliverable`): goal lặp lại được reuse từ deliverable cũ → lần chạy thứ hai của cùng goal = **0 AI call** (đóng vòng Reuse Before Create thật sự).
4. **`DefaultExecutionEngine` truyền `preferredTier`** từ plan vào `AIRequest` (đúng contract; Gateway route theo tier khi có ≥2 model — AD-31).

## Lý do cần làm

M0-4A đã cho Kernel quyết định; M0-4B cho hệ thống *nhớ và tái dùng kết quả của chính nó*. Không có bước này, reuse chỉ hoạt động với Knowledge seed sẵn — chưa phải vòng lặp tự cải thiện. Đây cũng là mảnh cuối của AD-10 (deliverable = file + index phái sinh) và AD-32 (một persister).

## Các file cần tạo

- `Tests/CoreTests/DeliverablePersistenceTests.swift` — (a) sau `kernel.handle`, file deliverable tồn tại trên đĩa và path nằm trong `ProjectState.deliverablePaths`; (b) chạy cùng goal lần 2 → 0 provider call (reuse từ deliverable); (c) `saveDeliverable` với projectID lạ → path an toàn (percent-encode, tái dùng helper hiện có).

## Các file cần sửa

- `Core/Store/Store.swift` — thêm `saveDeliverable` vào protocol + `Kind.deliverable`.
- `Core/Store/Persistence/FileBackedStore.swift` — implement saveDeliverable + đưa deliverable vào search (đọc file dưới prefix `deliverables/`).
- `Core/Kernel/Kernel.swift` — pha Persist: gọi `store.saveDeliverable`, thêm path vào state (qua Store, không LocalStorage).
- `Core/Execution/DefaultExecutionEngine.swift` — truyền preferredTier.
- `Core/Execution/ExecutionEngine.swift` — `ExecutionPlan` thêm `preferredTier: ModelTier` (Kernel quyết định tier — mặc định `.light` ở M0).
- `Docs/PROJECT_STATE.md`, `CHANGELOG.md`, `NEXT_TASK.md` (bản mới cho M0-5) — cuối phiên.

## Dependency

- Đã có đủ: LocalStorage (chỉ Store dùng), Architecture Tests sẽ tự cưỡng chế AD-32/33 trong lúc triển khai. Không dependency ngoài, không network.

## Checklist

- [ ] `testOnlyStoreTouchesLocalStorage` và `testKernelIsPureDecisionLogic` vẫn pass (Kernel không I/O; chỉ Store chạm LocalStorage).
- [ ] Goal lặp lại → 0 provider call, deliverable cũ được trả (CountingProvider chứng minh).
- [ ] Search deliverable KHÔNG load toàn bộ nội dung mọi file vào memory một cách vô tội vạ — đọc tuần tự, dừng sớm khi đủ limit.
- [ ] Không tạo Deliverable Registry (AD-10) — chỉ file + index + search.
- [ ] `swift build` 0 error / 0 warning; toàn bộ test (unit + architecture) pass, offline.
- [ ] Self Review + Architecture Review + cập nhật docs + NEXT_TASK mới (M0-5).

## Definition of Done

Vòng lặp reuse khép kín: goal mới → AI (placeholder) → deliverable file + index → goal lặp lại → reuse, 0 AI call. Kernel vẫn thuần túy (arch test chứng minh). Tài liệu cập nhật; NEXT_TASK M0-5 đã tạo.

## Estimated Complexity

Thấp–Trung bình — 1 method protocol mới, search mở rộng, không component mới.

## Estimated AI Cost

Dev session: nhỏ (PROJECT_STATE + NEXT_TASK + Store 2 file + Kernel + Execution 2 file). Runtime: 0 (Placeholder).

## Các rủi ro

- Reuse từ deliverable của goal *khác nhưng chứa* goal hiện tại → trả sai; giữ tiêu chí chặt (match nguyên văn goal), thà miss còn hơn sai — relevance ranking M1.
- `Store` protocol đổi (thêm method) → đây là mở rộng có chủ đích theo AD-32 đã duyệt, không phải drift; cập nhật SYSTEM_COMPONENTS nếu mô tả lệch.

## Những phần tuyệt đối không được sửa

- Ranh giới AD-33: Kernel không import Infrastructure, không I/O (arch test đang canh).
- `DefaultAIGateway` pipeline + contract AIGateway/AIProvider/ResponseCache.
- Không tích hợp provider thật (AD-31 — thuộc M0-6).
- Architecture Test rules hiện có (chỉ được THÊM rule, không nới lỏng rule để cho code qua).
- 6 thành phần Core, cấu trúc thư mục, Package.swift targets (trừ khi thêm test target mới có lý do).
