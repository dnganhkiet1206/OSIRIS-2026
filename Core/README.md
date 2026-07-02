# Core — 6 components, no business logic

| Component | Responsibility |
|---|---|
| Kernel/ | The ONLY place that decides. Five-phase lifecycle: Intake → Decide → Execute → Verify → Persist |
| Execution/ | The ONLY place that does. Runs plans mechanically per declared policy; escalates beyond-policy back to Kernel |
| Skills/ | Single extension point. Skill definitions + capability tags + prompt templates |
| Store/ | Single source of truth. ProjectState / Knowledge / WorkingContext + search |
| AIGateway/ | Single door for AI: retrieve → assemble → budget → cache → route → measure |
| Tools/ | Real-world adapters: on-device + remote MCP (later) |

Depends only on Infrastructure. Never on Presentation or Modules.
Banned components (do not recreate): see Docs/SYSTEM_COMPONENTS.md §6.
