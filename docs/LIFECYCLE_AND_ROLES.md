# 생애주기 및 사회적 역할 시스템 설계

## 1. 캐릭터 생애주기 시스템

### 1.1 생애 단계 (Life Stages)

```typescript
enum LifeStage {
  INFANT = "infant",           // 유아 (0-5세)
  CHILD = "child",             // 아동 (6-12세)
  ADOLESCENT = "adolescent",   // 청소년 (13-19세)
  YOUNG_ADULT = "young_adult", // 청년 (20-35세)
  MIDDLE_AGED = "middle_aged", // 중년 (36-55세)
  SENIOR = "senior",           // 노년 (56-75세)
  ELDERLY = "elderly"          // 고령 (76세+)
}

interface Character {
  id: string;
  userId: string;
  name: string;

  // 생애주기
  age: number;
  lifeStage: LifeStage;
  birthCycle: number;          // 태어난 시뮬레이션 사이클
  deathCycle?: number;         // 사망 사이클 (null이면 생존)
  lifeExpectancy: number;      // 기대수명 (건강, 행복도 등에 영향받음)

  // 가정 역할
  householdId: string;
  householdRole: HouseholdRole;  // "child", "parent", "grandparent", "spouse"

  // 사회적 역할 (제한된 슬롯)
  socialPositions: SocialPosition[];  // 현재 보유한 직책들

  // 능력치
  attributes: CharacterAttributes;

  // 경험/이력
  education: Education[];
  workHistory: WorkHistory[];
  achievements: Achievement[];
  reputation: ReputationScores;
}

interface CharacterAttributes {
  // 기본 능력 (생애주기에 따라 변화)
  physical: number;        // 체력 (청년기 최고, 노년기 감소)
  mental: number;          // 정신력 (중년기 최고)
  social: number;          // 사교성
  creativity: number;      // 창의성
  leadership: number;      // 리더십

  // 전문 능력
  science: number;
  economy: number;
  politics: number;
  military: number;
  culture: number;

  // 상태
  health: number;          // 건강 (0-100)
  energy: number;          // 활력 (사이클마다 소모/회복)
  stress: number;          // 스트레스
}
```

### 1.2 생애 단계별 특성

#### Infant (유아, 0-5세)
- **플레이 불가** - AI 자동 관리 또는 부모 플레이어가 간접 관리
- 가정에만 영향
- 부모의 행동에 따라 초기 능력치 형성

#### Child (아동, 6-12세)
- **제한적 플레이** - 간단한 행동만 (공부, 놀이, 가정 내 활동)
- 교육 시작 (초등학교)
- 기본 능력치 성장

#### Adolescent (청소년, 13-19세)
- **활성 플레이 시작**
- 교육 선택 (중/고등학교, 특성화)
- 진로 탐색 행동 가능
- 일부 사회 활동 참여 가능

#### Young Adult (청년, 20-35세)
- **완전한 플레이**
- 사회 진출 (직업 선택, 역할 경쟁)
- 가정 형성 (결혼, 자녀)
- 체력 최고치

#### Middle Aged (중년, 36-55세)
- **영향력 최대기**
- 고위 직책 경쟁 가능
- 정신력/경험 최고치
- 체력 서서히 감소

#### Senior (노년, 56-75세)
- **은퇴 및 멘토링**
- 일부 직책 유지 가능 (고문, 의원 등)
- 체력 감소, 정신력 유지
- 후계자 육성

#### Elderly (고령, 76세+)
- **제한적 플레이**
- 대부분 직책에서 은퇴
- 가정 내 역할 (조부모)
- 건강 관리 중요

### 1.3 시간 진행 및 노화

```typescript
interface TimeSystem {
  cyclesPerYear: number;      // 예: 24 (15분 사이클 기준)
  yearsPerCycle: number;      // 1/24 = 0.0417년
  agingRate: number;          // 사이클당 나이 증가율
}

// 기본 설정: 15분 사이클, 연 24 사이클
// 1 사이클 = 약 15일 (게임 내 시간)
// 1년 = 24 사이클 = 6시간 (실제 시간)

function updateCharacterAge(character: Character, currentCycle: number) {
  const cyclesSinceBirth = currentCycle - character.birthCycle;
  character.age = Math.floor(cyclesSinceBirth / 24); // 24 사이클 = 1년

  // 생애 단계 업데이트
  character.lifeStage = determineLifeStage(character.age);

  // 능력치 자연 변화
  applyAgingEffects(character);

  // 사망 체크
  if (character.age >= character.lifeExpectancy) {
    checkDeath(character);
  }
}

function applyAgingEffects(character: Character) {
  const stage = character.lifeStage;

  switch(stage) {
    case LifeStage.YOUNG_ADULT:
      // 체력 최대
      character.attributes.physical = Math.min(100, character.attributes.physical + 0.5);
      break;
    case LifeStage.MIDDLE_AGED:
      // 정신력 최대, 체력 감소 시작
      character.attributes.mental = Math.min(100, character.attributes.mental + 0.3);
      character.attributes.physical -= 0.2;
      break;
    case LifeStage.SENIOR:
      // 체력 감소, 정신력 유지
      character.attributes.physical -= 0.5;
      character.attributes.mental -= 0.1;
      break;
    case LifeStage.ELDERLY:
      // 전반적 감소
      character.attributes.physical -= 1.0;
      character.attributes.mental -= 0.3;
      character.health -= 0.5;
      break;
  }
}
```

---

## 2. 인터렉션 큐잉 시스템

### 2.1 인터렉션 타입

```typescript
interface Interaction {
  id: string;
  timestamp: number;
  cycle: number;

  // 참여자
  initiatorId: string;      // 시작한 캐릭터
  targetIds: string[];      // 대상 캐릭터들

  // 컨텍스트
  contextType: InteractionContext;  // "household", "organization", "nation", "public"
  contextId: string;        // 해당 가정/조직/국가 ID

  // 내용
  type: InteractionType;
  description: string;      // 유저 입력

  // 상태
  status: "queued" | "processing" | "completed";
  result?: InteractionResult;
}

enum InteractionContext {
  HOUSEHOLD = "household",           // 가정 내 인터렉션
  ORGANIZATION = "organization",     // 조직 내 인터렉션
  NATION = "nation",                 // 국가 내 인터렉션
  INTERNATIONAL = "international",   // 국가 간 인터렉션
  PUBLIC = "public"                  // 공개 인터렉션
}

enum InteractionType {
  // 가정 인터렉션
  FAMILY_TALK = "family_talk",
  FAMILY_ACTIVITY = "family_activity",
  FAMILY_DECISION = "family_decision",

  // 조직 인터렉션
  MEETING = "meeting",
  COLLABORATION = "collaboration",
  NEGOTIATION = "negotiation",
  COMPETITION = "competition",

  // 정치 인터렉션
  DEBATE = "debate",
  VOTE = "vote",
  CAMPAIGN = "campaign",
  POLICY_PROPOSE = "policy_propose",

  // 사회 인터렉션
  TRADE = "trade",
  ALLIANCE = "alliance",
  CONFLICT = "conflict",
  SOCIAL_EVENT = "social_event"
}
```

### 2.2 인터렉션 큐 처리

```typescript
class InteractionQueue {
  private queues: Map<string, Interaction[]>;  // contextId -> interactions

  // 인터렉션 제출
  submitInteraction(interaction: Interaction): void {
    const contextKey = `${interaction.contextType}:${interaction.contextId}`;

    if (!this.queues.has(contextKey)) {
      this.queues.set(contextKey, []);
    }

    interaction.status = "queued";
    this.queues.get(contextKey)!.push(interaction);
  }

  // 사이클 시작 시 모든 인터렉션 수집
  getInteractionsForCycle(cycle: number): Map<string, Interaction[]> {
    // 이번 사이클에 처리할 인터렉션들을 컨텍스트별로 그룹화
    const grouped = new Map<string, Interaction[]>();

    for (const [contextKey, interactions] of this.queues) {
      const pending = interactions.filter(i => i.status === "queued");
      if (pending.length > 0) {
        grouped.set(contextKey, pending);
      }
    }

    return grouped;
  }

  // 컨텍스트별 배치 처리
  async processContextInteractions(
    contextKey: string,
    interactions: Interaction[]
  ): Promise<InteractionResult[]> {
    // 같은 컨텍스트의 모든 인터렉션을 함께 고려
    // 예: Smith 가정의 모든 가족 대화를 한번에 처리

    const prompt = buildContextInteractionPrompt(contextKey, interactions);
    const result = await llm.query(prompt);

    return parseInteractionResults(result, interactions);
  }
}

// 프롬프트 예시: 가정 내 인터렉션
function buildHouseholdInteractionPrompt(
  household: Household,
  interactions: Interaction[]
): string {
  return `
가정: ${household.name}
구성원:
${household.members.map(m => `- ${m.name} (${m.age}세, ${m.lifeStage}, ${m.householdRole})`).join('\n')}

이번 기간(15일)동안 발생한 상호작용:
${interactions.map(i => `
[${i.initiatorId} → ${i.targetIds.join(', ')}]
타입: ${i.type}
내용: ${i.description}
`).join('\n')}

다음을 분석하시오:
1. 각 상호작용의 결과
2. 상호작용 간의 연결 및 시너지/갈등
3. 가정 전체에 미친 영향
4. 각 구성원의 변화 (능력치, 관계, 감정)

출력 형식 (JSON):
{
  "interactionResults": [
    {
      "interactionId": "...",
      "narrative": "상호작용 결과 서술",
      "participants": [
        {
          "characterId": "...",
          "attributeChanges": {...},
          "relationshipChanges": {...}
        }
      ]
    }
  ],
  "householdImpact": {
    "metricsChange": {...},
    "newEvents": [...],
    "atmosphereChange": "가정 분위기 변화"
  }
}
`;
}
```

### 2.3 인터렉션 축적 및 배치 처리

```
[Cycle N]
User actions + interactions → Queue
    ↓
[Cycle N+1] (처리 사이클)
Step 1: 모든 개인 행동 처리 (Level 8)
    ↓
Step 2: 컨텍스트별 인터렉션 처리
    - 가정별 인터렉션 배치
    - 조직별 인터렉션 배치
    - 국가별 인터렉션 배치
    ↓
Step 3: 결과 집계 (Level 7 → 0)
    ↓
[Results] 유저에게 결과 전달
```

**장점**:
- 한 사이클 동안의 모든 인터렉션을 맥락적으로 처리
- 인터렉션 간 영향 고려 (A와 B의 대화 → B와 C의 대화에 영향)
- 자연스러운 시간 흐름

---

## 3. 사회적 역할 시스템 (제한된 슬롯)

### 3.1 역할 계층 구조

```typescript
interface SocialPosition {
  id: string;
  title: string;
  positionType: PositionType;

  // 소속
  organizationId?: string;
  nationId?: string;
  level: HierarchyLevel;

  // 제약
  totalSlots: number;        // 전체 정원 (예: 대통령 = 1)
  currentHolders: string[];  // 현재 보유자들

  // 요구사항
  requirements: PositionRequirements;

  // 임기
  termLength?: number;       // 임기 (사이클 수, null이면 무기한)
  selectionMethod: SelectionMethod;

  // 권한 및 혜택
  powers: PositionPower[];
  benefits: PositionBenefit[];

  // 현황
  nextElection?: number;     // 다음 선거/심사 사이클
}

enum PositionType {
  // 정치
  PRESIDENT = "president",
  MINISTER = "minister",
  GOVERNOR = "governor",
  MAYOR = "mayor",
  LEGISLATOR = "legislator",
  JUDGE = "judge",

  // 조직
  CEO = "ceo",
  DIRECTOR = "director",
  MANAGER = "manager",
  TEAM_LEAD = "team_lead",

  // 군사
  GENERAL = "general",
  COLONEL = "colonel",
  CAPTAIN = "captain",

  // 학술/문화
  PROFESSOR = "professor",
  RESEARCHER = "researcher",
  ARTIST = "artist",

  // 기타
  ENTREPRENEUR = "entrepreneur",
  WORKER = "worker",
  UNEMPLOYED = "unemployed"
}

interface PositionRequirements {
  minAge: number;
  maxAge?: number;
  minLifeStage: LifeStage;

  minAttributes: Partial<CharacterAttributes>;  // 최소 능력치
  requiredEducation?: string[];
  requiredExperience?: string[];

  citizenship?: string;      // 필요한 국적
  minReputation?: number;
}

enum SelectionMethod {
  ELECTION = "election",           // 선거 (국민/조직원 투표)
  APPOINTMENT = "appointment",     // 임명 (상위자가 지정)
  MERIT = "merit",                 // 능력 기반 자동 선발
  PURCHASE = "purchase",           // 구매 (경제력)
  COMPETITION = "competition",     // 경쟁 (대결/시험)
  INHERITANCE = "inheritance"      // 세습
}
```

### 3.2 역할 경쟁 및 선출 시스템

#### 3.2.1 선거 시스템 (Election)

```typescript
interface Election {
  id: string;
  positionId: string;
  cycle: number;

  candidates: ElectionCandidate[];
  voters: string[];          // 투표권자 ID 목록
  votes: Map<string, string>;  // voterId -> candidateId

  status: "registration" | "campaign" | "voting" | "counting" | "completed";
  results?: ElectionResult;
}

interface ElectionCandidate {
  characterId: string;
  manifesto: string;         // 공약
  campaignActions: Action[]; // 선거운동 행동들
  support: number;           // 지지율 (동적 계산)
}

// 선거 프로세스
async function runElection(election: Election): Promise<ElectionResult> {
  // 1. 후보 등록 기간 (1-2 사이클)
  await candidateRegistration(election);

  // 2. 선거운동 기간 (2-3 사이클)
  //    - 후보들이 campaign 액션 수행
  //    - 토론, 연설, 공약 발표 등
  //    - 유권자들의 지지 변화
  await campaignPeriod(election);

  // 3. 투표 기간 (1 사이클)
  await votingPeriod(election);

  // 4. 개표 및 당선자 결정
  const result = await countVotes(election);

  // 5. 취임
  await inaugurate(result.winner, election.positionId);

  return result;
}

// LLM을 이용한 유권자 투표 결정
async function determineVoterChoice(
  voter: Character,
  election: Election
): Promise<string> {
  const prompt = `
유권자: ${voter.name} (${voter.age}세, ${voter.lifeStage})
- 능력치: ${JSON.stringify(voter.attributes)}
- 관심사: ${voter.interests}
- 가치관: ${voter.values}

선거: ${election.positionId}
후보자:
${election.candidates.map(c => `
[${c.characterId}]
- 공약: ${c.manifesto}
- 선거운동 활동: ${summarizeCampaign(c.campaignActions)}
- 현재 지지율: ${c.support}%
`).join('\n')}

이 유권자는 누구에게 투표할까요? 유권자의 성향, 후보자의 공약과 활동을 종합적으로 고려하시오.

출력: {"candidateId": "...", "reason": "투표 이유"}
`;

  const response = await llm.query(prompt);
  return response.candidateId;
}
```

#### 3.2.2 능력 기반 선발 (Merit)

```typescript
// 능력 기반 자동 선발 (예: 연구소 연구원)
function selectByMerit(
  position: SocialPosition,
  applicants: Character[]
): Character[] {
  // 요구사항 체크
  const eligible = applicants.filter(c =>
    meetsRequirements(c, position.requirements)
  );

  // 점수 계산
  const scored = eligible.map(c => ({
    character: c,
    score: calculatePositionScore(c, position)
  }));

  // 상위 N명 선발
  scored.sort((a, b) => b.score - a.score);
  const selected = scored.slice(0, position.totalSlots - position.currentHolders.length);

  return selected.map(s => s.character);
}

function calculatePositionScore(
  character: Character,
  position: SocialPosition
): number {
  let score = 0;

  // 관련 능력치
  switch(position.positionType) {
    case PositionType.RESEARCHER:
      score += character.attributes.science * 2;
      score += character.attributes.mental * 1;
      break;
    case PositionType.CEO:
      score += character.attributes.leadership * 2;
      score += character.attributes.economy * 1.5;
      break;
    case PositionType.GENERAL:
      score += character.attributes.military * 2;
      score += character.attributes.leadership * 1.5;
      break;
  }

  // 경험 가산점
  score += character.workHistory.filter(w => w.related).length * 10;

  // 학력 가산점
  score += character.education.filter(e => e.relevant).length * 5;

  // 평판 가산점
  score += character.reputation.overall * 0.5;

  return score;
}
```

#### 3.2.3 임명 시스템 (Appointment)

```typescript
// 임명 시스템 (예: 장관 임명)
async function appointmentProcess(
  appointer: Character,  // 임명권자 (예: 대통령)
  position: SocialPosition,
  candidates: Character[]
): Promise<Character> {
  // LLM이 임명권자의 성향을 고려해 선택
  const prompt = `
임명권자: ${appointer.name}
- 정치 성향: ${appointer.politicalLeaning}
- 우선순위: ${appointer.priorities}
- 현재 상황: ${getSituationSummary(appointer)}

임명할 직책: ${position.title}
- 요구사항: ${position.requirements}
- 권한: ${position.powers}

후보자:
${candidates.map(c => `
[${c.name}]
- 능력: ${summarizeAttributes(c.attributes)}
- 경력: ${summarizeWorkHistory(c.workHistory)}
- 평판: ${c.reputation.overall}
- 임명권자와의 관계: ${getRelationship(appointer.id, c.id)}
`).join('\n')}

임명권자의 입장에서 가장 적합한 후보를 선택하시오.
능력, 충성도, 정치적 이득을 고려하시오.

출력: {"appointeeId": "...", "reason": "임명 이유"}
`;

  const response = await llm.query(prompt);
  return candidates.find(c => c.id === response.appointeeId)!;
}
```

### 3.3 역할 경쟁의 시간 연속성

```typescript
// 역할 경쟁 타임라인
interface PositionCompetitionTimeline {
  positionId: string;

  events: PositionEvent[];
}

interface PositionEvent {
  cycle: number;
  type: "vacancy" | "registration_start" | "registration_end" |
        "campaign_start" | "voting_start" | "result" | "inauguration";
  data: any;
}

// 예시: 대통령 선거 타임라인
const presidentialElectionTimeline: PositionEvent[] = [
  { cycle: 100, type: "vacancy", data: { reason: "term_end" } },
  { cycle: 101, type: "registration_start", data: {} },
  { cycle: 103, type: "registration_end", data: { candidates: 5 } },
  { cycle: 103, type: "campaign_start", data: {} },
  { cycle: 108, type: "voting_start", data: {} },
  { cycle: 109, type: "result", data: { winner: "char_123" } },
  { cycle: 110, type: "inauguration", data: {} }
];

// 연속적인 역할 관리
class PositionManager {
  private positions: Map<string, SocialPosition>;
  private competitions: Map<string, PositionCompetition>;

  // 매 사이클마다 실행
  updatePositions(currentCycle: number): void {
    for (const [positionId, position] of this.positions) {
      // 임기 만료 체크
      if (position.termLength && this.isTermExpired(position, currentCycle)) {
        this.initiateNewCompetition(position, currentCycle);
      }

      // 공석 체크 (사망, 사임 등)
      if (position.currentHolders.length < position.totalSlots) {
        this.initiateNewCompetition(position, currentCycle);
      }

      // 진행 중인 경쟁 업데이트
      const competition = this.competitions.get(positionId);
      if (competition) {
        this.updateCompetition(competition, currentCycle);
      }
    }
  }

  // 유저가 납득할 수 있는 결과
  private async updateCompetition(
    competition: PositionCompetition,
    cycle: number
  ): Promise<void> {
    // 투명한 과정 기록
    competition.log.push({
      cycle,
      event: competition.currentPhase,
      details: this.getPhaseDetails(competition)
    });

    // 결과의 근거 제공
    if (competition.currentPhase === "result") {
      competition.resultExplanation = await this.generateResultExplanation(competition);
    }
  }

  private async generateResultExplanation(
    competition: PositionCompetition
  ): string {
    // LLM을 통해 결과에 대한 상세 설명 생성
    // "A 후보가 당선된 이유는..."
    // "투표 결과: A 45%, B 35%, C 20%"
    // "주요 요인: 경제 공약 지지, 젊은 층 표심 확보"
  }
}
```

### 3.4 역할 제약 및 공정성

```typescript
// 역할 제약 관리
class PositionConstraints {
  // 한 사람이 보유 가능한 역할 제한
  private maxConcurrentPositions = 3;

  // 양립 불가능한 역할 (예: 대통령이면서 판사 불가)
  private incompatiblePairs: [PositionType, PositionType][] = [
    [PositionType.PRESIDENT, PositionType.JUDGE],
    [PositionType.LEGISLATOR, PositionType.CEO],
    // ...
  ];

  canAcceptPosition(
    character: Character,
    newPosition: SocialPosition
  ): { allowed: boolean; reason?: string } {
    // 최대 보유 수 체크
    if (character.socialPositions.length >= this.maxConcurrentPositions) {
      return {
        allowed: false,
        reason: `이미 ${this.maxConcurrentPositions}개의 직책을 보유 중입니다.`
      };
    }

    // 양립 불가 체크
    for (const existing of character.socialPositions) {
      if (this.areIncompatible(existing.positionType, newPosition.positionType)) {
        return {
          allowed: false,
          reason: `${existing.title}와 ${newPosition.title}는 동시에 보유할 수 없습니다.`
        };
      }
    }

    // 요구사항 체크
    if (!this.meetsRequirements(character, newPosition.requirements)) {
      return {
        allowed: false,
        reason: "요구사항을 충족하지 못합니다."
      };
    }

    return { allowed: true };
  }
}

// 공정한 기회 제공
class FairOpportunitySystem {
  // 신규 유저 보호 (일정 기간 동안 기회 제공)
  protected calculateNewcomerBonus(character: Character): number {
    const cyclesSinceJoin = currentCycle - character.creationCycle;
    if (cyclesSinceJoin < 50) {  // 초기 50 사이클 동안
      return 10 - (cyclesSinceJoin / 5);  // 점진적 감소
    }
    return 0;
  }

  // 다양성 보너스 (예: 성별, 지역, 배경 다양성)
  protected calculateDiversityBonus(
    character: Character,
    currentHolders: Character[]
  ): number {
    // 현재 보유자들과 다른 배경이면 보너스
    // 예: 모두 경제 전공이면, 과학 전공에게 보너스
  }
}
```

---

## 4. 통합 예시: 한 사이클의 흐름

### 4.1 Cycle N (유저 행동 제출 기간)

```
[15분 동안 유저들의 행동]

캐릭터 A (청년, 연구원):
- 개인 행동: "새로운 에너지 기술 연구"
- 가정 인터렉션: [아내와 대화] "연구 진척 공유"
- 조직 인터렉션: [동료와 협업] "공동 연구 제안"

캐릭터 B (중년, CEO):
- 개인 행동: "사업 확장 계획"
- 조직 인터렉션: [임원 회의] "신규 프로젝트 승인"
- 정치 행동: "대통령 선거 출마 등록"

캐릭터 C (노년, 은퇴 정치인):
- 가정 인터렉션: [손자와 대화] "인생 조언"
- 정치 행동: "후배 정치인 지지 성명"

→ 모두 큐에 저장
```

### 4.2 Cycle N+1 (처리 사이클)

```
[Phase 1: 개인 행동 처리]
- A의 연구: LLM 처리 → "획기적 발견" (science +15)
- B의 사업: LLM 처리 → "성공적 확장" (economy +20)
- C의 조언: 가정 인터렉션 큐에 추가

[Phase 2: 인터렉션 처리]
- A의 가정 (Smith Family):
  * A의 연구 공유 + 아내의 격려 → 가정 분위기 ↑
  * LLM: "A의 성공으로 가정이 화목해졌다"

- B의 조직 (TechCorp):
  * 임원 회의에서 프로젝트 승인
  * 여러 임원들의 의견 종합
  * LLM: "신규 프로젝트 시작, 조직 성장 기대"

- C의 가정:
  * 손자와의 대화 → 손자 wisdom +5
  * LLM: "조부의 조언으로 손자가 진로 결정"

[Phase 3: 집계]
- Level 7 (Household): 가정별 영향 집계
- Level 6 (Organization): 조직별 영향 집계
- Level 5 (Nation): 국가별 영향 집계

[Phase 4: 역할 업데이트]
- 대통령 선거: 후보 등록 마감 (B 포함 5명)
- 선거운동 기간 시작
- 다음 사이클에 투표 예정

[Phase 5: 생애주기 업데이트]
- 모든 캐릭터 나이 +15일
- 일부 캐릭터 생애 단계 변경 (청소년 → 청년 등)
```

### 4.3 결과 전달

```
[캐릭터 A에게]
"당신의 연구가 획기적인 성과를 냈습니다!
과학력 +15, 평판 +5
아내와의 대화도 긍정적이었습니다. 가정 행복도 +3
소속 연구소의 명성이 올랐습니다. (조직 science +10)
한국의 과학 기술력에 기여했습니다. (국가 science +8)"

[캐릭터 B에게]
"사업 확장이 성공적이었습니다! 경제력 +20
대통령 선거 후보로 등록되었습니다.
현재 지지율: 18% (5명 중 2위)
선거운동을 시작하세요!"

[캐릭터 C에게]
"손자에게 훌륭한 조언을 했습니다. 손자의 지혜 +5
당신의 정치적 지지 성명이 여론에 영향을 주었습니다.
지지한 후배 정치인의 지지율 +2%"
```

---

## 5. 구현 우선순위

### Phase 1: 기본 생애주기
- ✅ 5단계 생애 구분 (유아 제외, 청소년부터 시작)
- ✅ 기본 노화 시스템
- ✅ 생애 단계별 능력치 변화

### Phase 2: 인터렉션 큐잉
- ✅ 기본 인터렉션 타입 (가정, 조직)
- ✅ 큐 시스템 구현
- ✅ 배치 처리

### Phase 3: 기본 역할 시스템
- ✅ 5-10개 핵심 역할 (대통령, CEO, 연구원 등)
- ✅ 능력 기반 선발
- ✅ 요구사항 체크

### Phase 4: 선거 시스템
- ✅ 기본 선거 (후보 등록, 투표, 개표)
- ✅ 간단한 선거운동

### Phase 5: 고급 기능
- ✅ 복잡한 선거 (토론, 여론조사)
- ✅ 임명/세습 시스템
- ✅ 역할 간 관계 및 권력 구조

---

## 6. 밸런싱 고려사항

### 6.1 시간 밸런스
- **실제 시간**: 15분 사이클
- **게임 시간**: 15일
- **1년**: 24 사이클 = 6시간
- **한 세대**: 약 40-50년 = 1000 사이클 = 250시간 (10일)

→ 적절한 속도: 플레이어가 캐릭터의 일생을 경험 가능하되, 너무 빠르지 않음

### 6.2 역할 경쟁 밸런스
- **고위직 (대통령 등)**: 매우 제한적 (1명), 높은 경쟁
- **중간직 (관리자 등)**: 제한적 (10-50명), 중간 경쟁
- **일반직 (연구원 등)**: 비교적 넉넉 (100+명), 낮은 경쟁

→ 피라미드 구조로 자연스러운 경쟁과 성취감

### 6.3 신규 유저 보호
- 초기 50 사이클 (2주) 동안 보너스
- 튜토리얼 역할 제공
- 멘토 시스템 (노년 플레이어 ↔ 신규 플레이어)

---

## 7. 유저 경험 고려

### 7.1 납득 가능한 결과
- ✅ 모든 선발/선거 결과에 상세 설명
- ✅ 투명한 점수 계산 (능력 기반)
- ✅ 투표 결과 공개 (득표율)

### 7.2 의미 있는 선택
- ✅ 진로 선택 (교육 → 직업)
- ✅ 정치 참여 vs 경제 활동
- ✅ 가정 vs 커리어

### 7.3 스토리텔링
- ✅ 각 생애 단계마다 고유한 경험
- ✅ 세대 간 연결 (부모 → 자식)
- ✅ 역사적 순간 (대통령 당선, 혁명 등)

이 시스템으로 **시간의 흐름**, **의미 있는 경쟁**, **공정한 기회**를 모두 제공할 수 있습니다!
