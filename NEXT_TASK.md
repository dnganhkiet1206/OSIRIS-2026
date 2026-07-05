# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Nợ đang cháy (song song):**
> - **CI macOS:** UI M6-2 đã push — nếu run mới nhất còn lỗi SwiftUI, dán `error:` vào phiên (sửa trước, như `ChatViewModel`). Cấp lại quyền GitHub (`/mcp`) để tôi tự đọc CI.
> - **API key** cho `LiveBaselineTests` — điều kiện tiên quyết của M7 (xem dưới).

## Current Milestone

**M7 — Optimization** (DEVELOPMENT_PLAN.md §2/M7) — CHỜ USER XÁC NHẬN MỞ

## Current Task

**M7-0 — Đo trước, tối ưu sau: thu baseline thật + chỉ tối ưu cái số liệu chứng minh**

## Nguyên tắc sống còn của M7 (đọc kỹ)

M7 là milestone **dễ vi phạm "không sửa khi không có bằng chứng" nhất**: tối ưu không số liệu = đoán = churn. Toàn bộ nợ Low perf (cache eviction, search đọc-lại-file, WC cleanup, metrics history, tier-routing) đã được HOÃN suốt M1→M6 với đúng lý do: **chờ số liệu thật**. M7 chỉ hợp lệ khi có số liệu.

**Điều kiện tiên quyết:** baseline provider thật (nợ Medium). Đầu phiên M7-0, kiểm tra `ANTHROPIC_API_KEY`:
- **CÓ key:** chạy `LiveBaselineTests` → điền §4b → giờ có số liệu token/latency/cost thật → chọn 1 tối ưu mà số liệu chỉ rõ (vd nếu token in cao → context trimming; nếu latency cao → cache/prompt-cache).
- **KHÔNG key:** M7 optimization phần lớn PHẢI HOÃN (đoán = vi phạm hiến pháp). Phần làm được không cần provider: đo **pipeline overhead** đã có (`PipelineBaselineTests` — fresh/reuse ms) và tối ưu thuật toán có bằng chứng NỘI BỘ (vd `Store.search` đọc lại toàn bộ file mỗi query — đo với store lớn, nếu chậm rõ thì thêm index/cache có test). KHÔNG đụng cái cần dữ liệu provider.

## Phạm vi (chọn theo điều kiện trên)

1. **Baseline thật** (nếu có key): chạy harness, ghi §4b, KHÔNG giả số.
2. **Tối ưu evidence-based, MỘT thứ một lần:** mỗi tối ưu phải kèm (a) số đo trước, (b) thay đổi, (c) số đo sau chứng minh cải thiện, (d) test giữ hành vi. Không "tối ưu phòng xa".
3. **Không làm:** tối ưu suy đoán; đổi kiến trúc; micro-opt không đo được; đụng hot path mà không có test bảo vệ hành vi.

## Ứng viên tối ưu (chỉ khi số liệu chỉ rõ — không làm cả loạt)

- `Store.search` đọc lại toàn bộ file mỗi query (đo được trên Linux với store lớn) → index/cache nếu chậm thật.
- `InMemoryResponseCache` không bound/TTL → eviction khi có hit-rate/bộ nhớ thật (cần usage → device/key).
- WorkingContext hết hạn chưa xóa vật lý → cleanup (đo được Linux).
- Tier routing Gateway-side (cần ≥2 model thật) → khi catalog có model thứ hai.

## Checklist

- [ ] Đầu phiên: kiểm key, quyết CÓ-số-liệu hay HOÃN, ghi lập luận.
- [ ] Mỗi tối ưu có số-trước/số-sau + test; 0 tối ưu suy đoán.
- [ ] Zero regression 157 test + 1 opt-in skip.
- [ ] Nếu phần lớn phải hoãn (không key): trung thực báo, làm phần Linux-đo-được, không vẽ tiến độ giả.

## Definition of Done

Hoặc: baseline thật đã ghi + ≥1 tối ưu có số liệu chứng minh + test. Hoặc: báo cáo trung thực "M7 chờ số liệu (key)" + tối ưu Linux-đo-được nếu có ứng viên rõ. Không milestone nào của dự án chấp nhận số liệu giả.

## Estimated Complexity

Biến thiên — nhỏ nếu chỉ thu baseline; trung bình nếu có tối ưu thuật toán đo được.

## Những phần tuyệt đối không được sửa

- Core 6; ModuleManifest; matcher; 3 module; AutomationRule schema; ApprovalGate không tái tạo tới khi có risky action thật.
- Architecture Test rules (chỉ THÊM/siết); ADR cũ (AD-01…AD-47).
- Hành vi đang có test — mọi tối ưu phải giữ test xanh (tối ưu là đổi HIỆU NĂNG, không đổi KẾT QUẢ).
