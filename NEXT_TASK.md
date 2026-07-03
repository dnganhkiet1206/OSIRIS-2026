# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M3 — Intelligence Layer** (DEVELOPMENT_PLAN.md §2/M3)

## Current Task

**M3-2 — Smart Planning v1: complexity → tier, Confidence Medium có consumer**

## Objective

Decide thông minh hơn mà không thêm token: (1) **ước lượng complexity deterministic** cho goal (heuristic từ dữ liệu có sẵn — độ dài, số yêu cầu con, từ khóa khối lượng như "detailed/toàn diện/full") → **chọn `ModelTier`** thay vì hardcode `.light` (chuẩn bị sẵn cho ngày có ≥2 model thật — tier routing đang là nợ Medium); (2) **Confidence Medium có consumer đầu tiên** (M1 mới dùng High/Low): goal dài-mơ-hồ (đo được: nhiều mệnh đề, thiếu đối tượng cụ thể — heuristic chặt) → proceed nhưng **assumption được ghi qua đúng WriteGate vừa xây** (justification `reducesFutureTokens`? — không: assumption phục vụ truy vết → `reusableLater`; chốt trong phiên) và xuất hiện trong context của goal sau.

## Phạm vi

1. **`ComplexityEstimate` (pure, Core/Kernel/Decision/):** enum `simple/standard/complex` từ heuristic deterministic; map → tier (`simple/standard → .light`, `complex → .standard` — có ý nghĩa khi catalog ≥2 model; hiện catalog 1 model thật nên tier routing vẫn chờ, nhưng plan.preferredTier bắt đầu mang giá trị thật).
2. **Confidence Medium:** `confidence(in:)` mở rộng (hiện: empty→low, else high): heuristic Medium chặt (vd goal >N từ nhưng không khớp skill/tool nào VÀ chứa đại từ mơ hồ "it/this/cái đó" không tiền ngữ — giữ đơn giản, thà High); Medium → vẫn thực thi + `MemoryCandidate` assumption ("Assumed interpretation: …") qua WriteGate.
3. **Metrics/observability:** không thêm seam mới — assumption ghi WC là đủ dấu vết.
4. **Không làm:** không AI-assisted planning; không đổi Gateway routing (tier consumption vẫn chờ ≥2 model); không nới matcher.

## Files cần tạo

- `Core/Kernel/Decision/ComplexityEstimate.swift`, `Tests/CoreTests/SmartPlanningTests.swift`.

## Files cần sửa

- `Core/Kernel/Kernel.swift` (Decide: estimate → tier; confidence medium → assumption candidate qua writeGate), `Core/Kernel/Decision/ExecutionStrategy.swift` (nếu cần chú thích ConfidenceTier.medium).
- Docs cuối phiên (+AD-42 nếu có quyết định mới đáng ghi).

## Checklist

- [ ] Toàn bộ heuristic deterministic, 0 AI call, 0 token thêm.
- [ ] Assumption đi qua WriteGate — KHÔNG đường ghi mới (arch rule memory-born-in-gate đang canh).
- [ ] Tier chỉ đổi trên `.ai/.composition` path; `.reuse/.tool` không bị ảnh hưởng.
- [ ] Heuristic Medium chặt — thà High (không spam assumption); test goal thường KHÔNG sinh assumption.
- [ ] Zero regression toàn bộ test cũ.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M3-3 — Deliverable Templates & Executive Summary v1).

## Definition of Done

Complexity→tier hoạt động có test; Medium confidence sinh assumption ghi qua gate và xuất hiện trong retrieval của goal sau; ConfidenceTier hết case chết; zero regression.

## Estimated Complexity

Trung bình — chạm Decide (vùng nhạy cảm nhất), thuần heuristic.

## Estimated AI Cost

Dev session: nhỏ–trung bình. Runtime: 0.

## Risk

- Heuristic phức tạp hóa Decide — giữ mỗi hàm thuần nhỏ, test riêng.
- Assumption spam làm nhiễu retrieval — tiêu chí Medium rất chặt + TTL tự dọn.

## Những phần tuyệt đối không được sửa

- WriteGate/Reflection vừa chốt (M3-2 chỉ *dùng* gate, không sửa); Gateway; Execution; Store.
- Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-41).
