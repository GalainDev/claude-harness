---
name: software-architecture
description: Software architecture skill covering structural patterns, layering, API design, CQRS, event-driven architecture, and hexagonal/clean architecture. Use when the user asks "how should I structure this", "where does this code go", "should I use events or direct calls", "how do I design this API", or any question about code organization, system boundaries, or architectural trade-offs. Complements domain-driven-design — DDD covers the domain model, this covers the structural skeleton it lives in.
metadata:
  author: galain
  version: 1.0.0
  category: backend
---

# Software Architecture Skill

Architecture is about managing complexity over time. The right structure makes the codebase easy to change; the wrong one makes every change a negotiation with the past.

Two questions drive every architectural decision:
1. **What changes together should live together** — cohesion
2. **What changes independently should be separated** — coupling

---

## Layered Architecture — The Default

Start here. Most applications don't need anything more sophisticated.

```
┌─────────────────────────────┐
│   Interfaces / Delivery      │  HTTP handlers, CLI, gRPC, consumers
│   (depends on Application)   │
├─────────────────────────────┤
│   Application / Use Cases    │  Orchestrates domain objects, thin
│   (depends on Domain)        │
├─────────────────────────────┤
│   Domain                     │  Business logic, entities, rules
│   (depends on nothing)       │
├─────────────────────────────┤
│   Infrastructure             │  DB, cache, external APIs, email
│   (implements Domain ports)  │
└─────────────────────────────┘
```

**Dependency rule:** dependencies point inward only. Domain knows nothing about infrastructure. Infrastructure implements interfaces defined by the domain.

This is called **hexagonal architecture** (or ports and adapters) when the dependency inversion is explicit. The domain defines ports (interfaces). Infrastructure provides adapters (implementations). You can swap the DB, HTTP framework, or message queue without touching domain logic.

See [references/hexagonal.md](references/hexagonal.md) for implementation patterns in Go and TypeScript.

---

## Choosing a Structure

### When to use layered / hexagonal

- Most web applications and APIs
- Teams of 1–10 engineers
- Domain logic is the primary complexity
- You want to be able to swap infrastructure later (or test without it)

### When to consider CQRS

Use when reads and writes have fundamentally different requirements:

- Reads need to be fast and denormalized; writes need to be consistent and normalized
- Read load is 100× write load (or vice versa)
- You need different models for querying vs mutating
- Audit trail of all changes is required

See [references/cqrs.md](references/cqrs.md).

### When to consider event-driven

Use when:
- Multiple systems need to react to things that happen
- You want to decouple publishers from subscribers
- Eventual consistency is acceptable for some flows
- You're building workflows that span multiple services

**Don't use event-driven because it's "modern" or "scalable".** It adds latency, makes debugging harder, and requires careful schema management. Use it when the decoupling genuinely solves a real problem.

See [references/event-driven.md](references/event-driven.md).

### When to use microservices

Almost never at the start. Microservices solve an organizational problem (independent deployment, independent scaling, independent team ownership) not a technical one. The prerequisite is:

- Clear bounded context boundaries (see domain-driven-design skill)
- Team autonomy is more valuable than simplicity
- You've already built and understood the monolith

Start with a well-structured monolith. Extract services when you have evidence that the boundary is stable and the coupling is costing you more than the operational complexity of distribution would.

---

## API Design

### REST

Principles:
- Resources are nouns, not verbs: `/orders`, not `/getOrders`
- HTTP methods carry the verb: `GET /orders`, `POST /orders`, `DELETE /orders/123`
- Status codes are semantic: 201 for created, 200 for success, 404 for not found
- Collections are paginated: never return unbounded lists

```
GET    /orders              → list orders (paginated)
POST   /orders              → create order → 201 + Location: /orders/456
GET    /orders/123          → get order
PATCH  /orders/123          → partial update
DELETE /orders/123          → delete → 204 No Content

GET    /orders/123/lines    → nested resource
POST   /orders/123/actions/cancel   → actions on a resource (verb when needed)
```

**Versioning:** version in the URL path (`/v1/orders`) not in headers. Easier to test, easier to route.

**Pagination:** prefer cursor-based over offset for large/frequently-changing datasets:
```json
{
  "data": [...],
  "pagination": {
    "cursor": "eyJpZCI6MTIzfQ==",
    "hasMore": true
  }
}
```

### gRPC

Use when:
- Service-to-service communication (not browser-facing)
- Strong typing and contract enforcement matter
- Streaming is needed
- Performance is critical (binary protocol, HTTP/2 multiplexing)

Define the contract in `.proto` first. Generate client/server code. Never write the wire format by hand.

### GraphQL

Use when:
- Clients have significantly different data needs (mobile vs web vs partner)
- Over-fetching / under-fetching is a real pain point
- You can invest in the tooling and schema governance overhead

Don't use GraphQL as a default. REST is simpler to implement, cache, and secure. GraphQL's value is in the flexibility — which only pays off when clients genuinely need it.

---

## Common Anti-Patterns

### Big Ball of Mud
**Symptom:** Every file imports from every other file. Changes cascade unpredictably.
**Fix:** Identify natural seams (domain boundaries). Enforce import rules (`eslint-plugin-import`, `go/analysis`). Make the dependency graph explicit.

### Anemic layers
**Symptom:** "Service" layer that just delegates to repository with no logic. "Domain" objects that are plain data structs.
**Fix:** Push logic into the right layer. Business rules belong in the domain, not in HTTP handlers or database queries.

### Leaking abstractions
**Symptom:** SQL row types, HTTP request objects, or ORM models appearing in domain code.
**Fix:** Define domain types. Map at the boundary. See domain-driven-design ACL pattern.

### Premature distribution
**Symptom:** Microservices with sync HTTP calls between them, shared databases, or deployment coupling.
**Fix:** If services can't be deployed independently or must call each other synchronously for every operation, they're a distributed monolith. Merge them or fix the boundaries.

### God service
**Symptom:** One service/class that does everything. `UserService` that also handles billing, notifications, and analytics.
**Fix:** Split by responsibility. Each service/class should have one reason to change.

---

## Decision Framework

When facing an architectural decision, answer these questions:

| Question | Why |
|----------|-----|
| What changes most often? | Put it in the layer with the fewest dependents |
| What needs to be testable in isolation? | Extract behind an interface |
| What has the most uncertainty? | Keep it replaceable |
| What's the blast radius if this is wrong? | Smaller blast radius = can afford to decide later |
| Will the team understand this in 6 months? | Complexity has a carrying cost |

Prefer boring over clever. The goal is software that works and can be changed — not software that demonstrates architectural sophistication.
