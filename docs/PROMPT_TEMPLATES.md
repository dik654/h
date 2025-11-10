# LLM Prompt Templates Collection

This document contains all prompt templates used throughout the hierarchical world simulation system. Each template is designed for specific aggregation levels and use cases.

## Table of Contents

1. [Level 8: Individual Action Processing](#level-8-individual-action-processing)
2. [Level 7: Household Aggregation](#level-7-household-aggregation)
3. [Level 6: Organization Aggregation](#level-6-organization-aggregation)
4. [Level 5: Nation Aggregation](#level-5-nation-aggregation)
5. [Level 4: Planet Aggregation](#level-4-planet-aggregation)
6. [Level 3-1: Cosmic Aggregation](#level-3-1-cosmic-aggregation)
7. [Cultural Trend Generation](#cultural-trend-generation)
8. [World Event Generation](#world-event-generation)
9. [Election & Competition](#election--competition)
10. [Character Development](#character-development)

---

## Level 8: Individual Action Processing

### Template: Individual Scientific Action

```
You are simulating a character in a detailed world simulation game.

CHARACTER CONTEXT:
- Name: {{character_name}}
- Age: {{age}} ({{life_stage}})
- Attributes: {{attributes_json}}
- Traits: {{traits_list}}
- Current Reputation: {{reputation_score}}
- Social Position: {{position_title}} ({{position_entity}})

WORLD STATE (Cycle {{cycle_number}}):
- Climate: {{climate_temp}}°C, {{climate_condition}}
- Resources: Food {{food_level}}/100, Energy {{energy_level}}/100
- Cultural Trends: {{top_3_trends}}
- Economic Phase: {{economic_phase}}
- Technology Level: {{tech_level}}/100

HOUSEHOLD CONTEXT:
- Members: {{member_count}} people
- Household Metrics: Economy {{household_economy}}, Happiness {{household_happiness}}
- Recent Events: {{recent_household_events}}

ACTION REQUESTED:
{{action_description}}

TRAIT MODIFIERS:
{{trait_advantage_disadvantage_list}}

INSTRUCTIONS:
Generate a realistic outcome for this action considering:
1. Character's attributes and life stage capabilities
2. Relevant traits and how current world state affects them
3. Social position influence (if applicable)
4. Household context and resources
5. World state conditions

Respond in JSON format:
{
  "narrative": {
    "action": "Brief restatement of what character attempted (1 sentence)",
    "result": "What happened as a result (2-3 sentences, engaging narrative)",
    "mood": "Character's emotional state after (1-2 words)"
  },
  "metrics": {
    "character": {
      "science": <-20 to +20>,
      "happiness": <-20 to +20>,
      "reputation": <-10 to +10>,
      "energy": <-30 to +10>
    },
    "household": {
      "economy": <-10 to +10>,
      "science": <-5 to +15>
    }
  },
  "events": [
    {
      "type": "discovery|failure|breakthrough|accident",
      "description": "Brief event description",
      "impact": "immediate|ongoing"
    }
  ],
  "tags": ["science", "research", "innovation"],
  "trait_activations": [
    {
      "trait": "trait_name",
      "effect": "Brief description of how this trait influenced the outcome"
    }
  ]
}

Keep narrative engaging but concise. Metrics should be realistic - most actions have modest effects (-10 to +10), exceptional outcomes can reach -20 to +20.
```

### Template: Individual Social Action

```
You are simulating a character in a detailed world simulation game.

CHARACTER CONTEXT:
- Name: {{character_name}}
- Age: {{age}} ({{life_stage}})
- Attributes: {{attributes_json}}
- Traits: {{traits_list}}
- Current Reputation: {{reputation_score}}
- Social Position: {{position_title}} ({{position_entity}})

WORLD STATE (Cycle {{cycle_number}}):
- Cultural Trends: {{top_3_trends}}
- Political Climate: {{political_climate}}
- Social Stability: {{stability_score}}/100

TARGET CHARACTER (if applicable):
- Name: {{target_name}}
- Relationship: {{relationship_type}} ({{relationship_score}}/100)
- Social Position: {{target_position}}

CONTEXT:
- Location: {{interaction_location}}
- Recent Interactions: {{recent_interactions_summary}}

ACTION REQUESTED:
{{action_description}}

TRAIT MODIFIERS:
{{trait_advantage_disadvantage_list}}

INSTRUCTIONS:
Generate a realistic social interaction outcome considering:
1. Character's social attributes (Charisma, Wisdom)
2. Life stage social capabilities
3. Relevant personality/value traits
4. Existing relationship dynamics
5. Cultural trends and political climate
6. Social position influence

Respond in JSON format:
{
  "narrative": {
    "action": "What character attempted (1 sentence)",
    "result": "How the interaction unfolded (2-3 sentences)",
    "mood": "Character's emotional state after"
  },
  "metrics": {
    "character": {
      "happiness": <-20 to +20>,
      "reputation": <-15 to +15>,
      "politics": <-10 to +10>
    },
    "household": {
      "culture": <-5 to +10>,
      "happiness": <-5 to +10>
    }
  },
  "relationships": [
    {
      "target_id": "{{target_character_id}}",
      "delta": <-30 to +30>,
      "new_type": "enemy|rival|neutral|acquaintance|friend|close_friend"
    }
  ],
  "events": [
    {
      "type": "conflict|alliance|romance|betrayal|reconciliation",
      "description": "Event description",
      "participants": ["character_id1", "character_id2"]
    }
  ],
  "tags": ["social", "diplomacy", "relationship"]
}

Social actions can have larger relationship swings (-30 to +30) but modest metric changes.
```

### Template: Individual Economic Action

```
You are simulating a character in a detailed world simulation game.

CHARACTER CONTEXT:
- Name: {{character_name}}
- Age: {{age}} ({{life_stage}})
- Attributes: {{attributes_json}}
- Traits: {{traits_list}}
- Social Position: {{position_title}}

WORLD STATE:
- Economic Phase: {{economic_phase}}
- Resource Availability: {{resource_summary}}
- Market Conditions: {{market_conditions}}

HOUSEHOLD CONTEXT:
- Economy: {{household_economy}}/100
- Members: {{member_count}}
- Income Sources: {{income_sources}}

ACTION REQUESTED:
{{action_description}}

TRAIT MODIFIERS:
{{trait_advantage_disadvantage_list}}

INSTRUCTIONS:
Generate economic action outcome considering:
1. Character's relevant attributes (Intelligence, Vitality)
2. Economic phase effects (boom/recession)
3. Resource availability
4. Traits like "Frugal", "Innovative", "Hardworking"
5. Social position economic influence

Respond in JSON format:
{
  "narrative": {
    "action": "Economic activity attempted",
    "result": "Outcome and consequences (2-3 sentences)",
    "mood": "Character's feeling about outcome"
  },
  "metrics": {
    "character": {
      "economy": <-25 to +25>,
      "happiness": <-15 to +15>,
      "energy": <-20 to +10>
    },
    "household": {
      "economy": <-20 to +20>,
      "stability": <-10 to +10>
    }
  },
  "resources": {
    "gained": {"resource_type": amount},
    "spent": {"resource_type": amount}
  },
  "events": [
    {
      "type": "windfall|loss|trade|investment|business",
      "description": "Event description"
    }
  ],
  "tags": ["economic", "trade", "business"]
}

Economic actions can have significant metric swings due to risk/reward nature.
```

---

## Level 7: Household Aggregation

### Template: Household Cycle Summary

```
You are aggregating multiple character actions within a household in a world simulation.

HOUSEHOLD CONTEXT:
- Name: {{household_name}}
- Type: {{household_type}}
- Members: {{member_count}} ({{member_age_distribution}})
- Location: {{location_entity_name}}
- Current Metrics: {{household_metrics_json}}

WORLD STATE (Cycle {{cycle_number}}):
- Climate: {{climate_condition}}
- Resources: {{resource_levels}}
- Cultural Trends: {{trends_list}}

INDIVIDUAL ACTIONS THIS CYCLE ({{action_count}} actions):
{{#each individual_actions}}
---
Character: {{character_name}} ({{life_stage}})
Action: {{action_type}}
Narrative: {{narrative_result}}
Metrics Impact: {{metrics_delta}}
Events: {{events_list}}
---
{{/each}}

INSTRUCTIONS:
Synthesize these individual actions into a cohesive household narrative:

1. Identify key themes and developments
2. Note how members' actions interacted or conflicted
3. Assess overall household trajectory
4. Consider lifecycle dynamics (elder mentoring youth, etc.)
5. Evaluate aggregate impact on household metrics

Respond in JSON format:
{
  "narrative": {
    "summary": "3-5 sentence narrative capturing household's cycle, emphasizing interactions between members and key developments",
    "mood": "overall household atmosphere",
    "key_events": ["event1", "event2", "event3"]
  },
  "metrics": {
    "economy": <-30 to +30>,
    "happiness": <-30 to +30>,
    "stability": <-30 to +30>,
    "culture": <-20 to +20>,
    "science": <-20 to +20>
  },
  "member_dynamics": {
    "conflicts": [{"members": ["id1", "id2"], "issue": "description"}],
    "collaborations": [{"members": ["id1", "id2"], "achievement": "description"}],
    "lifecycle_moments": ["birth", "coming_of_age", "retirement", "death"]
  },
  "entity_impact": {
    "organization": {
      "economy": <-10 to +10>,
      "politics": <-10 to +10>
    }
  },
  "tags": ["household_harmony|conflict", "growth|decline", "prosperous|struggling"]
}

Focus on emergent household dynamics - how individual actions combined to create household-level outcomes.
```

---

## Level 6: Organization Aggregation

### Template: Organization Cycle Summary

```
You are aggregating household/member activities within an organization in a world simulation.

ORGANIZATION CONTEXT:
- Name: {{organization_name}}
- Type: {{org_type}} (corporate|government|educational|military|religious|cultural)
- Size: {{member_count}} members in {{household_count}} households
- Current Metrics: {{org_metrics_json}}
- Leadership: {{leader_positions_list}}

WORLD STATE (Cycle {{cycle_number}}):
- Economic Phase: {{economic_phase}}
- Political Climate: {{political_climate}}
- Cultural Trends: {{trends_affecting_org}}

HOUSEHOLD SUMMARIES ({{household_count}} households):
{{#each household_summaries}}
---
Household: {{name}}
Summary: {{narrative_summary}}
Key Events: {{key_events}}
Metrics: {{metrics_json}}
---
{{/each}}

KEY ORGANIZATIONAL EVENTS:
- Leadership Changes: {{leadership_changes}}
- Elections/Competitions: {{selection_events}}
- External Interactions: {{external_interactions}}

INSTRUCTIONS:
Aggregate household activities into organizational developments:

1. Identify organizational trends from household patterns
2. Assess leadership effectiveness and decisions
3. Note internal politics and faction dynamics
4. Evaluate organization's external relationships
5. Consider organizational culture evolution

Respond in JSON format:
{
  "summary": "2-3 paragraph organizational update covering key developments, leadership actions, internal dynamics, and strategic direction",
  "metrics": {
    "economy": <aggregate change>,
    "politics": <aggregate change>,
    "culture": <aggregate change>,
    "science": <aggregate change>,
    "military": <aggregate change>,
    "stability": <aggregate change>
  },
  "internal_dynamics": {
    "morale": "high|medium|low",
    "cohesion": "unified|divided|fractured",
    "innovation": "stagnant|steady|rapid",
    "key_issues": ["issue1", "issue2"]
  },
  "leadership_assessment": {
    "effectiveness": <1-10>,
    "popular_support": <1-10>,
    "notable_decisions": ["decision1", "decision2"]
  },
  "entity_impact": {
    "nation": {
      "economy": <-20 to +20>,
      "politics": <-15 to +15>,
      "culture": <-15 to +15>
    }
  },
  "strategic_focus": ["economic_growth", "political_influence", "cultural_expansion", "military_strength", "scientific_advancement"]
}

Balance specific household stories with organizational-level analysis. Reduce narrative detail, increase strategic assessment.
```

---

## Level 5: Nation Aggregation

### Template: Nation Cycle Summary

```
You are aggregating organizational activities into national-level developments.

NATION CONTEXT:
- Name: {{nation_name}}
- Population: {{population_count}}
- Territory: {{territory_description}}
- Government Type: {{government_type}}
- Current Metrics: {{nation_metrics_json}}
- National Leadership: {{head_of_state}}, {{cabinet_summary}}

WORLD STATE (Cycle {{cycle_number}}):
- Global Economic Phase: {{economic_phase}}
- Climate: {{climate_summary}}
- Geopolitical Situation: {{geopolitical_context}}

ORGANIZATIONAL SUMMARIES (Top {{org_count}} organizations by impact):
{{#each org_summaries}}
---
Organization: {{name}} ({{type}})
Metrics: {{metrics_json}}
Key Developments: {{key_points}}
---
{{/each}}

NATIONAL EVENTS:
- Policy Changes: {{policy_changes}}
- International Relations: {{foreign_relations_events}}
- Natural Events: {{natural_events}}
- Economic Indicators: {{economic_summary}}

INSTRUCTIONS:
Synthesize organizational data into national-level analysis:

1. Identify macro trends across organizations
2. Assess government policy effectiveness
3. Evaluate economic health and trajectory
4. Note cultural/social movements
5. Analyze military/security situation
6. Consider international standing

Respond in JSON format:
{
  "summary": "1 paragraph national overview focusing on macro trends, government actions, economic health, and strategic position",
  "metrics": {
    "economy": <aggregate>,
    "politics": <aggregate>,
    "culture": <aggregate>,
    "science": <aggregate>,
    "military": <aggregate>,
    "happiness": <aggregate>,
    "stability": <aggregate>
  },
  "national_health": {
    "economic_vitality": <1-10>,
    "political_stability": <1-10>,
    "social_cohesion": <1-10>,
    "military_strength": <1-10>,
    "international_standing": <1-10>
  },
  "government_performance": {
    "policy_effectiveness": <1-10>,
    "public_approval": <1-10>,
    "key_policies": ["policy1", "policy2"]
  },
  "entity_impact": {
    "planet": {
      "economy": <-30 to +30>,
      "politics": <-25 to +25>,
      "culture": <-20 to +20>,
      "science": <-20 to +20>,
      "military": <-15 to +15>
    }
  },
  "strategic_priorities": ["priority1", "priority2", "priority3"]
}

Minimize narrative, maximize data-driven analysis. Focus on quantifiable trends and strategic implications.
```

---

## Level 4: Planet Aggregation

### Template: Planet Cycle Summary

```
You are aggregating national developments into planetary-level summary.

PLANET CONTEXT:
- Name: {{planet_name}}
- Total Population: {{population}}
- Nations: {{nation_count}}
- Current Metrics: {{planet_metrics_json}}

WORLD STATE (Cycle {{cycle_number}}):
- Climate: {{climate_state}}
- Resources: {{resource_state}}
- Technology Level: {{tech_level}}

NATIONAL SUMMARIES (All {{nation_count}} nations):
{{#each nation_summaries}}
{{nation_name}}: Economy {{economy}}, Politics {{politics}}, Military {{military}}, Happiness {{happiness}}
Key: {{brief_summary}}
---
{{/each}}

PLANETARY EVENTS:
- Climate Events: {{climate_events}}
- Resource Changes: {{resource_changes}}
- Technological Breakthroughs: {{tech_breakthroughs}}
- Major Conflicts: {{conflicts}}

INSTRUCTIONS:
Aggregate national data into planetary metrics and brief summary:

1. Calculate weighted averages based on population
2. Identify planet-wide trends
3. Note inter-national dynamics (wars, alliances, trade)
4. Assess global challenges (climate, resources, stability)

Respond in JSON format:
{
  "summary": "2-3 sentences on planetary state: overall stability, major developments, critical issues",
  "metrics": {
    "economy": <weighted average>,
    "politics": <weighted average>,
    "culture": <weighted average>,
    "science": <weighted average>,
    "military": <weighted average>,
    "happiness": <weighted average>,
    "stability": <weighted average>,
    "population": <total>
  },
  "planet_health": {
    "climate_stability": <1-10>,
    "resource_sustainability": <1-10>,
    "peace_index": <1-10>,
    "technological_advancement": <1-10>
  },
  "critical_issues": ["issue1", "issue2"],
  "entity_impact": {
    "solar_system": {
      "economy": <aggregate>,
      "science": <aggregate>,
      "military": <aggregate>
    }
  }
}

Highly condensed. Pure metrics with minimal narrative. Focus on planetary-scale phenomena only.
```

---

## Level 3-1: Cosmic Aggregation

### Template: Solar System to Universe

```
AGGREGATION LEVEL: {{level_name}} ({{level_number}})

CHILD ENTITIES ({{child_count}} entities):
{{#each child_summaries}}
{{entity_name}}: {{metrics_json}}
{{/each}}

INSTRUCTIONS:
Aggregate child entity metrics:

1. Calculate population-weighted averages for all metrics
2. Propagate only significant developments (wars, disasters, breakthroughs)
3. Identify cosmos-level trends

Respond in JSON format:
{
  "summary": "1 sentence if any major cosmic events, otherwise null",
  "metrics": {
    "economy": <weighted average>,
    "politics": <weighted average>,
    "culture": <weighted average>,
    "science": <weighted average>,
    "military": <weighted average>,
    "happiness": <weighted average>,
    "stability": <weighted average>,
    "population": <total>
  },
  "entity_impact": {
    "parent_level": {
      "economy": <aggregate>,
      "politics": <aggregate>,
      "culture": <aggregate>,
      "science": <aggregate>,
      "military": <aggregate>
    }
  }
}

Minimal processing. Simple aggregation unless truly cosmic-scale events occur.
```

---

## Cultural Trend Generation

### Template: Generate New Cultural Trends

```
You are generating cultural trends for a world simulation based on current state and recent events.

WORLD STATE (Cycle {{cycle_number}}):
- Technology Level: {{tech_level}}/100
- Economic Phase: {{economic_phase}}
- Climate: {{climate_state}}
- Average Happiness: {{avg_happiness}}/100
- Recent Major Events: {{recent_events}}

EXISTING CULTURAL TRENDS:
{{#each existing_trends}}
- {{name}}: {{description}} (Momentum: {{momentum}}, Age: {{age}} cycles)
{{/each}}

RECENT NATIONAL DEVELOPMENTS:
{{recent_national_summaries}}

INSTRUCTIONS:
Generate 1-3 new cultural trends that would organically emerge from current conditions:

1. Consider cause-and-effect (economic hardship → frugality movements)
2. Reflect technological changes (new tech → adoption trends)
3. React to major events (war → nationalism or pacifism)
4. Build on existing trends (trend evolution or counter-movements)
5. Consider lifecycle (new generation values)

Respond in JSON format:
{
  "new_trends": [
    {
      "name": "Trend name (2-4 words)",
      "description": "What this trend represents (1 sentence)",
      "category": "ideology|fashion|technology|social|economic|political",
      "momentum": <1-100, how strong/popular>,
      "effects": {
        "trait_modifiers": [
          {
            "trait": "trait_name",
            "modifier": "Gains +15 reputation in urban areas",
            "affected_contexts": ["urban", "organization:corporate"]
          }
        ],
        "entity_modifiers": [
          {
            "entity_level": "nation",
            "metric": "culture",
            "value": 5,
            "condition": "if >50% population adopts"
          }
        ]
      },
      "adoption_rate": <0-100, how quickly spreading>,
      "duration_estimate": <cycles until fade>,
      "origin": "Brief explanation of why this trend emerged"
    }
  ],
  "fading_trends": [
    {
      "trend_id": "existing_trend_id",
      "reason": "Why this trend is fading"
    }
  ]
}

Trends should feel organic, not random. They should meaningfully impact gameplay through trait/entity modifiers.
```

---

## World Event Generation

### Template: Generate Random World Events

```
You are generating world events for a simulation cycle based on current conditions and probability.

WORLD STATE (Cycle {{cycle_number}}):
- Climate: {{climate_state}}
- Resource Levels: {{resource_levels}}
- Technology Level: {{tech_level}}
- Average Stability: {{avg_stability}}/100
- Active Wars: {{war_count}}

ENTITY CONTEXT:
- Level: {{entity_level}}
- Name: {{entity_name}}
- Population: {{population}}
- Metrics: {{entity_metrics}}

EVENT PROBABILITY MODIFIERS:
- Climate instability: {{climate_risk}}% natural disaster chance
- Low stability: {{instability_risk}}% conflict/unrest chance
- High science: {{breakthrough_chance}}% discovery chance
- Resource scarcity: {{scarcity_risk}}% crisis chance

INSTRUCTIONS:
Generate 0-2 world events appropriate for this entity level:

1. Consider current conditions and risk factors
2. Scale impact to entity level (planet-wide vs local)
3. Create meaningful gameplay impact
4. Balance negative/positive events

Respond in JSON format:
{
  "events": [
    {
      "type": "natural_disaster|technological_breakthrough|political_crisis|resource_discovery|epidemic|war|peace|cultural_renaissance",
      "name": "Event name",
      "description": "2-3 sentence description of what happened",
      "severity": "minor|moderate|major|catastrophic",
      "affected_area": "{{entity_name}} or sub-entity",
      "duration": <cycles>,
      "effects": {
        "immediate": {
          "metrics": {
            "economy": <-50 to +50>,
            "happiness": <-50 to +50>,
            "stability": <-50 to +50>,
            "population": <-30 to +30>
          }
        },
        "ongoing": {
          "per_cycle": {
            "economy": <-10 to +10>
          },
          "duration": <cycles>
        }
      },
      "response_options": [
        {
          "action": "Government response option",
          "cost": {"economy": -20, "politics": -10},
          "benefit": {"stability": +15, "happiness": +10},
          "available_to": ["head_of_state", "minister"]
        }
      ],
      "narrative_hooks": [
        "Story opportunities this event creates"
      ]
    }
  ]
}

Events should create interesting choices and narrative opportunities, not just random metric changes.
```

---

## Election & Competition

### Template: Process Election

```
You are processing an election for a limited-slot social position.

POSITION CONTEXT:
- Title: {{position_title}}
- Entity: {{entity_name}} ({{entity_level}})
- Available Slots: {{slot_count}}
- Current Holders: {{current_holders}}
- Requirements: {{requirements_json}}
- Selection Method: election_popular|election_representative

CANDIDATES ({{candidate_count}} candidates):
{{#each candidates}}
---
Name: {{character_name}}
Age: {{age}} ({{life_stage}})
Attributes: {{attributes_json}}
Traits: {{traits_list}}
Reputation: {{reputation_score}}/100
Current Position: {{current_position}}
Campaign Platform: {{platform_summary}}
Achievements: {{achievement_list}}
---
{{/each}}

WORLD STATE:
- Cultural Trends: {{trends_list}}
- Political Climate: {{political_climate}}
- Key Issues: {{voter_concerns}}

VOTER BASE:
- Total Voters: {{voter_count}}
- Demographics: {{demographic_breakdown}}
- Issue Priorities: {{issue_priorities}}

INSTRUCTIONS:
Simulate election results considering:

1. Candidate qualifications and reputation
2. Platform alignment with voter concerns
3. Cultural trends affecting voter preferences
4. Traits that are currently advantageous
5. Campaign effectiveness (based on Charisma/Politics)
6. Incumbent advantages/disadvantages

Respond in JSON format:
{
  "results": [
    {
      "character_id": "uuid",
      "character_name": "Name",
      "votes": <count>,
      "percentage": <0-100>,
      "won": true|false
    }
  ],
  "vote_distribution": {
    "by_demographic": {
      "youth": {"winner_id": "votes"},
      "elderly": {"winner_id": "votes"}
    },
    "by_issue": {
      "economy": {"winner_id": "votes"},
      "security": {"winner_id": "votes"}
    }
  },
  "winner_explanation": "2-3 sentences explaining why winner(s) won: key factors, voter appeal, decisive issues",
  "narrative": {
    "campaign_highlights": ["memorable moment1", "memorable moment2"],
    "post_election_mood": "celebratory|divided|disappointed|hopeful",
    "losing_candidate_reactions": ["reaction1", "reaction2"]
  },
  "effects": {
    "winner_reputation": +10,
    "loser_reputation": -5,
    "entity_stability": <-10 to +10 based on election legitimacy>
  }
}

Elections should feel meaningful and explainable. Voters should have logical reasons for their choices.
```

### Template: Process Merit-Based Competition

```
You are processing a merit-based selection for a limited-slot social position.

POSITION CONTEXT:
- Title: {{position_title}}
- Entity: {{entity_name}}
- Available Slots: {{slot_count}}
- Selection Method: merit_based
- Evaluation Criteria: {{criteria_json}}

CANDIDATES ({{candidate_count}} candidates):
{{#each candidates}}
---
Name: {{character_name}}
Attributes: {{attributes_json}}
Traits: {{traits_list}}
Relevant Achievements: {{relevant_achievements}}
Experience: {{experience_years}} years
Current Position: {{current_position}}
---
{{/each}}

WORLD STATE:
- Cultural Trends: {{trends_affecting_selection}}
- Organizational Needs: {{current_priorities}}

EVALUATION CRITERIA WEIGHTS:
{{criteria_weights_json}}

INSTRUCTIONS:
Evaluate candidates based on merit:

1. Score each candidate against criteria
2. Apply trait modifiers based on world state
3. Consider organizational fit
4. Account for diversity of qualifications

Respond in JSON format:
{
  "evaluations": [
    {
      "character_id": "uuid",
      "character_name": "Name",
      "total_score": <0-100>,
      "criteria_scores": {
        "criterion1": <score>,
        "criterion2": <score>
      },
      "trait_bonuses": [
        {"trait": "name", "bonus": <-10 to +10>, "reason": "Why this trait helped/hurt"}
      ],
      "selected": true|false,
      "rank": <1-N>
    }
  ],
  "selection_explanation": "2-3 sentences explaining selection rationale: why winners stood out, how criteria were balanced",
  "effects": {
    "selected_reputation": +15,
    "not_selected_reputation": 0,
    "entity_morale": <-5 to +10 based on perceived fairness>
  },
  "notable_considerations": [
    "Any interesting factors or close decisions"
  ]
}

Merit selections should be transparent and fair. Criteria should clearly drive outcomes.
```

---

## Character Development

### Template: Trait Acquisition

```
You are determining if a character acquires a new trait based on their experiences.

CHARACTER CONTEXT:
- Name: {{character_name}}
- Age: {{age}} ({{life_stage}})
- Current Traits: {{existing_traits}}
- Attributes: {{attributes_json}}

RECENT EXPERIENCE (Last {{cycle_count}} cycles):
- Actions Taken: {{action_summary}}
- Events Experienced: {{event_summary}}
- Metrics Changes: {{metrics_delta}}
- Relationship Changes: {{relationship_changes}}
- Positions Held: {{positions}}

WORLD STATE:
- Cultural Trends: {{trends}}
- Major Events Witnessed: {{major_events}}

INSTRUCTIONS:
Determine if character should acquire a new trait based on:

1. Consistent behavior patterns (repeated action types)
2. Significant experiences (major events, trauma, achievements)
3. Life stage transitions (coming of age, midlife, retirement)
4. World influences (cultural trends, ideology exposure)
5. Relationship impacts (mentorship, betrayal, love)

Respond in JSON format:
{
  "trait_acquisition": {
    "should_acquire": true|false,
    "trait": {
      "name": "Trait name",
      "category": "personality|aptitude|values|acquired",
      "description": "What this trait represents",
      "effects": [
        {
          "context": "When applicable",
          "modifier": "Effect on actions/metrics"
        }
      ]
    },
    "acquisition_reason": "2-3 sentences explaining why character developed this trait: specific experiences, patterns, or events that led to it",
    "narrative_moment": "Brief 1-2 sentence narrative of the realization/change moment"
  },
  "trait_modification": [
    {
      "existing_trait": "trait_name",
      "change": "strengthened|weakened|transformed",
      "reason": "Why this trait evolved"
    }
  ]
}

Only suggest trait acquisition for meaningful character development. Not every cycle should add traits - most should return should_acquire: false.
Traits should feel earned through gameplay, not random.
```

### Template: Life Stage Transition

```
You are processing a character's transition to a new life stage.

CHARACTER CONTEXT:
- Name: {{character_name}}
- Current Age: {{current_age}}
- Current Life Stage: {{current_stage}}
- Next Life Stage: {{next_stage}}
- Attributes: {{attributes_json}}
- Traits: {{traits_list}}

LIFE HISTORY:
- Major Achievements: {{achievements}}
- Key Relationships: {{relationships}}
- Positions Held: {{positions}}
- Defining Experiences: {{defining_events}}

INSTRUCTIONS:
Generate a meaningful life stage transition:

1. Reflect on character's journey so far
2. Note physical/mental changes from aging
3. Suggest appropriate attribute changes
4. Identify new opportunities/limitations
5. Create narrative moment for transition

Respond in JSON format:
{
  "transition": {
    "from_stage": "{{current_stage}}",
    "to_stage": "{{next_stage}}",
    "age": {{current_age}}
  },
  "narrative": "3-4 sentence reflection on character's life and this transition: accomplishments, regrets, hopes, physical/mental changes",
  "attribute_changes": {
    "strength": <-20 to +20>,
    "vitality": <-20 to +20>,
    "agility": <-20 to +20>,
    "intelligence": <-10 to +10>,
    "wisdom": <-5 to +20>,
    "charisma": <-10 to +10>
  },
  "capability_changes": {
    "gained": [
      "New capabilities unlocked (e.g., voting rights, can_hold_office, can_mentor)"
    ],
    "lost": [
      "Capabilities removed (e.g., cannot_military_service, requires_assistance)"
    ]
  },
  "life_reflection": {
    "regrets": ["regret1", "regret2"],
    "proudest_moments": ["moment1", "moment2"],
    "unfulfilled_dreams": ["dream1", "dream2"]
  },
  "effects": {
    "happiness": <-10 to +10>,
    "relationships": [
      {
        "character_id": "uuid",
        "delta": <change>,
        "reason": "Why relationship changed with this transition"
      }
    ]
  }
}

Life stage transitions should feel significant and personal. Celebrate accomplishments, acknowledge limitations, maintain character continuity.
```

### Template: Character Death

```
You are processing a character's death and generating their legacy.

CHARACTER CONTEXT:
- Name: {{character_name}}
- Age at Death: {{age}}
- Life Stage: {{life_stage}}
- Cause of Death: {{cause_of_death}}

LIFE SUMMARY:
- Birth Cycle: {{birth_cycle}}
- Death Cycle: {{death_cycle}}
- Total Lifespan: {{lifespan_years}} years
- Final Attributes: {{attributes_json}}
- Traits: {{traits_list}}
- Positions Held: {{all_positions}}
- Major Achievements: {{achievements}}
- Key Relationships: {{relationships}}
- Legacy Metrics: {{legacy_metrics}}

WORLD IMPACT:
- Actions Taken: {{total_actions}}
- People Influenced: {{influenced_count}}
- Contributions: {{contributions_summary}}

INSTRUCTIONS:
Generate a meaningful obituary and legacy:

1. Summarize life story and major accomplishments
2. Assess lasting impact on world/community
3. Identify who will remember them and why
4. Determine inheritance and succession
5. Create narrative closure

Respond in JSON format:
{
  "obituary": {
    "headline": "One-line summary of life",
    "body": "3-4 paragraph obituary covering: early life, major accomplishments, relationships, circumstances of death, legacy",
    "notable_quotes": [
      "Memorable things character said/did"
    ]
  },
  "legacy": {
    "reputation_score": <final score>,
    "historical_significance": "forgotten|remembered|notable|famous|legendary",
    "remembered_for": [
      "Primary accomplishments/traits people remember"
    ],
    "lasting_impacts": [
      {
        "type": "policy|building|organization|cultural|technological",
        "description": "What they left behind",
        "duration": "temporary|ongoing|permanent"
      }
    ]
  },
  "inheritance": {
    "resources": {
      "economy": <amount to distribute>
    },
    "positions": [
      {
        "position_id": "uuid",
        "succession_method": "election|appointment|automatic",
        "suggested_successor": "character_id if applicable"
      }
    ],
    "relationships_affected": [
      {
        "character_id": "uuid",
        "relationship": "spouse|child|friend",
        "grief_impact": {
          "happiness": <-30 to -10>,
          "duration": <cycles>
        }
      }
    ]
  },
  "narrative_closure": "2-3 sentences providing emotional closure: final thoughts, peaceful/tragic nature of death, how community reacts"
}

Deaths should feel meaningful and create ripples in the world. Every life should matter, even if small in scope.
```

---

## Prompt Engineering Best Practices

### General Guidelines for All Templates

1. **Context Completeness**: Always provide sufficient context for LLM to make informed decisions
2. **Output Structure**: Use strict JSON schemas to ensure parseable responses
3. **Deterministic Ranges**: Specify numeric ranges (-20 to +20) to constrain outputs
4. **Narrative Quality**: Request specific length constraints (1-2 sentences, 2-3 paragraphs)
5. **Cause-and-Effect**: Instruct LLM to explain reasoning behind outcomes
6. **Consistency**: Reference existing game state to maintain continuity
7. **Validation**: Templates should produce outputs that fail fast if invalid

### Token Optimization

1. **Level 8 (Individual)**: ~1500-2000 tokens input, ~800-1200 tokens output
2. **Level 7 (Household)**: ~2500-3500 tokens input, ~600-900 tokens output
3. **Level 6 (Organization)**: ~3000-4000 tokens input, ~500-700 tokens output
4. **Level 5 (Nation)**: ~2000-3000 tokens input, ~300-500 tokens output
5. **Level 4+ (Cosmic)**: ~1000-1500 tokens input, ~200-300 tokens output

### Caching Strategy

All templates designed for prompt caching:
- Static schema/instructions in prefix (cacheable)
- Dynamic context in middle section (not cached)
- Consistent structure across similar queries

### Error Handling

Templates should instruct LLM to:
- Return null for optional fields rather than hallucinating
- Flag uncertainty with confidence scores
- Provide fallback values for failed generations
- Never break JSON schema

### Testing Recommendations

1. **Unit Test Each Template**: Validate JSON schema compliance
2. **Edge Case Testing**: Test extreme values, empty contexts, invalid states
3. **Consistency Testing**: Same input should produce similar outputs
4. **Performance Testing**: Monitor token usage and latency
5. **Quality Testing**: Human review of narrative quality and coherence

---

## Version History

- v1.0 (Cycle {{current_cycle}}): Initial template collection for hierarchical world simulation
- Templates aligned with SPECIFICATION.md v1.3, LIFECYCLE_AND_ROLES.md v1.0, WORLD_DYNAMICS.md v1.0

## Usage Notes

These templates should be:
1. Loaded into LLM service layer
2. Rendered with Handlebars or similar template engine
3. Cached at system/prompt level for cost optimization
4. Versioned alongside game balance changes
5. A/B tested for narrative quality improvements

For implementation details, see:
- `/database/schema_postgresql.sql` - Data structures
- `/docs/API_SPECIFICATION.md` - API integration
- `/docs/SPECIFICATION.md` - Core game mechanics
