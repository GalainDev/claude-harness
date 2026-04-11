# CQRS — Command Query Responsibility Segregation

CQRS separates the model used to mutate state (commands) from the model used to read state (queries). It is not a global architecture — apply it to the slices of your system where read and write requirements genuinely diverge.

---

## Core concept

```
                    ┌─────────────────┐
Write side          │   Command Bus   │
(normalized,        └────────┬────────┘
 consistent)                 ↓
                    ┌─────────────────┐     ┌──────────────────┐
                    │  Command Handler │────→│  Domain Model    │
                    └────────┬────────┘     └──────────────────┘
                             │ persists               │
                             ↓                        │ raises
                    ┌─────────────────┐     ┌──────────────────┐
                    │   Write Store   │     │  Domain Events   │
                    │  (normalized)   │     └────────┬─────────┘
                    └─────────────────┘              │ projects
                                                     ↓
Read side           ┌─────────────────┐     ┌──────────────────┐
(denormalized,      │   Query Handler │←────│   Read Model     │
 fast)              └─────────────────┘     │  (denormalized)  │
                                            └──────────────────┘
```

The read model is a **projection** — derived from events, kept up to date asynchronously. It can be a separate table, a Redis cache, Elasticsearch, or anything optimized for querying.

---

## When to use CQRS

**Use it when:**
- Read and write loads differ by 10×+ and require separate scaling
- Reads need denormalized views that would be expensive to join at query time
- You need a full audit trail (combine with event sourcing)
- Different teams own the read and write path

**Don't use it when:**
- Your app is CRUD with no complex domain logic
- Eventual consistency is unacceptable for all queries
- Team size is < 5 engineers (operational overhead outweighs benefit)

**Start with layered architecture.** Add CQRS to specific modules when you hit the above problems.

---

## Go implementation

### Commands and handlers

```go
// Commands are plain data — no behavior
type PlaceOrderCommand struct {
    UserID       string
    Items        []OrderItem
    PaymentToken string
}

type PlaceOrderResult struct {
    OrderID string
}

// Handler contains the use case logic
type PlaceOrderHandler struct {
    orders   OrderRepository    // write-side repository
    payments PaymentGateway
    events   EventPublisher
}

func (h *PlaceOrderHandler) Handle(ctx context.Context, cmd PlaceOrderCommand) (PlaceOrderResult, error) {
    order, err := domain.NewOrder(cmd.UserID, cmd.Items)
    if err != nil {
        return PlaceOrderResult{}, err
    }
    // ... business logic ...
    h.events.Publish(domain.OrderPlaced{OrderID: order.ID})
    return PlaceOrderResult{OrderID: order.ID.String()}, nil
}
```

### Queries and handlers

```go
// Query — describes what to fetch
type GetOrderSummaryQuery struct {
    UserID string
    Limit  int
    Cursor string
}

// Read model — denormalized, query-optimized
type OrderSummary struct {
    OrderID     string
    Status      string
    Total       string
    ItemCount   int
    CreatedAt   time.Time
    ProductNames []string  // denormalized — no join needed
}

// Query handler reads directly from the read model
type GetOrderSummaryHandler struct {
    readDB *pgxpool.Pool  // could be a replica, different DB, Redis, etc.
}

func (h *GetOrderSummaryHandler) Handle(ctx context.Context, q GetOrderSummaryQuery) ([]OrderSummary, error) {
    rows, err := h.readDB.Query(ctx, `
        SELECT order_id, status, total_display, item_count, created_at, product_names
        FROM order_summaries_view
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT $2
    `, q.UserID, q.Limit)
    // ...
}
```

### Projection (keeping the read model in sync)

```go
// Projection listens to domain events and updates the read model
type OrderSummaryProjection struct {
    db *pgxpool.Pool
}

func (p *OrderSummaryProjection) On(ctx context.Context, event domain.Event) error {
    switch e := event.(type) {
    case domain.OrderPlaced:
        return p.handleOrderPlaced(ctx, e)
    case domain.OrderCancelled:
        return p.handleOrderCancelled(ctx, e)
    }
    return nil
}

func (p *OrderSummaryProjection) handleOrderPlaced(ctx context.Context, e domain.OrderPlaced) error {
    _, err := p.db.Exec(ctx, `
        INSERT INTO order_summaries_view (order_id, user_id, status, total_display, item_count, created_at)
        VALUES ($1, $2, 'pending', $3, $4, $5)
    `, e.OrderID, e.UserID, e.TotalDisplay, e.ItemCount, e.OccurredAt)
    return err
}
```

---

## TypeScript implementation

```typescript
// Command
interface PlaceOrderCommand {
  userId: string
  items: OrderItem[]
  paymentToken: string
}

// Handler
class PlaceOrderHandler {
  constructor(
    private orders: OrderRepository,
    private payments: PaymentGateway,
    private events: EventPublisher,
  ) {}

  async handle(cmd: PlaceOrderCommand): Promise<{ orderId: string }> {
    const order = Order.create(cmd.userId, cmd.items)
    const chargeId = await this.payments.charge(order.total, cmd.paymentToken)
    order.markPaid(chargeId)
    await this.orders.save(order)
    await this.events.publish(new OrderPlacedEvent(order))
    return { orderId: order.id }
  }
}

// Query handler — reads from denormalized view
class GetOrderSummaryHandler {
  constructor(private db: Pool) {}

  async handle(userId: string, limit: number): Promise<OrderSummary[]> {
    const { rows } = await this.db.query(
      `SELECT order_id, status, total_display, item_count, created_at
       FROM order_summaries_view
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2`,
      [userId, limit]
    )
    return rows.map(mapToOrderSummary)
  }
}
```

---

## Event sourcing (optional complement)

Event sourcing stores the **sequence of events** as the source of truth instead of current state. The current state is derived by replaying events.

**Use event sourcing when:**
- Full audit trail is required (financial, medical, legal)
- You need to rebuild state as of any point in time
- Multiple projections need the same event stream

**Don't use it as a default** — it adds significant complexity (event versioning, snapshot strategies, eventual consistency everywhere).

```go
// Instead of storing current state:
// orders: { id, status, total, ... }

// Store events:
// order_events: { order_id, event_type, payload, version, occurred_at }

// Reconstruct by replaying:
func (r *EventSourcedOrderRepo) FindByID(ctx context.Context, id OrderID) (*Order, error) {
    events, err := r.store.LoadEvents(ctx, id.String())
    if err != nil {
        return nil, err
    }
    order := &Order{}
    for _, e := range events {
        order.Apply(e)  // each event mutates state
    }
    return order, nil
}
```

---

## Operational considerations

- **Eventual consistency**: the read model lags behind writes. How much lag is acceptable? Design your UI to handle it (optimistic updates, polling, websockets).
- **Projection replay**: when you change a projection's logic, you must replay all events. Design event stores to support this.
- **Schema evolution**: events are immutable once stored. Version your event schemas from day one. Use upcasters to transform old events to new shapes.
- **Dead letter queue**: failed projections should go to DLQ, not be silently dropped.
