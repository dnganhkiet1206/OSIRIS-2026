# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M5 — Platform Expansion** (DEVELOPMENT_PLAN.md §2/M5) — CHỜ USER XÁC NHẬN MỞ

## Current Task

**M5-0 — TikTok Module + MODULE_GUIDE.md (nhân bản khuôn lần đầu, viết guide bằng trải nghiệm thật)**

## Objective

M5 = nhân bản mô hình module. M5-0 làm HAI việc gắn chặt nhau: (1) dựng **TikTok module** (module thứ hai, thứ tự giá trị DEVELOPMENT_PLAN: TikTok trước) bằng CHÍNH khuôn YouTube — kỳ vọng chứng minh "0 dòng Core, 0 dòng contract" lần thứ tư; (2) trong lúc dựng, ghi lại từng bước thành **`Docs/MODULE_GUIDE.md`** — tài liệu DUY NHẤT người ngoài cần đọc để viết module (lỗ hổng open-source chỉ ra tại M4-4: guideline đang rải trong code comments/CHANGELOG).

## Phạm vi

1. **TikTok module v0** (`Modules/TikTok/TikTokModule.swift`): manifest `tiktok` + 3–4 skill data theo capability DEVELOPMENT_PLAN (content-planning, trend-research→dùng dữ liệu user dán như AD-45, publishing-package); ≥1 composition (cân nhắc xuyên namespace `core.research-outline` → tiktok skill — đã có tiền lệ); keywords: chạy sweep test chống overlap toàn registry (giờ 2 module — sweep mở rộng thành rule chung cho MỌI cặp skill, không chỉ skill mới).
2. **`Docs/MODULE_GUIDE.md`** — viết TRONG LÚC dựng TikTok, mục lục tối thiểu: manifest & namespace (precondition); skill = data (template/{goal}/tier/keywords); composition & curated-union guideline (2 bài học M4-1/M4-2 + luật tie-break id); precedence tests bắt buộc; đăng ký 1 dòng ở composition root; những gì module KHÔNG được làm (arch rules); khi nào cần hơn data → AD-45/M6.
3. **Wiring:** thêm `TikTokModule.manifest` vào `installedModules` (1 dòng — đúng lời hứa AD-44).
4. **Không làm:** không sửa khuôn để "tiện cho TikTok" (khuôn đổi = phải có bằng chứng + AD); không Shopify/Etsy (M5-1+); không tool-channel (M6).

## Files cần tạo/sửa

- `Modules/TikTok/TikTokModule.swift`, `Docs/MODULE_GUIDE.md`, `Tests/ModuleTests/TikTokModuleTests.swift`, CompositionRoot (1 dòng), docs cuối phiên.

## Checklist

- [ ] 0 dòng Core, 0 dòng contract — lần thứ tư liên tiếp.
- [ ] Sweep test nâng cấp: quét MỌI cặp skill trong registry hợp nhất (youtube × tiktok × generic) — trả lời câu n² một lần cho mãi mãi.
- [ ] MODULE_GUIDE đủ để người không đọc Core viết được module (thước đo: chính TikTok module chỉ dùng kiến thức trong guide).
- [ ] Zero regression 132 test cũ.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M5-1 — module kế theo giá trị, hoặc đánh giá lại thứ tự với user).

## Definition of Done

TikTok module chạy end-to-end offline qua lifecycle nguyên trạng; 2 module chung sống không giẫm keywords (test); MODULE_GUIDE.md hoàn chỉnh tự đứng được; zero regression; khuôn không đổi.

## Estimated Complexity

Thấp–trung bình — khuôn đã có; giá trị chính là guide + sweep tổng.

## Estimated AI Cost

Dev session: nhỏ–trung bình. Runtime: 0.

## Risk

- Hai module + generic = không gian keyword chật hơn — sweep tổng + precedence tests là lưới an toàn; nếu xuất hiện ca curated-union KHÔNG giải được, đó là bằng chứng matcher (dừng, ghi nhận, không tự sửa).
- MODULE_GUIDE phình thành sách — giữ ≤2 trang, mọi thứ dài hơn là dấu hiệu contract chưa đủ đơn giản.

## Những phần tuyệt đối không được sửa

- Core 6; ModuleManifest; matcher; YouTube module (khuôn tham chiếu — TikTok copy, không sửa gốc).
- Architecture Test rules (chỉ THÊM/siết); ADR cũ (AD-01…AD-46).
