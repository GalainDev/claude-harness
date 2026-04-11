# Context Mapping Reference

## Integration Patterns

### Anti-Corruption Layer (ACL)

The most important integration pattern. When your domain must consume an external system — a payment provider, a legacy ERP, a third-party API — the ACL translates their model into yours at the boundary. Their concepts never leak into your domain.

```
External System → ACL (translator) → Your Domain
```

```go
// Their model (Stripe)
type stripeCharge struct {
    ID     string
    Amount int64
    Status string  // "succeeded", "pending", "failed"
}

// Your domain model
type Payment struct {
    id     PaymentID
    amount Money
    status PaymentStatus
}

// ACL — lives in infrastructure, translates at the boundary
type stripeACL struct {
    client *stripe.Client
}

func (a *stripeACL) Charge(ctx context.Context, amount Money) (Payment, error) {
    charge, err := a.client.Charges.New(&stripe.ChargeParams{
        Amount:   stripe.Int64(int64(amount.Cents())),
        Currency: stripe.String(string(amount.Currency())),
    })
    if err != nil {
        return Payment{}, fmt.Errorf("stripe charge: %w", err)
    }
    // Translate their model into yours
    return Payment{
        id:     PaymentID(charge.ID),
        amount: amount,
        status: stripeStatusToPaymentStatus(charge.Status),
    }, nil
}

func stripeStatusToPaymentStatus(s string) PaymentStatus {
    switch s {
    case "succeeded": return PaymentStatusCompleted
    case "pending":   return PaymentStatusPending
    default:          return PaymentStatusFailed
    }
}
```

### Shared Kernel

Two bounded contexts share a small, explicitly agreed-upon model. Both teams own it. Any change requires coordination. Keep the kernel small — it's a coupling point.

```
Orders context ←→ [Shared Kernel: OrderID, CustomerID] ←→ Billing context
```

Only share value objects and IDs — never entities or aggregates. Typically lives in a dedicated package both contexts import.

### Open Host Service / Published Language

The upstream context provides a stable API that downstream contexts consume. The API is versioned and treated as a public contract.

```
Orders (upstream) → REST API / Event Schema (published language) → Shipping (downstream)
                                                                 → Billing (downstream)
                                                                 → Analytics (downstream)
```

The upstream team owns the API. Changes go through a deprecation cycle. Consumers must not be broken by upstream changes.

### Conformist

The downstream context adopts the upstream's model wholesale. No translation. Used when the upstream is a dominant external system (Salesforce, SAP, Shopify) and fighting it isn't worth the cost.

Risk: upstream's model bleeds into your domain. Use only when the upstream model genuinely fits your domain — not as an excuse to skip the ACL.

---

## Event-Driven Integration Between Contexts

Prefer domain events over direct calls for cross-context integration. Events are the loose coupling mechanism.

```
Orders context publishes: OrderPlaced, OrderCancelled, OrderShipped
Billing context subscribes to: OrderPlaced → creates invoice
Shipping context subscribes to: OrderPlaced → creates shipment
Inventory context subscribes to: OrderPlaced → reserves stock
```

### Event schema ownership

The publishing context owns the event schema. Consumers must handle schema evolution:
- **Additive changes** (new optional fields) — consumers ignore unknown fields
- **Breaking changes** (renamed or removed fields) — version the event: `OrderPlacedV2`

```go
// Events are immutable, versioned, carry all needed data
type OrderPlacedV1 struct {
    Version    int       `json:"version"`   // always 1
    OrderID    string    `json:"order_id"`
    CustomerID string    `json:"customer_id"`
    PlacedAt   time.Time `json:"placed_at"`
    TotalCents int64     `json:"total_cents"`
    Currency   string    `json:"currency"`
}
```

### Saga / Process Manager

For workflows that span multiple bounded contexts and require compensation on failure.

```
PlaceOrder saga:
  1. Reserve inventory (Inventory context)
  2. Charge payment (Billing context)
  3. Create shipment (Shipping context)

On step 2 failure:
  → Release inventory reservation (compensate step 1)
  → Fail the order
```

Implement as an explicit state machine. The saga listens to events and issues commands:

```go
type PlaceOrderSaga struct {
    state SagaState
    // ...
}

func (s *PlaceOrderSaga) Handle(event interface{}) []Command {
    switch e := event.(type) {
    case InventoryReserved:
        s.state = AwaitingPayment
        return []Command{ChargePayment{OrderID: e.OrderID, Amount: e.Total}}
    case PaymentCharged:
        s.state = AwaitingShipment
        return []Command{CreateShipment{OrderID: e.OrderID}}
    case PaymentFailed:
        s.state = Compensating
        return []Command{ReleaseInventory{OrderID: e.OrderID}}
    // ...
    }
}
```

---

## Identifying Bounded Context Boundaries

### EventStorming

The fastest way to find boundaries. Run a workshop:

1. **Domain events** (orange) — everything that happens: `OrderPlaced`, `PaymentFailed`, `ItemShipped`
2. **Commands** (blue) — what triggers events: `PlaceOrder`, `ChargePayment`
3. **Aggregates** (yellow) — what handles commands and produces events
4. **Bounded contexts** (pink) — cluster aggregates that belong together

Hotspots (red) mark areas of confusion or disagreement — usually a boundary.

### Linguistic boundaries

Ask domain experts:
- "What does 'customer' mean in your department?"
- "When you say 'product', what are you thinking of?"

Where the answers diverge significantly, you've found a boundary.

### Team boundaries

Conway's Law: systems mirror the communication structure of the organization. If two teams rarely talk, their software probably shouldn't be tightly coupled either. Bounded contexts often align with team ownership.

---

## Common Mistakes

**One model to rule them all** — a single `Customer` or `Product` model shared everywhere. Every context adds fields until the model is incoherent. Split it.

**Bounded contexts as microservices** — they're not the same thing. A bounded context is a conceptual boundary. It can live in one service or many. Don't over-distribute early.

**Events as database sync** — publishing events that carry full entity state and using them to keep read models synchronized. Use projections and CQRS for this, not domain events.

**Chatty sagas** — a saga that orchestrates fine-grained steps in real time. Sagas should coordinate coarse-grained business workflows, not micromanage every field update.

**Ignoring the ACL** — letting a third-party API's model names appear in your domain. The payment provider's concept of a `charge` is not your concept of a `payment`. Translate at the boundary.
