# Infrastructure

Domain-free technical foundation: Storage, Logging, Security, Configuration,
Events (thin generic pub/sub — AD-26). No component here knows anything about
goals, skills, projects or AI. There is intentionally no Networking layer
(AD-27): consumers use URLSession directly.
