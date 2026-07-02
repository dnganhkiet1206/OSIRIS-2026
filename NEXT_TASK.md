# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.

## Current Milestone

**M0 — Walking Skeleton** (DEVELOPMENT_PLAN.md §2)

## Current Task

**M0-5 — Chat UI v0: nối vòng đời 5 pha vào giao diện**

## Objective

Người dùng gõ một goal trong ChatView → thấy Execution Status events chạy ("Understanding… Planning… Executing…") → nhận deliverable → `needsClarification` hiển thị thành câu hỏi thân thiện → lỗi hiển thị theo UI contract (chuyện gì xảy ra / đã thử gì / bước tiếp theo). Toàn bộ chạy trên Placeholder provider — 0 chi phí.

## Thiết kế ràng buộc (đã chốt, không bàn lại)

- **Presentation không import OsirisInfrastructure** (arch rule mới từ M0-4B đang canh). UI nhận events qua `AsyncStream<ExecutionEvent>` (type Core) do CompositionRoot cung cấp — EventBus vẫn là chi tiết hạ tầng trong composition root.
- UI không lộ reasoning — chỉ activity events (UI contract §6 BLUEPRINT).
- Không chặn UI: `kernel.handle` chạy trong Task, progress cập nhật real-time.

## Files cần tạo

- `Presentation/Chat/ChatViewModel.swift` — `@MainActor @Observable`: nhận `Kernel` + `AsyncStream<ExecutionEvent>`; state: transcript (goal, events, deliverable, question/error), `isWorking`; logic mỏng nhất có thể (không compile được trên Linux — giữ nhỏ để rủi ro thấp).
- `Presentation/ExecutionStatus/ExecutionStatusView.swift` — hiển thị event hiện tại, calm & unobtrusive, không % giả.

## Files cần sửa

- `App/AppComposition/CompositionRoot.swift` — trả về `AppDependencies` (kernel + events stream) thay vì chỉ Kernel; EventBus subscribe được nối tại đây.
- `App/OsirisApp.swift` — khởi tạo dependencies một lần, inject vào ChatView.
- `Presentation/Chat/ChatView.swift` — form nhập goal, transcript, trạng thái làm việc, hiển thị kết quả/câu hỏi/lỗi.
- `Docs/PROJECT_STATE.md`, `CHANGELOG.md`, `NEXT_TASK.md` (bản mới cho M0-6) — cuối phiên.

## Dependency

- Core đã đủ: Kernel 5 pha, ExecutionEvent, KernelError.needsClarification, Gateway metrics. Không thêm dependency ngoài, không network, không đổi Core.

## Checklist

- [ ] Presentation không import OsirisInfrastructure (arch test canh).
- [ ] Không sửa bất kỳ file nào trong `Core/` (M0-5 là App/Presentation thuần túy; nếu phát hiện Core thiếu API cho UI → dừng, ghi nhận, đề xuất — không tiện tay sửa).
- [ ] `needsClarification` hiển thị câu hỏi, không hiển thị stack trace.
- [ ] Lỗi Gateway (budget, provider) hiển thị thân thiện theo UI contract.
- [ ] `swift build` + toàn bộ test (unit + architecture) vẫn 36+/36+ pass trên Linux (SPM package không đổi).
- [ ] Self Review + Architecture Review + cập nhật docs + NEXT_TASK mới (M0-6).

## Definition of Done

Luồng "gõ goal → thấy events → nhận kết quả → goal lặp lại trả về tức thì (reuse)" hoàn chỉnh ở mức code + test package xanh; xác minh chạy thật trên simulator thuộc M0-6 (cần Mac). Tài liệu cập nhật; NEXT_TASK M0-6 đã tạo.

## Estimated Complexity

Thấp–Trung bình — 2 file SwiftUI mới + 3 file sửa; rủi ro chính là không compile được UI trên Linux.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0 (Placeholder).

## Risk

- **App/Presentation không qua compiler trong môi trường này** — giữ SwiftUI tối giản, tránh API mới lạ; mọi lỗi compile sẽ lộ ở lần build Mac đầu tiên (M0-6 đã có mục xác minh).
- Concurrency SwiftUI (@Observable + Task + AsyncStream): giữ mọi state mutation trên @MainActor.

## Những phần tuyệt đối không được sửa

- Toàn bộ `Core/**` và `Infrastructure/**` (M0-5 không có lý do chạm vào).
- Architecture Test rules (chỉ được THÊM).
- Config schema, Package.swift targets.
- Không tích hợp provider thật (AD-31 — thuộc M0-6).
