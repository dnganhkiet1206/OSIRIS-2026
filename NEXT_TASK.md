# NEXT_TASK.md

> **TRẠNG THÁI: CHỜ USER DUYỆT MỞ M2.** M1 đã nghiệm thu (PROJECT_STATE §4c, tag `M1`). Task dưới đây là ĐỀ XUẤT đầu tiên của M2 — không tự ý bắt đầu.
>
> **Điều kiện nên hoàn thành trước/đầu M2 (nợ High):** user chạy `Docs/RUNBOOK_M1-0.md` — M2 là milestone toàn UI; xây tiếp trên 8 file SwiftUI chưa qua compiler là rủi ro kép. Nếu kết quả runbook được dán vào phiên M2-1: xử lý lỗi compile/baseline TRƯỚC, task dưới SAU.

## Current Milestone

**M2 — User Experience** (DEVELOPMENT_PLAN.md §2/M2: Sidebar, Projects, Settings, Search, Dashboard, Advanced Mode, Accessibility)

## Current Task (đề xuất)

**M2-1 — Projects v1: multi-project thật từ Store đến UI**

## Objective

Project là đơn vị cô lập nền tảng của OSIRIS (Project Isolation) nhưng hiện `ChatService.submit` hardcode `projectID: "default"` — mọi goal đổ vào một project. M2-1 làm multi-project thật: tạo/chọn project, mỗi project có transcript + state + deliverables riêng, sidebar liệt kê projects. Đây là nền của mọi UX sau (Search, Dashboard đều theo project).

## Phạm vi

1. **Store:** cần liệt kê projects — `listProjectStates()` (đọc qua prefix `project-state/` — pattern đã có; KHÔNG thêm record type mới).
2. **Application:** ChatService nhận `projectID` từ UI mỗi submit (bỏ hardcode); API mỏng cho danh sách/tạo project (qua Kernel? — KHÔNG: đọc danh sách là query thuần, không phải goal execution — cân nhắc trong phiên: ChatService thêm `listProjects()`/`createProject(name:)` gọi Store trực tiếp? ChatService được phép chạm Store? AD-35 nói Application là cầu nối UI↔Core — Store là Core; nhưng ranh giới hiện tại: ChatService chỉ biết Kernel. Mở rộng ChatService biết Store = thêm quyền lực cho Application. Phương án thay thế: Kernel expose query? Kernel là decision engine, không phải query service. **Chốt trong phiên với Năm Câu Hỏi + cập nhật arch test nếu mở ranh giới** — nghiêng về: Application được chạm Store cho *đọc* (query), mọi *ghi* vẫn qua vòng đời Kernel; nếu chọn hướng này → ghi AD-38).
3. **ProjectState:** thêm `name` (display) — field mới có migration mặc định (id làm name fallback).
4. **UI:** sidebar liệt kê projects + nút tạo; chọn project → transcript riêng (ChatViewModel giữ transcript theo project hoặc reset khi đổi — v1: reset + hiển thị state từ Store là M2-2 History; chốt phạm vi nhỏ).
5. **Tests:** listProjectStates; hai project không rò transcript/deliverable (đã có isolation test ở Store — thêm mức ChatService); tạo project → xuất hiện trong list.

## Files cần tạo

- `Tests/CoreTests/ProjectListingTests.swift` (+ ApplicationTests nếu ChatService đổi).

## Files cần sửa

- `Core/Store/Store.swift` + `FileBackedStore.swift` (listProjectStates; ProjectState.name).
- `Application/ChatService.swift` (projectID per submit + API project).
- `Presentation/Chat/*` + `App/` (sidebar projects, chọn/tạo).
- Docs cuối phiên (kể cả AD-38 nếu mở ranh giới đọc cho Application).

## Checklist

- [ ] Không nguồn sự thật thứ hai (danh sách project = đọc từ Store, không cache riêng trong UI ngoài view-state).
- [ ] Ghi vẫn CHỈ qua vòng đời Kernel/Store (arch tests; nếu Application được quyền đọc Store → cập nhật rule có chủ đích, ghi AD — không nới lỏng ngầm).
- [ ] Project Isolation giữ vững (test 2 project).
- [ ] `swift build` 0 warning; toàn bộ test pass offline.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M2-2).

## Definition of Done

Tạo/chọn project từ UI; goal chạy đúng project; deliverables/state cô lập theo project (test); zero regression.

## Estimated Complexity

Trung bình — một quyết định ranh giới (Application đọc Store) cần chốt cẩn thận.

## Estimated AI Cost

Dev session: trung bình. Runtime: 0.

## Risk

- Mở ranh giới Application→Store cẩu thả sẽ xói mòn AD-35 — nếu chốt mở, giới hạn READ-only bằng arch rule mới thay vì bỏ rule.
- UI code vẫn chưa compile được ở môi trường này (nợ High) — giữ Presentation diff nhỏ.

## Những phần tuyệt đối không được sửa

- Vòng đời 5 pha, resource order, Gateway pipeline (M2 là UX — Core đứng yên trừ mở rộng Store đọc có chủ đích).
- Architecture Test rules (chỉ THÊM/siết — kể cả khi mở ranh giới, thêm rule mới thay vì xóa rule cũ).
- ADR cũ (AD-01…AD-37).
