# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.
>
> **Song song:** nợ High — user chưa chạy `Docs/RUNBOOK_M1-0.md`. Nếu kết quả được dán vào phiên: xử lý trước, task dưới sau.

## Current Milestone

**M5 — Platform Expansion** (DEVELOPMENT_PLAN.md §2/M5) — tiến độ 1/≥3 module

## Current Task

**M5-1 — Shopify Module (module thứ ba, domain khác hẳn content-creation)**

## Objective

Module 1 (YouTube) + module 2 (TikTok) đều là content-creation — cùng "họ" nghiệp vụ. Shopify là domain KHÁC HẲN (thương mại điện tử: product research, listing, store analysis). Giá trị M5-1: chứng minh khuôn + MODULE_GUIDE hoạt động cho domain **không giống** hai module đầu (bằng chứng mạnh hơn cho "Contract v1 đủ tổng quát"), và đạt mốc **3 module = tiêu chí hoàn thành M5** (DEVELOPMENT_PLAN). Đây cũng là bài kiểm tra guide lần 2: nếu Shopify cần quay lại đọc Core → guide chưa đạt cho domain mới.

## Phạm vi

1. **Đọc trước:** CHỈ `Docs/MODULE_GUIDE.md` + `Core/Modules/Contracts/ModuleManifest.swift` (đóng vai session mới — như M5-0). Nếu thấy cần đọc thêm Core → DỪNG, ghi lại guide thiếu gì (đó là finding quan trọng hơn cả module).
2. **Shopify module v0** (`Modules/Shopify/ShopifyModule.swift`): 3–4 skill data theo DEVELOPMENT_PLAN (product-research, landing-page/listing-optimization, store-analysis); store-analysis dùng dữ liệu user dán (AD-45 — thương mại cũng cần số liệu thật); ≥1 composition (cân nhắc xuyên namespace).
3. **Tests** theo MODULE_GUIDE §7 (manifest, e2e, precedence, sweep module-mới-không-giẫm, composition); keywords chứa định danh "shopify"/"store"/"product" — rà sweep.
4. **Wiring:** 1 dòng `installedModules`.
5. **Không làm:** Shopify API/OAuth/webhook (M6, AD-45); không sửa Core/contract/matcher/module cũ.

## Files cần tạo/sửa

- `Modules/Shopify/ShopifyModule.swift`, `Tests/ModuleTests/ShopifyModuleTests.swift`, CompositionRoot (1 dòng), docs cuối phiên.

## Checklist

- [ ] Guide-test lần 2: dựng Shopify KHÔNG đọc Core — nếu phải đọc, ghi finding + bổ sung guide.
- [ ] 0 dòng Core, 0 dòng contract, 0 dòng matcher, 0 dòng module cũ.
- [ ] Sweep: keyword Shopify không giẫm toàn registry (giờ 3 module + generic + tool).
- [ ] Zero regression 139 test cũ.
- [ ] Đủ quy trình review + docs + NEXT_TASK (M5-2 hoặc M5 review nếu 3 module đủ chứng minh — tự đánh giá).

## Definition of Done

Shopify chạy end-to-end offline; đạt mốc 3 module Core-không-đổi (tiêu chí M5); guide-test lần 2 kết luận rõ (đạt / thiếu gì); zero regression.

## Estimated Complexity

Thấp — khuôn + guide đã có; giá trị là bằng chứng domain-khác + guide-test lần 2.

## Estimated AI Cost

Dev session: nhỏ. Runtime: 0.

## Risk

- Domain thương mại có thể lộ nhu cầu contract mới (vd cần structured product data) — nếu xuất hiện, DỪNG, đó là bằng chứng thật cho quyết định mở contract (AD-45/M6), không tự mở.
- 3 module + generic = keyword chật hơn — sweep + precedence là lưới.

## Những phần tuyệt đối không được sửa

- Core 6; ModuleManifest; matcher; YouTube/TikTok module (khuôn — copy, không sửa).
- Architecture Test rules (chỉ THÊM/siết); ADR cũ (AD-01…AD-46).
