# 계층 집계 데이터 형식 설계

## 1. 접근법 비교 분석

### 1.1 순수 수치화 접근법

**장점**
- ✅ 빠른 처리 속도 (산술 연산만으로 집계 가능)
- ✅ 낮은 LLM 비용 (단순 계산은 LLM 불필요)
- ✅ 예측 가능한 결과
- ✅ 쉬운 밸런스 조정 (수식만 수정)
- ✅ 효율적인 저장 (숫자 몇 개)

**단점**
- ❌ 맥락 손실 (왜 그런 변화가 생겼는지 불명확)
- ❌ 창발적 스토리 부족
- ❌ LLM의 추론 능력 활용 불가
- ❌ 단조로운 게임플레이
- ❌ 복잡한 상호작용 표현 어려움

**예시**
```json
{
  "individualAction": {
    "userId": "user123",
    "action": "research",
    "impact": {
      "science": +10,
      "economy": +2
    }
  },
  "householdAggregation": {
    "totalScience": +10,
    "totalEconomy": +2,
    "householdMetrics": {
      "science": 85 -> 95,
      "economy": 50 -> 52
    }
  }
}
```

### 1.2 순수 텍스트 접근법

**장점**
- ✅ 풍부한 맥락과 스토리
- ✅ LLM의 창발적 추론 능력 활용
- ✅ 예상치 못한 흥미로운 결과
- ✅ 몰입감 있는 내러티브
- ✅ 복잡한 관계성 표현 가능

**단점**
- ❌ 높은 LLM 비용 (모든 단계에서 LLM 필요)
- ❌ 느린 처리 속도
- ❌ 일관성 유지 어려움
- ❌ 밸런스 조정 어려움 (블랙박스)
- ❌ 비효율적인 저장

**예시**
```json
{
  "individualAction": {
    "userId": "user123",
    "description": "Alice가 획기적인 에너지 연구를 수행했다. 실험실에서 밤낮으로 연구한 결과..."
  },
  "householdAggregation": {
    "description": "Smith 가정에서 Alice의 연구 성공으로 가족들이 자부심을 느끼고, 경제적으로도 여유가 생겼다..."
  }
}
```

---

## 2. 권장 접근법: 하이브리드 (레이어드 수치화 + 텍스트)

### 2.1 핵심 아이디어

**각 계층마다 다른 표현 방식 사용**
- **하위 계층** (Individual, Household): 텍스트 풍부 + 수치
- **중간 계층** (Organization, Nation): 수치 중심 + 요약 텍스트
- **상위 계층** (Planet+): 순수 수치 + 주요 이벤트만

### 2.2 계층별 상세 설계

#### Level 8: Individual (개인)

**입력**: 유저의 자연어 행동
```
"새로운 에너지 기술을 연구한다"
```

**LLM 처리**
```
Prompt:
캐릭터: Alice (과학자, 35세, Tech Research Institute 소속)
현재 상황: 가정 안정도 80%, 조직 연구 예산 충분
행동: "새로운 에너지 기술을 연구한다"

다음을 출력하시오:
1. 행동 결과 서술 (2-3문장)
2. 수치 영향 (JSON)
3. 특별 이벤트 발생 여부
```

**출력**
```json
{
  "narrative": "Alice는 3개월간의 집중 연구 끝에 에너지 효율을 15% 향상시키는 새로운 촉매를 발견했다. 이 발견은 학계의 주목을 받았고, 연구소는 추가 펀딩을 확보했다.",
  "metrics": {
    "character": {
      "science": +10,
      "reputation": +5
    },
    "household": {
      "wealth": +3,
      "happiness": +2,
      "influence": +1
    }
  },
  "events": [
    {
      "type": "discovery",
      "significance": "medium",
      "title": "새로운 에너지 촉매 발견"
    }
  ],
  "tags": ["science", "energy", "breakthrough"]
}
```

**저장**: 전체 (narrative + metrics + events)

---

#### Level 7: Household (가정)

**입력**: 가정 내 모든 개인의 metrics + events
```json
{
  "members": [
    {
      "name": "Alice",
      "metrics": {"science": +10, "reputation": +5},
      "narrative": "에너지 촉매 발견..."
    },
    {
      "name": "Bob",
      "metrics": {"economy": +5},
      "narrative": "성공적인 거래..."
    }
  ],
  "currentHouseholdState": {
    "wealth": 75,
    "happiness": 68,
    "stability": 80
  }
}
```

**LLM 처리** (경량화)
```
Prompt:
가정: Smith Family
구성원 행동 요약:
- Alice: 에너지 촉매 발견 (science +10, reputation +5)
- Bob: 성공적인 거래 (economy +5)

가정에 미치는 종합 영향을 계산하시오:
1. 구성원 간 시너지 효과
2. 가정 메트릭 변화
3. 1문장 요약
```

**출력**
```json
{
  "summary": "Alice의 과학적 성과와 Bob의 경제적 기여로 Smith 가정의 사회적 지위가 상승했다.",
  "metrics": {
    "wealth": +8,      // Bob +5 + Alice 영향 +3
    "happiness": +5,   // 가족의 자부심
    "stability": +2,
    "influence": +3    // 사회적 지위 상승
  },
  "synergies": [
    {
      "type": "morale_boost",
      "effect": "happiness +2"
    }
  ],
  "propagateUp": {
    "organizationId": "tech_institute_01",
    "summary": "구성원 Alice의 과학적 돌파",
    "metrics": {"science": +10, "reputation": +5}
  }
}
```

**저장**: metrics + summary + propagateUp 데이터

---

#### Level 6: Organization (조직)

**입력**: 조직 내 모든 가정의 propagateUp 데이터
```json
{
  "households": [
    {
      "id": "smith_family",
      "summary": "구성원 Alice의 과학적 돌파",
      "metrics": {"science": +10, "reputation": +5}
    },
    {
      "id": "lee_family",
      "summary": "구성원 Charlie의 성공적인 프로젝트 관리",
      "metrics": {"economy": +7, "efficiency": +3}
    }
    // ... 총 50개 가정
  ],
  "currentOrgState": {
    "science": 450,
    "economy": 380,
    "reputation": 520
  }
}
```

**LLM 처리** (더 경량화, 배치 처리)
```
Prompt:
조직: Tech Research Institute
구성원 50명의 주요 기여:
- 과학적 성과: 3건 (총 science +25)
- 경제적 성과: 5건 (총 economy +30)
- 효율성 향상: 2건 (총 efficiency +8)

조직 차원의 영향을 계산하시오:
1. 조직 메트릭 변화 (집계 + 시너지)
2. 조직 이벤트 발생 여부 (신규 프로젝트, 승진 등)
3. 1문장 요약
```

**출력**
```json
{
  "summary": "연구소의 과학적 돌파와 효율적 운영으로 업계 선도 기관으로 부상",
  "metrics": {
    "science": +30,      // 직접 기여 +25 + 시너지 +5
    "economy": +35,      // 직접 기여 +30 + 펀딩 증가 +5
    "reputation": +20,
    "technology": +10
  },
  "events": [
    {
      "type": "funding_secured",
      "amount": "추가 예산 20% 확보"
    },
    {
      "type": "new_project",
      "description": "에너지 효율화 프로젝트 론칭"
    }
  ],
  "propagateUp": {
    "nationId": "korea",
    "metrics": {"science": +30, "economy": +35, "technology": +10},
    "category": "research_institution"
  }
}
```

**저장**: metrics + summary + events (개별 narrative 제외)

---

#### Level 5: Nation (국가)

**입력**: 국가 내 모든 조직의 aggregated metrics
```json
{
  "organizations": [
    {
      "id": "tech_institute_01",
      "type": "research",
      "metrics": {"science": +30, "economy": +35, "technology": +10}
    },
    {
      "id": "samsung_corp",
      "type": "corporation",
      "metrics": {"economy": +150, "technology": +20, "trade": +40}
    }
    // ... 총 500개 조직
  ],
  "currentNationState": {
    "economy": 85000,
    "science": 7200,
    "military": 6500,
    "happiness": 72
  }
}
```

**처리 방식**: LLM + 룰 기반 하이브리드
```
1. 룰 기반 집계 (빠르고 저렴)
   - 모든 조직의 metrics 단순 합산
   - 가중치 적용 (대기업 영향 > 중소기업)

2. LLM 처리 (선택적, 중요 이벤트만)
   - 임계값 초과 시 (예: science +100 이상)
   - 국가 정책 영향 분석
   - 타국과의 관계 변화
```

**출력**
```json
{
  "metrics": {
    "economy": +500,    // 룰 기반 집계
    "science": +120,
    "technology": +80,
    "culture": +30,
    "happiness": +2     // 경제 성장 효과
  },
  "events": [
    {
      "type": "technology_boom",
      "description": "기술 부문 급성장",
      "trigger": "science +120 임계값 초과"
    }
  ],
  "diplomaticChanges": [
    {
      "targetNation": "japan",
      "relation": +5,
      "reason": "기술 경쟁력 향상"
    }
  ],
  "propagateUp": {
    "planetId": "earth",
    "metrics": {"economy": +500, "science": +120, "technology": +80}
  }
}
```

**LLM 사용 빈도**: 10-20% (중요 변화만)

---

#### Level 4+: Planet, Solar System, Universe

**처리 방식**: 주로 룰 기반, LLM 최소화

```json
{
  "level": "planet",
  "metrics": {
    "totalEconomy": +2500,      // 모든 국가 합산
    "totalScience": +500,
    "totalPopulation": +10000,
    "averageHappiness": 68.5,   // 가중 평균
    "technologyLevel": 7.2      // 과학 기술 종합 지수
  },
  "events": [
    {
      "type": "planetary_milestone",
      "condition": "technologyLevel > 7.0",
      "description": "지구 문명이 Type 1 문명 단계에 근접"
    }
  ],
  "propagateUp": {
    "solarSystemId": "sol",
    "metrics": {"civilization": +0.5}
  }
}
```

**LLM 사용**: 거의 없음 (주요 우주적 이벤트만)

---

## 3. 데이터 흐름 최적화

### 3.1 데이터 요약 전략

각 계층을 올라갈 때마다 **정보 압축**:

```
Individual (Level 8):
- Full narrative (200 words)
- Detailed metrics (10+ fields)
- All events
  ↓ 압축
Household (Level 7):
- Brief summary (50 words)
- Key metrics (8 fields)
- Important events only
  ↓ 압축
Organization (Level 6):
- One-line summary (10 words)
- Core metrics (6 fields)
- Major events only
  ↓ 압축
Nation (Level 5):
- No narrative
- Aggregate metrics (5 fields)
- Critical events only
  ↓ 압축
Planet+ (Level 4-0):
- Pure numbers
- Global metrics (3-4 fields)
- Milestone events only
```

### 3.2 배치 처리 전략

**같은 레벨의 독립적 개체들을 배치로 묶어 병렬 처리**

```typescript
// Example: Level 7 (Household) processing
async function processHouseholdLevel(households: Household[]) {
  const BATCH_SIZE = 50;
  const batches = chunk(households, BATCH_SIZE);

  // 병렬 처리
  const results = await Promise.all(
    batches.map(batch => processHouseholdBatch(batch))
  );

  return results.flat();
}

async function processHouseholdBatch(batch: Household[]) {
  // 배치 내 모든 가정을 하나의 LLM 쿼리로 처리
  const prompt = `
    다음 ${batch.length}개 가정의 변화를 각각 분석하시오:
    ${batch.map(h => `가정 ${h.id}: ${summarizeHousehold(h)}`).join('\n')}

    각 가정마다 JSON 형식으로 출력:
    [
      {"householdId": "...", "metrics": {...}, "summary": "..."},
      ...
    ]
  `;

  const response = await llm.query(prompt);
  return parseJSONArray(response);
}
```

### 3.3 캐싱 전략

**유사한 상황은 캐시에서 재사용**

```typescript
interface CacheKey {
  actionType: string;
  contextHash: string;  // 현재 상태의 해시
  level: number;
}

async function processWithCache(
  action: Action,
  context: Context,
  level: number
) {
  const cacheKey = generateCacheKey(action, context, level);

  // 캐시 조회
  const cached = await cache.get(cacheKey);
  if (cached) {
    return adjustCachedResult(cached, context);
  }

  // LLM 쿼리
  const result = await llm.query(buildPrompt(action, context));

  // 캐시 저장 (TTL: 1시간)
  await cache.set(cacheKey, result, 3600);

  return result;
}
```

**캐시 적중률 목표**:
- Level 8 (Individual): 30-40%
- Level 7 (Household): 50-60%
- Level 6 (Organization): 70-80%
- Level 5+ (Nation+): 90%+

---

## 4. 실제 구현 예시

### 4.1 전체 데이터 구조

```typescript
// Level 8: Individual Action
interface IndividualActionResult {
  userId: string;
  characterId: string;
  timestamp: number;

  // Rich narrative
  narrative: {
    action: string;           // 유저 입력
    result: string;           // LLM 생성 (2-3 문장)
    mood: string;             // "triumphant", "disappointed", etc.
  };

  // Quantified impact
  metrics: {
    character: MetricsDelta;
    household: MetricsDelta;
  };

  // Events
  events: GameEvent[];

  // Tags for categorization
  tags: string[];
}

// Level 7: Household Aggregation
interface HouseholdAggregationResult {
  householdId: string;
  timestamp: number;

  // Brief summary
  summary: string;  // 1 문장

  // Aggregated metrics
  metrics: MetricsDelta;

  // Synergy effects
  synergies: {
    type: string;
    effect: string;
    bonus: MetricsDelta;
  }[];

  // Data to propagate up
  propagateUp: {
    organizationId: string;
    summary: string;
    metrics: MetricsDelta;
  };
}

// Level 6: Organization Aggregation
interface OrganizationAggregationResult {
  organizationId: string;
  timestamp: number;

  // Very brief summary
  summary: string;  // 10 단어 이내

  // Core metrics only
  metrics: {
    economy: number;
    science: number;
    culture: number;
    power: number;
  };

  // Major events only
  events: GameEvent[];

  // Data to propagate up
  propagateUp: {
    nationId: string;
    metrics: CoreMetrics;
    category: string;  // "research", "commerce", "military", etc.
  };
}

// Level 5: Nation Aggregation
interface NationAggregationResult {
  nationId: string;
  timestamp: number;

  // No narrative

  // Aggregate metrics
  metrics: CoreMetrics;

  // Critical events only
  events: GameEvent[];

  // Inter-nation relations
  diplomaticChanges: {
    targetNation: string;
    relationDelta: number;
    reason: string;
  }[];

  // Data to propagate up
  propagateUp: {
    planetId: string;
    metrics: {
      economy: number;
      science: number;
      technology: number;
    };
  };
}

// Level 4+: Planet and above
interface CosmicAggregationResult {
  entityId: string;
  level: HierarchyLevel;
  timestamp: number;

  // Pure metrics
  metrics: {
    [key: string]: number;
  };

  // Milestone events only
  events: {
    type: "milestone";
    description: string;
    significance: "cosmic";
  }[];
}
```

### 4.2 LLM 쿼리 비용 추정

**시나리오**: 1000명의 활성 유저, 15분 사이클

| Level | Entities | LLM Queries | Tokens/Query | Total Tokens | Cost (GPT-4) |
|-------|----------|-------------|--------------|--------------|--------------|
| 8: Individual | 1000 | 1000 | 800 | 800K | $24 |
| 7: Household | 500 | 50 (배치) | 2000 | 100K | $3 |
| 6: Organization | 100 | 10 (배치) | 3000 | 30K | $0.90 |
| 5: Nation | 20 | 5 (선택적) | 4000 | 20K | $0.60 |
| 4+: Cosmic | 5 | 1 (선택적) | 2000 | 2K | $0.06 |
| **Total** | | | | **~950K** | **~$28.56** |

**캐싱 후 (50% 적중률)**: ~$15/cycle

**월간 비용** (cycle당 15분, 24/7 운영):
- 사이클/일: 96
- 사이클/월: 2,880
- 월간 비용: **~$43,000** (캐싱 전) → **~$22,000** (캐싱 후)

**비용 절감 전략**:
1. 캐싱 강화 (70% 적중률 목표): **~$13,000/월**
2. 오픈소스 모델 (Llama 3, Mixtral): **~$5,000/월**
3. Self-hosted 모델: **~$2,000/월** (인프라 비용)

---

## 5. 권장 구현 단계

### Phase 1: MVP (단순화)
- ✅ Level 8-5만 구현 (Individual → Nation)
- ✅ Level 8: 텍스트 + 수치
- ✅ Level 7-5: 수치 위주
- ✅ 기본 LLM 통합 (캐싱 없음)

### Phase 2: 최적화
- ✅ 캐싱 시스템 구현
- ✅ 배치 처리 추가
- ✅ Level 6-7에 텍스트 요약 추가

### Phase 3: 풀 스케일
- ✅ Level 4-0 (Planet → Universe) 추가
- ✅ 고급 캐싱 전략
- ✅ Self-hosted LLM 도입 검토

---

## 6. 결론 및 권장사항

### 최종 권장 방식

**하이브리드 레이어드 접근법**:

1. **하위 계층** (Individual, Household):
   - **텍스트 중심** - 스토리텔링과 몰입감
   - LLM의 창발적 추론 활용
   - 플레이어와 직접 관련된 부분이므로 투자 가치 있음

2. **중간 계층** (Organization, Nation):
   - **수치 중심 + 간단한 요약**
   - LLM 선택적 사용 (중요 이벤트만)
   - 효율성과 의미 사이의 균형

3. **상위 계층** (Planet → Universe):
   - **순수 수치**
   - 룰 기반 집계
   - LLM 거의 사용 안함 (milestone만)

### 핵심 이점

✅ **몰입감**: 플레이어는 풍부한 스토리 경험
✅ **효율성**: 상위로 갈수록 비용/시간 절감
✅ **확장성**: 수천 명 유저도 처리 가능
✅ **밸런스**: 수치 기반이라 조정 용이
✅ **창발성**: LLM이 예상치 못한 재미 생성

### 구현 우선순위

1. **먼저 구현**: Level 8 (개인) 텍스트 처리
2. **다음**: Level 7-5 수치 집계 + 간단한 요약
3. **나중**: Level 4-0 우주적 스케일
4. **지속 최적화**: 캐싱, 배치, 비용 절감

이 방식으로 **게임의 재미**(스토리)와 **시스템의 효율성**(확장성)을 모두 잡을 수 있습니다!
