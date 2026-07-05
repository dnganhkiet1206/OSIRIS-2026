# DEVELOPMENT_PLAN.md — Kế Hoạch Phát Triển OSIRIS

> **Phiên bản:** 1.1 · **Ngày:** 2026-07-02 · *(v1.1: cập nhật theo vòng review 2 — Core 6 thành phần, AD-22…AD-29)*
> Roadmap này **sửa lại** roadmap gốc (Part 15) theo quyết định AD-16: thay "big-bang foundation" bằng **walking skeleton** — một lát cắt dọc mỏng chạy end-to-end ngay từ M0, sau đó dày dần từng lớp. Lý do: đặc tả gốc yêu cầu xây ~16 core component (M0+M1) trước khi có bất kỳ giá trị người dùng nào — vi phạm chính nguyên tắc "smallest solution" và trì hoãn việc kiểm chứng kiến trúc bằng thực tế.

---

## 0. Nguyên tắc thi công

- **Một milestone tại một thời điểm.** Không bắt đầu milestone kế tiếp khi milestone hiện tại chưa qua đủ: Architecture Review, Quality Review, Token Review, cập nhật PROJECT_STATE.md.
- **Mỗi milestone kết thúc ở trạng thái chạy được** (production-ready cho phạm vi của nó), không phải "gần xong".
- **Nợ kỹ thuật Critical phải trả trước khi sang milestone mới.** Important/Minor ghi vào PROJECT_STATE.md.
- **Đo trước, tối ưu sau.** Không tối ưu sớm; nhưng đo (token/cost/time) ngay từ M0 để có baseline (AD-15).
- Mỗi chu kỳ trong milestone: Design → Implement → Test → Review → Optimize → Update State/Memory → Commit.

## 1. Lộ trình tổng quan

```
M0 Walking Skeleton      ── chứng minh kiến trúc bằng lát cắt dọc mỏng nhất
M1 Core Runtime          ── Kernel đầy đủ 5 pha, Skill Registry, Memory, Context
M2 User Experience       ── ứng dụng dùng được hằng ngày: Sidebar, Projects, Search
M3 Intelligence Layer    ── quyết định thông minh hơn, rẻ hơn: cache, reflection
M4 YouTube Module        ── module nghiệp vụ đầu tiên = reference implementation
M5 Platform Expansion    ── nhân bản mô hình module (TikTok, Shopify, …)
M6 Automation            ── scheduling, background, MCP mở rộng
M7 Optimization          ── hạ chi phí vận hành toàn hệ thống
M8 Production Readiness  ── ổn định lâu dài: test, security, backup, recovery
```

---

## 2. Chi tiết milestone

### M0 — Walking Skeleton *(thay thế Milestone 0 gốc)* — ✅ ĐÃ NGHIỆM THU 2026-07-02 (tag `M0`; 2 pending: Mac simulator + baseline provider thật → M1-0)

**Mục tiêu:** Một request đi hết vòng đời 5 pha ở dạng tối giản và trả về kết quả thật, kèm persist Project State. Chứng minh mọi tầng kiến trúc nói chuyện được với nhau.

**Phạm vi:**
1. Khung Xcode project theo `FOLDER_STRUCTURE.md`.
2. Infrastructure tối thiểu: Configuration (file JSON + `preamble.md`), Logging có cấu trúc, Local Storage, Event Bus mỏng (AD-26).
3. **AI Gateway v0:** đo token/cost mỗi call (AD-15), System Preamble tĩnh từ Config (AD-13, AD-23). Provider thật là Integration — hoãn đến khi Core hoàn thiện (AD-31); PlaceholderProvider là provider duy nhất trong M0.
4. **Kernel v0:** vòng đời Intake → Decide → Execute → Verify → Persist. Tách hai bước để bảo vệ ranh giới Decision/Execution (AD-32/33): *M0-4A* — Decide thuần túy (reuse detection, strategy, confidence; Kernel không side effect, không phụ thuộc Infrastructure); *M0-4B* — Execution materialize deliverable, Store là persister duy nhất ghi deliverable file + index.
5. **Chat UI v0:** một màn hình chat + Execution Status events.
6. **Store v0:** bản ghi ProjectState đọc/ghi local, khôi phục khi mở lại app.
7. **Architecture Tests (AD-34):** test target quét source cưỡng chế quy tắc kiến trúc (một persister, một cổng AI, Kernel thuần túy, cấm tái tạo component đã loại bỏ) — chạy trong `swift test`, chống architecture drift từ M0.

**Không làm ở M0:** Skill Registry, Knowledge/WorkingContext records, Module, Search, Dashboard, Advanced Mode.

**Tiêu chí hoàn thành:** Người dùng gõ một mục tiêu → thấy execution events → nhận kết quả → tắt app mở lại vẫn thấy ProjectState. Token mỗi call được log.

### M1 — Core Runtime *(gộp Milestone 0+1 gốc, trừ phần đã làm ở M0)* — ✅ ĐÃ NGHIỆM THU 2026-07-02 (tag `M1`; chi tiết PROJECT_STATE §4c)

> **Quyết định chốt tại M1 Review (AD-36):** Parallel Execution và Resume-after-suspend HOÃN — không có bằng chứng cần trong M1. Điều kiện kích hoạt: *Parallel* khi Planner tách goal thành nhiều task độc lập (M3 — Smart Planning); *Resume* khi có bằng chứng mất tiến độ thật do iOS suspend trên thiết bị (sau khi app chạy thật từ M2). Không xây trước khi điều kiện xuất hiện.

**Mục tiêu:** Kernel đầy đủ, hệ điều hành AI thực sự vận hành.

**Phạm vi:**
1. **Skill Registry:** schema tối thiểu (AD-28: 6 trường bắt buộc, còn lại optional); 3–5 skill tổng quát (Research, Summarize, Document…).
2. **Store đầy đủ:** thêm bản ghi Knowledge + WorkingContext (TTL); năng lực search/retrieval; policy ghi + learning gate (AD-20, AD-22).
3. **AI Gateway đầy đủ:** retrieve qua Store.search → assemble → context budget 4 mức → compression cơ bản → cache → route (AD-24).
4. **Execution Engine đầy đủ:** parallel task độc lập, retry/fallback theo policy khai báo — escalation về Kernel (AD-25), workflow-as-skill-composition (AD-07), resume sau khi app suspend.
5. **Kernel đầy đủ:** decision theo thứ tự tài nguyên (data → cache → logic → tool → workflow → AI), Confidence 3 tier, approval gates cho hành động rủi ro.
6. **Tool Layer v1:** on-device tools (filesystem, network qua URLSession trực tiếp — AD-27, media qua Apple frameworks).

**Tiêu chí hoàn thành:** Runtime thực thi được task tổng quát nhiều bước một cách tin cậy; task có thể hoàn thành **không cần AI call nào** khi tài nguyên có sẵn đáp ứng; mọi AI call đều qua AI Gateway.

### M2 — User Experience *(giữ Milestone 2 gốc)* — ✅ ĐÃ NGHIỆM THU 2026-07-02 (tag `M2`, code-complete; xác minh thiết bị PENDING runbook — PROJECT_STATE §4d)

**Mục tiêu:** Ứng dụng cảm giác hoàn chỉnh, dùng hằng ngày được.

**Phạm vi:** Sidebar (Chat, Projects, Settings; Advanced Mode ẩn) · Projects (goals, files, deliverables, history, resume tức thì) · Settings tối giản · Global Search · Dashboard nhận thức vận hành (Current Goal/Task, Progress, Token Usage, System Status) · Advanced Mode (Memory Viewer, Logs, Token Analysis, Model Routing) · Accessibility (Dynamic Type, VoiceOver, Dark/Light) từ đầu.

**Tiêu chí hoàn thành:** Người dùng mới hiểu app trong phút đầu tiên, không cần hướng dẫn; mọi màn hình đạt UI contract (không lộ reasoning, lỗi thân thiện).

### M3 — Intelligence Layer *(giữ Milestone 3 gốc, đã gọn hóa theo AD-05/AD-10/AD-20)* — ✅ ĐÃ NGHIỆM THU 2026-07-03 (tag `M3`; chi tiết PROJECT_STATE §4e)

> **Hoãn có điều kiện kích hoạt (chốt tại M3-4):** (1) *Reuse pipeline nới* (relevance-ranked reuse, cross-project) — kích hoạt khi có dữ liệu sử dụng thật cho thấy miss-rate đáng kể; wrong-reuse đắt hơn miss nên không nới bằng phỏng đoán. (2) *Cache optimization* (bound/TTL/eviction) — kích hoạt khi có số liệu hit-rate thật từ thiết bị (runbook M1-0 + sử dụng M4). Không xây trước khi điều kiện xuất hiện.

**Mục tiêu:** Quyết định tốt hơn trước khi gọi model — rẻ hơn mà chất lượng cao hơn.

**Phạm vi:** Smart planning (ước lượng complexity/cost trước khi chạy) · Reuse pipeline hoàn chỉnh (search deliverable/memory/cache trước khi tạo) · Response cache + prompt cache tối ưu · Reflection sau task (cải thiện lần sau, có gate AD-20) · Deliverable indexing & templates (Executive Summary, actionable next steps) · Tự động cập nhật Project State/Memory sau mỗi execution.

**Tiêu chí hoàn thành:** Số AI call và token trung bình cho cùng loại task **giảm có đo lường** so với baseline M1; chất lượng deliverable qua Verify gate ổn định. *(Nghiệm thu: cơ chế giảm chứng minh bằng test vĩnh viễn — reuse/tool = 0 call, cache-hit; số token provider thật PENDING runbook, không giả số liệu.)*

### M4 — YouTube Module (Reference Implementation) — ✅ ĐÃ NGHIỆM THU 2026-07-03 (tag `M4`; chi tiết PROJECT_STATE §4f)

> **Chốt tại M4-4:** khuôn mẫu module PROVEN với 4/9 mảng (ideas, script, SEO+publishing, channel analysis) — các mảng còn lại (Thumbnail, Shorts, Project Tracking…) là data thuần theo khuôn có sẵn, bổ sung **theo nhu cầu thật khi dùng app**, không phải để đủ danh sách. EventBus xóa đúng deadline (AD-46). Tool-channel cho module: điều kiện kích hoạt tại M6 (AD-45).

**Mục tiêu:** Module nghiệp vụ production-quality đầu tiên; trở thành khuôn mẫu bắt buộc cho mọi module sau (AD-21).

**Phạm vi:** Research, Channel Analysis, Idea Generation, Script Generation, SEO, Thumbnail Planning, Shorts Planning, Publishing Package, Project Tracking — tất cả hiện thực dưới dạng **Skills + Templates trong module**, tái dùng toàn bộ Core.

**Tiêu chí hoàn thành:** Hoàn thành công việc YouTube có ý nghĩa từ đầu tới cuối chỉ bằng mục tiêu một câu; module tuân thủ 100% Module contract (manifest, cấu trúc thư mục chuẩn, không đụng Core). *(Nghiệm thu: end-to-end offline bằng test; chất lượng nội dung thật PENDING runbook.)*

### M5 — Platform Expansion — ✅ ĐÃ NGHIỆM THU 2026-07-04 (tag `M5`; chi tiết PROJECT_STATE §4g)

> **M5-0/M5-1/M5-2 (2026-07-04):** TikTok + Shopify = module thứ hai & ba, mỗi cái dựng chỉ từ `Docs/MODULE_GUIDE.md` — 0 dòng Core/contract. Bài kiểm tra guide đạt 2 lần (content-creation + e-commerce). Guide tự-đủ (Phụ lục A+B). Contract v1 giữ nguyên qua cả 3 module. M5-2 review: plugin architecture PROVEN; không AD mới; tiếp theo M6.

**Mục tiêu:** Nhân bản mô hình module. Thứ tự đề xuất theo giá trị: TikTok → Shopify → Etsy → Instagram/Facebook → Research/Documents → Trading Research.

**Quy tắc:** mỗi module copy đúng cấu trúc YouTube module (`Docs/MODULE_GUIDE.md`); **không** sửa Core; nếu một module "cần" sửa Core → dừng lại, review kiến trúc trước.

**Tiêu chí hoàn thành:** ≥ 3 module mới hoạt động mà Core không đổi (chứng minh plugin architecture). *(✅ ĐẠT: YouTube M4 + TikTok M5-0 + Shopify M5-1 — 3 module, 0 dòng Core. Nghiệm thu chính thức tại M5-2.)*

### M6 — Automation — ✅ CORE NGHIỆM THU 2026-07-04 (tag `M6`; chi tiết PROJECT_STATE §4h)

> **M6-0/1/2/3 (2026-07-04):** AD-47 (4 quyết định: xóa ApprovalGate, tool-channel không mở, EventBus không tái sinh, automation=data). M6-1 automation-as-data (record+port+run-now), M6-2 Automation UI (VM riêng, tôn trọng trigger M2-6). **HOÃN CÓ ĐIỀU KIỆN:** *scheduled background firing* (iOS BGTaskScheduler) — kích hoạt khi có thiết bị/simulator test bg task; *MCP remote tools* (AD-18) = mở tool-channel (AD-45) + risky action + ApprovalGate tái sinh, chờ use case thật + user consent network. Risky action vẫn chưa tồn tại (automation chỉ sinh deliverable local).

**Mục tiêu:** Nối trí tuệ với thực thi tự động — *không* xây visual workflow builder.

**Phạm vi:** Scheduling · Background execution & task queue (trong giới hạn iOS) · Automation rules đơn giản (điều kiện → skill composition) · MCP integration mở rộng cho remote tools (AD-18) · Execution monitoring.

**Tiêu chí hoàn thành:** Công việc lặp lại chạy tự động, mọi hành động rủi ro vẫn qua approval gate.

### M7 — Optimization

**Mục tiêu:** Hạ chi phí vận hành, dựa trên số liệu đã tích lũy từ M0.

**Phạm vi:** Context loading, caching, memory compression, model routing (dùng model nhỏ hơn khi số liệu cho phép), tốc độ thực thi, network, battery, UI performance.

**Tiêu chí hoàn thành:** Chất lượng giữ nguyên hoặc tăng trong khi token/cost/latency giảm có số liệu.

### M8 — Production Readiness

**Mục tiêu:** Sẵn sàng sử dụng hằng ngày lâu dài.

**Phạm vi:** Test coverage cho Core contracts · Performance review · Security review (API keys, dữ liệu người dùng) · Backup & Recovery (Project State, Memory, Files) · Crash recovery (không mất tiến độ) · Documentation cập nhật · Accessibility audit.

**Tiêu chí hoàn thành:** Mất điện thoại giữa chừng task → mở lại không mất trạng thái; toàn bộ Definition of Done đạt.

---

## 3. Definition of Done (áp dụng mọi milestone)

- [ ] Tính năng chạy đúng, qua Verify gate.
- [ ] Kiến trúc sạch: không vi phạm dependency rule, không business logic trong Core.
- [ ] `PROJECT_STATE.md` + Memory cập nhật.
- [ ] Tài liệu module/component cập nhật (ngắn gọn).
- [ ] Test cho contract quan trọng.
- [ ] Token review: số liệu ghi nhận, không thoái lui so với baseline.
- [ ] Nợ kỹ thuật phân loại (Critical/Important/Minor); Critical = 0.
- [ ] Việc kế tiếp được ghi vào PROJECT_STATE.md.

## 4. Khác biệt so với roadmap gốc (Part 15) — tóm tắt

| Gốc | Sửa | Lý do |
|---|---|---|
| M0 xây toàn bộ foundation, M1 xây toàn bộ runtime, chưa có UI đến M2 | M0 = lát cắt dọc mỏng có UI + AI call thật | Kiểm chứng kiến trúc sớm; đúng nguyên tắc smallest solution (AD-16) |
| Workflow Runtime cần ở M1 nhưng Workflow Engine ở M6 | Workflow = skill composition từ M1; M6 chỉ thêm automation/scheduling | Gỡ mâu thuẫn (AD-07) |
| Deliverable Registry ở M3 | Deliverable indexing trong State + Files | AD-10 |
| Experience Engine là deliverable riêng ở M3 | Reflection + learning policy có gate, là policy ghi của Store | AD-20, AD-22 |
| Không có baseline đo lường | Đo token/cost từ M0 | AD-15 |
