# Hierarchical World Simulation Game - Specification

## 1. Overview

계층적 우주 시뮬레이션 게임은 LLM을 활용한 다층 구조의 멀티플레이어 세계 시뮬레이션입니다. 각 유저는 개인 캐릭터로 참여하며, 하위 계층에서의 개별 행동이 상위 계층으로 전파되어 우주 전체에 영향을 미치는 시스템입니다.

## 2. Core Concept

### 2.1 Hierarchical Structure
```
Level 0: Universe (전체 우주)
    ├─ Level 1: Medium Universe (중우주)
    │   ├─ Level 2: Small Universe (소우주)
    │   │   ├─ Level 3: Solar System (태양계)
    │   │   │   ├─ Level 4: Planet (지구)
    │   │   │   │   ├─ Level 5: Nation (국가)
    │   │   │   │   │   ├─ Level 6: Organization (조직)
    │   │   │   │   │   │   ├─ Level 7: Household (가정)
    │   │   │   │   │   │   │   └─ Level 8: Individual (개인)
```

### 2.2 Bottom-Up Propagation
1. 개인(Individual) 행동 → 가정(Household) 영향
2. 가정 집계 → 조직(Organization) 영향
3. 조직 집계 → 국가(Nation) 영향
4. 국가 집계 → 행성(Planet) 영향
5. 행성 집계 → 태양계(Solar System) 영향
6. 태양계 집계 → 소우주(Small Universe) 영향
7. 소우주 집계 → 중우주(Medium Universe) 영향
8. 중우주 집계 → 전체 우주(Universe) 영향

## 3. Technical Architecture

### 3.1 LLM Query Hierarchy

#### Phase 1: Individual Action Processing
- 각 유저의 행동을 LLM에게 개별적으로 쿼리
- 출력: 행동의 결과, 수치화된 영향도 (경제, 정치, 문화, 과학, 군사 등)

#### Phase 2: Household Aggregation
- 같은 가정 내 개인들의 행동 집계
- LLM 쿼리: "가정 X에서 Y, Z 개인들이 A, B 행동을 했을 때 가정의 상태 변화"
- 출력: 가정 수치 (wealth, stability, happiness, influence)

#### Phase 3: Organization Aggregation
- 같은 조직 내 가정들의 영향 집계
- LLM 쿼리: "조직 X에 속한 가정들의 변화가 조직에 미치는 영향"
- 출력: 조직 수치 (power, resources, technology, culture)

#### Phase 4-8: Higher Level Aggregation
- 국가 → 행성 → 태양계 → 소우주 → 중우주 → 우주 순차적 집계
- 각 단계마다 LLM이 하위 계층의 수치를 분석하여 상위 계층 영향 계산

### 3.2 Data Model

```typescript
// Base entity structure (all hierarchy levels)
interface Entity {
  id: string;
  level: HierarchyLevel;
  name: string;
  parentId: string | null;
  childrenIds: string[];
  metrics: Metrics;
  history: HistoryEntry[];
  timestamp: number;
}

interface Metrics {
  economy: number;      // 경제력
  politics: number;     // 정치력
  culture: number;      // 문화력
  science: number;      // 과학력
  military: number;     // 군사력
  happiness: number;    // 행복도
  stability: number;    // 안정도
  population: number;   // 인구/구성원수
}

interface Action {
  userId: string;
  characterId: string;
  type: ActionType;
  description: string;
  timestamp: number;
  targetId?: string;
}

// Level-specific result structures

// Level 8: Individual Action Result
interface IndividualActionResult {
  userId: string;
  characterId: string;
  timestamp: number;

  // Rich narrative (stored)
  narrative: {
    action: string;           // User input
    result: string;           // LLM generated (2-3 sentences)
    mood: string;             // "triumphant", "disappointed", etc.
  };

  // Quantified impact (stored)
  metrics: {
    character: MetricsDelta;
    household: MetricsDelta;
  };

  // Events (stored)
  events: GameEvent[];

  // Tags for categorization (stored)
  tags: string[];
}

// Level 7: Household Aggregation Result
interface HouseholdAggregationResult {
  householdId: string;
  timestamp: number;

  // Brief summary (stored)
  summary: string;  // 1 sentence

  // Aggregated metrics (stored)
  metrics: MetricsDelta;

  // Synergy effects (stored)
  synergies: {
    type: string;
    effect: string;
    bonus: MetricsDelta;
  }[];

  // Data to propagate up (transient, not stored)
  propagateUp: {
    organizationId: string;
    summary: string;
    metrics: MetricsDelta;
  };
}

// Level 6: Organization Aggregation Result
interface OrganizationAggregationResult {
  organizationId: string;
  timestamp: number;

  // Very brief summary (stored)
  summary: string;  // 10 words max

  // Core metrics only (stored)
  metrics: {
    economy: number;
    science: number;
    culture: number;
    power: number;
  };

  // Major events only (stored)
  events: GameEvent[];

  // Data to propagate up (transient)
  propagateUp: {
    nationId: string;
    metrics: CoreMetrics;
    category: string;  // "research", "commerce", "military", etc.
  };
}

// Level 5: Nation Aggregation Result
interface NationAggregationResult {
  nationId: string;
  timestamp: number;

  // No narrative

  // Aggregate metrics (stored)
  metrics: CoreMetrics;

  // Critical events only (stored)
  events: GameEvent[];

  // Inter-nation relations (stored)
  diplomaticChanges: {
    targetNation: string;
    relationDelta: number;
    reason: string;
  }[];

  // Data to propagate up (transient)
  propagateUp: {
    planetId: string;
    metrics: {
      economy: number;
      science: number;
      technology: number;
    };
  };
}

// Level 4+: Cosmic Aggregation Result (Planet and above)
interface CosmicAggregationResult {
  entityId: string;
  level: HierarchyLevel;
  timestamp: number;

  // Pure metrics (stored)
  metrics: {
    [key: string]: number;
  };

  // Milestone events only (stored)
  events: {
    type: "milestone";
    description: string;
    significance: "cosmic";
  }[];
}

interface SimulationCycle {
  cycleId: string;
  startTime: number;
  endTime: number;
  processedLevels: Map<HierarchyLevel, ProcessingResult>;
}

interface MetricsDelta {
  [key: string]: number;  // Can be positive or negative
}

interface CoreMetrics {
  economy: number;
  science: number;
  culture: number;
  military: number;
  happiness: number;
}

interface GameEvent {
  type: string;
  description: string;
  significance: "low" | "medium" | "high" | "cosmic";
  timestamp: number;
  affectedEntities: string[];
}
```

### 3.3 Processing Pipeline

```
[User Actions]
    ↓
[Action Queue] → [Validation]
    ↓
[Level 8: Process Individuals]
    ↓ (LLM Query Batch 1)
[Level 7: Aggregate to Households]
    ↓ (LLM Query Batch 2)
[Level 6: Aggregate to Organizations]
    ↓ (LLM Query Batch 3)
[Level 5: Aggregate to Nations]
    ↓ (LLM Query Batch 4)
[Level 4: Aggregate to Planets]
    ↓ (LLM Query Batch 5)
[Level 3: Aggregate to Solar Systems]
    ↓ (LLM Query Batch 6)
[Level 2: Aggregate to Small Universes]
    ↓ (LLM Query Batch 7)
[Level 1: Aggregate to Medium Universes]
    ↓ (LLM Query Batch 8)
[Level 0: Update Universe State]
    ↓
[Store Results] → [Notify Users]
```

## 4. Game Mechanics

### 4.1 Player Actions

#### Individual Actions
- **Social**: 대화, 협력, 경쟁, 거래
- **Economic**: 생산, 소비, 투자, 거래
- **Political**: 투표, 선동, 협상, 반란
- **Cultural**: 창작, 교육, 전파, 보존
- **Scientific**: 연구, 발명, 실험, 응용
- **Military**: 훈련, 전투, 방어, 정찰

### 4.2 Interaction Types

#### Intra-Level Interactions
- 같은 계층 내 개체들 간의 직접 상호작용
- 예: 개인 ↔ 개인, 국가 ↔ 국가

#### Cross-Level Influences
- 하위 계층에서 상위 계층으로의 영향 전파
- 상위 계층의 정책/이벤트가 하위 계층에 영향

### 4.3 Simulation Cycle

#### Turn-Based Cycle (권장)
1. **Action Phase** (5-10분): 유저들이 행동 제출
2. **Processing Phase** (2-5분): 계층별 순차 처리
3. **Result Phase** (2분): 결과 반영 및 알림
4. **총 사이클 시간**: 10-15분

#### Real-Time Alternative
- 지속적인 행동 큐 처리
- 주기적 배치 집계 (예: 매 1분마다)

## 5. LLM Integration & Aggregation Strategy

### 5.1 Hybrid Approach: Layered Text + Metrics

**핵심 원칙**: 계층마다 다른 데이터 표현 방식 사용

#### Level 8 (Individual): Rich Text + Detailed Metrics
- **목적**: 플레이어 몰입감, 스토리텔링
- **데이터 형식**:
  - Full narrative (2-3 문장)
  - Detailed metrics (10+ fields)
  - All events
- **LLM 사용**: 모든 행동마다 사용
- **예시**:
```json
{
  "narrative": "Alice는 3개월간의 집중 연구 끝에 에너지 효율을 15% 향상시키는 새로운 촉매를 발견했다.",
  "metrics": {
    "character": {"science": +10, "reputation": +5},
    "household": {"wealth": +3, "happiness": +2, "influence": +1}
  },
  "events": [{"type": "discovery", "significance": "medium"}]
}
```

#### Level 7 (Household): Summary + Key Metrics
- **목적**: 가족 단위 스토리, 효율성 시작
- **데이터 형식**:
  - Brief summary (1 문장)
  - Key metrics (8 fields)
  - Important events only
- **LLM 사용**: 배치 처리 (50개 가정/쿼리)
- **예시**:
```json
{
  "summary": "Alice의 과학적 성과와 Bob의 경제적 기여로 Smith 가정의 사회적 지위가 상승했다.",
  "metrics": {"wealth": +8, "happiness": +5, "stability": +2, "influence": +3},
  "synergies": [{"type": "morale_boost", "effect": "happiness +2"}]
}
```

#### Level 6 (Organization): Metrics-Focused + One-line
- **목적**: 조직 동향 파악, 효율성 우선
- **데이터 형식**:
  - One-line summary (10 단어 이내)
  - Core metrics (6 fields)
  - Major events only
- **LLM 사용**: 배치 처리 (100개 조직/10 쿼리) + 선택적
- **예시**:
```json
{
  "summary": "연구소의 과학적 돌파로 업계 선도 기관으로 부상",
  "metrics": {"science": +30, "economy": +35, "reputation": +20, "technology": +10},
  "events": [{"type": "funding_secured"}]
}
```

#### Level 5 (Nation): Rule-Based + Selective LLM
- **목적**: 국가 스케일 집계, 비용 절감
- **데이터 형식**:
  - No narrative
  - Aggregate metrics (5 fields)
  - Critical events only
- **LLM 사용**: 10-20% (중요 변화만)
- **처리**: 주로 룰 기반 집계 + 임계값 초과 시 LLM

#### Level 4-0 (Planet → Universe): Pure Metrics
- **목적**: 우주적 스케일, 최대 효율
- **데이터 형식**:
  - Pure numbers
  - Global metrics (3-4 fields)
  - Milestone events only
- **LLM 사용**: 거의 없음 (cosmic events만)
- **처리**: 룰 기반 집계

### 5.2 Query Design by Level

#### Level 8: Individual Action Processing
```
Prompt Template:
캐릭터: {name} ({role}, {age}, {organization})
현재 상황:
  - 가정 상태: wealth={x}, stability={y}
  - 조직 상태: {org_summary}
  - 최근 행동: {recent_actions}
행동: "{user_input_action}"

다음을 JSON으로 출력:
1. 행동 결과 서술 (2-3문장, 구체적이고 흥미롭게)
2. 수치 영향 (character, household 메트릭)
3. 특별 이벤트 발생 여부

출력 형식:
{
  "narrative": "...",
  "metrics": {"character": {...}, "household": {...}},
  "events": [...]
}
```

#### Level 7: Household Aggregation (Batch)
```
Prompt Template:
다음 {N}개 가정의 변화를 각각 분석하시오:

가정 1 (Smith Family):
- Alice: 에너지 촉매 발견 (science +10, reputation +5)
- Bob: 성공적인 거래 (economy +5)
현재 가정 상태: wealth=75, happiness=68

가정 2 (Lee Family):
- Charlie: 프로젝트 완료 (economy +7, efficiency +3)
현재 가정 상태: wealth=82, happiness=71
...

각 가정마다 다음을 출력 (JSON array):
1. 1문장 요약
2. 가정 메트릭 변화 (구성원 간 시너지 고려)
3. 조직에 전파할 데이터

출력: [
  {"householdId": "smith_family", "summary": "...", "metrics": {...}, "propagateUp": {...}},
  ...
]
```

#### Level 6: Organization Aggregation (Batch + Selective)
```
Rule-Based Aggregation (기본):
- 모든 household의 metrics 가중 합산
- 임계값 체크 (science > +100, economy > +200 등)

LLM Query (임계값 초과 시만):
조직: Tech Research Institute
이번 사이클 변화:
- 구성원 50명의 주요 기여: science +125, economy +230
- 임계값 초과: science +125 (임계값: +100)

다음을 출력:
1. 조직 차원의 특별 이벤트 (신규 프로젝트, 승진 등)
2. 시너지 효과 (단순 합산 이상의 효과)
3. 10단어 이내 요약

출력: {...}
```

#### Level 5+: Nation and Above (Mostly Rule-Based)
```
Rule-Based Processing:
1. 하위 개체들의 metrics 집계
2. 가중치 적용 (대기업 > 중소기업)
3. 이벤트 임계값 체크
4. 임계값 초과 시에만 LLM 호출

LLM Query (매우 선택적):
국가: Korea
변화: science +500, economy +2000, technology +150
임계값 초과: science +500 (임계값: +200)

국가 차원의 영향 분석:
1. 주요 이벤트 (기술 부흥기, 경제 도약 등)
2. 타국과의 관계 변화
3. 행성 차원 영향

출력: {...}
```

### 5.3 Optimization Strategies

#### Batch Processing
- **Level 8**: 독립적, 병렬 처리 (1000개 → 1000 병렬 쿼리)
- **Level 7**: 50개 가정/배치 (500개 가정 → 10 배치 쿼리)
- **Level 6**: 100개 조직/배치, 선택적 (100개 조직 → 1-2 쿼리)
- **Level 5+**: 선택적 쿼리만 (20개 국가 → 0-2 쿼리)

#### Caching Strategy
```typescript
interface CacheKey {
  actionType: string;
  contextHash: string;  // 현재 상태의 해시 (버킷화)
  level: number;
}

// 캐시 적중률 목표
Level 8: 30-40%  // 개인 행동은 다양함
Level 7: 50-60%  // 가정 패턴은 제한적
Level 6: 70-80%  // 조직 패턴은 더 제한적
Level 5+: 90%+   // 국가 이상은 매우 유사한 패턴
```

#### Progressive Summarization
```
Individual (Level 8):  200 words, 10+ metrics
    ↓ 압축 (87.5% 감소)
Household (Level 7):   25 words, 8 metrics
    ↓ 압축 (60% 감소)
Organization (Level 6): 10 words, 6 metrics
    ↓ 압축 (100% 텍스트 제거)
Nation (Level 5):      0 words, 5 metrics
    ↓ 압축
Planet+ (Level 4-0):   0 words, 3-4 metrics
```

### 5.4 Cost Estimation & Optimization

#### Baseline Cost (1000 active users, 15min cycle)
```
Level 8:  1000 queries × 800 tokens  = 800K tokens  ($24)
Level 7:    50 queries × 2000 tokens = 100K tokens  ($3)
Level 6:    10 queries × 3000 tokens = 30K tokens   ($0.90)
Level 5:     5 queries × 4000 tokens = 20K tokens   ($0.60)
Level 4-0:   1 query   × 2000 tokens = 2K tokens    ($0.06)
────────────────────────────────────────────────────
Total:                                 ~950K tokens  ($28.56/cycle)

Monthly (2,880 cycles): $82,253
```

#### Optimized Cost (with caching & rule-based)
```
Level 8: 50% cache hit  → $12/cycle
Level 7: 60% cache hit  → $1.20/cycle
Level 6: 80% cache hit  → $0.18/cycle
Level 5+: 90% rule-based → $0.06/cycle
────────────────────────────────────────
Total: $13.44/cycle

Monthly (2,880 cycles): $38,707

Further optimization (self-hosted LLM): $10,000-15,000/month
```

### 5.5 Implementation Priority

1. **Phase 1 (MVP)**:
   - Level 8: Full LLM (text + metrics)
   - Level 7-5: Rule-based 집계만
   - 캐싱 없음

2. **Phase 2 (Optimization)**:
   - Level 7: LLM 추가 (배치)
   - 기본 캐싱 구현
   - Level 6: 선택적 LLM

3. **Phase 3 (Full Scale)**:
   - 고급 캐싱 (70%+ 적중률)
   - Level 4-0 추가
   - Self-hosted LLM 검토

## 6. Storage & State Management

### 6.1 Database Schema

#### Primary Collections
- `entities`: 모든 계층의 개체 정보
- `actions`: 유저 행동 로그
- `cycles`: 시뮬레이션 사이클 기록
- `events`: 게임 내 이벤트 (전쟁, 재난, 발견 등)
- `users`: 유저 계정 정보

#### Indexes
- `entities.level + entities.parentId`: 계층별 조회
- `actions.timestamp + actions.characterId`: 행동 이력
- `cycles.cycleId`: 사이클 조회

### 6.2 State Synchronization
- WebSocket for real-time updates
- Event-driven architecture
- Eventual consistency for upper layers

## 7. Scalability Considerations

### 7.1 Horizontal Scaling

#### Level-Based Sharding
- 각 계층을 별도 서비스로 분리
- Level 8-7 (Individual, Household): High-frequency service
- Level 6-5 (Organization, Nation): Medium-frequency service
- Level 4-0 (Planet ~ Universe): Low-frequency service

#### Geographic Distribution
- 국가/대륙별 데이터센터 분산
- 로컬 처리 후 글로벌 집계

### 7.2 Performance Targets

- Individual action processing: < 1초
- Full cycle completion: < 5분 (1000 active users)
- Database query latency: < 100ms (p95)
- LLM query latency: < 3초 (p95)

## 8. User Experience

### 8.1 Client Interface

#### Main Views
- **Personal Dashboard**: 캐릭터 상태, 소속 조직/국가 정보
- **Action Panel**: 가능한 행동 목록, 행동 제출
- **Hierarchy View**: 우주 → 개인까지의 계층 구조 시각화
- **Impact Tracker**: 내 행동이 각 계층에 미친 영향 추적
- **Events Feed**: 각 계층에서 발생한 주요 이벤트

#### Visualizations
- 계층 트리 그래프
- 국가/조직 간 관계 네트워크
- 메트릭 변화 타임라인
- 우주 지도 (3D visualization)

### 8.2 Notification System
- 내 행동의 결과 알림
- 소속 조직/국가의 주요 이벤트
- 상위 계층 변화가 나에게 미치는 영향

## 9. Example Scenario

### Scenario: 과학자의 발견

1. **개인 행동** (Level 8)
   - 유저 "Alice"가 "새로운 에너지 기술 연구" 행동 제출
   - LLM 처리: Alice의 과학력 +10, 발견 확률 계산

2. **가정 영향** (Level 7)
   - Alice의 가정 "Smith Family"의 wealth +5, influence +3
   - LLM: 가족 구성원들의 자부심, 경제적 혜택 분석

3. **조직 영향** (Level 6)
   - Alice의 소속 "Tech Research Institute"의 science +15, funding +20
   - LLM: 조직의 명성 상승, 신규 프로젝트 가능성 분석

4. **국가 영향** (Level 5)
   - 국가 "Korea"의 science +8, economy +5
   - LLM: 국가 경쟁력 향상, 타국과의 관계 변화

5. **행성 영향** (Level 4)
   - 지구의 technology level +2
   - LLM: 지구 문명 발전 단계 평가

6. **상위 계층 파급** (Level 3-0)
   - 태양계 → 소우주 → 중우주 → 우주로 미세한 영향 전파
   - LLM: 우주적 기술 발전 패턴에 기여

7. **피드백**
   - Alice: "당신의 연구가 국가 과학력 향상에 기여했습니다!"
   - 조직원들: "연구소의 명성이 올랐습니다. 신규 펀딩 획득!"
   - 국민들: "Korea의 기술력이 상승했습니다."

## 10. Future Extensions

### 10.1 Advanced Features
- **AI NPCs**: LLM으로 제어되는 NPC 캐릭터
- **Dynamic Events**: 우주 재난, 외계 접촉 등
- **Time Travel**: 과거 시점의 시뮬레이션 분기
- **Parallel Universes**: 여러 우주 동시 시뮬레이션

### 10.2 Governance
- 유저 투표로 게임 규칙 변경
- 커뮤니티 주도 컨텐츠 생성

### 10.3 Economy
- 게임 내 화폐/자원 거래
- NFT 기반 독특한 아이템/업적

## 11. Technical Stack (Recommended)

### Backend
- **Runtime**: Node.js / Deno
- **Framework**: NestJS / Fastify
- **Database**: PostgreSQL (entities, users) + MongoDB (logs, events)
- **Cache**: Redis
- **Queue**: BullMQ / RabbitMQ
- **LLM**: OpenAI API / Claude API / Custom model

### Frontend
- **Framework**: React / Vue.js
- **3D Visualization**: Three.js / D3.js
- **State Management**: Redux / Zustand
- **Real-time**: Socket.io

### Infrastructure
- **Container**: Docker
- **Orchestration**: Kubernetes
- **Monitoring**: Prometheus + Grafana
- **Logging**: ELK Stack

## 12. Risks & Mitigations

### 12.1 LLM Query Cost
- **Risk**: 대량의 LLM 쿼리로 인한 높은 비용
- **Mitigation**:
  - Aggressive caching
  - 유사 상황 배치 처리
  - Self-hosted 모델 검토

### 12.2 Processing Delay
- **Risk**: 수천명 유저 시 처리 지연
- **Mitigation**:
  - 턴 기반 사이클로 시간 확보
  - 계층별 병렬 처리
  - 우선순위 큐 (활성 유저 우선)

### 12.3 Data Consistency
- **Risk**: 분산 처리 시 상태 불일치
- **Mitigation**:
  - Saga pattern
  - Event sourcing
  - 계층별 트랜잭션 경계 명확화

### 12.4 Balance Issues
- **Risk**: 특정 행동/계층이 과도하게 유리
- **Mitigation**:
  - 지속적인 모니터링
  - A/B 테스트
  - 커뮤니티 피드백 반영

## 13. Success Metrics

### 13.1 Technical Metrics
- Average cycle completion time
- LLM query success rate
- System uptime
- Database performance

### 13.2 Game Metrics
- Daily Active Users (DAU)
- Average actions per user
- Retention rate (D1, D7, D30)
- Hierarchy engagement (각 계층별 유저 관심도)

### 13.3 Quality Metrics
- User satisfaction score
- Bug report rate
- Balance satisfaction (설문)
- LLM output quality (인간 평가)
