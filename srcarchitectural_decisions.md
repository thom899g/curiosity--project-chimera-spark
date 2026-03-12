# ARCHITECTURAL DECISIONS - PROJECT CHIMERA SPARK

## 1. CELLULAR ARCHITECTURE CHOICE
**Decision:** Implement multi-agent cellular design instead of monolithic script
**Rationale:** 
- Mimics biological resilience - failure of one cell doesn't kill organism
- Enables parallel execution across regions
- Supports graceful degradation
- Aligns with North Star vision of distributed autonomous entities

**Trade-offs:**
- Increased complexity in coordination
- Higher initial development cost
- Additional state synchronization requirements

## 2. ETHEREUM SEPOLIA OVER OTHER TESTNETS
**Decision:** Use Ethereum Sepolia testnet exclusively
**Rationale:**
- Most production-like test environment
- Real gas economics (not free)
- Chainlink Data Feeds available
- Largest developer ecosystem
- Closest simulation to mainnet conditions

**Rejected Alternatives:**
- Goerli: Being deprecated
- Local Ganache: Unrealistic network conditions
- Polygon Mumbai: Different fee structure distorts economics

## 3. FIREBASE OVER OTHER STATE MANAGEMENT
**Decision:** Use Firebase Firestore as single source of truth for off-chain state
**Rationale:**
- Free tier available (Spark plan)
- Real-time synchronization across regions
- Built-in offline capabilities
- Simple authentication model
- Meets mission constraint requirements

**Rejected Alternatives:**
- PostgreSQL: Requires managed service or self-hosting
- MongoDB Atlas: More complex setup
- AWS DynamoDB: Cost concerns at scale

## 4. EVENT-DRIVEN OVER POLLING
**Decision:** Implement event-driven architecture with Cloud Pub/Sub pattern
**Rationale:**
- Reduces unnecessary computation cycles
- Lower latency for signal detection
- Better resource utilization
- More resilient to network delays

**Implementation Note:** Fallback to scheduled heartbeat (24h max) ensures liveness

## 5. DEFENSIVE PRIMITIVES LAYERING
**Decision:** Four-layer defensive system (Pre-execution → Execution → Post-execution → Circuit Breaker)
**Rationale:**
- Defense in depth principle
- Each layer catches different failure modes
- Enables graceful degradation
- Provides audit trail for forensic analysis

**Critical Insight:** Most trading bots fail due to unhandled edge cases, not strategy flaws

## 6. EPHEMERAL AGENTS OVER PERSISTENT
**Decision:** Cloud functions that self-terminate after execution
**Rationale:**
- Eliminates state drift over time
- Forces idempotent design
- Reduces attack surface
- Aligns with serverless cost model
- Enables rapid scaling during volatility

## 7. SMA CROSSOVER AS INITIAL STRATEGY
**Decision:** Start with simple SMA crossover despite availability of complex ML
**Rationale:**
- Strategy validation is NOT the primary objective
- Simple strategy reduces debugging complexity
- Focus remains on architectural validation
- Can be upgraded later without changing architecture

## 8. TELEGRAM FOR EMERGENCY CONTACT
**Decision:** Use Telegram bot instead of email/SMS
**Rationale:**
- Immediate push notifications
- Two-way communication capability
- Simple command interface for overrides
- Works without phone number (bot API)
- Mission constraint explicitly allows this