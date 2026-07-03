# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M2 — User Experience** (DEVELOPMENT_PLAN.md §2/M2)

## Current Task

**M2-4 — Dashboard v1: nhận thức vận hành, không phải trang thống kê**

## Objective

Dashboard theo đúng BLUEPRINT: *chỉ* Current Goal, Current Task, Progress, Recent Activity, Token Usage hôm nay, System Status — không hơn. Đây cũng là lúc **EventBus có consumer production đầu tiên** (trả nợ Low đã ghi từ M0-5): Kernel publish → cả ChatService (như cũ) lẫn Dashboard (recent activity) — đúng lý do tồn tại của bus (nhiều consumer).

## Phạm vi

1. **Token Usage cần nguồn dữ liệu:** metrics hiện chỉ ra log — Dashboard cần đọc được. Phương án phải chốt trong phiên (Năm Câu Hỏi): (a) Gateway ghi metrics vào Store (Knowledge record dạng `metrics/`? — NO, Knowledge là "cách hệ thống hoạt động"); (b) một `MetricsRecorder` in-memory session-level trong Application nhận `AIRequestMetrics` qua callback từ composition (giống relay pattern) — session-only, khớp "Today's Resource Usage", không persist (không thêm record type Store khi chưa có bằng chứng cần lịch sử dài hạn — M7 mới cần). **Nghiêng về (b)** — rẻ nhất, đủ cho Dashboard v1; ghi nợ "persist metrics history" cho M7.
   - Cần seam: `DefaultAIGateway` thêm `onMetrics: (@Sendable (AIRequestMetrics) -> Void)?` (optional, default nil — zero regression)? Đây là đổi Core (Gateway) — được phép vì có bằng chứng (Dashboard cần đọc số đo, AD-15 nói đo để dùng); giữ nhỏ: một callback, không MetricsStore, không telemetry framework.
2. **EventBus vào wiring:** composition: Kernel publish → bus; bus consumers: ChatService.relay + DashboardModel. (EventBus generic đã sẵn từ M0-1 — lần đầu dùng thật.)
3. **Application:** `DashboardSnapshot` DTO + port closures (`dashboard()` đọc ProjectState hiện tại + số liệu session) — pure assemble function testable như các task trước.
4. **UI:** `DashboardView` — 4-6 dòng thông tin, không chart, không %. Sidebar thêm mục Dashboard.
5. **System Status:** provider mode (Connected/Offline — từ ProviderSettings.currentStatus có sẵn) + test suite... không, System Status v1 = provider mode + counts (projects). Giữ tối giản.

## Files cần tạo

- `Application/DashboardModel.swift` (hoặc gộp DTO vào file port hiện có nếu nhỏ), `Presentation/Dashboard/DashboardView.swift`, `Tests/ApplicationTests/DashboardTests.swift`.

## Files cần sửa

- `Core/AIGateway/DefaultAIGateway.swift` (+onMetrics callback — một dòng gọi trong log path), `App/AppComposition/CompositionRoot.swift` (bus + metrics wiring), `Presentation/Chat/ChatView.swift` (sidebar), ViewModel nếu cần.
- Docs cuối phiên (+AD-39 nếu chốt metrics-callback).

## Checklist

- [ ] Dashboard KHÔNG trở thành analytics page (đúng BLUEPRINT — 6 mục, không chart).
- [ ] Metrics session-level, không persist (nợ M7 ghi rõ); Gateway thay đổi tối thiểu (1 callback optional, test cũ pass nguyên trạng).
- [ ] EventBus có ≥2 consumer thật — gỡ dòng nợ "EventBus chưa có consumer".
- [ ] Assemble logic thuần trong Application (pattern M2-2/M2-3).
- [ ] `swift build` 0 warning; toàn bộ test pass offline.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M2-5 — Accessibility pass + M2 Review chuẩn bị).

## Definition of Done

Dashboard hiển thị goal/task/progress/activity/token-hôm-nay/status từ dữ liệu thật; EventBus đa consumer; test assemble + metrics recorder; zero regression.

## Estimated Complexity

Trung bình — một seam Core nhỏ (callback) + wiring bus.

## Estimated AI Cost

Dev session: trung bình. Runtime: 0.

## Risk

- Metrics callback mở cửa telemetry creep — giữ đúng 1 callback, không aggregation trong Gateway.
- Bus wiring đổi đường publish của Kernel — giữ test ChatService nguyên trạng làm guard.

## Những phần tuyệt đối không được sửa

- Pipeline Gateway ngoài việc THÊM callback optional; Kernel/Execution/Store.
- Architecture Test rules (chỉ THÊM); ADR cũ (AD-01…AD-38).
