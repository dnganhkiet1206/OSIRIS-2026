# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M6 — Automation** (DEVELOPMENT_PLAN.md §2/M6) — CHỜ USER XÁC NHẬN MỞ

## Current Task

**M6-0 — Automation bootstrap: ApprovalGate có consumer đầu tiên (risky-action) HOẶC xóa**

## Vì sao task này trước

M6 là nơi 3 deadline/điều kiện đã hẹn cùng đến hạn — làm đúng thứ tự bằng chứng, KHÔNG xây visual workflow builder (DEVELOPMENT_PLAN §2/M6 cấm rõ):
1. **ApprovalGate** (nợ Low, hẹn cứng M6): wired từ M0, chưa từng tham vấn vì chưa có risky action. M6 introduce risky action đầu tiên (scheduling/publish) → gate PHẢI có consumer thật, hoặc xóa nếu automation v1 chưa có hành động rủi ro. Quyết bằng bằng chứng.
2. **AD-45 tool-channel** (điều kiện M6): MCP/remote tools (AD-18) — nếu automation cần gọi ngoài, đây là lúc câu hỏi mở-contract-tools quay lại VỚI use case thật. Nếu chưa cần → giữ đóng.
3. **EventBus tái sinh** (AD-46): automation có tạo audience ĐỘNG (nhiều rule subscribe) không? Nếu có → bus được earn lại bằng bằng chứng; nếu không → tiếp tục fan-out closure.

## Phạm vi (lát cắt mỏng nhất — walking skeleton của M6)

1. **Architecture Review TRƯỚC code** (như M4-3): automation "rule" là gì ở dạng đơn giản nhất? Đề xuất khởi điểm: **rule = (trigger điều kiện) → (goal/skill composition có sẵn)** thuần data, KHÔNG engine. Tự phản biện: có phải chỉ là một cách lưu goal + điều kiện chạy? Có tái dùng vòng đời Kernel hiện có không? (phải có).
2. **Risky action + ApprovalGate:** định nghĩa risky action ĐẦU TIÊN cụ thể (vd "tự động chạy goal theo lịch" có rủi ro tốn token/side-effect) → Kernel tham vấn `approvalGate` trước khi thực thi; test chứng minh gate chặn/cho qua. Nếu kết luận automation v1 CHƯA có risky action thật → xóa ApprovalGate đúng quy trình (như EventBus M4-4).
3. **iOS background limits** (rủi ro theo dõi từ M1): scheduling trong giới hạn iOS — chỉ thiết kế interface, KHÔNG cần background thật trên Linux (ghi PENDING thiết bị như UI).
4. **Không làm:** visual workflow builder; scheduler/dispatcher engine; MCP thật nếu chưa có use case; bất kỳ engine mới nào chưa có bằng chứng (Năm Câu Hỏi + DỪNG hỏi user).

## Checklist

- [ ] Architecture Review 11 câu trước khi code (chạm vùng nhạy: Kernel tham vấn gate).
- [ ] ApprovalGate: quyết consume (có test risky-action) HOẶC xóa (đúng quy trình, arch rule cập nhật).
- [ ] Automation = data + vòng đời Kernel hiện có; 0 engine mới không bằng chứng.
- [ ] Nếu chạm Core (Kernel gọi gate là vùng Core): tối thiểu, có arch test, không phá 146 test cũ.
- [ ] Zero regression; đủ review + docs + NEXT_TASK.

## Definition of Done

Lát cắt automation v1 chạy end-to-end offline (rule data → Kernel → gate → execution); ApprovalGate quyết xong bằng bằng chứng; iOS-background khoanh vùng PENDING; zero regression.

## Estimated Complexity

Trung bình — chạm Kernel/gate (vùng nhạy); trọng tâm là quyết định kiến trúc automation-là-gì.

## Estimated AI Cost

Dev session: trung bình. Runtime: 0 (test offline).

## Risk

- Automation dễ phình thành workflow engine — DEVELOPMENT_PLAN cấm rõ; mỗi cấu trúc mới qua Năm Câu Hỏi.
- ApprovalGate: xóa vội nếu M6 thật sự cần, hoặc giữ vô ích nếu automation v1 chưa rủi ro — quyết bằng risky action CỤ THỂ, không phỏng đoán.

## Những phần tuyệt đối không được sửa

- Core 6 (trừ Kernel-tham-vấn-gate nếu review chứng minh cần — tối thiểu, có test); ModuleManifest; matcher; 3 module.
- Architecture Test rules (chỉ THÊM/siết); ADR cũ (AD-01…AD-46).
