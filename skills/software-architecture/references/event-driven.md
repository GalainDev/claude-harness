# Event-Driven Architecture

Event-driven architecture decouples services by having them communicate through events rather than direct calls. A service publishes that something happened; any number of subscribers react independently.

**Use it when decoupling genuinely solves a real problem.** Don't use it because it sounds scalable — it adds latency, makes debugging harder, and requires careful schema management.

---

## Core concepts

**Event**: something that happened in the past, immutable, named in past tense.
- `OrderPlaced`, `PaymentFailed`, `UserRegistered`
- NOT `CreateOrder` (that's a command), NOT `OrderStatus` (that's state)

**Producer**: publishes events when something happens in its domain. Doesn't know who's listening.

**Consumer**: subscribes to events it cares about. Doesn't know who published or what other consumers exist.

**Event broker**: Kafka, RabbitMQ, AWS SNS/SQS, Google Pub/Sub — the transport layer.

---

## Choreography vs Orchestration

### Choreography — services react independently

```
OrderService → [OrderPlaced] → InventoryService (reserves stock)
                             → EmailService (sends confirmation)
                             → AnalyticsService (tracks conversion)
```

Each service knows what to do when it sees an event. No central coordinator.

**When to use:** When services are truly independent, each completing their own bounded unit of work. Works well when the flow is simple and services don't need to be coordinated for a single outcome.

**Downsides:** Hard to understand the overall flow. Debugging requires correlating events across multiple services. No single place to see "what happens when an order is placed."

### Orchestration — a coordinator drives the flow

```
OrderSaga:
  1. Publish ReserveInventoryCommand → wait for InventoryReserved or InventoryFailed
  2. If reserved: Publish ChargePaymentCommand → wait for PaymentCharged or PaymentFailed
  3. If charged: Publish ConfirmOrderCommand
  4. If any step fails: compensate previous steps
```

**When to use:** Multi-step workflows that span services and need coordinated rollback (sagas). When you need a clear picture of the overall process state.

**Implementation:** A saga/process manager is a stateful component that subscribes to events and issues commands. Its state lives in a database.

---

## Event schema design

### Structure

```json
{
  "id": "evt_01H8X2K...",
  "type": "order.placed",
  "version": "1",
  "occurredAt": "2024-11-15T14:22:33Z",
  "source": "order-service",
  "correlationId": "req_abc123",
  "data": {
    "orderId": "ord_789",
    "userId": "usr_456",
    "total": { "amount": 4999, "currency": "USD" },
    "items": [...]
  }
}
```

**Required fields:**
- `id` — globally unique, idempotency key for consumers
- `type` — namespaced with the domain: `order.placed`, not just `placed`
- `version` — for schema evolution
- `occurredAt` — when it happened (not when it was published)
- `source` — which service emitted it

**Optional but useful:**
- `correlationId` — trace the originating request across services
- `causationId` — which event/command caused this one

### Schema evolution

Events are immutable once stored. Plan for evolution from day one.

**Additive changes (safe):**
- Add optional fields to `data`
- Consumers that don't know the field ignore it

**Breaking changes (require versioning):**
- Rename a field
- Change a field's type
- Remove a field consumers depend on

**How to version:**
```
event.type = "order.placed"    → version in the field, consumers handle v1 and v2
event.type = "order.placed.v2" → version in the type name (less flexible)
```

Use **upcasters**: a function that transforms an old event version to the new schema before it reaches consumers.

---

## Go implementation

### Publishing

```go
type EventPublisher interface {
    Publish(ctx context.Context, event Event) error
}

type Event struct {
    ID            string          `json:"id"`
    Type          string          `json:"type"`
    Version       string          `json:"version"`
    OccurredAt    time.Time       `json:"occurredAt"`
    Source        string          `json:"source"`
    CorrelationID string          `json:"correlationId,omitempty"`
    Data          json.RawMessage `json:"data"`
}

// Kafka adapter
type KafkaPublisher struct {
    producer *kafka.Writer
    source   string
}

func (p *KafkaPublisher) Publish(ctx context.Context, event Event) error {
    payload, err := json.Marshal(event)
    if err != nil {
        return fmt.Errorf("marshal event: %w", err)
    }
    return p.producer.WriteMessages(ctx, kafka.Message{
        Key:   []byte(event.ID),
        Value: payload,
    })
}
```

### Consuming with idempotency

```go
type OrderPlacedConsumer struct {
    inventory InventoryService
    processed ProcessedEventStore  // tracks which event IDs have been handled
}

func (c *OrderPlacedConsumer) Handle(ctx context.Context, event Event) error {
    // Idempotency: skip if already processed
    already, err := c.processed.Has(ctx, event.ID)
    if err != nil {
        return fmt.Errorf("check processed: %w", err)
    }
    if already {
        return nil  // ack without reprocessing
    }

    var data OrderPlacedData
    if err := json.Unmarshal(event.Data, &data); err != nil {
        return fmt.Errorf("unmarshal: %w", err)
    }

    if err := c.inventory.Reserve(ctx, data.OrderID, data.Items); err != nil {
        return fmt.Errorf("reserve: %w", err)  // will be retried
    }

    return c.processed.Mark(ctx, event.ID)
}
```

---

## TypeScript implementation

```typescript
interface DomainEvent<T = unknown> {
  id: string
  type: string
  version: string
  occurredAt: Date
  source: string
  correlationId?: string
  data: T
}

// Publisher
class KafkaEventPublisher implements EventPublisher {
  constructor(private producer: Producer, private source: string) {}

  async publish<T>(event: Omit<DomainEvent<T>, 'id' | 'source'>): Promise<void> {
    const full: DomainEvent<T> = {
      ...event,
      id: generateId(),
      source: this.source,
    }
    await this.producer.send({
      topic: event.type.replace('.', '-'),
      messages: [{ key: full.id, value: JSON.stringify(full) }],
    })
  }
}

// Consumer with idempotency
class OrderPlacedConsumer {
  constructor(
    private inventory: InventoryService,
    private processed: ProcessedEventStore,
  ) {}

  async handle(event: DomainEvent<OrderPlacedData>): Promise<void> {
    if (await this.processed.has(event.id)) return

    await this.inventory.reserve(event.data.orderId, event.data.items)
    await this.processed.mark(event.id)
  }
}
```

---

## Operational patterns

### Dead letter queue

When a consumer fails after retries, move the message to a DLQ instead of losing it or blocking the queue.

```go
// Retry with exponential backoff, then DLQ
func processWithRetry(ctx context.Context, msg Message, handler Handler, dlq DLQPublisher) {
    backoff := []time.Duration{1*time.Second, 5*time.Second, 30*time.Second}
    var lastErr error
    for _, wait := range backoff {
        if err := handler.Handle(ctx, msg); err == nil {
            return
        } else {
            lastErr = err
            time.Sleep(wait)
        }
    }
    // Move to DLQ with error context
    dlq.Publish(ctx, DeadLetter{Message: msg, Error: lastErr.Error(), FailedAt: time.Now()})
}
```

### Outbox pattern (transactional guarantees)

Problem: you can't atomically write to your DB and publish to Kafka.

Solution: write events to an `outbox` table in the same DB transaction. A separate process polls the outbox and publishes to Kafka, then marks events as sent.

```sql
CREATE TABLE outbox_events (
    id          UUID PRIMARY KEY,
    type        TEXT NOT NULL,
    payload     JSONB NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at TIMESTAMPTZ
);
```

```go
// In the same transaction as your domain write:
tx.Exec(ctx, `INSERT INTO outbox_events (id, type, payload) VALUES ($1, $2, $3)`,
    eventID, "order.placed", payload)
// Commit transaction — event is durably stored

// Separate outbox relay process polls and publishes:
rows := db.Query("SELECT id, type, payload FROM outbox_events WHERE published_at IS NULL")
for _, row := range rows {
    kafka.Publish(row)
    db.Exec("UPDATE outbox_events SET published_at = NOW() WHERE id = $1", row.ID)
}
```

### Consumer group design

- One consumer group per service — each service gets every message
- Multiple instances of the same service share a consumer group — Kafka partitions ensure each message goes to exactly one instance
- Partition by a stable key (e.g., `orderId`) to ensure ordered processing per entity

---

## When to not use event-driven

- **When you need synchronous response**: user submits form, needs immediate confirmation. Use direct call + async side-effects via events.
- **When services are tightly coupled anyway**: if Service B can't function without Service A's data, they shouldn't be decoupled with events — they should be the same service.
- **When debugging is already hard**: adding async event flows to an already complex system makes debugging exponentially harder. Fix the complexity first.
- **When the team isn't ready**: event-driven requires discipline around schema evolution, idempotency, and observability. A team new to distributed systems should start with synchronous calls.
