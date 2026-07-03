# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M3 — Intelligence Layer** (DEVELOPMENT_PLAN.md §2/M3)

## Current Task

**M3-3 — Deliverable Templates & Executive Summary v1**

## Objective

Deliverable có cấu trúc nhất quán mà không thêm component: mọi deliverable đường AI mở đầu bằng **Executive Summary ngắn + actionable next steps** (đúng phạm vi M3 trong DEVELOPMENT_PLAN). Template là **DATA trong SkillDefinition** (AD-04: prompt template sống cùng skill — KHÔNG Prompt/Deliverable/Template Registry, danh sách cấm còn nguyên). Executive OS trả về thứ đọc được trong 10 giây, không phải bức tường chữ.

## Phạm vi

1. **Output scaffold = data:** hướng dẫn cấu trúc output (Executive Summary → nội dung → Next steps) đi vào prompt như DATA — cân nhắc: (a) mở rộng `promptTemplate` của 3 skill hiện có, hay (b) MỘT scaffold chung ở tầng assemble của Execution/Gateway cho đường `.ai/.composition`. Tự phản biện chọn 1 (gợi ý: (b) một chỗ, 0 lặp — nhưng phải chứng minh không phải "Template Engine trá hình"; nếu chỉ là hằng string nối vào prompt thì OK).
2. **Plain AI path (không skill)** cũng nhận scaffold — user không cần biết skill tồn tại.
3. **Presentation:** deliverable reader hiện có đọc markdown — kiểm tra Executive Summary hiển thị tự nhiên, KHÔNG viết parser/formatter mới.
4. **Không làm:** không Template Registry/file template riêng; không AI hậu xử lý deliverable (1 goal = 1 AI call như cũ); không đổi Store schema; không chạm Reflection/WriteGate/ComplexityEstimate vừa chốt.

## Files cần tạo

- `Tests/CoreTests/DeliverableTemplateTests.swift` (captured-prompt: scaffold vào prompt cả đường skill lẫn plain AI; composition chỉ scaffold bước cuối — bước giữa là intermediate).

## Files cần sửa

- Tùy quyết định (1): `Core/Execution/DefaultExecutionEngine.swift` (assembleTask) HOẶC skill definitions trong CompositionRoot; docs cuối phiên (+AD-43 nếu có quyết định mới đáng ghi).

## Checklist

- [ ] Scaffold là data/hằng số — 0 engine mới, 0 registry mới, 0 AI call thêm.
- [ ] Đường plain AI (không skill) cũng có Executive Summary.
- [ ] Composition: chỉ bước cuối nhận scaffold (intermediate output là nguyên liệu, không phải deliverable).
- [ ] Reuse path trả nguyên văn — KHÔNG re-format deliverable cũ.
- [ ] Zero regression toàn bộ test cũ (captured-prompt tests M1-1/M1-2 có thể cần cập nhật expected prompt — được phép vì đó là test NỘI DUNG prompt, không phải arch rule).
- [ ] Đủ quy trình review + docs + NEXT_TASK (đề xuất: M3-4 — Reuse pipeline hoàn chỉnh + cache optimization, HOẶC M3 review nếu phạm vi còn lại mỏng — tự đánh giá).

## Definition of Done

Goal đường AI ra deliverable có Executive Summary + next steps (test bằng captured prompt — nội dung thật cần Mac/API key, ghi trung thực); plain-AI path có scaffold; zero regression; không component/registry mới.

## Estimated Complexity

Thấp–trung bình — chủ yếu prompt data + test; rủi ro chính là cám dỗ xây Template Engine.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0 (scaffold đi cùng request có sẵn).

## Risk

- "Template Engine trá hình" — nếu thấy cần placeholder/conditional/inheritance trong template: DỪNG, hỏi user (3 câu: đơn giản vì sao không đủ / bằng chứng thật / chi phí bảo trì).
- Scaffold làm phình prompt — đo token thêm (phải < ~80 token), ghi vào report.

## Những phần tuyệt đối không được sửa

- WriteGate/Reflection (M3-1), ComplexityEstimate/confidence (M3-2) — vừa chốt, chỉ *dùng*.
- Gateway pipeline; Store; Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-42).
