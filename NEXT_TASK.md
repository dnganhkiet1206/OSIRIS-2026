# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** user vẫn chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu user dán kết quả runbook, xử lý trước (baseline §4b / lỗi compile) rồi mới làm task dưới.

## Current Milestone

**M1 — Core Runtime** (DEVELOPMENT_PLAN.md §2)

## Current Task

**M1-3 — Composition Execution v1: chuỗi skill tuần tự**

## Objective

`SkillComposition` (workflow = dữ liệu khai báo, AD-07) chạy được thật: Kernel chọn một composition, Execution chạy các bước tuần tự — output bước trước là input bước sau — toàn bộ qua Gateway, máy móc, không quyết định. Sau M1-3: một goal như "research rồi draft" có thể chạy 2 skill nối tiếp thành một deliverable.

## Điều chỉnh scope so với DEVELOPMENT_PLAN (cần user duyệt trong phiên hoặc trước đó)

M1 gốc ghi "parallel + composition + resume sau suspend". Đề xuất hoãn 2 phần với lập luận:
- **Parallel:** chưa tồn tại nguồn sinh task độc lập (một goal → một plan tuyến tính) — xây parallel bây giờ là abstraction không có người dùng. Bằng chứng cần: khi Planner tách goal thành nhiều task (M3).
- **Resume-sau-suspend:** cần thiết kế state cho in-flight execution (ai persist? — chỉ Store được persist, nhưng Execution không được chạm Store → phải đi qua Kernel checkpoint). Đáng một thiết kế riêng, không nhét vào cuối M1-3.
Quyết định cuối ghi ở M1 review. Nếu user không đồng ý hoãn → dừng, thảo luận trước khi code.

## Phạm vi

1. **Composition là dữ liệu:** thêm 1 composition mẫu generic (`core.research-then-draft` — steps: [research-outline, draft]) — khai báo cạnh GenericSkills.
2. **Kernel Decide:** goal khớp composition (triggerKeywords riêng của composition? — composition hiện là `[SkillID]` thuần; cần định danh + trigger → cân nhắc: composition được mô tả bằng một SkillDefinition có `compositionSteps` (field ĐÃ CÓ sẵn từ AD-28!) — không type mới, một skill "cha" khai báo các bước. Nếu hướng này đứng vững qua Năm Câu Hỏi thì `SkillComposition` struct riêng có thể thành thừa → đánh giá và đề xuất trong phiên).
3. **Execution chạy steps tuần tự:** mỗi step = assemble template của skill bước đó với `{goal}` + `{previous}` (output bước trước); qua Gateway từng bước; metrics từng bước được log tự nhiên (mỗi bước một `ai.request`); deliverable cuối = output bước cuối.
4. **Giới hạn khai báo:** tối đa 5 bước (đúng quy tắc "composition ngắn" của BLUEPRINT); vượt → config/validation lỗi.
5. **Tests:** composition 2 bước chạy đúng thứ tự (captured prompts chứng minh output bước 1 vào prompt bước 2); goal không khớp composition → hành vi cũ; 1 bước fail → lỗi rõ ràng, không deliverable nửa vời.

## Files cần tạo

- `Tests/CoreTests/CompositionExecutionTests.swift`.

## Files cần sửa

- `Core/Skills/BuiltIn/GenericSkills.swift` (+composition mẫu), `Core/Kernel/Kernel.swift` (Decide nhận composition), `Core/Execution/DefaultExecutionEngine.swift` (chạy steps), có thể `Core/Execution/Composition/SkillComposition.swift` (nếu kết luận hợp nhất vào SkillDefinition.compositionSteps — đề xuất trước khi xóa).
- `Docs/PROJECT_STATE.md`, `CHANGELOG.md`, `NEXT_TASK.md` (M1-4) — cuối phiên.

## Dependency

- Skill matching (M1-1) + Gateway (M1-2) đã sẵn. Registry cần trả skill theo ID cho từng step (`skill(withID:)` đã có — nhưng Execution KHÔNG được chạm SkillRegistry (arch rule)! → Kernel resolve toàn bộ steps thành `[SkillDefinition]` NGAY trong Decide, plan mang danh sách đã resolve — Execution thuần máy móc).

## Checklist

- [ ] Execution không chạm SkillRegistry/Store (arch tests canh — plan mang skill đã resolve).
- [ ] Mỗi bước một `ai.request` metrics; bước fail → error rõ, không persist deliverable dở.
- [ ] Goal không khớp composition: zero regression (test cũ pass nguyên trạng).
- [ ] Không tạo Workflow Engine/Runtime (banned) — composition chạy trong DefaultExecutionEngine.
- [ ] Nếu đề xuất bỏ `SkillComposition` struct: nêu lập luận + đợi thể hiện rõ trong báo cáo (xóa type là thay đổi kiến trúc nhỏ — cần bằng chứng, đã có sẵn: field `compositionSteps` trùng vai trò).
- [ ] `swift build` 0 warning; toàn bộ test pass offline.
- [ ] Self/Architecture Review + docs + NEXT_TASK mới (M1-4).

## Definition of Done

Composition 2 bước chạy trọn qua vòng đời thật với captured prompts chứng minh chuỗi; giới hạn 5 bước cưỡng chế; zero regression; tài liệu cập nhật.

## Estimated Complexity

Trung bình — chạm cả Decide lẫn Execution nhưng toàn bộ là data-driven.

## Estimated AI Cost

Dev session: trung bình. Runtime: 0 (Capturing/Placeholder provider).

## Risk

- `{previous}` bơm output lớn vào prompt bước sau → token phình: cap bằng cơ chế snippet/budget hiện có của Gateway (đã có sẵn trim).
- Hai cách mô tả composition (struct riêng vs field trên SkillDefinition) tồn tại song song = nguồn sự thật đôi — phải chốt một trong phiên.

## Những phần tuyệt đối không được sửa

- Gateway pipeline vừa chốt M1-2 (composition dùng nó nguyên trạng, mỗi bước một call).
- Ranh giới AD-25/32/33; Architecture Test rules (chỉ THÊM).
- Reuse của Kernel; ADR cũ (AD-01…AD-35).
