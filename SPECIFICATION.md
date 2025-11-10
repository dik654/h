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
[Action Queue]
    ↓
[Layer 1: Input Validation] ← 생애 단계, 특성, 자원, 쿨다운 검증
    ↓ (Invalid actions rejected)
[Layer 2: Context Enrichment] ← Character memory, 최근 행동, 진행 중 스토리 로드
    ↓
[Level 8: Process Individuals] ← LLM with enriched context
    ↓ (LLM Query Batch 1)
[Layer 3: Output Validation] ← Metric bounds, 서사 일관성, 시간 스케일 검증
    ↓ (Failed outputs regenerated up to 3x)
[Level 7: Aggregate to Households]
    ↓ (LLM Query Batch 2)
[Layer 4: Cross-Level Consistency] ← 하위→상위 일관성 검증
    ↓
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
[Causality Tracking] ← 변화 원인 기록
    ↓
[Personality Drift Detection] ← 캐릭터 일관성 모니터링
    ↓
[Story Arc Update] ← 진행 중인 스토리 업데이트
    ↓
[Store Results] → [Notify Users]
```

**Validation Layers**:
- **Layer 1 (Input)**: ~5ms/action, 거부율 5-10%
- **Layer 2 (Context)**: ~20ms/action, DB 조회 및 요약 생성
- **Layer 3 (Output)**: ~10ms/result, 재생성율 10-15%
- **Layer 4 (Cross-Level)**: ~50ms/entity, 불일치율 1-2%

## 4. Game Mechanics

### 4.1 Character Lifecycle System

#### Life Stages
캐릭터는 7단계 생애를 거치며, 각 단계마다 다른 능력치와 가능한 행동이 변화합니다.

- **Infant (유아, 0-5세)**: AI 자동 관리, 플레이 불가
- **Child (아동, 6-12세)**: 제한적 플레이, 교육 시작
- **Adolescent (청소년, 13-19세)**: 활성 플레이, 진로 탐색
- **Young Adult (청년, 20-35세)**: 완전한 플레이, 사회 진출, 체력 최대
- **Middle Aged (중년, 36-55세)**: 영향력 최대, 고위 직책 가능, 정신력 최고
- **Senior (노년, 56-75세)**: 은퇴 및 멘토링, 경험 전수
- **Elderly (고령, 76세+)**: 제한적 플레이, 가정 내 역할

#### Time Progression
- **1 Cycle** = 15분 (실제) = 15일 (게임)
- **1 Year** = 24 cycles = 6시간 (실제)
- **1 Generation** = ~50년 = 1,200 cycles = 300시간 ≈ 12.5일

#### Aging Effects
- 생애 단계 전환 시 능력치 자동 변화
- 청년기: Physical ↑, Energy ↑
- 중년기: Mental ↑, Leadership ↑, Physical ↓
- 노년기: Physical ↓↓, Mental →, Wisdom ↑

상세 설계: `docs/LIFECYCLE_AND_ROLES.md`

### 4.2 Interaction Queuing System

#### Interaction Types
캐릭터 간 상호작용은 큐에 저장되어 사이클마다 일괄 처리됩니다.

**가정 인터렉션** (Household)
- Family talk, Family activity, Family decision
- 같은 가정 구성원 간의 대화, 공동 활동, 의사결정

**조직 인터렉션** (Organization)
- Meeting, Collaboration, Negotiation, Competition
- 같은 조직 구성원 간의 회의, 협업, 경쟁

**정치 인터렉션** (Nation)
- Debate, Vote, Campaign, Policy proposal
- 같은 국가 내 정치적 활동

**사회 인터렉션** (Public)
- Trade, Alliance, Conflict, Social event
- 불특정 다수와의 공개 활동

#### Batch Processing
- 한 사이클 동안 제출된 모든 인터렉션을 컨텍스트별로 그룹화
- 같은 가정/조직의 모든 인터렉션을 함께 처리 (맥락 고려)
- LLM이 인터렉션 간 영향을 분석 (A↔B 대화가 B↔C 대화에 영향)

**예시**:
```
Smith 가정 (사이클 N):
- Alice → Bob: "연구 성공 공유"
- Bob → Alice: "축하와 격려"
- Alice → 아들: "진로 조언"

→ 한번에 처리:
"Alice의 연구 성공으로 가정 분위기가 좋아졌고,
Bob의 격려에 Alice가 힘을 얻었으며,
아들은 어머니를 롤모델로 삼아 과학자를 꿈꾸게 되었다."
```

### 4.3 Social Position System (Limited Slots)

#### Position Hierarchy
사회적 역할은 **제한된 정원(TO)**이 있으며, 경쟁을 통해 획득합니다.

**정치 역할**
- President (1명): 최고 권력, 선거로 선출
- Minister (10명): 대통령 임명
- Legislator (50명): 선거로 선출
- Governor/Mayor (N명): 지역별 선거

**조직 역할**
- CEO (조직당 1명): 능력/선거/임명
- Director (조직당 5-10명): 능력 기반 또는 CEO 임명
- Manager (조직당 20-50명): 능력 기반
- Worker (무제한): 누구나

**학술/군사 역할**
- General (5명): 능력 + 경력
- Professor (대학당 50명): 능력 + 경력
- Researcher (연구소당 100명): 능력 기반

#### Selection Methods

**Election (선거)**
- 후보 등록 → 선거운동 (2-3 사이클) → 투표 → 개표
- 유권자는 후보의 공약, 능력, 평판을 종합 고려
- LLM이 각 유권자의 성향에 따른 투표 결정

**Merit (능력 기반)**
- 관련 능력치, 경력, 학력, 평판을 점수화
- 상위 N명 자동 선발
- 투명한 점수 공개

**Appointment (임명)**
- 상위자가 후보 중 선택
- LLM이 임명권자의 성향, 정치적 이득, 후보 능력을 고려
- 임명 이유 공개

**Competition (경쟁)**
- 직접 대결 (토론, 시험, 프로젝트 성과)
- 승자가 역할 획득

#### Fair Competition
- **투명성**: 모든 선발 과정과 결과에 상세 설명 제공
- **공정성**: 요구사항 명확, 점수 계산 공개
- **기회**: 신규 유저 보호 시스템 (초기 50 사이클 보너스)
- **다양성**: 배경/전공 다양성 보너스

#### Position Constraints
- 한 캐릭터당 최대 3개 역할 보유 가능
- 양립 불가능한 역할 쌍 (예: 대통령이면서 판사 불가)
- 생애 단계 제약 (대통령: 35-75세만 가능)
- 국적/거주지 제약

상세 설계: `docs/LIFECYCLE_AND_ROLES.md` 섹션 3

### 4.4 Individual Actions

#### Action Categories
- **Social**: 대화, 협력, 경쟁, 거래
- **Economic**: 생산, 소비, 투자, 거래
- **Political**: 투표, 선동, 협상, 반란
- **Cultural**: 창작, 교육, 전파, 보존
- **Scientific**: 연구, 발명, 실험, 응용
- **Military**: 훈련, 전투, 방어, 정찰

#### Action Constraints
- 생애 단계에 따른 행동 제한 (아동은 정치 행동 불가)
- Energy 소모 (사이클당 회복)
- Cooldown (중요 행동은 연속 실행 불가)
- 역할 요구사항 (대통령만 가능한 행동 등)

### 4.5 Simulation Cycle Flow

#### Turn-Based Cycle (15분)
```
[Cycle N: Action Submission Phase (10분)]
- 유저들이 개인 행동 제출
- 유저들이 인터렉션 제출 (가정, 조직, 정치)
- 역할 경쟁 참여 (선거 후보 등록, 투표 등)

[Cycle N+1: Processing Phase (5분)]
1. 개인 행동 처리 (Level 8) - LLM
2. 인터렉션 배치 처리 (컨텍스트별) - LLM
3. 가정 집계 (Level 7)
4. 조직 집계 (Level 6)
5. 국가 집계 (Level 5)
6. 행성+ 집계 (Level 4-0)
7. 역할 경쟁 업데이트 (선거 진행 등)
8. 생애주기 업데이트 (나이 +15일)

[Result Phase (즉시)]
- 유저에게 결과 알림
- 계층별 영향 표시
- 역할 변동 알림 (당선, 승진 등)
```

#### Concurrent Systems
- **Main Simulation**: 매 사이클 진행
- **Elections**: 여러 사이클에 걸쳐 진행 (등록 → 운동 → 투표)
- **Aging**: 매 사이클 자동
- **World Events**: 비정기적 (전쟁, 재난 등)

### 4.6 Interaction Types (Extended)

#### Intra-Level Interactions
- 같은 계층 내 개체들 간의 직접 상호작용
- 예: 개인 ↔ 개인, 국가 ↔ 국가

#### Cross-Level Influences
- 하위 계층에서 상위 계층으로의 영향 전파
- 상위 계층의 정책/이벤트가 하위 계층에 영향

#### Multi-Character Interactions
- 2명 이상의 캐릭터가 참여하는 복잡한 상호작용
- 회의, 토론, 협상, 전투 등
- 모든 참여자의 행동과 반응을 종합 고려

### 4.7 World Dynamics System

#### Dynamic World State
세계는 지속적으로 변화하며, 이러한 변화가 캐릭터들에게 다양한 영향을 미칩니다.

**환경적 변화**
- **기후**: 온도, 강수량, 극한 기후 빈도가 변화
  - 온난화 시: 농업 피해, 이주 증가
  - 한랭화 시: 식량 부족, 생존 도전
  - 최적 기후 시: 경제 활성화

- **자원**: 식량, 물, 에너지, 광물의 풍부도 변화
  - 부족 시: 해당 자원 관련 직업 가치 상승
  - 풍부 시: 가격 하락, 새로운 기회

**사회문화적 변화**
- **문화 트렌드**: 10-20 사이클마다 새 트렌드 발생/소멸
  - 음식 트렌드: "채식주의 열풍", "전통 음식 부활"
  - 패션 트렌드: "사이버펑크 스타일", "복고풍"
  - 이데올로기 트렌드: "환경주의", "탈성장 운동"
  - 라이프스타일 트렌드: "디지털 노마드", "귀농 열풍"

- **사고방식**: 사회의 지배적 가치관 변화
  - 전통 ↔ 혁신
  - 권위 ↔ 자유
  - 물질 ↔ 정신
  - 과학 ↔ 신앙

**경제적 변화**
- **경제 사이클**: 호황 → 성장 → 안정 → 불황 → 대공황 순환
  - 호황: 투자/기업가 유리
  - 불황: 생존주의자/절약가 유리
  - 대공황: 자급자족 능력자/물물교환 전문가 유리

**정치적 변화**
- **전쟁/평화**: 전쟁 시 군인/무기상 유리, 평화 시 외교관/상인 유리
- **정치 기조**: 권위주의 ↔ 민주주의, 고립 ↔ 개방

#### Character Traits (캐릭터 특성)
각 캐릭터는 고유한 특성을 가지며, 이는 세계 상태에 따라 유리/불리하게 작용합니다.

**특성 카테고리**
- **성격**: Adaptable, Traditionalist, Risk Taker, Conservative
- **재능**: Green Thumb, Tech Savvy, Athletic, Artistic
- **가치관**: Environmentalist, Materialist, Pacifist, Nationalist
- **배경**: Rural Origin, City Dweller, Immigrant, Noble Born
- **후천적**: Experienced Farmer, Battle Hardened, Renowned Scholar
  (지속적인 행동 패턴으로 획득)

**특성의 조건부 효과**
```
예시: "Green Thumb" (농업 재능)

기본 효과:
- Farming efficiency +30%

조건부 효과:
✅ 최적 기후 (12-18도) → Farming +50%, economy +15
❌ 극한 기후 (온난화/한랭) → Farming -20%, stress +10
✅ 식량 부족 시대 → Reputation +25, happiness +10
❌ 첨단 기술 시대 (자동화) → Farming -15%, reputation -5
```

#### Dynamic Advantage System
**World State × Character Traits = 유불리**

캐릭터의 특성이 현재 세계 상태와 어떻게 조합되는지에 따라 실시간으로 이점이 계산됩니다.

**예시 시나리오: 온난화 + 식량 부족 + 기술 중시**

*캐릭터 A: 전통 농부*
- Green Thumb: +25 (식량 부족) -20 (온난화) = +5
- Traditionalist: -15 (기술 중시 사회)
- **총 이점: -10 (불리)**

*캐릭터 B: 농업 혁신가*
- Green Thumb: +25 (식량 부족) -20 (온난화) = +5
- Tech Savvy: +20 (기술 중시)
- Adaptable: +15 (급격한 변화)
- **총 이점: +40 (매우 유리)**

#### Player Feedback
플레이어는 매 사이클마다 세계 변화와 자신에게 미치는 영향을 알림받습니다.

```
[세계 변화 알림]
- 평균 기온 +2도 상승 (농업 생산성 감소)
- 새 트렌드: "친환경 라이프스타일" (환경주의자 유리)

[개인 영향]
당신의 이점이 -15 감소했습니다.
- [Traditional Farmer] 특성이 불리해지고 있습니다 (-25)
- [Patient] 특성이 위기 극복에 도움됩니다 (+10)

[추천 행동]
✓ 기후 적응형 농업 기술 교육 수강
✓ 환경주의 트렌드 동참 (평판 향상)
✓ 커뮤니티 협력 강화
```

상세 설계: `docs/WORLD_DYNAMICS.md`

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

### 5.5 Validation & Consistency System

**핵심 원칙**: 개연성과 논리적 일관성을 유지하여 몰입감 있는 시뮬레이션 제공

#### 4단계 검증 시스템

**1. Input Validation (LLM 호출 전)**
- 생애 단계별 행동 제약 검증 (아동은 정치 행동 불가 등)
- 특성-행동 충돌 검사 (Pacifist가 전쟁 시작 불가)
- 자원/에너지 요구사항 확인
- 쿨다운 체크 (같은 행동 연속 실행 제한)

**2. Context Enrichment (LLM 입력 강화)**
```typescript
interface EnrichedContext {
  recent_actions: Action[];           // 최근 10개 행동
  character_summary: string;          // "Alice는 조용한 과학자..."
  trait_history: TraitActivation[];   // 특성이 과거에 어떻게 작용했는지
  metric_bounds: MetricBounds;        // 허용된 변화량 범위
  prohibited_outcomes: string[];      // 불가능한 결과들
  ongoing_narrative: string;          // 진행 중인 스토리 라인
}
```

**3. Output Validation (LLM 결과 검증)**
- Metric bounds 위반 체크 (-50 ~ +50 범위 등)
- 서사 일관성 검증 (성격과 맞지 않는 행동 감지)
- 시간 스케일 검증 (15일 안에 불가능한 일 감지)
- Event 개수 제한 (사이클당 최대 3개 이벤트)
- 재시도 메커니즘 (최대 3회, 오류 피드백 포함)

**4. Cross-Level Consistency (계층 간 일관성)**
- 하위 레벨 변화가 상위 레벨에 논리적으로 반영되는지 확인
- 상위 레벨 상태(예: 가뭄)가 하위 레벨을 제약하는지 확인
- 예: 행성 수준 가뭄 발생 시 → 모든 국가의 농업 생산 감소 필수

#### Character Memory System

모든 캐릭터는 지속적 기억을 가지며, 이를 통해 일관성을 유지합니다:

```typescript
interface CharacterMemory {
  personality_summary: string;        // "Alice는 내성적이고 정직한 과학자"
  behavioral_patterns: Pattern[];     // 행동 패턴 (갈등 회피, 연구 선호 등)
  never_would: string[];              // "친구 배신", "거짓말"
  always_would: string[];             // "평화적 해결 추구", "진실 말하기"
  defining_moments: Event[];          // 인생의 결정적 순간들
  ongoing_story_arcs: StoryArc[];     // 진행 중인 스토리
}
```

#### Metric Bounds (동적 변화량 제한)

각 행동의 메트릭 변화는 동적으로 계산된 범위 내로 제한됩니다:

```typescript
// 기본 범위
scientific_action: { science: [-10, +15], energy: [-15, -5] }

// 수정 요소:
+ 캐릭터 능력치 (Intelligence 80 → +50% 보너스)
+ 생애 단계 (중년 → +20% 정신 활동)
+ 세계 상태 (기술 중시 시대 → +30%)
+ 특성 (Tech Savvy → +15)

// 최종 범위
= { science: [-10, +35], energy: [-18, -6] }
```

#### Causality Tracking (인과관계 추적)

모든 중요한 변화는 명확한 원인이 기록됩니다:

```
행복도 -25 감소 원인:
━━━━━━━━━━━━━━━━━━━━━━━━
🔴 45% - 연구 프로젝트 실패 (Cycle 1234)
🔴 30% - 글로벌 경기 침체 (Cycle 1232)
🔴 15% - 친구와의 갈등 (Cycle 1235)
🟡 10% - Pessimistic 특성 불리 (현 문화 트렌드)
━━━━━━━━━━━━━━━━━━━━━━━━
```

#### Personality Drift Detection

캐릭터 성격이 비논리적으로 변하는 것을 감지하고 방지:

```typescript
// 최근 20 사이클과 과거 200 사이클 행동 패턴 비교
const drift = calculatePatternDivergence(recent, historical);

if (drift.score > 0.7) {
  // 급격한 성격 변화 감지
  const justified = checkJustification(character, drift);

  if (!justified) {
    // 정당화되지 않으면 경고 또는 되돌림
    return { action: 'REVERT_OR_JUSTIFY' };
  } else {
    // 트라우마, 생애 전환 등으로 정당화되면 수용
    updatePersonalitySummary(character);
  }
}
```

#### World State Constraints

세계 상태 변화도 제약을 받습니다:

```typescript
const TRANSITION_RULES = {
  max_temperature_change: 2,       // °C per cycle (15 days)
  max_resource_change: 10,         // percentage points
  min_climate_phase_duration: 24,  // cycles (~1 year)
  major_change_requires_event: true,
};

// 예: 온도가 5°C 급변 → 대규모 기후 이벤트 필요
if (tempDelta > 2 && !hasCatastrophicEvent) {
  reject('Unrealistic climate change');
}
```

#### Story Arc Continuity

진행 중인 스토리 라인을 추적하고 유지:

```typescript
interface StoryArc {
  arc_type: 'personal_growth' | 'conflict' | 'romance' | 'ambition';
  status: 'building' | 'climax' | 'resolution';
  current_narrative_thread: string;
  unresolved_elements: string[];
  participants: string[];
  estimated_end_cycle: number;
}

// LLM 프롬프트에 주입
"진행 중인 스토리: Alice는 3년간 양자 컴퓨터 연구 중
미해결 요소: 펀딩 부족 문제, 경쟁사의 압박
→ 현재 행동을 이 맥락에서 처리하세요"
```

상세 설계: `docs/CONSISTENCY_AND_VALIDATION.md`

### 5.6 Implementation Priority

1. **Phase 1 (MVP)**:
   - Level 8: Full LLM (text + metrics)
   - Level 7-5: Rule-based 집계만
   - 캐싱 없음
   - 기본 입력 검증만

2. **Phase 2 (Optimization + Consistency)**:
   - Level 7: LLM 추가 (배치)
   - 기본 캐싱 구현
   - Level 6: 선택적 LLM
   - Character Memory System 추가
   - Output Validation 강화
   - Metric Bounds 동적 계산

3. **Phase 3 (Full Scale + Advanced Consistency)**:
   - 고급 캐싱 (70%+ 적중률)
   - Level 4-0 추가
   - Self-hosted LLM 검토
   - Causality Tracking
   - Story Arc System
   - Personality Drift Detection
   - Cross-Level Consistency Validation

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
