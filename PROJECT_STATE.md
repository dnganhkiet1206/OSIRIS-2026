# PROJECT_STATE.md — Trạng Thái Dự Án OSIRIS

> **Cập nhật lần cuối:** 2026-07-02
> Đây là **nguồn sự thật duy nhất** về trạng thái dự án (nguyên tắc *State Over Chat*). Mọi phiên phát triển bắt đầu bằng việc đọc file này và kết thúc bằng việc cập nhật file này. Giữ file ngắn gọn, dạng cấu trúc — không viết đoạn văn dài.

---

## 1. Tổng quan nhanh

| Hạng mục | Giá trị |
|---|---|
| Giai đoạn | **Pre-code — Kiến trúc đã chốt, chưa viết dòng code nào** |
| Milestone hiện tại | Chuẩn bị **M0 — Walking Skeleton** (xem DEVELOPMENT_PLAN.md) |
| Nền tảng | iOS (iPhone), SwiftUI |
| Trạng thái kiến trúc | ✅ Đã review & hợp nhất từ 18 file đặc tả gốc |
| Trạng thái codebase | Trống (chỉ có tài liệu) |

## 2. Mục tiêu hiện tại (Current Goal)

Hoàn tất bộ tài liệu nền tảng và bắt đầu Milestone 0: một lát cắt dọc mỏng chạy end-to-end (Chat UI → Kernel tối giản → AI Gateway → kết quả + persist Project State).

## 3. Việc đã hoàn thành (Completed)

- [x] Viết 18 phần đặc tả gốc (OSIRIS 1–18 .docx).
- [x] Architecture Review toàn bộ đặc tả: phát hiện 21 vấn đề trùng lặp / mâu thuẫn / nguy cơ debt (AD-01 → AD-21, xem PROJECT_BLUEPRINT.md §3).
- [x] Hợp nhất kiến trúc: ~16–20 tên component → **9 Core component**; 5 pipeline → **1 vòng đời chuẩn 5 pha**; 6 registry → **2**.
- [x] Chuẩn hóa memory model 4 tầng (Vision / Knowledge / Project Memory / Working Context).
- [x] Sửa mâu thuẫn roadmap (Workflow ở M1 vs M6) bằng mô hình workflow-as-skill-composition.
- [x] Ban hành bộ 5 tài liệu nền tảng: BLUEPRINT, STATE, PLAN, FOLDER_STRUCTURE, SYSTEM_COMPONENTS.

## 4. Việc đang chờ (Next Tasks) — theo thứ tự

1. Khởi tạo Xcode project theo `FOLDER_STRUCTURE.md` (M0-1).
2. Dựng khung Infrastructure tối thiểu: Config, Logging, Storage (M0-2).
3. AI Gateway v0: 1 provider adapter + đo token/cost (M0-3).
4. Kernel v0: vòng đời 5 pha dạng tối giản (chưa có skill selection) (M0-4).
5. Chat UI v0 + Execution Status events (M0-5).
6. State Store v0: persist Project State ra local storage (M0-6).

## 5. Quyết định kiến trúc đã chốt (Architecture Decisions Log)

Chi tiết đầy đủ tại PROJECT_BLUEPRINT.md §3. Tóm tắt:

| ID | Quyết định |
|---|---|
| AD-01 | Một bộ não duy nhất: `Kernel` (hợp nhất Planner + Executive Brain + Intelligent Execution) |
| AD-02 | Một `Context Engine` duy nhất (bỏ tên Context Loader / Context Builder) |
| AD-03 | Một `Skill Registry`; Capability = tag trên Skill, không có registry riêng |
| AD-04 | Prompt template nằm trong Skill definition; không có Prompt Registry |
| AD-05 | Validation = gates trong vòng đời Kernel; Confidence = 3 tier (High/Medium/Low), không dùng điểm số |
| AD-06 | `AI Gateway` = Model Router + Token Manager + Provider Layer hợp nhất; cửa duy nhất cho AI call |
| AD-07 | Workflow = declarative skill composition, chạy bởi Execution Engine; không có Workflow Engine riêng |
| AD-08 | Executive State = view phái sinh từ Project State, không persist riêng |
| AD-09 | Memory 4 tầng: Vision / Knowledge / Project Memory / Working Context; Archive là flag |
| AD-10 | Deliverable = bản ghi trong State + file; không có Deliverable Registry |
| AD-11 | Chat thuộc Presentation, không thuộc Core |
| AD-12 | Một vòng đời chuẩn 5 pha: Intake → Decide → Execute → Verify → Persist |
| AD-13 | System Preamble tĩnh < 400 token, dùng prompt caching; mọi context khác retrieve theo nhu cầu |
| AD-14 | 5 tài liệu này thay 18 file gốc làm context cho dev session |
| AD-15 | Mọi AI call phải được đo (token, cost, cache-hit, model) tại AI Gateway |
| AD-16 | Roadmap theo walking skeleton, không big-bang foundation |
| AD-17 | Chỉ 2 registry: Skill Registry + Module Manifest |
| AD-18 | Tool Layer chia on-device (Apple frameworks) và remote (MCP client, tùy chọn) |
| AD-19 | Module giao tiếp qua Event Bus + capability contract, không gọi đích danh module khác |
| AD-20 | Learning bị gate: chỉ từ kết quả đo được / user correction xác nhận; là policy của Memory Store |
| AD-21 | YouTube Module là reference implementation cho mọi module sau |

## 6. Vấn đề đã biết & Nợ kỹ thuật (Known Issues / Tech Debt)

| Mức | Mô tả | Kế hoạch |
|---|---|---|
| Minor | 18 file .docx gốc còn trong repo, trùng ~40% nội dung với bộ tài liệu mới | Giữ làm tham chiếu lịch sử; **không nạp vào AI context** (AD-14). Cân nhắc chuyển vào `Docs/archive/` khi khởi tạo project |
| Minor | Chưa chọn provider AI đầu tiên cho M0 và cơ chế lưu trữ local (SwiftData vs file JSON) | Quyết định ở M0-2/M0-3; yêu cầu: dễ thay thế, đúng contract AI Gateway |
| Ghi chú | Chưa có số liệu token baseline | Bắt đầu đo từ AI call đầu tiên (AD-15) |

## 7. Rủi ro đang theo dõi

- **Scope creep module:** danh sách module tương lai rất dài — chỉ được bắt đầu module mới sau khi YouTube module đạt chuẩn reference (AD-21).
- **iOS background limits:** task chạy dài trên iPhone bị hệ điều hành giới hạn — thiết kế Execution Engine phải resume được sau khi app bị suspend (đưa vào tiêu chí M1).
- **Provider lock-in:** mọi tính năng chỉ được dùng provider qua AI Gateway; vi phạm = fail code review.

## 8. Quy tắc cập nhật file này

- Cập nhật sau **mỗi** phiên phát triển (nguyên tắc Session Continuity).
- Chỉ ghi thông tin có giá trị tương lai; xóa mục đã hết hạn.
- Không ghi lại nội dung hội thoại; chỉ ghi trạng thái, quyết định, việc còn lại.
