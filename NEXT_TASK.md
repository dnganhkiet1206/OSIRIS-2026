# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song / nợ đang cháy:**
> - **CI macOS** đã chạy: nếu run mới nhất (sau fix `ChatViewModel` + UI M6-2) còn lỗi SwiftUI → dán `error:` vào phiên, sửa trước (giống ChatViewModel). Cần cấp lại quyền GitHub (`/mcp`) để tôi tự đọc CI.
> - **API key** cho `LiveBaselineTests` (nợ Medium) — user cấp qua env, đừng dán vào chat.

## Current Milestone

**M6 — Automation** (DEVELOPMENT_PLAN.md §2/M6)

## Current Task

**M6-3 — M6 Milestone Review & Acceptance**

## Vì sao review bây giờ

Core testable/buildable của M6 đã xong: M6-0 (arch review + xoá ApprovalGate, AD-47), M6-1 (automation-as-data: record + port + run-now), M6-2 (Automation UI). Phần còn lại của phạm vi M6 (scheduled background firing, MCP remote tools, monitoring) đều **device/evidence-gated** — không build mù được (giống UI PENDING từ M0). Review đánh giá trung thực phần đã xong + khoanh vùng phần hoãn, như M1-5/M2-6/M3-4/M4-4/M5-2.

## Phạm vi review

1. **Bảng tiêu chí M6** (DEVELOPMENT_PLAN §2/M6: scheduling · background · automation rules · MCP · monitoring; "công việc lặp lại chạy tự động, hành động rủi ro qua approval gate") → ✅/⚠️/HOÃN từng mục, PENDING ghi địa chỉ (thiết bị/CI/AD-45).
2. **ADR M6:** AD-46 (EventBus xoá) · AD-47 (risky-action cluster + automation design) — Decision→Evidence→Result.
3. **Nợ rà toàn bộ:** CI macOS đã hạ nợ High từ "unknown" xuống "CI-visible, đang sửa" — cập nhật trạng thái theo kết quả CI mới nhất; baseline live-harness sẵn (chờ key); ChatViewModel trigger đã được tôn trọng (M6-2). Không gia hạn thiếu bằng chứng.
4. **Risky action / ApprovalGate:** xác nhận điều kiện tái sinh (external-effect tool đầu tiên = mở tool-channel AD-45) chưa đến — automation v1 vẫn 0 risky action (chỉ sinh deliverable local).
5. **Acceptance report + tag `M6`** (local) + DEVELOPMENT_PLAN (đánh dấu M6 + điều kiện kích hoạt scheduled-firing/MCP) + NEXT_TASK cho M7 (Optimization — nơi các nợ Low perf/cache/search có số liệu thật để tối ưu; ĐỌC kỹ §2/M7).
6. **Open-source readiness:** cập nhật — CI macOS giờ compile UI tự động (contributor thấy build status); còn baseline thật + device UX.

## Điều kiện HOÃN có ghi (không build mù)

- **Scheduled `.daily` firing:** iOS `BGTaskScheduler` adapter — kích hoạt khi có thiết bị/simulator để test bg task thật. Interface đã sẵn (trigger enum M6-1).
- **MCP remote tools:** = mở tool-channel (AD-45) + risky action + ApprovalGate tái sinh — cụm quyết định M6+/M7 khi có use case thật + user consent network.

## Checklist

- [ ] Không sửa code trừ lỗi thật (vd CI macOS lộ thêm lỗi SwiftUI → sửa trước review).
- [ ] Mọi PENDING có địa chỉ + chủ sở hữu; ADR cũ không sửa; tag M6 local.
- [ ] Zero regression (157 test + 1 opt-in skip).

## Definition of Done

Bảng tiêu chí M6 trung thực; AD-46/47 evidence; nợ cập nhật theo CI thật; scheduled-firing/MCP khoanh vùng điều kiện; tag `M6`; NEXT_TASK M7; DỪNG chờ user.

## Estimated Complexity

Thấp — đánh giá + tài liệu (trừ khi CI lộ thêm lỗi SwiftUI cần sửa).

## Những phần tuyệt đối không được sửa

- Core 6; ModuleManifest; matcher; 3 module; `AutomationRule` schema; ApprovalGate không tái tạo tới khi có risky action thật.
- Architecture Test rules (chỉ THÊM/siết); ADR cũ (AD-01…AD-47).
