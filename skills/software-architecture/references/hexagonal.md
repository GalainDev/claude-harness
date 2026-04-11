# Hexagonal Architecture — Ports and Adapters

The domain defines **ports** (interfaces). Infrastructure provides **adapters** (implementations). Nothing in the domain imports from infrastructure.

---

## Go

### Directory structure

```
internal/
  domain/
    order.go          ← entity + business logic
    repository.go     ← port (interface)
    events.go         ← domain events
  application/
    order_service.go  ← use case orchestration
  infrastructure/
    postgres/
      order_repo.go   ← adapter: implements domain.OrderRepository
    stripe/
      payment.go      ← adapter: implements domain.PaymentGateway
  interfaces/
    http/
      handler.go      ← adapter: HTTP → application service
    grpc/
      server.go       ← adapter: gRPC → application service
```

### Port (domain layer)

```go
// internal/domain/repository.go
package domain

import "context"

type OrderRepository interface {
    FindByID(ctx context.Context, id OrderID) (*Order, error)
    Save(ctx context.Context, order *Order) error
    FindByUser(ctx context.Context, userID UserID) ([]*Order, error)
}

type PaymentGateway interface {
    Charge(ctx context.Context, amount Money, token string) (ChargeID, error)
    Refund(ctx context.Context, chargeID ChargeID) error
}
```

### Adapter (infrastructure layer)

```go
// internal/infrastructure/postgres/order_repo.go
package postgres

import (
    "context"
    "myapp/internal/domain"
    "github.com/jackc/pgx/v5/pgxpool"
)

type orderRepository struct {
    db *pgxpool.Pool
}

func NewOrderRepository(db *pgxpool.Pool) domain.OrderRepository {
    return &orderRepository{db: db}
}

func (r *orderRepository) FindByID(ctx context.Context, id domain.OrderID) (*domain.Order, error) {
    row := r.db.QueryRow(ctx,
        "SELECT id, user_id, status, total_cents FROM orders WHERE id = $1",
        id.String(),
    )
    var o domain.Order
    var totalCents int64
    if err := row.Scan(&o.ID, &o.UserID, &o.Status, &totalCents); err != nil {
        return nil, fmt.Errorf("find order %s: %w", id, err)
    }
    o.Total = domain.Money{Cents: totalCents, Currency: "USD"}
    return &o, nil
}
```

### Application service (use case)

```go
// internal/application/order_service.go
package application

import (
    "context"
    "myapp/internal/domain"
)

type OrderService struct {
    orders   domain.OrderRepository
    payments domain.PaymentGateway
    events   domain.EventPublisher
}

func NewOrderService(
    orders domain.OrderRepository,
    payments domain.PaymentGateway,
    events domain.EventPublisher,
) *OrderService {
    return &OrderService{orders: orders, payments: payments, events: events}
}

func (s *OrderService) PlaceOrder(ctx context.Context, cmd PlaceOrderCommand) (*domain.Order, error) {
    order, err := domain.NewOrder(cmd.UserID, cmd.Items)
    if err != nil {
        return nil, fmt.Errorf("create order: %w", err)
    }

    chargeID, err := s.payments.Charge(ctx, order.Total, cmd.PaymentToken)
    if err != nil {
        return nil, fmt.Errorf("charge payment: %w", err)
    }
    order.MarkPaid(chargeID)

    if err := s.orders.Save(ctx, order); err != nil {
        return nil, fmt.Errorf("save order: %w", err)
    }

    s.events.Publish(domain.OrderPlaced{OrderID: order.ID, UserID: order.UserID})
    return order, nil
}
```

### Wiring (main.go)

```go
func main() {
    db := mustConnectDB(os.Getenv("DATABASE_URL"))
    
    // Infrastructure adapters
    orderRepo := postgres.NewOrderRepository(db)
    paymentGW := stripe.NewGateway(os.Getenv("STRIPE_SECRET_KEY"))
    eventBus  := kafka.NewPublisher(os.Getenv("KAFKA_BROKERS"))
    
    // Application services
    orderSvc := application.NewOrderService(orderRepo, paymentGW, eventBus)
    
    // Interface adapters
    handler := httphandler.New(orderSvc)
    
    http.ListenAndServe(":8080", handler)
}
```

### Testing with fakes (no mocking frameworks)

```go
// internal/domain/repository_fake.go  (test helper, build tag or _test.go)
type FakeOrderRepository struct {
    orders map[domain.OrderID]*domain.Order
    mu     sync.Mutex
}

func NewFakeOrderRepository() *FakeOrderRepository {
    return &FakeOrderRepository{orders: make(map[domain.OrderID]*domain.Order)}
}

func (r *FakeOrderRepository) FindByID(_ context.Context, id domain.OrderID) (*domain.Order, error) {
    r.mu.Lock()
    defer r.mu.Unlock()
    o, ok := r.orders[id]
    if !ok {
        return nil, domain.ErrNotFound
    }
    return o, nil
}

// Test
func TestPlaceOrder(t *testing.T) {
    repo     := NewFakeOrderRepository()
    payments := &FakePaymentGateway{}
    svc      := application.NewOrderService(repo, payments, &FakeEventPublisher{})
    
    order, err := svc.PlaceOrder(ctx, PlaceOrderCommand{...})
    require.NoError(t, err)
    assert.Equal(t, domain.StatusPaid, order.Status)
}
```

---

## TypeScript

### Directory structure

```
src/
  domain/
    order.ts          ← entity + business logic
    repositories.ts   ← port interfaces
    events.ts         ← domain events
  application/
    orderService.ts   ← use case orchestration
  infrastructure/
    postgres/
      orderRepository.ts  ← adapter
    stripe/
      paymentGateway.ts   ← adapter
  interfaces/
    http/
      orderHandler.ts     ← Express/Hono adapter
```

### Port (domain)

```typescript
// src/domain/repositories.ts
export interface OrderRepository {
  findById(id: string): Promise<Order | null>
  save(order: Order): Promise<void>
  findByUser(userId: string): Promise<Order[]>
}

export interface PaymentGateway {
  charge(amount: Money, token: string): Promise<string>  // returns chargeId
  refund(chargeId: string): Promise<void>
}
```

### Adapter (infrastructure)

```typescript
// src/infrastructure/postgres/orderRepository.ts
import { Pool } from 'pg'
import type { OrderRepository } from '../../domain/repositories'
import type { Order } from '../../domain/order'

export class PostgresOrderRepository implements OrderRepository {
  constructor(private db: Pool) {}

  async findById(id: string): Promise<Order | null> {
    const { rows } = await this.db.query(
      'SELECT id, user_id, status, total_cents FROM orders WHERE id = $1',
      [id]
    )
    if (rows.length === 0) return null
    return mapRowToOrder(rows[0])
  }

  async save(order: Order): Promise<void> {
    await this.db.query(
      `INSERT INTO orders (id, user_id, status, total_cents)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id) DO UPDATE SET status = $3, total_cents = $4`,
      [order.id, order.userId, order.status, order.total.cents]
    )
  }
}
```

### Wiring (composition root)

```typescript
// src/index.ts
const db = new Pool({ connectionString: process.env.DATABASE_URL })

const orderRepo    = new PostgresOrderRepository(db)
const paymentGW    = new StripeGateway(process.env.STRIPE_SECRET_KEY!)
const eventBus     = new KafkaPublisher(process.env.KAFKA_BROKERS!)

const orderService = new OrderService(orderRepo, paymentGW, eventBus)

const app = createApp(orderService)
app.listen(8080)
```

---

## Key rules

1. **Domain imports nothing outside domain.** No database drivers, no HTTP, no env vars.
2. **Interfaces live in the domain.** The domain defines what it needs; infrastructure satisfies that need.
3. **Application services orchestrate.** They coordinate domain objects and infrastructure calls but contain no business rules themselves.
4. **Adapters translate.** HTTP request → command. DB row → domain entity. Never let the DB schema bleed into the domain model.
5. **Test domain in isolation.** Fake adapters in tests. Real adapters in integration tests.
