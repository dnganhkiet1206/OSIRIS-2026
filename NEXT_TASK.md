# NEXT_TASK.md

> Quy trình phiên làm việc: đọc `Docs/PROJECT_STATE.md` → đọc file này → đọc các file liên quan → thiết kế → kiểm tra tái sử dụng → triển khai → Self Review → Architecture Review → refactor nếu cần → cập nhật tài liệu → cập nhật PROJECT_STATE → tạo NEXT_TASK mới → kết thúc. Không bỏ qua bước nào.

## Current Milestone

**M0 — Walking Skeleton** (DEVELOPMENT_PLAN.md §2)

## Current Task

**M0-3 — AI Gateway v0: provider adapter thật**

## Mục tiêu

1. `AnthropicProvider`: adapter đầu tiên implement `AIProvider` — gọi Anthropic Messages API bằng URLSession thuần (AD-27), đọc usage thật (input/output tokens, model) từ response vào `AIUsage`.
2. `RoutingConfiguration` promote từ CompositionRoot vào `Core/AIGateway/Routing/` (Gateway bắt đầu tiêu thụ routing trực tiếp).
3. `KeychainSecretsVault` trong App layer (implement `SecretsVault` bằng Keychain Services) — chỉ viết, kiểm chứng compile ở Mac.
4. CompositionRoot: chọn provider theo nguyên tắc *graceful*: có API key trong SecretsVault → AnthropicProvider; chưa có key → PlaceholderAIProvider (app luôn chạy được, không crash vì thiếu key).

## Lý do cần làm

Đây là bước biến walking skeleton thành hệ thống thật: AI call đầu tiên có chi phí thật → kích hoạt đo lường AD-15 và tạo **token baseline** đầu tiên của dự án. Không có provider thật thì M0-4/M0-5 chỉ demo với dữ liệu giả.

## Các file cần tạo

- `Core/AIGateway/Providers/AnthropicProvider.swift` — request/response DTO tối thiểu cho Messages API; parse usage; error rõ ràng (401/429/5xx).
- `Core/AIGateway/Routing/RoutingConfiguration.swift` — struct Decodable (defaultModelID, tierDefaults) chuyển từ CompositionRoot vào Core.
- `App/AppComposition/KeychainSecretsVault.swift` — Keychain impl của SecretsVault (App layer vì cần Security framework).
- `Tests/CoreTests/AnthropicProviderTests.swift` — parse response từ JSON fixture (KHÔNG gọi mạng thật trong test); test map lỗi HTTP.

## Các file cần sửa

- `App/AppComposition/CompositionRoot.swift` — bỏ private RoutingConfiguration (dùng bản Core), logic chọn provider theo key.
- `Config/models.json` + `Config/routing.json` — thêm model Anthropic thật cho tier light (giữ placeholder làm fallback).
- `Docs/PROJECT_STATE.md`, `CHANGELOG.md`, `NEXT_TASK.md` (bản mới cho M0-4) — cuối phiên.

## Dependency

- Đã có: `AIProvider`/`AIGateway` contract, `AIUsage`, `SecretsVault` protocol, ConfigurationLoader.
- Không thêm SDK/dependency ngoài — URLSession thuần (AD-27). Trên Linux test dùng fixture, không network.

## Checklist

- [ ] AnthropicProvider parse đúng text + usage từ fixture response.
- [ ] Lỗi HTTP map thành error có thể hiển thị thân thiện (UI contract: what happened / attempted / next).
- [ ] Không hardcode model ID trong code — chỉ từ routing.json.
- [ ] API key chỉ đi qua SecretsVault; **không bao giờ** xuất hiện trong log, prompt, config file (Prompt Security).
- [ ] App chạy được khi chưa có key (Placeholder fallback) — không crash.
- [ ] `swift build` 0 error / 0 warning; `swift test` pass toàn bộ.
- [ ] Không tái tạo component bị cấm; mọi AI call vẫn chỉ qua AI Gateway.
- [ ] Self Review + Architecture Review + cập nhật docs + NEXT_TASK mới (M0-4).

## Definition of Done

Provider thật hoạt động sau AI Gateway với usage được log (AD-15); routing config sống trong Core; Keychain vault viết xong chờ kiểm chứng Mac; test parse/error pass không cần mạng; tài liệu cập nhật; NEXT_TASK M0-4 đã tạo.

## Estimated Complexity

Trung bình — 1 adapter mạng + DTO + error mapping; không đụng contract Core nào ngoài việc *thêm* RoutingConfiguration.

## Estimated AI Cost

Dev session: nhỏ (nạp PROJECT_STATE + NEXT_TASK + 3 file AIGateway). Runtime: lần đầu phát sinh chi phí thật — chỉ khi user có key; test không tốn token.

## Các rủi ro

- Test gọi mạng thật = flaky + tốn tiền → cấm; chỉ fixture. Smoke test thật thực hiện thủ công ở M0-5.
- Keychain code không compile được trên Linux → không đưa vào SPM target; nằm ở App/ (Xcode-only), rủi ro lỗi compile tồn đến khi build Mac đầu tiên — giữ file nhỏ nhất có thể.
- API schema thay đổi theo version header → pin `anthropic-version` trong adapter, ghi chú nguồn.

## Những phần tuyệt đối không được sửa

- Protocol `AIGateway`, `AIProvider`, `Store` (chỉ thêm implementation/type mới, không đổi interface).
- `Kernel`, `ExecutionEngine` (thuộc M0-4).
- 6 thành phần Core, cấu trúc thư mục, Package.swift targets, danh sách component bị cấm (SYSTEM_COMPONENTS.md §6).
- `Docs/PROJECT_BLUEPRINT.md` (trừ khi có AD mới được duyệt).
