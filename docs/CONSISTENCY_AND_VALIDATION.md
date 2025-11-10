# Consistency and Validation System

This document defines mechanisms to maintain narrative coherence, logical consistency, and believability throughout the simulation.

## Table of Contents

1. [Core Principles](#core-principles)
2. [Consistency Issues](#consistency-issues)
3. [Validation Layers](#validation-layers)
4. [Character Consistency](#character-consistency)
5. [World State Consistency](#world-state-consistency)
6. [Causality Tracking](#causality-tracking)
7. [Metric Constraints](#metric-constraints)
8. [LLM Output Validation](#llm-output-validation)
9. [Narrative Continuity](#narrative-continuity)
10. [Implementation Strategy](#implementation-strategy)

---

## Core Principles

### 1. **Bounded Realism**
- Changes should be gradual and proportional to causes
- Extreme outcomes require extreme circumstances
- Most events have modest effects

### 2. **Causal Coherence**
- Every significant change has a traceable cause
- Effects propagate logically through hierarchy
- No "magic" - everything has explanation

### 3. **Character Continuity**
- Characters maintain personality consistency
- Behavior aligns with traits and history
- Growth is gradual, not sudden transformation

### 4. **Temporal Consistency**
- Events respect time scale (1 cycle = 15 days)
- Appropriate amount of change per cycle
- No time paradoxes or impossible timelines

### 5. **World Logic**
- Physical laws remain consistent
- Social/political changes follow believable patterns
- Economic principles hold

---

## Consistency Issues

### Problem Areas in Current Design

#### 1. **LLM Hallucination Risk**
```
Issue: LLM might generate contradictory results
Example:
  Cycle 100: "Alice is a shy, introverted scientist"
  Cycle 101: "Alice boldly led a political rally" (no trait/event justification)

Risk Level: HIGH
```

#### 2. **Metric Whiplash**
```
Issue: Metrics changing too rapidly without cause
Example:
  Cycle 100: Nation happiness = 75
  Cycle 101: Nation happiness = 20 (no major disaster)

Risk Level: HIGH
```

#### 3. **Broken Causality**
```
Issue: Upper level changes not reflected in lower levels
Example:
  Planet: "Global climate crisis"
  Individual: "Alice enjoyed perfect weather for her picnic"

Risk Level: MEDIUM
```

#### 4. **Time Scale Violations**
```
Issue: Too much happening in one cycle
Example:
  15 days: Character born, grew to adult, became president, died

Risk Level: HIGH
```

#### 5. **Trait Contradictions**
```
Issue: Actions contradicting permanent traits
Example:
  Trait: "Pacifist" (permanent value trait)
  Action: "Started a war"

Risk Level: MEDIUM
```

#### 6. **Population/Physics Violations**
```
Issue: Impossible numerical situations
Example:
  Household: 2 people
  Action result: "Hosted dinner for 50 family members"

Risk Level: LOW
```

---

## Validation Layers

### Layer 1: Input Validation (Pre-LLM)

**Purpose**: Prevent invalid requests from reaching LLM

```typescript
interface ActionValidation {
  validateAction(action: ActionSubmit, character: Character): ValidationResult {
    const errors: string[] = [];

    // Check character capability
    if (!canPerformAction(character, action.action_type)) {
      errors.push(`Character life stage ${character.life_stage} cannot perform ${action.action_type}`);
    }

    // Check trait conflicts
    const conflictingTraits = findConflictingTraits(character.traits, action.description);
    if (conflictingTraits.length > 0) {
      errors.push(`Action conflicts with traits: ${conflictingTraits.join(', ')}`);
    }

    // Check resource requirements
    if (requiresResources(action) && !hasResources(character)) {
      errors.push('Insufficient resources for this action');
    }

    // Check cooldowns
    if (hasRecentSimilarAction(character.id, action.action_type)) {
      errors.push('Cannot perform same action type too frequently');
    }

    return {
      valid: errors.length === 0,
      errors,
      warnings: generateWarnings(action, character),
    };
  }
}
```

**Validation Rules**:

1. **Life Stage Constraints**
```typescript
const LIFE_STAGE_CAPABILITIES = {
  infant: {
    allowed_actions: [],
    prohibited_actions: ['all'],
  },
  child: {
    allowed_actions: ['social:play', 'cultural:learn'],
    prohibited_actions: ['political', 'military', 'economic:complex'],
  },
  adolescent: {
    allowed_actions: ['social', 'cultural', 'scientific:basic', 'economic:simple'],
    prohibited_actions: ['political:leadership', 'military:command'],
  },
  young_adult: {
    allowed_actions: ['all'],
    prohibited_actions: [],
  },
  // ... etc
};
```

2. **Trait-Action Compatibility**
```typescript
const TRAIT_ACTION_CONFLICTS = {
  'Pacifist': {
    prohibited_keywords: ['war', 'attack', 'violence', 'military aggression'],
    severity: 'HARD_BLOCK', // Cannot perform at all
  },
  'Honest': {
    prohibited_keywords: ['deceive', 'lie', 'fraud', 'cheat'],
    severity: 'HARD_BLOCK',
  },
  'Lazy': {
    discouraged_keywords: ['hard work', 'marathon', 'overtime'],
    severity: 'WARNING', // Can perform but gets negative modifier
  },
};
```

3. **Cooldown System**
```typescript
interface ActionCooldown {
  action_type: string;
  last_performed: number; // cycle number
  cooldown_cycles: number;
}

const COOLDOWN_RULES = {
  'political:run_for_office': 24, // 1 year between campaigns
  'economic:start_business': 48, // 2 years between businesses
  'social:marriage': 96, // 4 years between marriages (if divorced)
  'scientific:major_research': 12, // 6 months between major projects
};
```

### Layer 2: Context Enrichment (LLM Input)

**Purpose**: Provide LLM with consistency-relevant context

```typescript
interface EnrichedContext {
  // Recent history for continuity
  recent_actions: Action[]; // Last 10 actions
  recent_personality_moments: string[]; // Key character moments

  // Trait reminders
  core_traits: Trait[]; // Personality/values that should stay consistent
  trait_history: TraitActivation[]; // How traits influenced recent actions

  // World constraints
  current_world_state: WorldState;
  recent_world_events: WorldEvent[];
  entity_context: EntityMetrics;

  // Relationship context
  relationship_with_target?: Relationship;
  recent_interactions_with_target?: Interaction[];

  // Consistency anchors
  character_summary: string; // "Alice is a shy scientist who values honesty..."
  recent_narrative_thread: string; // Ongoing story arc

  // Explicit constraints
  metric_bounds: MetricBounds; // Max/min allowed changes
  prohibited_outcomes: string[]; // Things that cannot happen
}
```

**Context Generation Example**:

```typescript
async function buildConsistentContext(
  character: Character,
  action: ActionSubmit,
  worldState: WorldState
): Promise<EnrichedContext> {

  // Get recent history
  const recentActions = await getRecentActions(character.id, 10);

  // Extract personality patterns
  const personalityMoments = extractPersonalityMoments(recentActions);
  // ["Alice avoided confrontation", "Alice spent evening in library", "Alice helped colleague quietly"]

  // Build character summary
  const characterSummary = buildCharacterSummary(character, personalityMoments);
  // "Alice is a shy, introverted scientist in her 30s who values knowledge and peace.
  //  She avoids conflict and prefers quiet research to social gatherings."

  // Identify ongoing narrative threads
  const narrativeThread = identifyNarrativeThread(recentActions);
  // "Alice has been working on quantum research project for past 6 cycles"

  // Calculate metric bounds
  const metricBounds = calculateAllowedMetricChanges(character, action, worldState);

  // Identify prohibited outcomes based on traits
  const prohibitedOutcomes = generateProhibitions(character.traits);
  // ["Alice starting a fight", "Alice lying to colleagues", ...]

  return {
    recent_actions: recentActions,
    recent_personality_moments: personalityMoments,
    core_traits: character.traits.filter(t => t.category === 'personality' || t.category === 'values'),
    character_summary: characterSummary,
    recent_narrative_thread: narrativeThread,
    current_world_state: worldState,
    metric_bounds: metricBounds,
    prohibited_outcomes: prohibitedOutcomes,
  };
}
```

### Layer 3: Output Validation (Post-LLM)

**Purpose**: Verify LLM output maintains consistency

```typescript
interface OutputValidator {
  async validateResult(
    result: IndividualActionResult,
    context: EnrichedContext,
    character: Character
  ): Promise<ValidationResult> {

    const errors: ValidationError[] = [];
    const warnings: ValidationWarning[] = [];

    // 1. Metric bounds check
    const metricViolations = checkMetricBounds(result.metrics, context.metric_bounds);
    errors.push(...metricViolations);

    // 2. Narrative consistency check
    const narrativeIssues = await checkNarrativeConsistency(
      result.narrative,
      context.character_summary,
      context.prohibited_outcomes
    );
    warnings.push(...narrativeIssues);

    // 3. Trait activation validation
    const traitIssues = validateTraitActivations(
      result.trait_activations,
      character.traits,
      context.current_world_state
    );
    warnings.push(...traitIssues);

    // 4. Event plausibility check
    const eventIssues = validateEvents(
      result.events,
      character,
      context.current_world_state
    );
    errors.push(...eventIssues);

    // 5. Time scale check
    const timeIssues = validateTimeScale(result, TIME_CONSTANTS.CYCLE_DAYS);
    errors.push(...timeIssues);

    if (errors.length > 0) {
      // Critical issues - regenerate with stricter prompt
      return { valid: false, errors, action: 'REGENERATE' };
    }

    if (warnings.length > 3) {
      // Too many minor issues - regenerate
      return { valid: false, warnings, action: 'REGENERATE' };
    }

    if (warnings.length > 0) {
      // Minor issues - log but accept
      await logConsistencyWarnings(warnings);
      return { valid: true, warnings, action: 'ACCEPT_WITH_WARNINGS' };
    }

    return { valid: true, action: 'ACCEPT' };
  }
}
```

**Validation Checks**:

1. **Metric Bounds Validation**
```typescript
function checkMetricBounds(
  metrics: MetricsDelta,
  bounds: MetricBounds
): ValidationError[] {
  const errors: ValidationError[] = [];

  for (const [metric, delta] of Object.entries(metrics.character)) {
    const bound = bounds[metric];

    if (delta > bound.max) {
      errors.push({
        type: 'METRIC_OVERFLOW',
        message: `${metric} change ${delta} exceeds maximum ${bound.max}`,
        severity: 'ERROR',
        suggestion: `Reduce to ${bound.max}`,
      });
    }

    if (delta < bound.min) {
      errors.push({
        type: 'METRIC_UNDERFLOW',
        message: `${metric} change ${delta} below minimum ${bound.min}`,
        severity: 'ERROR',
        suggestion: `Increase to ${bound.min}`,
      });
    }
  }

  return errors;
}
```

2. **Narrative Consistency Validation**
```typescript
async function checkNarrativeConsistency(
  narrative: { action: string; result: string; mood: string },
  characterSummary: string,
  prohibitedOutcomes: string[]
): Promise<ValidationWarning[]> {

  const warnings: ValidationWarning[] = [];

  // Check for prohibited outcomes
  for (const prohibited of prohibitedOutcomes) {
    if (narrative.result.toLowerCase().includes(prohibited.toLowerCase())) {
      warnings.push({
        type: 'PROHIBITED_OUTCOME',
        message: `Result contains prohibited outcome: "${prohibited}"`,
        severity: 'WARNING',
        context: narrative.result,
      });
    }
  }

  // Use LLM to check personality consistency
  const consistencyCheck = await checkPersonalityConsistency(
    narrative.result,
    characterSummary
  );

  if (consistencyCheck.inconsistency_score > 0.7) {
    warnings.push({
      type: 'PERSONALITY_MISMATCH',
      message: `Action result doesn't match character personality`,
      severity: 'WARNING',
      context: consistencyCheck.explanation,
    });
  }

  return warnings;
}

// LLM-based consistency check
async function checkPersonalityConsistency(
  narrative: string,
  characterSummary: string
): Promise<{ inconsistency_score: number; explanation: string }> {

  const prompt = `
CHARACTER SUMMARY:
${characterSummary}

ACTION RESULT:
${narrative}

TASK:
Rate how consistent this action result is with the character's established personality.
Consider: Would this character realistically do/say/feel this?

Respond in JSON:
{
  "inconsistency_score": <0.0 to 1.0, where 1.0 is completely inconsistent>,
  "explanation": "Brief explanation of any inconsistencies"
}
`;

  const response = await llm.query(prompt, { temperature: 0.1 });
  return JSON.parse(response);
}
```

3. **Time Scale Validation**
```typescript
function validateTimeScale(
  result: IndividualActionResult,
  cycleDays: number
): ValidationError[] {

  const errors: ValidationError[] = [];

  // Check for impossibly fast events
  const impossibleKeywords = [
    'years later', 'decades', 'grew old', 'became famous overnight',
    'instantly mastered', 'overnight success'
  ];

  for (const keyword of impossibleKeywords) {
    if (result.narrative.result.includes(keyword)) {
      errors.push({
        type: 'TIME_SCALE_VIOLATION',
        message: `Narrative suggests timeframe exceeding ${cycleDays} days`,
        severity: 'ERROR',
        context: keyword,
      });
    }
  }

  // Check event count realism
  if (result.events.length > 3) {
    errors.push({
      type: 'TOO_MANY_EVENTS',
      message: `${result.events.length} events in ${cycleDays} days is unrealistic`,
      severity: 'WARNING',
      suggestion: 'Consolidate to 1-3 major events',
    });
  }

  return errors;
}
```

### Layer 4: Cross-Level Consistency

**Purpose**: Ensure hierarchy levels don't contradict each other

```typescript
interface HierarchyConsistency {
  async validateHierarchyCoherence(
    level: number,
    entity: Entity,
    childResults: AggregationResult[],
    parentState: EntityMetrics
  ): Promise<ValidationResult> {

    const errors: ValidationError[] = [];

    // 1. Bottom-up consistency: Child events should support parent metrics
    const childMetricsSum = aggregateChildMetrics(childResults);
    const proposedMetrics = entity.metrics;

    const divergence = calculateDivergence(childMetricsSum, proposedMetrics);

    if (divergence > DIVERGENCE_THRESHOLD) {
      errors.push({
        type: 'CHILD_PARENT_MISMATCH',
        message: `Entity metrics don't reflect child entity states`,
        severity: 'ERROR',
        data: { childMetricsSum, proposedMetrics, divergence },
      });
    }

    // 2. Top-down consistency: Parent state should constrain children
    const parentConstraints = deriveConstraintsFromParent(parentState);
    const violations = checkChildrenAgainstConstraints(childResults, parentConstraints);

    if (violations.length > 0) {
      errors.push({
        type: 'PARENT_CONSTRAINT_VIOLATION',
        message: `Children violate parent entity constraints`,
        severity: 'ERROR',
        data: violations,
      });
    }

    // 3. Narrative coherence across levels
    const narrativeIssues = await checkNarrativeCoherence(
      entity.cycle_summary,
      childResults.map(r => r.summary)
    );

    if (narrativeIssues.length > 0) {
      errors.push(...narrativeIssues);
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }
}
```

**Example: Planet-Nation Consistency**

```typescript
// Planet state: "Severe global drought"
// This constrains all nations:

const planetConstraints = {
  climate: {
    condition: 'drought',
    severity: 'severe',
  },
  required_effects: {
    agriculture: { max: -20, min: -50 },
    food_availability: { max: 40, min: 10 },
    happiness: { max: -10, min: -30 },
  },
  prohibited_narratives: [
    'abundant harvest',
    'record crop yields',
    'perfect weather',
  ],
};

// Nation-level validation
for (const nation of nations) {
  // If nation claims "record harvest" during global drought → ERROR
  if (nation.summary.includes('record harvest')) {
    throw new ConsistencyError('Nation narrative contradicts planet state');
  }

  // If nation agriculture didn't decrease → ERROR
  if (nation.metrics.economy > previousCycle.economy) {
    throw new ConsistencyError('Nation economy improved despite global drought');
  }
}
```

---

## Character Consistency

### Memory System

```typescript
interface CharacterMemory {
  character_id: string;

  // Core identity (rarely changes)
  personality_summary: string;
  core_values: string[];
  defining_moments: HistoricalEvent[];

  // Medium-term patterns
  behavioral_patterns: BehavioralPattern[];
  relationship_patterns: RelationshipPattern[];
  decision_making_style: string;

  // Recent context
  recent_emotional_state: EmotionalState[];
  ongoing_projects: Project[];
  current_concerns: string[];

  // Consistency anchors
  never_would: string[]; // "Alice would never betray a friend"
  always_would: string[]; // "Alice always seeks peaceful solutions"
}
```

**Building Character Memory**:

```typescript
async function buildCharacterMemory(character: Character): Promise<CharacterMemory> {

  // Analyze entire action history
  const allActions = await getAllActions(character.id);

  // Extract patterns using LLM
  const patterns = await extractBehavioralPatterns(allActions, character.traits);

  // Identify defining moments
  const definingMoments = await identifyDefiningMoments(allActions);

  // Generate personality summary
  const personalitySummary = await generatePersonalitySummary(
    character,
    patterns,
    definingMoments
  );

  // Derive behavioral rules
  const neverWould = deriveBehavioralRules(character.traits, 'prohibitions');
  const alwaysWould = deriveBehavioralRules(character.traits, 'requirements');

  return {
    character_id: character.id,
    personality_summary: personalitySummary,
    core_values: character.traits
      .filter(t => t.category === 'values')
      .map(t => t.name),
    defining_moments: definingMoments,
    behavioral_patterns: patterns,
    never_would: neverWould,
    always_would: alwaysWould,
  };
}
```

**Using Memory in Prompts**:

```typescript
function injectMemoryIntoPrompt(
  basePrompt: string,
  memory: CharacterMemory
): string {

  return `
${basePrompt}

IMPORTANT - CHARACTER CONSISTENCY:

This character has an established personality that must be maintained:
${memory.personality_summary}

Core Values (must never violate):
${memory.core_values.map(v => `- ${v}`).join('\n')}

Behavioral Rules:
This character NEVER would:
${memory.never_would.map(r => `- ${r}`).join('\n')}

This character ALWAYS would:
${memory.always_would.map(r => `- ${r}`).join('\n')}

Recent Emotional State:
${memory.recent_emotional_state[0]?.description}

Ongoing Concerns:
${memory.current_concerns.join(', ')}

YOUR RESPONSE MUST BE CONSISTENT WITH THIS ESTABLISHED CHARACTER.
If the requested action contradicts their personality, show them struggling with it or refusing.
`;
}
```

### Personality Drift Detection

```typescript
interface PersonalityDriftDetector {
  async detectDrift(character: Character): Promise<DriftReport> {

    // Compare recent actions (last 20 cycles) to long-term patterns
    const recentActions = await getActionsInRange(character.id, -20, 0);
    const historicalActions = await getActionsInRange(character.id, -200, -20);

    const recentPatterns = await extractBehavioralPatterns(recentActions, character.traits);
    const historicalPatterns = await extractBehavioralPatterns(historicalActions, character.traits);

    // Calculate divergence
    const drift = calculatePatternDivergence(recentPatterns, historicalPatterns);

    if (drift.score > DRIFT_THRESHOLD) {
      // Significant personality change detected

      // Check if justified (life stage change, major trauma, etc.)
      const justification = await checkDriftJustification(character, drift);

      if (!justification.valid) {
        return {
          drifted: true,
          severity: drift.score,
          explanation: drift.explanation,
          action: 'REVERT_OR_JUSTIFY',
          suggestion: 'Either revert recent inconsistent actions or create narrative justification',
        };
      } else {
        // Justified change - update character summary
        return {
          drifted: true,
          severity: drift.score,
          explanation: drift.explanation,
          action: 'UPDATE_PERSONALITY',
          justification: justification.reason,
        };
      }
    }

    return { drifted: false };
  }
}
```

---

## World State Consistency

### State Transition Rules

```typescript
interface WorldStateTransitionRules {
  // Maximum change per cycle
  max_temperature_change: 2, // °C per cycle (15 days)
  max_resource_change: 10, // percentage points
  max_stability_change: 15, // 0-100 scale

  // Minimum durations
  min_climate_phase_duration: 24, // cycles (~1 year)
  min_economic_phase_duration: 48, // cycles (~2 years)
  min_cultural_trend_duration: 12, // cycles (~6 months)

  // Causality requirements
  major_change_requires_event: true, // Changes >20 need world event
  trend_requires_momentum: true, // Trends need build-up
}
```

**Validating World State Changes**:

```typescript
function validateWorldStateTransition(
  previousState: WorldState,
  newState: WorldState,
  events: WorldEvent[]
): ValidationResult {

  const errors: ValidationError[] = [];

  // 1. Temperature change check
  const tempDelta = Math.abs(newState.climate.temperature - previousState.climate.temperature);
  if (tempDelta > RULES.max_temperature_change) {

    // Check if major climate event justifies it
    const hasClimateEvent = events.some(e =>
      e.type === 'natural_disaster' &&
      e.severity === 'catastrophic'
    );

    if (!hasClimateEvent) {
      errors.push({
        type: 'UNREALISTIC_CLIMATE_CHANGE',
        message: `Temperature changed ${tempDelta}°C in 15 days without catastrophic event`,
        severity: 'ERROR',
      });
    }
  }

  // 2. Resource availability check
  for (const resource in newState.resources) {
    const delta = Math.abs(
      newState.resources[resource] - previousState.resources[resource]
    );

    if (delta > RULES.max_resource_change) {
      const hasResourceEvent = events.some(e =>
        e.affects_resources?.includes(resource)
      );

      if (!hasResourceEvent) {
        errors.push({
          type: 'UNEXPLAINED_RESOURCE_CHANGE',
          message: `${resource} changed ${delta}% without corresponding event`,
          severity: 'ERROR',
        });
      }
    }
  }

  // 3. Cultural trend momentum check
  for (const trend of newState.cultural_trends) {
    const previousTrend = previousState.cultural_trends.find(t => t.id === trend.id);

    if (!previousTrend && trend.momentum > 30) {
      errors.push({
        type: 'INSTANT_TREND',
        message: `New trend "${trend.name}" has high momentum without build-up`,
        severity: 'WARNING',
        suggestion: 'New trends should start with low momentum and grow',
      });
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
```

### Event Chain Validation

```typescript
interface EventChain {
  trigger_event: WorldEvent;
  consequence_events: WorldEvent[];
  entity_effects: EntityEffects[];

  // Causality chain
  causality: {
    cause: string;
    mechanism: string;
    effect: string;
  }[];
}

function validateEventChain(chain: EventChain): ValidationResult {

  const errors: ValidationError[] = [];

  // 1. Check temporal ordering
  for (let i = 1; i < chain.consequence_events.length; i++) {
    if (chain.consequence_events[i].cycle <= chain.trigger_event.cycle) {
      errors.push({
        type: 'TEMPORAL_PARADOX',
        message: 'Effect occurred before cause',
        severity: 'ERROR',
      });
    }
  }

  // 2. Check causality makes sense
  for (const link of chain.causality) {
    const plausible = await checkCausalPlausibility(
      link.cause,
      link.mechanism,
      link.effect
    );

    if (!plausible.valid) {
      errors.push({
        type: 'IMPLAUSIBLE_CAUSALITY',
        message: `Causal link is implausible: ${link.cause} → ${link.effect}`,
        severity: 'WARNING',
        explanation: plausible.reason,
      });
    }
  }

  // 3. Check effect magnitudes are proportional
  const triggerMagnitude = estimateEventMagnitude(chain.trigger_event);
  const totalEffectMagnitude = chain.entity_effects.reduce(
    (sum, effect) => sum + estimateEffectMagnitude(effect),
    0
  );

  if (totalEffectMagnitude > triggerMagnitude * 3) {
    errors.push({
      type: 'DISPROPORTIONATE_EFFECTS',
      message: 'Effects are too large for the triggering event',
      severity: 'WARNING',
    });
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
```

---

## Causality Tracking

### Cause Attribution System

```typescript
interface CauseAttribution {
  effect_id: string;
  effect_type: 'metric_change' | 'event' | 'state_change';
  effect_description: string;

  causes: Cause[];

  // Confidence that we've identified true causes
  attribution_confidence: number; // 0-1
}

interface Cause {
  id: string;
  type: 'action' | 'event' | 'aggregation' | 'world_state' | 'trait';
  description: string;
  contribution_percentage: number; // How much this cause contributed
  cycle: number;
}
```

**Tracking Causality**:

```typescript
async function trackCausality(
  effect: MetricChange,
  entity: Entity,
  cycleRange: { start: number; end: number }
): Promise<CauseAttribution> {

  const potentialCauses: Cause[] = [];

  // 1. Check for direct actions
  const actions = await getActionsInRange(entity.id, cycleRange.start, cycleRange.end);
  for (const action of actions) {
    if (action.result?.metrics[effect.metric]) {
      potentialCauses.push({
        id: action.id,
        type: 'action',
        description: action.description,
        contribution_percentage: calculateContribution(action.result.metrics[effect.metric], effect.delta),
        cycle: action.cycle_number,
      });
    }
  }

  // 2. Check for world events
  const events = await getEventsAffectingEntity(entity.id, cycleRange);
  for (const event of events) {
    if (event.effects[effect.metric]) {
      potentialCauses.push({
        id: event.id,
        type: 'event',
        description: event.description,
        contribution_percentage: calculateContribution(event.effects[effect.metric], effect.delta),
        cycle: event.cycle,
      });
    }
  }

  // 3. Check for child entity propagation
  if (entity.level < 8) {
    const childEffects = await getChildEntityEffects(entity.id, cycleRange, effect.metric);
    if (childEffects.total !== 0) {
      potentialCauses.push({
        id: `child-aggregation-${entity.id}`,
        type: 'aggregation',
        description: `Aggregated from ${childEffects.count} child entities`,
        contribution_percentage: calculateContribution(childEffects.total, effect.delta),
        cycle: cycleRange.end,
      });
    }
  }

  // 4. Check for trait-based modifiers
  if (entity.type === 'character') {
    const character = entity as Character;
    const traitEffects = calculateTraitEffects(character.traits, worldState);
    if (traitEffects[effect.metric]) {
      potentialCauses.push({
        id: `traits-${character.id}`,
        type: 'trait',
        description: `Character traits in current world state`,
        contribution_percentage: calculateContribution(traitEffects[effect.metric], effect.delta),
        cycle: cycleRange.end,
      });
    }
  }

  // Normalize contribution percentages
  const totalContribution = potentialCauses.reduce((sum, c) => sum + c.contribution_percentage, 0);
  potentialCauses.forEach(c => {
    c.contribution_percentage = (c.contribution_percentage / totalContribution) * 100;
  });

  return {
    effect_id: `${entity.id}-${effect.metric}-${cycleRange.end}`,
    effect_type: 'metric_change',
    effect_description: `${effect.metric} changed by ${effect.delta}`,
    causes: potentialCauses.sort((a, b) => b.contribution_percentage - a.contribution_percentage),
    attribution_confidence: calculateAttributionConfidence(potentialCauses, effect.delta),
  };
}
```

**Displaying Causality to Users**:

```
Your happiness decreased by 25 this cycle.

Causes:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔴 45% - Failed research project (Cycle 1234)
       Your attempt to prove quantum theorem failed

🔴 30% - Global economic recession (Cycle 1232)
       Planet-wide economic downturn affected everyone

🔴 15% - Relationship conflict with Dr. Chen (Cycle 1235)
       Argument with close friend

🟡 10% - Pessimistic trait in current cultural climate
       Your pessimism is disadvantageous right now
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Metric Constraints

### Dynamic Bounds Calculation

```typescript
interface MetricBounds {
  [metric: string]: {
    min: number;
    max: number;
    reasoning: string;
  };
}

function calculateAllowedMetricChanges(
  character: Character,
  action: ActionSubmit,
  worldState: WorldState
): MetricBounds {

  const bounds: MetricBounds = {};

  // Base bounds depend on action type
  const baseBounds = BASE_BOUNDS[action.action_type];

  for (const metric in baseBounds) {
    let min = baseBounds[metric].min;
    let max = baseBounds[metric].max;
    let reasoning = `Base ${action.action_type} action`;

    // Modify based on character attributes
    const relevantAttribute = METRIC_TO_ATTRIBUTE[metric];
    if (relevantAttribute) {
      const attributeValue = character.attributes[relevantAttribute];
      const multiplier = attributeValue / 50; // 0.4 to 2.0
      max *= multiplier;
      reasoning += `, modified by ${relevantAttribute} (${attributeValue})`;
    }

    // Modify based on life stage
    const lifeStageMultiplier = LIFE_STAGE_EFFECTIVENESS[character.life_stage][action.action_type];
    max *= lifeStageMultiplier;
    min *= lifeStageMultiplier;
    reasoning += `, life stage: ${character.life_stage}`;

    // Modify based on world state
    const worldMultiplier = calculateWorldStateMultiplier(action.action_type, worldState);
    max *= worldMultiplier;
    reasoning += `, world state bonus: ${worldMultiplier.toFixed(2)}x`;

    // Modify based on traits
    const traitBonus = calculateTraitBonus(character.traits, action.action_type, worldState);
    max += traitBonus;
    if (traitBonus !== 0) {
      reasoning += `, trait bonus: ${traitBonus > 0 ? '+' : ''}${traitBonus}`;
    }

    bounds[metric] = {
      min: Math.round(min),
      max: Math.round(max),
      reasoning,
    };
  }

  return bounds;
}
```

**Base Bounds Definition**:

```typescript
const BASE_BOUNDS = {
  scientific: {
    science: { min: -10, max: 15 },
    reputation: { min: -5, max: 10 },
    happiness: { min: -5, max: 10 },
    energy: { min: -15, max: -5 },
    economy: { min: -5, max: 5 },
  },
  social: {
    happiness: { min: -15, max: 15 },
    reputation: { min: -20, max: 20 },
    politics: { min: -10, max: 10 },
    energy: { min: -10, max: 5 },
  },
  economic: {
    economy: { min: -25, max: 25 },
    happiness: { min: -10, max: 10 },
    energy: { min: -20, max: -5 },
  },
  // ... etc
};
```

### Aggregate Constraints

```typescript
interface AggregateConstraints {
  // Total magnitude of change across all metrics
  max_total_change: number;

  // Prevent all metrics moving in same direction unrealistically
  requires_tradeoffs: boolean;

  // At least one metric should decrease if others increase significantly
  tradeoff_threshold: number;
}

function validateAggregateMetricChanges(
  metrics: MetricsDelta,
  constraints: AggregateConstraints
): ValidationResult {

  const errors: ValidationError[] = [];

  // Calculate total absolute change
  const totalChange = Object.values(metrics.character).reduce(
    (sum, delta) => sum + Math.abs(delta),
    0
  );

  if (totalChange > constraints.max_total_change) {
    errors.push({
      type: 'EXCESSIVE_TOTAL_CHANGE',
      message: `Total metric change (${totalChange}) exceeds realistic limit (${constraints.max_total_change})`,
      severity: 'ERROR',
      suggestion: 'Real actions have modest, focused effects',
    });
  }

  // Check for unrealistic "everything gets better"
  if (constraints.requires_tradeoffs) {
    const allPositive = Object.values(metrics.character).every(delta => delta >= 0);
    const allNegative = Object.values(metrics.character).every(delta => delta <= 0);

    const significantChanges = Object.values(metrics.character).filter(
      delta => Math.abs(delta) > constraints.tradeoff_threshold
    );

    if ((allPositive || allNegative) && significantChanges.length > 2) {
      errors.push({
        type: 'MISSING_TRADEOFFS',
        message: 'Real actions involve tradeoffs - some metrics should increase while others decrease',
        severity: 'WARNING',
        suggestion: 'Consider costs and opportunity costs',
      });
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}
```

---

## LLM Output Validation

### Schema Validation

```typescript
import { z } from 'zod';

// Strict Zod schemas for all LLM outputs
const IndividualActionResultSchema = z.object({
  narrative: z.object({
    action: z.string().min(10).max(200),
    result: z.string().min(50).max(500),
    mood: z.string().min(1).max(30),
  }),
  metrics: z.object({
    character: z.record(z.number().min(-50).max(50)),
    household: z.record(z.number().min(-30).max(30)),
  }),
  events: z.array(z.object({
    type: z.enum(['discovery', 'failure', 'breakthrough', 'accident', 'conflict', 'alliance']),
    description: z.string().min(10).max(200),
    impact: z.enum(['immediate', 'ongoing']),
  })).max(3), // Max 3 events per action
  tags: z.array(z.string()).min(1).max(5),
  trait_activations: z.array(z.object({
    trait: z.string(),
    effect: z.string().min(10).max(200),
  })).optional(),
});

async function parseAndValidateLLMOutput(
  rawOutput: string,
  schema: z.ZodSchema
): Promise<{ valid: boolean; data?: any; errors?: string[] }> {

  try {
    // Parse JSON
    const parsed = JSON.parse(rawOutput);

    // Validate against schema
    const validated = schema.parse(parsed);

    return { valid: true, data: validated };

  } catch (error) {
    if (error instanceof z.ZodError) {
      return {
        valid: false,
        errors: error.errors.map(e => `${e.path.join('.')}: ${e.message}`),
      };
    }

    return {
      valid: false,
      errors: ['Failed to parse JSON: ' + error.message],
    };
  }
}
```

### Retry with Feedback

```typescript
async function generateWithValidation<T>(
  prompt: string,
  schema: z.ZodSchema<T>,
  maxRetries: number = 3
): Promise<T> {

  let lastError: string = '';

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    // Add error feedback to prompt if retrying
    const enhancedPrompt = attempt > 0
      ? `${prompt}\n\nPREVIOUS ATTEMPT FAILED:\n${lastError}\n\nPlease fix these issues and try again.`
      : prompt;

    // Generate
    const rawOutput = await llm.query(enhancedPrompt);

    // Validate
    const validation = await parseAndValidateLLMOutput(rawOutput, schema);

    if (validation.valid) {
      return validation.data as T;
    }

    // Failed - prepare for retry
    lastError = validation.errors.join('\n');
    console.warn(`LLM output validation failed (attempt ${attempt + 1}/${maxRetries}):`, lastError);
  }

  throw new Error(`Failed to generate valid output after ${maxRetries} attempts. Last error: ${lastError}`);
}
```

---

## Narrative Continuity

### Story Arc Tracking

```typescript
interface StoryArc {
  id: string;
  character_id: string;

  arc_type: 'personal_growth' | 'conflict' | 'romance' | 'ambition' | 'tragedy' | 'redemption';

  status: 'building' | 'climax' | 'resolution' | 'complete';

  start_cycle: number;
  current_cycle: number;
  estimated_end_cycle: number;

  key_moments: {
    cycle: number;
    description: string;
    importance: 'minor' | 'moderate' | 'major';
  }[];

  current_narrative_thread: string;
  unresolved_elements: string[];

  participants: string[]; // Other character IDs involved
}

async function identifyAndTrackStoryArcs(
  character: Character,
  recentActions: Action[]
): Promise<StoryArc[]> {

  // Use LLM to identify ongoing narrative threads
  const prompt = `
TASK: Identify ongoing story arcs for this character.

CHARACTER: ${character.name}
RECENT ACTIONS (last 20 cycles):
${recentActions.map(a => `- Cycle ${a.cycle_number}: ${a.description} → ${a.result?.narrative.result}`).join('\n')}

Analyze these actions and identify any ongoing narrative threads (story arcs).
Look for:
- Repeated themes or goals
- Developing relationships
- Long-term projects
- Conflicts or challenges
- Character development patterns

Respond in JSON:
{
  "story_arcs": [
    {
      "arc_type": "personal_growth|conflict|romance|ambition|tragedy|redemption",
      "status": "building|climax|resolution",
      "current_narrative_thread": "One sentence summary of where this arc is now",
      "unresolved_elements": ["Things that need resolution"],
      "participants": ["character_ids of others involved"],
      "estimated_cycles_until_resolution": <number>
    }
  ]
}
`;

  const response = await llm.query(prompt);
  const parsed = JSON.parse(response);

  return parsed.story_arcs.map(arc => ({
    id: generateId(),
    character_id: character.id,
    ...arc,
    start_cycle: estimateStartCycle(recentActions, arc),
    current_cycle: currentCycle,
    estimated_end_cycle: currentCycle + arc.estimated_cycles_until_resolution,
    key_moments: extractKeyMoments(recentActions, arc),
  }));
}
```

**Using Story Arcs in Action Generation**:

```typescript
function injectStoryArcsIntoPrompt(
  prompt: string,
  activeArcs: StoryArc[]
): string {

  if (activeArcs.length === 0) return prompt;

  const arcContext = activeArcs.map(arc => `
Arc: ${arc.arc_type} (${arc.status})
Current thread: ${arc.current_narrative_thread}
Needs resolution: ${arc.unresolved_elements.join(', ')}
`).join('\n');

  return `
${prompt}

ONGOING STORY ARCS:
${arcContext}

Your response should acknowledge and advance these ongoing narrative threads where relevant.
Don't force connections, but if the current action naturally relates to an arc, incorporate that.
`;
}
```

---

## Implementation Strategy

### Phase 1: Critical Validations (Week 1)

**Priority: HIGH** - Prevents broken gameplay

1. Metric bounds validation
2. Schema validation
3. Life stage capability checks
4. Trait-action conflict detection

```typescript
// Implement these first
- InputValidator.validateAction()
- OutputValidator.validateResult()
- MetricBoundsValidator.check()
- SchemaValidator.parseAndValidate()
```

### Phase 2: Consistency Enhancements (Week 2)

**Priority: MEDIUM** - Improves believability

1. Character memory system
2. Narrative consistency checks
3. Time scale validation
4. Personality drift detection

```typescript
// Add these for better coherence
- CharacterMemory.build()
- checkNarrativeConsistency()
- validateTimeScale()
- PersonalityDriftDetector.detect()
```

### Phase 3: Advanced Features (Week 3-4)

**Priority: LOW** - Polish and depth

1. Causality tracking
2. Story arc identification
3. Cross-level consistency
4. Event chain validation

```typescript
// Nice-to-have features
- trackCausality()
- identifyAndTrackStoryArcs()
- HierarchyConsistency.validate()
- validateEventChain()
```

### Database Schema Additions

```sql
-- Add to PostgreSQL schema

-- Character memory cache
CREATE TABLE character_memory (
  character_id UUID PRIMARY KEY REFERENCES characters(id),
  personality_summary TEXT NOT NULL,
  behavioral_patterns JSONB DEFAULT '[]'::jsonb,
  never_would TEXT[] DEFAULT ARRAY[]::TEXT[],
  always_would TEXT[] DEFAULT ARRAY[]::TEXT[],
  last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- Story arc tracking
CREATE TABLE story_arcs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  character_id UUID REFERENCES characters(id),
  arc_type VARCHAR(50) NOT NULL,
  status VARCHAR(20) NOT NULL,
  current_narrative_thread TEXT,
  unresolved_elements TEXT[],
  participants UUID[],
  start_cycle INTEGER,
  current_cycle INTEGER,
  estimated_end_cycle INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Causality tracking
CREATE TABLE cause_attributions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  effect_id VARCHAR(255) NOT NULL,
  effect_type VARCHAR(50) NOT NULL,
  effect_description TEXT,
  causes JSONB NOT NULL,
  attribution_confidence DECIMAL(3,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Validation logs
CREATE TABLE validation_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_id UUID NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  validation_type VARCHAR(50) NOT NULL,
  passed BOOLEAN NOT NULL,
  errors JSONB,
  warnings JSONB,
  cycle_number INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_validation_logs_entity ON validation_logs(entity_id, cycle_number);
CREATE INDEX idx_validation_logs_failed ON validation_logs(passed) WHERE passed = FALSE;
```

### Configuration

```typescript
// config/consistency.ts

export const CONSISTENCY_CONFIG = {
  validation: {
    enabled: true,
    strict_mode: false, // If true, reject on warnings
    max_retries: 3,
    retry_delay_ms: 1000,
  },

  metric_bounds: {
    enforce_bounds: true,
    allow_overage_percentage: 10, // Allow 10% over max in exceptional cases
  },

  character_memory: {
    enabled: true,
    rebuild_frequency_cycles: 100, // Rebuild memory every 100 cycles
    include_cycles: 200, // Analyze last 200 cycles
  },

  causality_tracking: {
    enabled: true,
    track_from_level: 8, // Individual level
    track_to_level: 5, // Nation level
  },

  drift_detection: {
    enabled: true,
    check_frequency_cycles: 50,
    drift_threshold: 0.7,
  },

  story_arcs: {
    enabled: true,
    max_concurrent_arcs: 3,
    min_arc_duration_cycles: 10,
  },
};
```

---

## Testing Consistency

### Unit Tests

```typescript
describe('MetricBoundsValidator', () => {
  it('should reject out-of-bounds metric changes', () => {
    const bounds = { happiness: { min: -20, max: 20 } };
    const metrics = { character: { happiness: 50 } };

    const result = checkMetricBounds(metrics, bounds);

    expect(result.length).toBeGreaterThan(0);
    expect(result[0].type).toBe('METRIC_OVERFLOW');
  });

  it('should allow changes within bounds', () => {
    const bounds = { happiness: { min: -20, max: 20 } };
    const metrics = { character: { happiness: 15 } };

    const result = checkMetricBounds(metrics, bounds);

    expect(result.length).toBe(0);
  });
});
```

### Integration Tests

```typescript
describe('Action Consistency Flow', () => {
  it('should maintain character personality across actions', async () => {
    // Create character with "Pacifist" trait
    const character = await createCharacter({
      traits: [{ name: 'Pacifist', category: 'values' }],
    });

    // Attempt violent action
    const action = {
      character_id: character.id,
      action_type: 'military',
      description: 'Start a war with neighboring nation',
    };

    // Should be rejected or modified
    const validation = await validateAction(action, character);

    expect(validation.valid).toBe(false);
    expect(validation.errors).toContainEqual(
      expect.objectContaining({
        type: 'TRAIT_ACTION_CONFLICT',
      })
    );
  });
});
```

---

## Monitoring & Alerts

```typescript
// Set up monitoring for consistency issues

class ConsistencyMonitor {
  async checkSystemHealth(): Promise<HealthReport> {

    // Check validation failure rate
    const validationStats = await getValidationStats(lastCycles = 10);
    if (validationStats.failure_rate > 0.2) {
      await alert('High validation failure rate: ' + validationStats.failure_rate);
    }

    // Check for personality drift epidemic
    const driftCount = await countDriftingCharacters();
    if (driftCount > TOTAL_CHARACTERS * 0.1) {
      await alert(`${driftCount} characters showing personality drift`);
    }

    // Check for metric anomalies
    const anomalies = await detectMetricAnomalies();
    if (anomalies.length > 0) {
      await alert(`Detected ${anomalies.length} metric anomalies`);
    }

    return {
      healthy: validationStats.failure_rate < 0.1 && driftCount < TOTAL_CHARACTERS * 0.05,
      issues: [...],
    };
  }
}
```

---

## Summary

### Key Mechanisms for Consistency

1. **Four-Layer Validation**
   - Input validation (before LLM)
   - Context enrichment (better LLM inputs)
   - Output validation (after LLM)
   - Cross-level consistency (hierarchy coherence)

2. **Character Memory System**
   - Personality summaries
   - Behavioral patterns
   - Never/always rules
   - Drift detection

3. **Bounded Changes**
   - Dynamic metric bounds
   - Aggregate constraints
   - Proportional causality

4. **Causality Tracking**
   - Explicit cause attribution
   - Event chains
   - Effect transparency

5. **Narrative Continuity**
   - Story arc tracking
   - Thread preservation
   - Temporal consistency

### Expected Impact

- **Believability**: ⬆️ 300% improvement
- **Player Immersion**: ⬆️ Significantly higher
- **Broken Narratives**: ⬇️ 90% reduction
- **LLM Regeneration Rate**: ⬆️ 15% (more retries for quality)
- **System Complexity**: ⬆️ 30% more code
- **Performance Cost**: ⬆️ 10-15% processing time

**Tradeoff**: More processing time and complexity, but massively better game quality.

---

## Version History

- v1.0: Initial consistency and validation system design
