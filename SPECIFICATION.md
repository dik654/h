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

interface SimulationCycle {
  cycleId: string;
  startTime: number;
  endTime: number;
  processedLevels: Map<HierarchyLevel, ProcessingResult>;
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

## 5. LLM Integration

### 5.1 Query Design

#### Individual Action Query Template
```
Context: {character_profile}, {current_household_state}, {current_world_state}
Action: {user_action_description}
Task: Analyze the consequences of this action and output metrics changes.
Output Format: JSON with metrics delta
```

#### Aggregation Query Template
```
Context: {entity_current_state}, {children_entities_changes}
Task: Calculate how the collective changes from {N} children entities affect this {entity_type}.
Consider: interdependencies, conflicts, synergies
Output Format: JSON with new metrics and events
```

### 5.2 Optimization Strategies

#### Batch Processing
- 동일 계층의 독립적인 개체들을 배치로 묶어 병렬 처리
- 예: 100명의 개인 행동을 10개 배치로 나누어 동시 쿼리

#### Caching
- 유사한 상황/행동 패턴에 대한 결과 캐싱
- 캐시 키: hash(context + action_type)

#### Summarization
- 상위 계층으로 갈수록 세부 정보 요약
- 국가 레벨 이상에서는 개별 인물 정보 불필요

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
