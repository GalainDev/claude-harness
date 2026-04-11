---
name: domain-driven-design
description: Domain-driven design skill covering tactical and strategic patterns. Use when the user is designing a system, modelling a domain, defining bounded contexts, structuring a codebase around business concepts, or asking about aggregates, entities, value objects, domain events, repositories, application services, or context mapping. Also triggers on "how should I structure this", "where does this logic live", or any architecture question where the business domain is the primary concern.
metadata:
  author: galain
  version: 1.0.0
  category: backend
---

# Domain-Driven Design Skill

DDD is not about technology — it's about making software that reflects the business domain so deeply that engineers and domain experts can reason about it in the same language. Apply it when complexity lives in the business logic, not the infrastructure.

Don't reach for DDD on CRUD apps or simple data pipelines. It earns its cost when the domain has real complexity: rules that change, concepts that mean different things in different contexts, workflows that span multiple business areas.

---

## Strategic Patterns — Start Here

Strategic design happens before any code. Get this wrong and tactical patterns won't save you.

### Ubiquitous Language

Every concept in the codebase must use the exact word the domain expert uses — not a synonym, not an abbreviation, not a technical translation.

- If the business says "Policy", the code says `Policy` — not `Rule`, not `Config`, not `Settings`
- If the business says "Submit a claim", the code has `SubmitClaim` — not `CreateClaim`, not `PostClaim`
- When the language changes in conversation, the code changes too

Build a glossary. Put it in `docs/ubiquitous-language.md`. Update it when terms evolve.

### Bounded Contexts

A bounded context is a boundary within which a model is consistent and a term has one meaning.

The same word can mean different things in different contexts:

| Term | Sales context | Shipping context | Billing context |
|------|--------------|-----------------|----------------|
| `Customer` | A prospect or account | A delivery recipient | A payer with payment methods |
| `Order` | A quote or intent | A shipment to dispatch | An invoice to collect |
| `Product` | A SKU with pricing | A physical item with weight | A line item with tax code |

Don't try to make one `Customer` model that works everywhere. Give each context its own model. The translation happens at the boundary.

**Finding context boundaries:**
- Where do teams have different vocabularies for the same thing?
- Where does a concept mean something subtly different?
- Where do changes in one area frequently break another?
- Where are the organizational seams (different teams, departments)?

### Context Mapping

How bounded contexts relate to each other:

| Pattern | When to use |
|---------|-------------|
| **Shared Kernel** | Two contexts share a small model — both teams own it, changes require coordination |
| **Customer/Supplier** | Upstream context publishes, downstream consumes — upstream sets the API |
| **Conformist** | Downstream adopts upstream's model wholesale (e.g. integrating a third-party API) |
| **Anti-Corruption Layer (ACL)** | Downstream translates upstream's model into its own — protects the domain from external concepts leaking in |
| **Open Host Service** | Upstream provides a stable published API (REST, events) for multiple consumers |
| **Separate Ways** | Contexts have no integration — duplicate rather than couple |

ACL is the most important pattern for integration. When you consume an external system (payment provider, ERP, legacy service), always translate at the boundary. Never let their model names appear in your domain code.

---

## Tactical Patterns — Building Blocks

### Entity

An object defined by its identity, not its attributes. Two entities are the same if they have the same ID, even if all other attributes differ.

```go
// Go
type Order struct {
    id         OrderID   // identity
    customerID CustomerID
    lines       []OrderLine
    status      OrderStatus
}

func (o Order) ID() OrderID { return o.id }

func (o Order) Equals(other Order) bool {
    return o.id == other.id
}
```

```typescript
// TypeScript
class Order {
  constructor(
    private readonly id: OrderId,
    private customerId: CustomerId,
    private lines: OrderLine[],
    private status: OrderStatus,
  ) {}

  equals(other: Order): boolean {
    return this.id.equals(other.id)
  }
}
```

Use entities when: the object has a lifecycle, it changes over time, you need to track it across operations.

### Value Object

An object defined entirely by its attributes. No identity. Immutable. Interchangeable if equal.

```go
// Go — value object as struct with no ID
type Money struct {
    amount   int64  // cents — never floats for money
    currency Currency
}

func (m Money) Add(other Money) (Money, error) {
    if m.currency != other.currency {
        return Money{}, errors.New("currency mismatch")
    }
    return Money{amount: m.amount + other.amount, currency: m.currency}, nil
}
```

```typescript
// TypeScript — value object, immutable
class Money {
  constructor(
    readonly amount: number,  // cents
    readonly currency: Currency,
  ) {}

  add(other: Money): Money {
    if (this.currency !== other.currency) throw new Error('currency mismatch')
    return new Money(this.amount + other.amount, this.currency)
  }

  equals(other: Money): boolean {
    return this.amount === other.amount && this.currency === other.currency
  }
}
```

Use value objects for: Money, Address, DateRange, Coordinates, Email, PhoneNumber, Quantity, Percentage. Anything that is a measurement or descriptor with no lifecycle of its own.

**Primitive obsession is the most common DDD mistake.** `string` is not an email address. `number` is not money. Wrap primitives in value objects to carry validation and behaviour with the data.

### Aggregate

A cluster of entities and value objects treated as a single unit for data changes. One entity is the **Aggregate Root** — the only entry point. All changes go through the root. External objects only hold references to the root's ID, never to internal entities.

Rules:
- Only the root can be loaded from the repository
- All invariants (business rules) of the aggregate are enforced within the boundary
- One aggregate = one transaction boundary
- Aggregates communicate with each other via domain events, not direct references

```go
// Order is the aggregate root
type Order struct {
    id     OrderID
    lines  []OrderLine  // internal entity — only accessible via Order methods
    status OrderStatus
}

// All mutations go through the root — it enforces invariants
func (o *Order) AddLine(productID ProductID, qty Quantity, price Money) error {
    if o.status != OrderStatusDraft {
        return ErrOrderNotEditable
    }
    if qty.IsZero() {
        return ErrZeroQuantity
    }
    o.lines = append(o.lines, newOrderLine(productID, qty, price))
    return nil
}

// Root loads the whole aggregate — no direct DB access to OrderLine
func (o *Order) Total() Money {
    total := Money{currency: "USD"}
    for _, line := range o.lines {
        total, _ = total.Add(line.Subtotal())
    }
    return total
}
```

**Aggregate sizing:** start small. One aggregate per concept. If you feel the urge to include more, ask: does this rule actually need to be enforced in the same transaction? Usually the answer is no — use eventual consistency via domain events instead.

### Domain Event

Something that happened in the domain that other parts of the system might care about. Named in the past tense. Immutable. Carries everything needed to describe what happened.

```go
type OrderPlaced struct {
    OrderID    OrderID
    CustomerID CustomerID
    PlacedAt   time.Time
    Total      Money
}

type ItemShipped struct {
    OrderID   OrderID
    TrackingCode string
    ShippedAt time.Time
}
```

```typescript
interface OrderPlaced {
  readonly type: 'OrderPlaced'
  readonly orderId: OrderId
  readonly customerId: CustomerId
  readonly placedAt: Date
  readonly total: Money
}
```

Domain events decouple bounded contexts. When `Billing` needs to know an order was placed, it subscribes to `OrderPlaced` — it doesn't call into the `Orders` context directly.

Raise events inside aggregates, dispatch them after the transaction commits:

```go
func (o *Order) Place() error {
    if len(o.lines) == 0 {
        return ErrEmptyOrder
    }
    o.status = OrderStatusPlaced
    o.addEvent(OrderPlaced{
        OrderID:    o.id,
        CustomerID: o.customerID,
        PlacedAt:   time.Now(),
        Total:      o.Total(),
    })
    return nil
}
```

### Repository

Abstracts persistence. The domain doesn't know about databases. The repository speaks the domain's language, not SQL's.

```go
// Domain interface — in the domain package
type OrderRepository interface {
    FindByID(ctx context.Context, id OrderID) (*Order, error)
    FindByCustomer(ctx context.Context, customerID CustomerID) ([]*Order, error)
    Save(ctx context.Context, order *Order) error
}

// Infrastructure implementation — in the infrastructure package
type postgresOrderRepository struct {
    db *sql.DB
}

func (r *postgresOrderRepository) FindByID(ctx context.Context, id OrderID) (*Order, error) {
    // SQL query here — domain knows nothing about this
}
```

The domain package defines the interface. The infrastructure package implements it. Dependency flows inward — domain never imports infrastructure.

### Application Service

Orchestrates use cases. Thin. No business logic — that lives in the domain. Handles:
- Loading aggregates from repositories
- Calling domain methods
- Dispatching events
- Managing transactions

```go
type PlaceOrderCommand struct {
    CustomerID string
    Lines      []OrderLineInput
}

type OrderApplicationService struct {
    orders    OrderRepository
    customers CustomerRepository
    events    EventBus
}

func (s *OrderApplicationService) PlaceOrder(ctx context.Context, cmd PlaceOrderCommand) (OrderID, error) {
    customer, err := s.customers.FindByID(ctx, CustomerID(cmd.CustomerID))
    if err != nil {
        return "", fmt.Errorf("loading customer: %w", err)
    }

    order := NewOrder(customer.ID())
    for _, line := range cmd.Lines {
        if err := order.AddLine(ProductID(line.ProductID), Quantity(line.Qty), line.Price); err != nil {
            return "", fmt.Errorf("adding line: %w", err)
        }
    }

    if err := order.Place(); err != nil {
        return "", fmt.Errorf("placing order: %w", err)
    }

    if err := s.orders.Save(ctx, order); err != nil {
        return "", fmt.Errorf("saving order: %w", err)
    }

    s.events.Publish(order.Events()...)
    return order.ID(), nil
}
```

---

## Package Structure

Dependency rule: domain knows nothing about the outside world. Everything depends inward.

```
myapp/
├── domain/                    # pure business logic — no imports from outside
│   ├── order/
│   │   ├── order.go           # aggregate root
│   │   ├── order_line.go      # internal entity
│   │   ├── events.go          # domain events
│   │   ├── repository.go      # repository interface
│   │   └── money.go           # value object
│   └── customer/
│       ├── customer.go
│       └── repository.go
│
├── application/               # use cases — orchestrates domain, thin
│   ├── order_service.go
│   └── customer_service.go
│
├── infrastructure/            # implements domain interfaces
│   ├── postgres/
│   │   ├── order_repository.go
│   │   └── customer_repository.go
│   └── events/
│       └── bus.go
│
└── interfaces/                # delivery mechanism — HTTP, gRPC, CLI
    ├── http/
    │   ├── order_handler.go
    │   └── router.go
    └── grpc/
```

**Dependency direction:**
```
interfaces → application → domain ← infrastructure
```

Infrastructure implements domain interfaces. Domain never imports infrastructure.

---

## Red Flags

- Domain logic in HTTP handlers — move it to the domain or application layer
- Repositories that return DTOs or database rows — return domain objects
- Aggregates that load other aggregates — use IDs and events
- Anemic domain model — objects with only getters/setters and no behaviour; logic is in services instead of entities
- Sharing a database table across bounded contexts — each context owns its own data
- Using infrastructure types (`*sql.Tx`, `*gorm.DB`) in domain code
- God aggregates — one aggregate that owns everything; split by transaction boundary
- Skipping ubiquitous language — using tech terms (`UserRecord`, `DataProcessor`) instead of domain terms

---

## When to apply DDD

| Situation | Apply DDD? |
|-----------|-----------|
| Complex domain with rich business rules | Yes — tactical + strategic |
| Multiple teams working on interconnected systems | Yes — strategic (bounded contexts, events) |
| Simple CRUD with little business logic | No — over-engineering |
| Data pipeline or ETL | No — different paradigm |
| Early-stage prototype | Start with just ubiquitous language and bounded contexts, add tactical patterns as complexity grows |

See [references/context-mapping.md](references/context-mapping.md) for deeper context mapping patterns and integration strategies.
