# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** user vẫn chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu user dán kết quả runbook, xử lý trước rồi mới làm task dưới.

## Current Milestone

**M1 — Core Runtime** (DEVELOPMENT_PLAN.md §2) — task áp chót; sau đó M1-5 = M1 Review.

## Current Task

**M1-4 — Tool đầu tiên: đường `.tool` sống, "AI Is The Last Tool" được chứng minh bằng máy**

## Objective

Thứ tự tài nguyên của Decide hoàn chỉnh phần còn thiếu trước AI: **reuse → tool → skill/composition → plain AI**. Một goal trả lời được bằng tool on-device (ngày/giờ hiện tại) hoàn thành với **0 AI call** — nguyên tắc "AI Is The Last Tool" lần đầu được chứng minh bằng test thay vì tài liệu.

## Thiết kế phải chốt trong phiên (với Năm Câu Hỏi)

1. **Tool matching data-driven** giống skill: tool cần khai báo nó phục vụ goal nào. `Tool` protocol hiện chỉ có `id` + `run`. Phương án đề xuất: struct `ToolDescriptor` (data: toolID + triggerKeywords + purpose) đăng ký cùng tool — HOẶC mở rộng protocol thêm `var triggerKeywords: [String]`. Chọn phương án ít abstraction hơn, nhất quán với triggerKeywords của skill (một cơ chế matching, không hai).
2. **Kernel biết tools thế nào:** Kernel chưa có dependency tools. Inject `tools: [any Tool]` qua init (danh sách nhỏ, không cần Tool Registry riêng — Skill Registry là registry duy nhất theo AD-17; tool list là dependency tĩnh của composition root cho đến khi có bằng chứng cần registry).
3. **Execution chạy tool:** `.tool(ToolID)` case hiện có — nhưng Execution không được chạm danh sách tool để resolve (AD-25 tương tự skill)! → plan phải mang tool đã resolve: đổi case thành `.tool(any Tool)`? Enum với existential — Sendable OK (Tool: Sendable). Chốt trong phiên.

## Phạm vi

1. **`CurrentDateTimeTool`** (Core/Tools/OnDevice/): trả ngày giờ hiện tại (format thân thiện) — deterministic-ish, không mạng, không AI. Use case thật: "hôm nay ngày mấy" không được tốn token.
2. **Kernel Decide:** sau reuse-check, trước skill-match: tool matching bằng triggerKeywords (tái dùng đúng thuật toán hit-count/tie-break của skill nếu tách được thành hàm chung — DRY, nhưng chỉ tách khi sạch).
3. **Execution:** case `.tool` — chạy tool máy móc, output là deliverable; lỗi tool → error rõ ràng.
4. **Persist:** deliverable từ tool vẫn ghi file + index như mọi deliverable (qua Store, bởi Kernel).
5. **Tests:** goal "what is the date today" → 0 provider call, deliverable chứa ngày; goal thường → không bị tool cướp (keywords hẹp); tool lỗi → thông điệp thân thiện qua ChatService (nếu chạm được — tối thiểu là error rõ ở Execution).

## Files cần tạo

- `Core/Tools/OnDevice/CurrentDateTimeTool.swift`
- `Tests/CoreTests/ToolExecutionTests.swift`

## Files cần sửa

- `Core/Tools/Contracts/Tool.swift` (triggerKeywords theo phương án chốt), `Core/Kernel/Kernel.swift` (tools dependency + Decide), `Core/Kernel/Decision/ExecutionStrategy.swift` (`.tool` mang tool đã resolve), `Core/Execution/DefaultExecutionEngine.swift` (chạy tool), `App/AppComposition/CompositionRoot.swift` + toàn bộ test dựng Kernel (thêm `tools:` param).
- `Docs/PROJECT_STATE.md`, `CHANGELOG.md`, `NEXT_TASK.md` (M1-5 = M1 Review) — cuối phiên.

## Dependency

- Toàn bộ vòng đời + matching đã sẵn. Không dependency ngoài, offline.

## Checklist

- [ ] Goal khớp tool: **0 provider call** (CountingProvider chứng minh) — "AI Is The Last Tool" thành test vĩnh viễn.
- [ ] Thứ tự Decide: reuse > tool > skill > plain AI — đúng resource order BLUEPRINT.
- [ ] Execution không resolve tool (plan mang tool sẵn); không chạm registry/Store (arch tests).
- [ ] Không tạo Tool Registry riêng khi chưa có bằng chứng (AD-17: 2 registry là trần).
- [ ] Tool keywords hẹp — goal thường không bị cướp khỏi skill/AI (test).
- [ ] `swift build` 0 warning; toàn bộ test pass offline.
- [ ] Self/Architecture Review + docs + NEXT_TASK mới (M1-5 — M1 Review: DoD, quyết định cuối parallel/resume, danh sách chuẩn bị M2).

## Definition of Done

Goal về ngày giờ hoàn thành với 0 token qua đường `.tool` đầy đủ vòng đời (persist như mọi deliverable); resource order hoàn chỉnh; zero regression; tài liệu cập nhật.

## Estimated Complexity

Trung bình — chạm Decide + Execution + nhiều call site Kernel init.

## Estimated AI Cost

Dev session: trung bình. Runtime: 0.

## Risk

- Tool matching tham → goal AI bị trả lời bằng tool sai: keywords rất hẹp ("what time", "what date", "hôm nay ngày", "mấy giờ"), thà miss.
- Đổi Kernel init chữ ký → sửa đồng loạt test — cơ học, ít rủi ro.

## Những phần tuyệt đối không được sửa

- Gateway pipeline; composition vừa chốt M1-3; reuse.
- Ranh giới AD-25/32/33; Architecture Test rules (chỉ THÊM).
- ADR cũ (AD-01…AD-36).
