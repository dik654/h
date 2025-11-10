# 세계 동적 시스템 설계 (World Dynamics System)

## 1. 개요

시대의 흐름에 따라 기후, 먹거리, 문화, 사고방식, 유행이 변화하며, 각 캐릭터의 고유 특성(traits)이 시대적 맥락에서 유리하거나 불리하게 작용하는 시스템입니다.

**핵심 개념**:
- **World State**: 현재 세계의 상태 (기후, 경제, 문화, 기술 수준 등)
- **Character Traits**: 캐릭터의 고유 특성 (성격, 재능, 선호도)
- **Dynamic Advantage**: World State × Character Traits = 유불리

---

## 2. 세계 상태 시스템 (World State System)

### 2.1 세계 상태 구조

```typescript
interface WorldState {
  cycle: number;
  era: Era;

  // 환경적 요인
  climate: ClimateState;
  resources: ResourceAvailability;
  disasters: ActiveDisaster[];

  // 사회적 요인
  culturalTrends: CulturalTrend[];
  ideology: IdeologyState;
  economicPhase: EconomicPhase;
  technologicalLevel: number;

  // 정치적 요인
  politicalClimate: PoliticalClimate;
  warStatus: WarStatus;

  // 시대별 수정자
  modifiers: WorldModifier[];
}

interface ClimateState {
  temperature: number;        // -50 ~ 50 (평균 기온 편차)
  rainfall: number;           // 0 ~ 100 (강수량 지수)
  seasonality: number;        // 0 ~ 100 (계절성)
  extremeEvents: number;      // 0 ~ 100 (극한 기후 빈도)

  effects: ClimateEffect[];   // 현재 기후가 미치는 영향
}

interface ClimateEffect {
  type: "agriculture" | "health" | "economy" | "migration";
  magnitude: number;          // -100 ~ 100
  affectedRegions: string[];
}

interface ResourceAvailability {
  food: number;               // 0 ~ 100 (식량 풍부도)
  water: number;
  energy: number;
  minerals: number;

  scarcities: string[];       // 현재 부족한 자원들
  abundance: string[];        // 현재 풍부한 자원들
}

interface CulturalTrend {
  id: string;
  name: string;
  type: "fashion" | "food" | "art" | "ideology" | "lifestyle";
  strength: number;           // 0 ~ 100 (얼마나 강한 트렌드인가)
  startCycle: number;
  peakCycle: number;
  endCycle?: number;

  favoredTraits: string[];    // 이 트렌드에서 유리한 특성들
  disfavoredTraits: string[]; // 이 트렌드에서 불리한 특성들

  description: string;
}

interface IdeologyState {
  dominant: string;           // "collectivism", "individualism", "environmentalism", etc.
  secondary: string[];

  values: {
    tradition: number;        // 0 ~ 100 (전통 중시 ↔ 혁신 중시)
    authority: number;        // 0 ~ 100 (권위 중시 ↔ 자유 중시)
    materialism: number;      // 0 ~ 100 (물질 중시 ↔ 정신 중시)
    science: number;          // 0 ~ 100 (과학 중시 ↔ 신앙 중시)
  };
}

enum EconomicPhase {
  BOOM = "boom",              // 호황
  GROWTH = "growth",          // 성장
  STABLE = "stable",          // 안정
  RECESSION = "recession",    // 불황
  DEPRESSION = "depression"   // 대공황
}

enum PoliticalClimate {
  PEACEFUL = "peaceful",
  TENSE = "tense",
  CONFLICT = "conflict",
  WAR = "war"
}

interface WarStatus {
  active: boolean;
  participants: string[];     // 참전 국가들
  intensity: number;          // 0 ~ 100
  duration: number;           // 사이클 수
}

interface Era {
  name: string;               // "Agricultural Age", "Industrial Age", "Information Age"
  startCycle: number;
  characteristics: string[];

  // 시대별 기본 특성
  technologyBias: number;     // 기술 발전 속도
  culturalDiversity: number;  // 문화 다양성
  mobilityRate: number;       // 사회 이동성
}
```

### 2.2 기후 변화 시스템

#### 장기 기후 변동
```typescript
class ClimateSystem {
  private baseTemperature: number = 15; // 기준 온도

  // 사이클마다 실행
  updateClimate(currentCycle: number, worldState: WorldState): ClimateState {
    // 1. 자연적 변동 (장기 사이클)
    const naturalVariation = this.calculateNaturalVariation(currentCycle);

    // 2. 인간 활동에 의한 변화
    const anthropogenicChange = this.calculateHumanImpact(worldState);

    // 3. 랜덤 변동
    const randomFluctuation = (Math.random() - 0.5) * 2;

    const newTemperature = this.baseTemperature + naturalVariation +
                          anthropogenicChange + randomFluctuation;

    // 4. 기후 효과 계산
    const effects = this.calculateClimateEffects(newTemperature, worldState);

    return {
      temperature: newTemperature - 15, // 편차로 표시
      rainfall: this.calculateRainfall(newTemperature, currentCycle),
      seasonality: this.calculateSeasonality(currentCycle),
      extremeEvents: this.calculateExtremeEvents(newTemperature),
      effects
    };
  }

  // 인간 활동이 기후에 미치는 영향
  calculateHumanImpact(worldState: WorldState): number {
    let impact = 0;

    // 산업 발전에 따른 온난화
    if (worldState.technologicalLevel > 50) {
      impact += (worldState.technologicalLevel - 50) * 0.01;
    }

    // 전쟁으로 인한 환경 파괴
    if (worldState.warStatus.active) {
      impact += worldState.warStatus.intensity * 0.005;
    }

    // 환경주의 이데올로기가 강하면 완화
    if (worldState.ideology.dominant === "environmentalism") {
      impact *= 0.5;
    }

    return impact;
  }

  // 기후가 세계에 미치는 효과
  calculateClimateEffects(temperature: number, worldState: WorldState): ClimateEffect[] {
    const effects: ClimateEffect[] = [];

    // 온도 상승 → 농업 영향
    if (temperature > 17) {
      effects.push({
        type: "agriculture",
        magnitude: -(temperature - 17) * 5, // 부정적
        affectedRegions: ["tropical", "temperate"]
      });
    }

    // 극심한 추위 → 건강 영향
    if (temperature < 10) {
      effects.push({
        type: "health",
        magnitude: -(10 - temperature) * 3,
        affectedRegions: ["all"]
      });
    }

    // 최적 온도 → 경제 활성화
    if (temperature >= 12 && temperature <= 18) {
      effects.push({
        type: "economy",
        magnitude: 10,
        affectedRegions: ["all"]
      });
    }

    return effects;
  }
}
```

#### 기후 효과 예시

**시나리오 1: 온난화 (Temperature +5)**
```
효과:
- 농업: -25% (열대/온대 지역 작물 피해)
- 건강: -10% (질병 증가)
- 이주: +30% (기후 난민 증가)

유리한 특성:
- "Adaptable" (적응력 높음)
- "Heat Resistant" (더위 저항)
- "Agricultural Innovation" (농업 혁신)

불리한 특성:
- "Traditional Farmer" (전통 농법 고수)
- "Cold Climate Native" (한랭 지역 출신)
```

**시나리오 2: 빙하기 (Temperature -8)**
```
효과:
- 농업: -40% (대부분 작물 재배 불가)
- 건강: -20% (동상, 질병)
- 경제: -30% (활동 위축)

유리한 특성:
- "Survivalist" (생존 전문가)
- "Cold Resistant" (추위 저항)
- "Hunter-Gatherer" (수렵채집 능력)

불리한 특성:
- "City Dweller" (도시 생활자)
- "Luxury Dependent" (사치품 의존)
```

### 2.3 문화 트렌드 시스템

#### 트렌드 발생 및 소멸

```typescript
class CulturalTrendSystem {
  private activeTrends: CulturalTrend[] = [];

  // 매 10-20 사이클마다 새 트렌드 발생 체크
  checkNewTrend(cycle: number, worldState: WorldState): void {
    if (Math.random() < 0.1) { // 10% 확률
      const newTrend = this.generateTrend(cycle, worldState);
      this.activeTrends.push(newTrend);
    }
  }

  // LLM을 이용한 트렌드 생성
  async generateTrend(cycle: number, worldState: WorldState): Promise<CulturalTrend> {
    const prompt = `
현재 세계 상황:
- 시대: ${worldState.era.name}
- 경제: ${worldState.economicPhase}
- 기술 수준: ${worldState.technologicalLevel}
- 주요 이데올로기: ${worldState.ideology.dominant}
- 전쟁 상태: ${worldState.warStatus.active ? "전쟁 중" : "평화"}

이 상황에 어울리는 새로운 문화 트렌드를 생성하시오.

출력 형식 (JSON):
{
  "name": "트렌드 이름",
  "type": "fashion | food | art | ideology | lifestyle",
  "description": "트렌드 설명 (2-3문장)",
  "favoredTraits": ["이 트렌드에서 유리한 캐릭터 특성들"],
  "disfavoredTraits": ["이 트렌드에서 불리한 캐릭터 특성들"],
  "duration": 20-50  // 지속 사이클 수
}

예시:
전쟁 중 + 경제 불황 → "검소함의 미학" (절약, 실용성 중시)
평화 + 경제 호황 → "사치품 열풍" (명품, 과시 소비)
기술 발전 + 개인주의 → "디지털 노마드" (원격 근무, 여행)
`;

    const response = await llm.query(prompt);

    return {
      id: `trend_${cycle}`,
      name: response.name,
      type: response.type,
      strength: 50, // 초기 강도
      startCycle: cycle,
      peakCycle: cycle + Math.floor(response.duration / 2),
      endCycle: cycle + response.duration,
      favoredTraits: response.favoredTraits,
      disfavoredTraits: response.disfavoredTraits,
      description: response.description
    };
  }

  // 트렌드 강도 업데이트 (종 모양 곡선)
  updateTrendStrength(trend: CulturalTrend, currentCycle: number): number {
    const progress = (currentCycle - trend.startCycle) /
                    (trend.endCycle! - trend.startCycle);

    // 종 모양 곡선 (0 → 100 → 0)
    return 100 * Math.sin(progress * Math.PI);
  }
}
```

#### 트렌드 예시

**1. 음식 트렌드**
```typescript
{
  name: "채식주의 열풍",
  type: "food",
  description: "환경 보호와 건강을 위한 식물성 식단이 대유행",
  strength: 75,
  favoredTraits: [
    "Environmentalist",
    "Health Conscious",
    "Innovation Seeker"
  ],
  disfavoredTraits: [
    "Traditional Carnivore",
    "Resistant to Change"
  ],
  effects: {
    economy: { agriculture: +20, livestock: -30 },
    health: { average: +5 },
    environment: { pollution: -10 }
  }
}
```

**2. 패션 트렌드**
```typescript
{
  name: "사이버펑크 스타일",
  type: "fashion",
  description: "기술과 반문화를 결합한 미래지향적 스타일",
  strength: 60,
  favoredTraits: [
    "Tech Savvy",
    "Rebel",
    "Creative"
  ],
  disfavoredTraits: [
    "Conservative",
    "Traditionalist"
  ],
  effects: {
    culture: { creativity: +10, conformity: -15 },
    economy: { fashion: +25, tech: +15 }
  }
}
```

**3. 이데올로기 트렌드**
```typescript
{
  name: "탈성장 운동",
  type: "ideology",
  description: "무한 경제 성장 대신 지속가능성과 웰빙 추구",
  strength: 40,
  favoredTraits: [
    "Philosopher",
    "Community Builder",
    "Minimalist"
  ],
  disfavoredTraits: [
    "Capitalist",
    "Materialist",
    "Growth Obsessed"
  ],
  effects: {
    economy: { gdp_growth: -10, happiness: +15 },
    politics: { progressive: +20 },
    environment: { sustainability: +25 }
  }
}
```

### 2.4 경제 사이클

```typescript
class EconomicCycleSystem {
  private currentPhase: EconomicPhase = EconomicPhase.STABLE;
  private cyclesInPhase: number = 0;

  updateEconomicPhase(worldState: WorldState): EconomicPhase {
    this.cyclesInPhase++;

    // 각 페이즈의 평균 지속 시간 (사이클)
    const phaseDurations = {
      boom: 15,
      growth: 30,
      stable: 40,
      recession: 20,
      depression: 10
    };

    // 페이즈 전환 체크
    if (this.cyclesInPhase > phaseDurations[this.currentPhase]) {
      this.currentPhase = this.transitionPhase(worldState);
      this.cyclesInPhase = 0;
    }

    return this.currentPhase;
  }

  transitionPhase(worldState: WorldState): EconomicPhase {
    const transitions = {
      boom: [EconomicPhase.GROWTH, EconomicPhase.RECESSION],
      growth: [EconomicPhase.BOOM, EconomicPhase.STABLE],
      stable: [EconomicPhase.GROWTH, EconomicPhase.RECESSION],
      recession: [EconomicPhase.STABLE, EconomicPhase.DEPRESSION],
      depression: [EconomicPhase.RECESSION, EconomicPhase.GROWTH]
    };

    // 전쟁 중이면 불황 확률 증가
    if (worldState.warStatus.active) {
      return Math.random() < 0.7 ? EconomicPhase.RECESSION :
             transitions[this.currentPhase][0];
    }

    // 기술 발전이 빠르면 성장 확률 증가
    if (worldState.technologicalLevel > 70) {
      return Math.random() < 0.6 ? EconomicPhase.GROWTH :
             transitions[this.currentPhase][1];
    }

    // 기본: 50/50 확률
    return Math.random() < 0.5 ? transitions[this.currentPhase][0] :
           transitions[this.currentPhase][1];
  }

  // 경제 페이즈별 효과
  getPhaseEffects(phase: EconomicPhase): EconomicEffects {
    const effects = {
      boom: {
        employment: +30,
        wages: +25,
        investment: +40,
        happiness: +15,
        favoredTraits: ["Entrepreneur", "Risk Taker", "Investor"],
        disfavoredTraits: ["Conservative", "Risk Averse"]
      },
      growth: {
        employment: +15,
        wages: +10,
        investment: +20,
        happiness: +10,
        favoredTraits: ["Skilled Worker", "Manager", "Planner"],
        disfavoredTraits: []
      },
      stable: {
        employment: 0,
        wages: 0,
        investment: 0,
        happiness: 0,
        favoredTraits: ["Stable Career", "Civil Servant"],
        disfavoredTraits: ["Innovation Seeker"]
      },
      recession: {
        employment: -20,
        wages: -15,
        investment: -30,
        happiness: -15,
        favoredTraits: ["Survivalist", "Frugal", "Adaptable"],
        disfavoredTraits: ["Luxury Dependent", "High Spender"]
      },
      depression: {
        employment: -40,
        wages: -30,
        investment: -50,
        happiness: -30,
        favoredTraits: ["Self-Sufficient", "Community Helper", "Barter Skilled"],
        disfavoredTraits: ["Corporate Ladder", "Status Seeker"]
      }
    };

    return effects[phase];
  }
}
```

---

## 3. 캐릭터 특성 시스템 (Character Traits)

### 3.1 특성 구조

```typescript
interface CharacterTraits {
  // 성격 특성 (Personality)
  personality: PersonalityTrait[];

  // 재능/적성 (Aptitudes)
  aptitudes: AptitudeTrait[];

  // 선호도/가치관 (Values)
  values: ValueTrait[];

  // 배경 특성 (Background)
  background: BackgroundTrait[];

  // 후천적 특성 (Acquired, 경험으로 획득)
  acquired: AcquiredTrait[];
}

interface Trait {
  id: string;
  name: string;
  description: string;
  category: string;

  // 기본 효과
  baseEffects: {
    attributeModifiers: Partial<CharacterAttributes>;  // 능력치 수정
    actionEfficiency: { [actionType: string]: number }; // 행동 효율
  };

  // 조건부 효과 (세계 상태에 따라 변화)
  conditionalEffects: ConditionalEffect[];

  // 특성 간 시너지/상충
  synergiesWith: string[];    // 함께 있으면 강화되는 특성들
  conflictsWith: string[];    // 함께 있으면 약화되는 특성들
}

interface ConditionalEffect {
  condition: WorldCondition;
  effects: {
    attributeModifiers?: Partial<CharacterAttributes>;
    actionEfficiency?: { [actionType: string]: number };
    happiness?: number;
    reputation?: number;
  };
}

interface WorldCondition {
  type: "climate" | "economy" | "culture" | "ideology" | "war" | "technology";
  requirement: any;  // 조건 (예: climate.temperature > 20)
  description: string;
}
```

### 3.2 특성 예시

#### 성격 특성 (Personality)

```typescript
const TRAIT_ADAPTABLE: Trait = {
  id: "adaptable",
  name: "적응력",
  description: "변화하는 환경에 빠르게 적응하는 능력",
  category: "personality",

  baseEffects: {
    attributeModifiers: {
      mental: +5
    },
    actionEfficiency: {
      learning: +15,
      innovation: +10
    }
  },

  conditionalEffects: [
    {
      condition: {
        type: "climate",
        requirement: "변화가 큼",
        description: "급격한 기후 변화 시"
      },
      effects: {
        attributeModifiers: { health: +10 },
        happiness: +15,
        reputation: +5
      }
    },
    {
      condition: {
        type: "culture",
        requirement: "트렌드 변화 빈번",
        description: "문화 트렌드 급변 시"
      },
      effects: {
        actionEfficiency: { socializing: +20 },
        happiness: +10
      }
    }
  ],

  synergiesWith: ["curious", "open_minded"],
  conflictsWith: ["traditionalist", "rigid"]
};

const TRAIT_TRADITIONALIST: Trait = {
  id: "traditionalist",
  name: "전통주의자",
  description: "전통과 관습을 중시하며 변화를 경계함",
  category: "personality",

  baseEffects: {
    attributeModifiers: {
      culture: +10,
      stability: +5
    },
    actionEfficiency: {
      preservation: +20,
      teaching: +10
    }
  },

  conditionalEffects: [
    {
      condition: {
        type: "ideology",
        requirement: "tradition value > 70",
        description: "전통 중시 사회"
      },
      effects: {
        reputation: +20,
        happiness: +15,
        actionEfficiency: { politics: +15 }
      }
    },
    {
      condition: {
        type: "ideology",
        requirement: "tradition value < 30",
        description: "혁신 중시 사회"
      },
      effects: {
        reputation: -15,
        happiness: -10,
        actionEfficiency: { politics: -10 }
      }
    },
    {
      condition: {
        type: "culture",
        requirement: "rapid trend changes",
        description: "빠른 문화 변화"
      },
      effects: {
        happiness: -20,
        stress: +15
      }
    }
  ],

  synergiesWith: ["conservative", "patient"],
  conflictsWith: ["adaptable", "innovative"]
};
```

#### 재능 특성 (Aptitude)

```typescript
const TRAIT_GREEN_THUMB: Trait = {
  id: "green_thumb",
  name: "농업 재능",
  description: "식물을 키우는 탁월한 재능",
  category: "aptitude",

  baseEffects: {
    attributeModifiers: {
      economy: +5
    },
    actionEfficiency: {
      farming: +30,
      gardening: +25
    }
  },

  conditionalEffects: [
    {
      condition: {
        type: "climate",
        requirement: "optimal temperature (12-18)",
        description: "최적 기후"
      },
      effects: {
        actionEfficiency: { farming: +50 },
        economy: +15
      }
    },
    {
      condition: {
        type: "climate",
        requirement: "extreme temperature or drought",
        description: "극한 기후"
      },
      effects: {
        actionEfficiency: { farming: -20 },
        stress: +10
      }
    },
    {
      condition: {
        type: "economy",
        requirement: "food scarcity",
        description: "식량 부족 시대"
      },
      effects: {
        reputation: +25,
        happiness: +10,
        actionEfficiency: { farming: +20 }
      }
    },
    {
      condition: {
        type: "technology",
        requirement: "tech level > 80",
        description: "첨단 기술 시대"
      },
      effects: {
        actionEfficiency: { farming: -15 }, // 자동화로 인간 농부 가치 하락
        reputation: -5
      }
    }
  ],

  synergiesWith: ["patient", "nature_lover"],
  conflictsWith: ["city_dweller", "tech_dependent"]
};

const TRAIT_TECH_SAVVY: Trait = {
  id: "tech_savvy",
  name: "기술 통달",
  description: "최신 기술을 빠르게 이해하고 활용",
  category: "aptitude",

  baseEffects: {
    attributeModifiers: {
      science: +10,
      innovation: +5
    },
    actionEfficiency: {
      programming: +30,
      research: +20
    }
  },

  conditionalEffects: [
    {
      condition: {
        type: "technology",
        requirement: "tech level > 70",
        description: "정보화 시대"
      },
      effects: {
        reputation: +20,
        actionEfficiency: { all_jobs: +15 },
        happiness: +10
      }
    },
    {
      condition: {
        type: "technology",
        requirement: "tech level < 30",
        description: "전근대 시대"
      },
      effects: {
        actionEfficiency: { most_jobs: -10 },
        happiness: -15  // 활용할 곳이 없어 불행
      }
    },
    {
      condition: {
        type: "culture",
        requirement: "anti-tech movement active",
        description: "반기술 운동 유행"
      },
      effects: {
        reputation: -10,
        stress: +10
      }
    }
  ],

  synergiesWith: ["curious", "logical"],
  conflictsWith: ["technophobe", "traditionalist"]
};
```

#### 가치관 특성 (Values)

```typescript
const TRAIT_ENVIRONMENTALIST: Trait = {
  id: "environmentalist",
  name: "환경주의자",
  description: "자연 보호와 지속가능성을 최우선으로 여김",
  category: "values",

  baseEffects: {
    attributeModifiers: {
      culture: +5
    },
    actionEfficiency: {
      conservation: +25,
      green_policy: +20
    }
  },

  conditionalEffects: [
    {
      condition: {
        type: "climate",
        requirement: "climate crisis (extreme events > 50)",
        description: "기후 위기 시"
      },
      effects: {
        reputation: +30,
        actionEfficiency: { politics: +25, activism: +30 },
        happiness: -10  // 위기에 대한 걱정
      }
    },
    {
      condition: {
        type: "ideology",
        requirement: "dominant = environmentalism",
        description: "환경주의 시대"
      },
      effects: {
        reputation: +25,
        happiness: +20,
        actionEfficiency: { all_green: +20 }
      }
    },
    {
      condition: {
        type: "economy",
        requirement: "phase = boom, heavy industry",
        description: "산업 호황기"
      },
      effects: {
        happiness: -15,  // 환경 파괴 목격
        stress: +15,
        actionEfficiency: { activism: +20 }
      }
    }
  ],

  synergiesWith: ["nature_lover", "minimalist"],
  conflictsWith: ["materialist", "industrial_advocate"]
};
```

### 3.3 특성 획득 시스템

```typescript
class TraitAcquisitionSystem {
  // 행동에 따른 특성 획득
  async checkTraitAcquisition(
    character: Character,
    recentActions: Action[]
  ): Promise<AcquiredTrait | null> {
    // 패턴 감지
    const patterns = this.detectActionPatterns(recentActions);

    // 특정 행동을 지속적으로 수행 → 관련 특성 획득
    for (const pattern of patterns) {
      if (pattern.count > 20 && pattern.consistency > 0.8) {
        const newTrait = this.mapPatternToTrait(pattern);

        if (newTrait && !character.traits.acquired.includes(newTrait)) {
          return newTrait;
        }
      }
    }

    return null;
  }

  // 예: 20번 이상 연속 farming 행동 → "Experienced Farmer" 특성 획득
  mapPatternToTrait(pattern: ActionPattern): AcquiredTrait | null {
    const traitMap = {
      farming: "experienced_farmer",
      research: "dedicated_researcher",
      diplomacy: "skilled_diplomat",
      trading: "shrewd_merchant",
      fighting: "battle_hardened"
    };

    return traitMap[pattern.actionType] || null;
  }
}
```

---

## 4. 동적 이점 시스템 (Dynamic Advantage System)

### 4.1 이점 계산

```typescript
class DynamicAdvantageCalculator {
  // 캐릭터의 현재 총 이점 계산
  calculateTotalAdvantage(
    character: Character,
    worldState: WorldState
  ): AdvantageReport {
    const report: AdvantageReport = {
      totalBonus: 0,
      totalPenalty: 0,
      details: []
    };

    // 각 특성에 대해
    for (const trait of character.getAllTraits()) {
      const traitAdvantage = this.calculateTraitAdvantage(trait, worldState);

      report.totalBonus += traitAdvantage.bonus;
      report.totalPenalty += traitAdvantage.penalty;
      report.details.push(traitAdvantage);
    }

    // 특성 간 시너지
    const synergies = this.calculateSynergies(character.getAllTraits());
    report.totalBonus += synergies;

    return report;
  }

  // 개별 특성의 이점 계산
  calculateTraitAdvantage(
    trait: Trait,
    worldState: WorldState
  ): TraitAdvantage {
    let bonus = 0;
    let penalty = 0;
    const reasons: string[] = [];

    // 조건부 효과 체크
    for (const condEffect of trait.conditionalEffects) {
      if (this.checkCondition(condEffect.condition, worldState)) {
        // 긍정적 효과
        if (condEffect.effects.happiness > 0 ||
            condEffect.effects.reputation > 0) {
          bonus += this.quantifyEffect(condEffect.effects);
          reasons.push(`✅ ${condEffect.condition.description}`);
        }
        // 부정적 효과
        else {
          penalty += Math.abs(this.quantifyEffect(condEffect.effects));
          reasons.push(`❌ ${condEffect.condition.description}`);
        }
      }
    }

    // 문화 트렌드와의 매칭
    for (const trend of worldState.culturalTrends) {
      if (trend.favoredTraits.includes(trait.id)) {
        const trendBonus = trend.strength * 0.3;
        bonus += trendBonus;
        reasons.push(`✅ 트렌드 "${trend.name}"에서 유리 (+${trendBonus.toFixed(0)})`);
      }

      if (trend.disfavoredTraits.includes(trait.id)) {
        const trendPenalty = trend.strength * 0.2;
        penalty += trendPenalty;
        reasons.push(`❌ 트렌드 "${trend.name}"에서 불리 (-${trendPenalty.toFixed(0)})`);
      }
    }

    return {
      traitName: trait.name,
      bonus,
      penalty,
      netAdvantage: bonus - penalty,
      reasons
    };
  }

  // 조건 체크
  checkCondition(condition: WorldCondition, worldState: WorldState): boolean {
    switch(condition.type) {
      case "climate":
        return this.checkClimateCondition(condition, worldState.climate);
      case "economy":
        return this.checkEconomyCondition(condition, worldState.economicPhase);
      case "ideology":
        return this.checkIdeologyCondition(condition, worldState.ideology);
      case "technology":
        return this.checkTechCondition(condition, worldState.technologicalLevel);
      case "culture":
        return this.checkCultureCondition(condition, worldState.culturalTrends);
      default:
        return false;
    }
  }
}

interface AdvantageReport {
  totalBonus: number;
  totalPenalty: number;
  netAdvantage: number;
  details: TraitAdvantage[];
}

interface TraitAdvantage {
  traitName: string;
  bonus: number;
  penalty: number;
  netAdvantage: number;
  reasons: string[];
}
```

### 4.2 실제 적용 예시

#### 시나리오 A: 온난화 + 식량 부족 + 전통주의 쇠퇴

**캐릭터 1: 전통 농부**
```
특성:
- Green Thumb (농업 재능)
- Traditionalist (전통주의자)
- Patient (인내심)

세계 상태:
- Climate: Temperature +5 (온난화)
- Resources: Food scarcity (식량 부족)
- Ideology: Tradition 25 (전통 쇠퇴, 혁신 중시)

이점 계산:
[Green Thumb]
  ✅ 식량 부족 시대 → 농부 가치 상승 (+25 reputation, +20 efficiency)
  ❌ 온난화로 작물 피해 (-20 farming efficiency)
  순이익: +5

[Traditionalist]
  ❌ 혁신 중시 사회 → 전통주의자 입지 약화 (-15 reputation, -10 happiness)
  순이익: -25

[Patient]
  중립적 (조건부 효과 없음)
  순이익: 0

총 순이익: -20

→ 전통 농부는 현재 시대에 다소 불리함
→ 대응 전략: 혁신적 농법 습득 (기술 교육) 또는 정치 활동 (전통 가치 옹호)
```

**캐릭터 2: 농업 혁신가**
```
특성:
- Green Thumb (농업 재능)
- Tech Savvy (기술 통달)
- Adaptable (적응력)

세계 상태: 동일

이점 계산:
[Green Thumb]
  ✅ 식량 부족 → +25
  ❌ 온난화 → -20
  순이익: +5

[Tech Savvy]
  ✅ 기술 중시 사회 → +20 reputation
  순이익: +20

[Adaptable]
  ✅ 급격한 기후 변화 → +15 happiness, +10 health
  순이익: +25

총 순이익: +50

→ 농업 혁신가는 현재 시대에 매우 유리함!
→ 최적 행동: 첨단 농업 기술 연구, 기후 적응형 작물 개발
```

#### 시나리오 B: 경제 대공황 + 전쟁

**캐릭터 3: 사치품 상인**
```
특성:
- Shrewd Merchant (영리한 상인)
- Luxury Specialist (사치품 전문)
- Charismatic (카리스마)

세계 상태:
- Economy: Depression (대공황)
- War: Active, Intensity 80
- Ideology: Collectivism (집단주의)

이점 계산:
[Shrewd Merchant]
  중립적 (시장은 있지만 위축)
  순이익: 0

[Luxury Specialist]
  ❌ 대공황 → 사치품 수요 급감 (-40 sales, -20 reputation)
  ❌ 전쟁 → 사치품 생산 중단 (-30 supply)
  ❌ 집단주의 → 사치품 비난 (-15 social acceptance)
  순이익: -105

[Charismatic]
  ✅ 어려운 시기 → 사람들 위로 (+10 social)
  순이익: +10

총 순이익: -95

→ 사치품 상인은 파산 위기!
→ 생존 전략: 업종 전환 (필수품 거래), 암시장 활용, 전쟁 물자 공급
```

**캐릭터 4: 생존 전문가**
```
특성:
- Survivalist (생존주의자)
- Self-Sufficient (자급자족)
- Barter Skilled (물물교환 숙련)

세계 상태: 동일

이점 계산:
[Survivalist]
  ✅ 대공황 → 생존 기술 가치 상승 (+30 reputation)
  ✅ 전쟁 → 비상 대비 중요 (+25 importance)
  순이익: +55

[Self-Sufficient]
  ✅ 경제 붕괴 → 자급자족 필수 (+40 survival rate)
  ✅ 물자 부족 → 자급자족 선망 (+20 reputation)
  순이익: +60

[Barter Skilled]
  ✅ 화폐 가치 하락 → 물물교환 활성화 (+35 trade efficiency)
  순이익: +35

총 순이익: +150

→ 생존 전문가는 위기에서 번성!
→ 최적 행동: 커뮤니티 리더, 생존 교육, 물물교환 중개
```

---

## 5. 플레이어 피드백 시스템

### 5.1 세계 상태 알림

```typescript
// 매 사이클마다 유저에게 세계 변화 알림
interface WorldStateNotification {
  cycle: number;

  majorChanges: {
    type: "climate" | "economy" | "culture" | "war";
    description: string;
    impact: "positive" | "negative" | "neutral";
  }[];

  newTrends: CulturalTrend[];
  endedTrends: CulturalTrend[];

  personalImpact: {
    advantageChange: number;  // -100 ~ +100
    explanation: string;
    recommendations: string[];
  };
}

// 예시
const notification: WorldStateNotification = {
  cycle: 1250,

  majorChanges: [
    {
      type: "climate",
      description: "평균 기온이 2도 상승했습니다. 농업 생산성이 감소하고 있습니다.",
      impact: "negative"
    },
    {
      type: "culture",
      description: "환경주의 운동이 강화되고 있습니다.",
      impact: "neutral"
    }
  ],

  newTrends: [
    {
      name: "친환경 라이프스타일",
      type: "lifestyle",
      description: "재생 가능 에너지, 제로 웨이스트, 미니멀리즘이 유행",
      favoredTraits: ["Environmentalist", "Minimalist", "Innovator"]
    }
  ],

  personalImpact: {
    advantageChange: -15,
    explanation: `
당신의 [Traditional Farmer] 특성이 불리해지고 있습니다.
- 온난화로 인한 작물 피해 (-20)
- 전통 농법의 가치 하락 (-10)
하지만 당신의 [Patient] 특성은 위기 극복에 도움이 됩니다 (+15).
`,
    recommendations: [
      "기후 적응형 농업 기술을 배워보세요 (교육 행동)",
      "환경주의 트렌드에 동참하여 평판을 높이세요",
      "커뮤니티와 협력하여 집단 대응 전략을 수립하세요"
    ]
  }
};
```

### 5.2 특성 추천 시스템

```typescript
// 신규 캐릭터 생성 시 또는 특성 선택 시
class TraitRecommendationSystem {
  async recommendTraits(
    currentWorldState: WorldState,
    predictedFuture: WorldStatePrediction
  ): Promise<TraitRecommendation[]> {
    const recommendations: TraitRecommendation[] = [];

    // 현재 유리한 특성
    const currentlyFavoredTraits = this.analyzeCurrentAdvantage(currentWorldState);

    // 미래 유망 특성 (예측)
    const futureFavoredTraits = this.analyzeFutureAdvantage(predictedFuture);

    // 균형잡힌 추천
    const balanced = this.findBalancedTraits(currentlyFavoredTraits, futureFavoredTraits);

    return balanced;
  }

  // 예시 출력
  /*
  추천 특성:

  [현재 시대에 유리]
  1. Tech Savvy (★★★★★)
     - 정보화 시대에 최적
     - 모든 직업에서 +15% 효율

  2. Adaptable (★★★★☆)
     - 급변하는 문화 트렌드에 유리
     - 기후 변화 대응 가능

  [미래 유망]
  3. Environmentalist (★★★★☆)
     - 환경 위기 심화 예상
     - 향후 10년 내 정치적 영향력 ↑

  [안정적 선택]
  4. Green Thumb (★★★☆☆)
     - 식량은 항상 필요
     - 기후 변화로 농부 가치 재평가 예상
  */
}
```

---

## 6. LLM 통합

### 6.1 세계 이벤트 생성

```typescript
// 세계 상태에 기반한 랜덤 이벤트 생성
async function generateWorldEvent(
  worldState: WorldState,
  cycle: number
): Promise<WorldEvent> {
  const prompt = `
현재 세계 상태 (사이클 ${cycle}):
- 기후: 온도 ${worldState.climate.temperature > 0 ? '+' : ''}${worldState.climate.temperature}도,
  극한 기후 빈도 ${worldState.climate.extremeEvents}%
- 경제: ${worldState.economicPhase}
- 이데올로기: ${worldState.ideology.dominant}
- 전쟁: ${worldState.warStatus.active ? '진행 중' : '평화'}
- 기술 수준: ${worldState.technologicalLevel}/100
- 활성 트렌드: ${worldState.culturalTrends.map(t => t.name).join(', ')}

이 상황에서 발생 가능한 흥미로운 세계적 이벤트를 생성하시오.

요구사항:
1. 현재 세계 상태와 논리적으로 연결됨
2. 플레이어들에게 도전 또는 기회 제공
3. 일부 특성을 가진 캐릭터에게 유리/불리

출력 형식 (JSON):
{
  "name": "이벤트 이름",
  "type": "disaster | breakthrough | social_movement | political_shift",
  "description": "이벤트 설명 (3-4문장)",
  "duration": 5-20,  // 지속 사이클
  "effects": {
    "climate": { "temperature": +/-N, ... },
    "economy": { "phase": "...", "gdp": +/-N },
    "resources": { "food": +/-N, ... }
  },
  "favoredTraits": ["이벤트에서 유리한 특성들"],
  "disfavoredTraits": ["이벤트에서 불리한 특성들"]
}
`;

  const response = await llm.query(prompt);
  return parseWorldEvent(response);
}

// 예시 이벤트
/*
{
  name: "대가뭄",
  type: "disaster",
  description: "10년 만의 최악의 가뭄이 농업 지대를 강타했습니다. 식량 생산이 급감하고 물 부족이 심각합니다. 많은 농민들이 도시로 이주하고 있으며, 정부는 긴급 배급을 시작했습니다.",
  duration: 15,
  effects: {
    climate: { rainfall: -40 },
    economy: { phase: "recession", agriculture: -60 },
    resources: { food: -50, water: -40 }
  },
  favoredTraits: [
    "Survivalist",      // 위기 대처
    "Water Engineer",   // 물 관리 전문
    "Drought Resistant" // 건조 기후 적응
  ],
  disfavoredTraits: [
    "Traditional Farmer", // 전통 농법 무용
    "Water Dependent",    // 물 의존적
    "City Dweller"        // 도시 생활 어려움
  ]
}
*/
```

### 6.2 개인화된 영향 서술

```typescript
// LLM이 캐릭터 특성과 세계 상태를 고려해 개인화된 영향 서술
async function generatePersonalizedImpact(
  character: Character,
  worldState: WorldState,
  advantageReport: AdvantageReport
): Promise<string> {
  const prompt = `
캐릭터: ${character.name} (${character.age}세, ${character.profession})
특성:
${character.getAllTraits().map(t => `- ${t.name}: ${t.description}`).join('\n')}

현재 세계 상황:
- 기후: ${describeClimate(worldState.climate)}
- 경제: ${worldState.economicPhase}
- 주요 트렌드: ${worldState.culturalTrends[0]?.name}

이점/불이점 분석:
총 이점: ${advantageReport.totalBonus}
총 불이점: ${advantageReport.totalPenalty}
순이익: ${advantageReport.netAdvantage}

상세:
${advantageReport.details.map(d =>
  `${d.traitName}: ${d.netAdvantage > 0 ? '+' : ''}${d.netAdvantage}\n  ${d.reasons.join('\n  ')}`
).join('\n')}

이 캐릭터가 현재 세계에서 어떤 상황에 처해있는지
생생하고 구체적으로 서술하시오. (3-4문장)
개인의 감정, 도전, 기회를 포함하시오.
`;

  return await llm.query(prompt);
}

// 예시 출력
/*
"당신은 최근 급증하는 채식주의 트렌드 속에서 기회를 발견했습니다.
당신의 [Green Thumb] 특성 덕분에 유기농 채소 재배가 순조롭고,
[Environmentalist] 가치관이 소비자들에게 높은 평가를 받고 있습니다.
하지만 온난화로 인한 병충해 증가가 걱정이며, [Adaptable] 특성을
살려 새로운 재배 기술을 배울 필요가 있습니다."
*/
```

---

## 7. 구현 우선순위

### Phase 1: 기본 세계 상태
- ✅ 기후 시스템 (온도, 강수량)
- ✅ 경제 사이클 (호황/불황)
- ✅ 5-10개 핵심 특성

### Phase 2: 문화 트렌드
- ✅ 트렌드 발생/소멸 시스템
- ✅ LLM 기반 트렌드 생성
- ✅ 특성과 트렌드 매칭

### Phase 3: 동적 이점
- ✅ 특성별 조건부 효과
- ✅ 이점 계산 시스템
- ✅ 유저 피드백 (알림, 추천)

### Phase 4: 고급 기능
- ✅ 복잡한 세계 이벤트
- ✅ 특성 간 시너지/상충
- ✅ 미래 예측 시스템

---

## 8. 밸런싱 원칙

### 8.1 특성 밸런스
- 모든 특성은 **어떤 시대/상황에서는 유리**해야 함
- "완벽한 특성"이나 "쓸모없는 특성"은 없어야 함
- 시너지 효과로 특화된 빌드 가능

### 8.2 세계 변화 속도
- 너무 빠르면: 플레이어가 적응 불가능
- 너무 느리면: 정적이고 지루함
- **권장**: 10-20 사이클마다 소변화, 50-100 사이클마다 대변화

### 8.3 예측 가능성
- 완전 랜덤 X → 패턴 존재
- 예: 호황 → 불황 사이클, 계절 변화
- 플레이어가 미래를 어느정도 예측하고 대비 가능

---

이 시스템으로 **살아 숨쉬는 세계**와 **고유한 캐릭터**가 상호작용하며 역동적인 게임플레이를 만들어냅니다!
