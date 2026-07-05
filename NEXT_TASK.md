# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Nợ đang cháy (song song):**
> - **API key** cho `LiveBaselineTests` — điều kiện tiên quyết của **phần provider-side của M7** (token/latency/cost). Không có key, phần này HOÃN (đoán = vi phạm hiến pháp). Set qua env/secret, KHÔNG dán vào chat.
> - **CI macOS:** UI đã xác thực trên Mac thật 2026-07-05 (§4i) — nợ High UI RETIRED. CI macOS giữ để chống regression tự động; nếu run đỏ, dán `error:` vào phiên.

## Trạng thái M7

**M7-0 ✅ ĐÃ XONG (2026-07-05):** đo baseline nội bộ thật, quyết KHÔNG tối ưu (path nội bộ đã đơn-con-số ms; AI call thật áp đảo ~100×). Chi tiết PROJECT_STATE §4j. Harness `StoreSearchBaselineTests` (opt-in) đã ship. **0 tối ưu code — đúng kỷ luật "đo trước, số liệu nói chưa cần".**

## Current Task — CHỜ USER CHỌN HƯỚNG

Hai đường đi hợp lệ, **dừng chờ lệnh** trước khi mở:

### Đường A — M7 provider-side (mở khi CÓ key)
Đây là bề mặt tối ưu THẬT (M7-0 đã chứng minh nội bộ không cần tối ưu).
1. User set `ANTHROPIC_API_KEY` (env/secret) → chạy `LiveBaselineTests` → điền §4b số token/latency/cost thật.
2. Chọn **một** tối ưu mà số liệu chỉ rõ, có số-trước/số-sau + test:
   - token-in cao → context trimming / prompt-cache preamble.
   - latency cao → response cache / prompt cache.
   - nhiều model thật trong catalog → tier routing Gateway-side.
3. Mỗi tối ưu: (a) đo trước, (b) đổi, (c) đo sau chứng minh cải thiện, (d) test giữ hành vi. MỘT thứ một lần. Không "tối ưu phòng xa".

### Đường B — M8 Production Readiness (mở nếu chưa muốn cấp key)
M7 core-discipline đã xong (đo + quyết định); M7 provider-side có thể để mở, tiến sang M8:
- Test coverage cho Core contracts · Performance review (đã có baseline §4j/§4b) · Security review (API keys, dữ liệu) · Backup & Recovery (ProjectState/Memory/Files) · Crash recovery · Docs · Accessibility audit.
- M8 phần lớn Linux-làm-được (test, security, backup logic), không cần key.

## Nguyên tắc sống còn (giữ nguyên qua mọi hướng)

- **Đo trước, tối ưu sau.** Không tối ưu suy đoán. M7-0 đã đặt chuẩn: số liệu có thể nói "đừng tối ưu" — đó là kết quả hợp lệ.
- Không đổi kiến trúc; không micro-opt không đo được; không đụng hot path thiếu test bảo vệ hành vi.
- Không milestone nào chấp nhận số liệu giả.

## Những phần tuyệt đối không được sửa

- Core 6; ModuleManifest; matcher; 3 module; AutomationRule schema; ApprovalGate không tái tạo tới khi có risky action thật.
- Architecture Test rules (chỉ THÊM/siết); ADR cũ (AD-01…AD-47).
- Hành vi đang có test — mọi tối ưu phải giữ test xanh (tối ưu là đổi HIỆU NĂNG, không đổi KẾT QUẢ).

## Definition of Done (cho task kế)

- Đường A: baseline provider thật ghi §4b + ≥1 tối ưu có số-trước/số-sau + test.
- Đường B: task M8 đầu tiên (vd Core contract test coverage) xong trọn quy trình.
