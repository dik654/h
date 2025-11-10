-- ============================================================================
-- Hierarchical World Simulation - PostgreSQL Schema
-- ============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE TYPE hierarchy_level AS ENUM (
  'universe',
  'medium_universe',
  'small_universe',
  'solar_system',
  'planet',
  'nation',
  'organization',
  'household',
  'individual'
);

CREATE TYPE life_stage AS ENUM (
  'infant',
  'child',
  'adolescent',
  'young_adult',
  'middle_aged',
  'senior',
  'elderly'
);

CREATE TYPE action_type AS ENUM (
  'social',
  'economic',
  'political',
  'cultural',
  'scientific',
  'military'
);

CREATE TYPE position_type AS ENUM (
  'president',
  'minister',
  'legislator',
  'governor',
  'mayor',
  'judge',
  'ceo',
  'director',
  'manager',
  'team_lead',
  'worker',
  'general',
  'colonel',
  'captain',
  'professor',
  'researcher',
  'artist',
  'entrepreneur',
  'unemployed'
);

CREATE TYPE selection_method AS ENUM (
  'election',
  'appointment',
  'merit',
  'purchase',
  'competition',
  'inheritance'
);

CREATE TYPE economic_phase AS ENUM (
  'boom',
  'growth',
  'stable',
  'recession',
  'depression'
);

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  role VARCHAR(20) DEFAULT 'player' CHECK (role IN ('player', 'admin', 'observer'))
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

-- Entities table (all hierarchy levels)
CREATE TABLE entities (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  level hierarchy_level NOT NULL,
  name VARCHAR(255) NOT NULL,
  parent_id UUID REFERENCES entities(id) ON DELETE SET NULL,

  -- Metrics (JSONB for flexibility)
  metrics JSONB NOT NULL DEFAULT '{
    "economy": 50,
    "politics": 50,
    "culture": 50,
    "science": 50,
    "military": 50,
    "happiness": 50,
    "stability": 50,
    "population": 0
  }'::jsonb,

  -- Additional data by level
  metadata JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_entities_level ON entities(level);
CREATE INDEX idx_entities_parent ON entities(parent_id);
CREATE INDEX idx_entities_name ON entities USING gin(name gin_trgm_ops);
CREATE INDEX idx_entities_metrics ON entities USING gin(metrics);

-- Characters table (Level 8: Individual)
CREATE TABLE characters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,

  name VARCHAR(100) NOT NULL,
  age INTEGER NOT NULL DEFAULT 20,
  life_stage life_stage NOT NULL DEFAULT 'young_adult',

  birth_cycle INTEGER NOT NULL,
  death_cycle INTEGER,
  life_expectancy INTEGER DEFAULT 75,

  -- Household relation
  household_id UUID REFERENCES entities(id),
  household_role VARCHAR(50),

  -- Attributes (JSONB)
  attributes JSONB NOT NULL DEFAULT '{
    "physical": 50,
    "mental": 50,
    "social": 50,
    "creativity": 50,
    "leadership": 50,
    "science": 50,
    "economy": 50,
    "politics": 50,
    "military": 50,
    "culture": 50,
    "health": 100,
    "energy": 100,
    "stress": 0
  }'::jsonb,

  -- Traits
  traits JSONB DEFAULT '[]'::jsonb,

  -- Reputation
  reputation JSONB DEFAULT '{
    "overall": 50,
    "science": 50,
    "economy": 50,
    "politics": 50,
    "culture": 50
  }'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, entity_id)
);

CREATE INDEX idx_characters_user ON characters(user_id);
CREATE INDEX idx_characters_household ON characters(household_id);
CREATE INDEX idx_characters_age ON characters(age);
CREATE INDEX idx_characters_life_stage ON characters(life_stage);
CREATE INDEX idx_characters_traits ON characters USING gin(traits);

-- Social Positions table
CREATE TABLE social_positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(100) NOT NULL,
  position_type position_type NOT NULL,

  -- Belongs to
  organization_id UUID REFERENCES entities(id),
  nation_id UUID REFERENCES entities(id),
  level hierarchy_level NOT NULL,

  -- Constraints
  total_slots INTEGER NOT NULL DEFAULT 1,
  current_holders UUID[] DEFAULT ARRAY[]::UUID[],

  -- Requirements (JSONB)
  requirements JSONB DEFAULT '{
    "minAge": 18,
    "maxAge": null,
    "minLifeStage": "young_adult",
    "minAttributes": {},
    "requiredEducation": [],
    "requiredExperience": [],
    "citizenship": null
  }'::jsonb,

  -- Selection
  selection_method selection_method NOT NULL,
  term_length INTEGER, -- in cycles, null = indefinite
  next_election INTEGER, -- cycle number

  -- Powers and benefits (JSONB)
  powers JSONB DEFAULT '[]'::jsonb,
  benefits JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_positions_type ON social_positions(position_type);
CREATE INDEX idx_positions_org ON social_positions(organization_id);
CREATE INDEX idx_positions_nation ON social_positions(nation_id);
CREATE INDEX idx_positions_method ON social_positions(selection_method);

-- Character Positions (join table)
CREATE TABLE character_positions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
  position_id UUID REFERENCES social_positions(id) ON DELETE CASCADE,

  acquired_at_cycle INTEGER NOT NULL,
  term_end_cycle INTEGER,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(character_id, position_id)
);

CREATE INDEX idx_char_positions_char ON character_positions(character_id);
CREATE INDEX idx_char_positions_pos ON character_positions(position_id);

-- ============================================================================
-- SIMULATION TABLES
-- ============================================================================

-- Simulation Cycles
CREATE TABLE simulation_cycles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cycle_number INTEGER UNIQUE NOT NULL,

  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,

  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),

  -- Processing results by level (JSONB)
  processed_levels JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cycles_number ON simulation_cycles(cycle_number);
CREATE INDEX idx_cycles_status ON simulation_cycles(status);

-- Actions
CREATE TABLE actions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  character_id UUID REFERENCES characters(id) ON DELETE CASCADE,

  cycle_number INTEGER NOT NULL,
  action_type action_type NOT NULL,
  description TEXT NOT NULL,

  target_id UUID REFERENCES characters(id) ON DELETE SET NULL,

  -- Result (populated after processing)
  result JSONB,

  status VARCHAR(20) DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed')),

  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

CREATE INDEX idx_actions_user ON actions(user_id);
CREATE INDEX idx_actions_character ON actions(character_id);
CREATE INDEX idx_actions_cycle ON actions(cycle_number);
CREATE INDEX idx_actions_type ON actions(action_type);
CREATE INDEX idx_actions_status ON actions(status);

-- Interactions (between characters)
CREATE TABLE interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  initiator_id UUID REFERENCES characters(id) ON DELETE CASCADE,
  target_ids UUID[] NOT NULL,

  -- Context
  context_type VARCHAR(50) NOT NULL CHECK (context_type IN ('household', 'organization', 'nation', 'public')),
  context_id UUID REFERENCES entities(id),

  interaction_type VARCHAR(50) NOT NULL,
  description TEXT NOT NULL,

  cycle_number INTEGER NOT NULL,

  -- Result (populated after processing)
  result JSONB,

  status VARCHAR(20) DEFAULT 'queued' CHECK (status IN ('queued', 'processing', 'completed', 'failed')),

  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

CREATE INDEX idx_interactions_initiator ON interactions(initiator_id);
CREATE INDEX idx_interactions_context ON interactions(context_type, context_id);
CREATE INDEX idx_interactions_cycle ON interactions(cycle_number);
CREATE INDEX idx_interactions_status ON interactions(status);

-- ============================================================================
-- WORLD STATE TABLES
-- ============================================================================

-- World State (one row per cycle)
CREATE TABLE world_state (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cycle_number INTEGER UNIQUE NOT NULL,

  -- Climate
  climate JSONB NOT NULL DEFAULT '{
    "temperature": 0,
    "rainfall": 50,
    "seasonality": 50,
    "extremeEvents": 10
  }'::jsonb,

  -- Resources
  resources JSONB NOT NULL DEFAULT '{
    "food": 50,
    "water": 50,
    "energy": 50,
    "minerals": 50
  }'::jsonb,

  -- Economic phase
  economic_phase economic_phase DEFAULT 'stable',

  -- Technology level
  technology_level INTEGER DEFAULT 50,

  -- Ideology (JSONB)
  ideology JSONB DEFAULT '{
    "dominant": "mixed",
    "values": {
      "tradition": 50,
      "authority": 50,
      "materialism": 50,
      "science": 50
    }
  }'::jsonb,

  -- War status
  war_status JSONB DEFAULT '{
    "active": false,
    "participants": [],
    "intensity": 0
  }'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_world_state_cycle ON world_state(cycle_number);

-- Cultural Trends
CREATE TABLE cultural_trends (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  trend_type VARCHAR(50) NOT NULL CHECK (trend_type IN ('fashion', 'food', 'art', 'ideology', 'lifestyle')),

  strength INTEGER DEFAULT 50 CHECK (strength >= 0 AND strength <= 100),

  start_cycle INTEGER NOT NULL,
  peak_cycle INTEGER NOT NULL,
  end_cycle INTEGER,

  -- Favored/disfavored traits
  favored_traits TEXT[] DEFAULT ARRAY[]::TEXT[],
  disfavored_traits TEXT[] DEFAULT ARRAY[]::TEXT[],

  description TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_trends_cycle ON cultural_trends(start_cycle, end_cycle);
CREATE INDEX idx_trends_type ON cultural_trends(trend_type);
CREATE INDEX idx_trends_active ON cultural_trends(end_cycle) WHERE end_cycle IS NULL OR end_cycle > EXTRACT(EPOCH FROM NOW());

-- ============================================================================
-- EVENTS TABLES
-- ============================================================================

-- Game Events
CREATE TABLE game_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cycle_number INTEGER NOT NULL,

  event_type VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  significance VARCHAR(20) CHECK (significance IN ('low', 'medium', 'high', 'cosmic')),

  -- Affected entities
  affected_entities UUID[] DEFAULT ARRAY[]::UUID[],

  -- Event data (JSONB)
  data JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_events_cycle ON game_events(cycle_number);
CREATE INDEX idx_events_type ON game_events(event_type);
CREATE INDEX idx_events_significance ON game_events(significance);

-- Elections
CREATE TABLE elections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  position_id UUID REFERENCES social_positions(id) ON DELETE CASCADE,

  start_cycle INTEGER NOT NULL,
  end_cycle INTEGER,

  status VARCHAR(20) DEFAULT 'registration' CHECK (status IN ('registration', 'campaign', 'voting', 'counting', 'completed')),

  -- Candidates
  candidates UUID[] DEFAULT ARRAY[]::UUID[],

  -- Voters
  voters UUID[] DEFAULT ARRAY[]::UUID[],

  -- Results (JSONB)
  results JSONB,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_elections_position ON elections(position_id);
CREATE INDEX idx_elections_cycle ON elections(start_cycle, end_cycle);
CREATE INDEX idx_elections_status ON elections(status);

-- Election Votes
CREATE TABLE election_votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  election_id UUID REFERENCES elections(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES characters(id) ON DELETE CASCADE,
  candidate_id UUID REFERENCES characters(id) ON DELETE CASCADE,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(election_id, voter_id)
);

CREATE INDEX idx_votes_election ON election_votes(election_id);
CREATE INDEX idx_votes_voter ON election_votes(voter_id);
CREATE INDEX idx_votes_candidate ON election_votes(candidate_id);

-- ============================================================================
-- AGGREGATION RESULTS TABLES
-- ============================================================================

-- Household Aggregation Results
CREATE TABLE household_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  household_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  cycle_number INTEGER NOT NULL,

  summary TEXT,

  metrics JSONB NOT NULL,
  synergies JSONB DEFAULT '[]'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(household_id, cycle_number)
);

CREATE INDEX idx_household_results_cycle ON household_results(cycle_number);
CREATE INDEX idx_household_results_household ON household_results(household_id);

-- Organization Aggregation Results
CREATE TABLE organization_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  organization_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  cycle_number INTEGER NOT NULL,

  summary TEXT,

  metrics JSONB NOT NULL,
  events JSONB DEFAULT '[]'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(organization_id, cycle_number)
);

CREATE INDEX idx_org_results_cycle ON organization_results(cycle_number);
CREATE INDEX idx_org_results_org ON organization_results(organization_id);

-- Nation Aggregation Results
CREATE TABLE nation_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nation_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  cycle_number INTEGER NOT NULL,

  metrics JSONB NOT NULL,
  events JSONB DEFAULT '[]'::jsonb,
  diplomatic_changes JSONB DEFAULT '[]'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(nation_id, cycle_number)
);

CREATE INDEX idx_nation_results_cycle ON nation_results(cycle_number);
CREATE INDEX idx_nation_results_nation ON nation_results(nation_id);

-- ============================================================================
-- HISTORY TABLES
-- ============================================================================

-- Character History (lifecycle events)
CREATE TABLE character_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  character_id UUID REFERENCES characters(id) ON DELETE CASCADE,
  cycle_number INTEGER NOT NULL,

  event_type VARCHAR(50) NOT NULL, -- 'birth', 'life_stage_change', 'position_acquired', 'position_lost', 'death', etc.
  description TEXT,

  data JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_char_history_char ON character_history(character_id);
CREATE INDEX idx_char_history_cycle ON character_history(cycle_number);
CREATE INDEX idx_char_history_type ON character_history(event_type);

-- Entity History (metrics changes over time)
CREATE TABLE entity_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  cycle_number INTEGER NOT NULL,

  metrics JSONB NOT NULL,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_entity_history_entity ON entity_history(entity_id);
CREATE INDEX idx_entity_history_cycle ON entity_history(cycle_number);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_entities_updated_at BEFORE UPDATE ON entities
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_characters_updated_at BEFORE UPDATE ON characters
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_positions_updated_at BEFORE UPDATE ON social_positions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Active characters view
CREATE VIEW active_characters AS
SELECT
  c.*,
  u.username,
  e.name as entity_name,
  h.name as household_name
FROM characters c
JOIN users u ON c.user_id = u.id
JOIN entities e ON c.entity_id = e.id
LEFT JOIN entities h ON c.household_id = h.id
WHERE c.death_cycle IS NULL AND u.is_active = TRUE;

-- Current world state view
CREATE VIEW current_world_state AS
SELECT *
FROM world_state
ORDER BY cycle_number DESC
LIMIT 1;

-- Active cultural trends view
CREATE VIEW active_cultural_trends AS
SELECT *
FROM cultural_trends
WHERE end_cycle IS NULL OR end_cycle >= (SELECT MAX(cycle_number) FROM simulation_cycles);

-- Character with positions view
CREATE VIEW characters_with_positions AS
SELECT
  c.*,
  ARRAY_AGG(
    JSON_BUILD_OBJECT(
      'position_id', sp.id,
      'title', sp.title,
      'type', sp.position_type,
      'acquired_at', cp.acquired_at_cycle
    )
  ) FILTER (WHERE sp.id IS NOT NULL) as positions
FROM characters c
LEFT JOIN character_positions cp ON c.id = cp.character_id
LEFT JOIN social_positions sp ON cp.position_id = sp.id
GROUP BY c.id;

-- ============================================================================
-- INITIAL DATA
-- ============================================================================

-- Insert initial universe hierarchy (example)
INSERT INTO entities (level, name, parent_id, metadata) VALUES
  ('universe', 'The Cosmos', NULL, '{}'::jsonb);

-- Will be populated during initialization:
-- - Medium universes
-- - Small universes
-- - Solar systems
-- - Planets
-- - Nations
-- - Organizations
-- - Households

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE entities IS 'Hierarchical entities from universe to individual';
COMMENT ON TABLE characters IS 'Player characters (individuals)';
COMMENT ON TABLE social_positions IS 'Available social positions with limited slots';
COMMENT ON TABLE actions IS 'Individual character actions';
COMMENT ON TABLE interactions IS 'Multi-character interactions';
COMMENT ON TABLE world_state IS 'Global world state per cycle';
COMMENT ON TABLE cultural_trends IS 'Active cultural trends affecting characters';
COMMENT ON TABLE game_events IS 'Significant events in the world';
COMMENT ON TABLE elections IS 'Political elections for positions';
COMMENT ON TABLE household_results IS 'Aggregated household results per cycle';
COMMENT ON TABLE organization_results IS 'Aggregated organization results per cycle';
COMMENT ON TABLE nation_results IS 'Aggregated nation results per cycle';
