# API Specification

## Base URL
```
Development: http://localhost:3000/api/v1
Production: https://api.hierarchical-world.com/api/v1
```

## Authentication
All endpoints (except `/auth/*`) require JWT authentication.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

---

## 1. Authentication Endpoints

### POST /auth/register
Register a new user account.

**Request Body:**
```json
{
  "username": "string (3-50 chars, unique)",
  "email": "string (valid email, unique)",
  "password": "string (min 8 chars)"
}
```

**Response: 201 Created**
```json
{
  "user": {
    "id": "uuid",
    "username": "string",
    "email": "string",
    "created_at": "timestamp"
  },
  "token": "jwt_token"
}
```

**Errors:**
- 400: Validation error (username/email taken, weak password)
- 500: Server error

---

### POST /auth/login
Login with existing credentials.

**Request Body:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Response: 200 OK**
```json
{
  "user": {
    "id": "uuid",
    "username": "string",
    "email": "string",
    "last_login": "timestamp"
  },
  "token": "jwt_token"
}
```

**Errors:**
- 401: Invalid credentials
- 500: Server error

---

### GET /auth/me
Get current authenticated user info.

**Response: 200 OK**
```json
{
  "id": "uuid",
  "username": "string",
  "email": "string",
  "role": "player|admin|observer",
  "created_at": "timestamp",
  "last_login": "timestamp"
}
```

---

### POST /auth/logout
Logout (blacklist current token).

**Response: 200 OK**
```json
{
  "message": "Logged out successfully"
}
```

---

## 2. Character Endpoints

### POST /characters
Create a new character.

**Request Body:**
```json
{
  "name": "string (max 100 chars)",
  "household_id": "uuid (optional)",
  "traits": ["string"] (optional, max 5)
}
```

**Response: 201 Created**
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "entity_id": "uuid",
  "name": "string",
  "age": 20,
  "life_stage": "young_adult",
  "household_id": "uuid",
  "attributes": {
    "physical": 50,
    "mental": 50,
    "science": 50,
    ...
  },
  "traits": ["adaptable", "tech_savvy"],
  "created_at": "timestamp"
}
```

**Errors:**
- 400: Invalid data, user already has max characters (5)
- 404: Household not found

---

### GET /characters/:id
Get character details.

**Response: 200 OK**
```json
{
  "id": "uuid",
  "name": "string",
  "age": 25,
  "life_stage": "young_adult",
  "household": {
    "id": "uuid",
    "name": "Smith Family",
    "role": "parent"
  },
  "attributes": { ... },
  "traits": [...],
  "positions": [
    {
      "id": "uuid",
      "title": "Researcher",
      "type": "researcher",
      "acquired_at_cycle": 1250
    }
  ],
  "reputation": { ... },
  "updated_at": "timestamp"
}
```

**Errors:**
- 403: Not authorized to view this character
- 404: Character not found

---

### GET /characters
Get all characters for current user.

**Query Params:**
- `include_positions` (bool): Include position details
- `include_household` (bool): Include household details

**Response: 200 OK**
```json
{
  "characters": [
    {
      "id": "uuid",
      "name": "string",
      "age": 25,
      "life_stage": "young_adult",
      ...
    }
  ],
  "total": 3
}
```

---

### PUT /characters/:id
Update character (limited fields).

**Request Body:**
```json
{
  "household_id": "uuid (optional)"
}
```

**Response: 200 OK**
```json
{
  "id": "uuid",
  "name": "string",
  ...updated fields...
}
```

**Errors:**
- 403: Not authorized
- 404: Character or household not found

---

### GET /characters/:id/stats
Get character statistics.

**Query Params:**
- `cycles` (int, default 100): Number of cycles to analyze

**Response: 200 OK**
```json
{
  "character_id": "uuid",
  "cycles_analyzed": 100,
  "total_actions": 245,
  "actions_by_type": {
    "scientific": 120,
    "social": 80,
    "economic": 45
  },
  "avg_impact": {
    "science": 8.5,
    "reputation": 3.2
  },
  "achievements": [
    {
      "type": "discovery",
      "count": 5,
      "latest_cycle": 1350
    }
  ]
}
```

---

### GET /characters/:id/history
Get character lifecycle history.

**Query Params:**
- `limit` (int, default 50)
- `event_type` (string, optional): Filter by event type

**Response: 200 OK**
```json
{
  "character_id": "uuid",
  "events": [
    {
      "cycle_number": 1350,
      "event_type": "position_acquired",
      "description": "Became Team Lead at Tech Institute",
      "data": { "position_id": "uuid" },
      "timestamp": "timestamp"
    },
    {
      "cycle_number": 1200,
      "event_type": "life_stage_change",
      "description": "Entered middle age",
      ...
    }
  ],
  "total": 15
}
```

---

## 3. Action Endpoints

### POST /actions
Submit a new action.

**Request Body:**
```json
{
  "character_id": "uuid",
  "action_type": "scientific|social|economic|political|cultural|military",
  "description": "string (max 500 chars)",
  "target_id": "uuid (optional, for targeted actions)"
}
```

**Response: 201 Created**
```json
{
  "id": "uuid",
  "character_id": "uuid",
  "cycle_number": 1351,
  "action_type": "scientific",
  "description": "Research new energy technology",
  "status": "queued",
  "created_at": "timestamp"
}
```

**Errors:**
- 400: Invalid action type, description too long, character on cooldown
- 403: Not authorized to control this character
- 404: Character or target not found

---

### GET /actions
Get action history for current user.

**Query Params:**
- `character_id` (uuid, optional): Filter by character
- `cycle_start` (int, optional): Start cycle
- `cycle_end` (int, optional): End cycle
- `status` (string, optional): queued|processing|completed|failed
- `limit` (int, default 50, max 200)
- `offset` (int, default 0)

**Response: 200 OK**
```json
{
  "actions": [
    {
      "id": "uuid",
      "character_id": "uuid",
      "character_name": "Alice",
      "cycle_number": 1350,
      "action_type": "scientific",
      "description": "Research...",
      "status": "completed",
      "result": {
        "narrative": "Alice discovered...",
        "metrics": {
          "character": { "science": +10 },
          "household": { "wealth": +3 }
        }
      },
      "created_at": "timestamp",
      "processed_at": "timestamp"
    }
  ],
  "total": 245,
  "page": {
    "limit": 50,
    "offset": 0
  }
}
```

---

### GET /actions/:id
Get specific action details.

**Response: 200 OK**
```json
{
  "id": "uuid",
  "character": {
    "id": "uuid",
    "name": "Alice"
  },
  "cycle_number": 1350,
  "action_type": "scientific",
  "description": "Research new energy technology",
  "status": "completed",
  "result": {
    "narrative": "...",
    "metrics": { ... },
    "events": [ ... ],
    "tags": ["discovery", "breakthrough"]
  },
  "created_at": "timestamp",
  "processed_at": "timestamp"
}
```

**Errors:**
- 403: Not authorized to view this action
- 404: Action not found

---

## 4. Interaction Endpoints

### POST /interactions
Submit a new interaction.

**Request Body:**
```json
{
  "initiator_id": "uuid",
  "target_ids": ["uuid", "uuid"],
  "context_type": "household|organization|nation|public",
  "context_id": "uuid",
  "interaction_type": "string",
  "description": "string (max 500 chars)"
}
```

**Response: 201 Created**
```json
{
  "id": "uuid",
  "initiator_id": "uuid",
  "target_ids": ["uuid", "uuid"],
  "context_type": "household",
  "cycle_number": 1351,
  "status": "queued",
  "created_at": "timestamp"
}
```

**Errors:**
- 400: Invalid data, targets not in same context
- 403: Not authorized
- 404: Characters or context not found

---

## 5. Entity/Hierarchy Endpoints

### GET /entities/:id
Get entity details.

**Response: 200 OK**
```json
{
  "id": "uuid",
  "level": "nation",
  "name": "Korea",
  "parent": {
    "id": "uuid",
    "name": "Earth",
    "level": "planet"
  },
  "metrics": {
    "economy": 8500,
    "science": 720,
    "military": 650,
    ...
  },
  "children_count": 150,
  "metadata": { ... },
  "updated_at": "timestamp"
}
```

---

### GET /entities/:id/children
Get child entities.

**Query Params:**
- `limit` (int, default 50)
- `offset` (int, default 0)

**Response: 200 OK**
```json
{
  "entity_id": "uuid",
  "entity_name": "Korea",
  "children": [
    {
      "id": "uuid",
      "name": "Samsung Corp",
      "level": "organization",
      "metrics": { ... }
    }
  ],
  "total": 150,
  "page": { ... }
}
```

---

### GET /hierarchy
Get full hierarchy tree (cached, limited depth).

**Query Params:**
- `from_level` (string, default "planet"): Start level
- `max_depth` (int, default 3): Max depth from start level

**Response: 200 OK**
```json
{
  "root": {
    "id": "uuid",
    "name": "Earth",
    "level": "planet",
    "children": [
      {
        "id": "uuid",
        "name": "Korea",
        "level": "nation",
        "children": [...]
      }
    ]
  }
}
```

---

## 6. Position Endpoints

### GET /positions
Get available positions.

**Query Params:**
- `level` (string, optional): Filter by level
- `position_type` (string, optional): Filter by type
- `has_vacancies` (bool, optional): Only show positions with open slots

**Response: 200 OK**
```json
{
  "positions": [
    {
      "id": "uuid",
      "title": "President",
      "position_type": "president",
      "level": "nation",
      "nation_id": "uuid",
      "nation_name": "Korea",
      "total_slots": 1,
      "filled_slots": 1,
      "current_holders": [
        {
          "character_id": "uuid",
          "character_name": "John Doe",
          "term_end_cycle": 1500
        }
      ],
      "requirements": {
        "minAge": 35,
        "maxAge": 75,
        "minAttributes": { "politics": 60 }
      },
      "selection_method": "election",
      "next_election": 1500
    }
  ],
  "total": 50
}
```

---

### GET /positions/:id
Get position details.

**Response: 200 OK**
```json
{
  "id": "uuid",
  "title": "President",
  "position_type": "president",
  "requirements": { ... },
  "current_holders": [ ... ],
  "powers": [
    "appoint_ministers",
    "propose_laws",
    "declare_war"
  ],
  "benefits": {
    "salary": 1000,
    "reputation_bonus": 50
  },
  "selection_method": "election",
  "term_length": 120,
  "next_election": 1500
}
```

---

### POST /positions/:id/apply
Apply for a position (if applicable).

**Request Body:**
```json
{
  "character_id": "uuid",
  "manifesto": "string (for elections, optional)"
}
```

**Response: 201 Created**
```json
{
  "message": "Application submitted",
  "application_id": "uuid",
  "position_id": "uuid",
  "character_id": "uuid",
  "status": "pending"
}
```

**Errors:**
- 400: Does not meet requirements, position full
- 403: Not authorized
- 404: Position or character not found

---

## 7. Simulation Endpoints

### GET /simulation/status
Get current simulation status.

**Response: 200 OK**
```json
{
  "current_cycle": 1351,
  "cycle_status": "action_submission",
  "next_cycle_start": "timestamp",
  "time_until_next_cycle": 540,
  "active_users": 1250,
  "pending_actions": 3200
}
```

---

### GET /simulation/cycles
Get cycle history.

**Query Params:**
- `limit` (int, default 10, max 100)
- `offset` (int, default 0)

**Response: 200 OK**
```json
{
  "cycles": [
    {
      "cycle_number": 1350,
      "start_time": "timestamp",
      "end_time": "timestamp",
      "duration_ms": 285000,
      "status": "completed",
      "stats": {
        "total_actions": 3150,
        "active_users": 1245,
        "llm_queries": 1580,
        "cache_hit_rate": 0.48
      }
    }
  ],
  "total": 1350
}
```

---

### GET /simulation/cycles/:cycle_number
Get specific cycle details.

**Response: 200 OK**
```json
{
  "cycle_number": 1350,
  "start_time": "timestamp",
  "end_time": "timestamp",
  "status": "completed",
  "stats": {
    "total_actions": 3150,
    "total_interactions": 850,
    "active_users": 1245,
    "level8": {
      "processed": 3150,
      "llm_queries": 3150,
      "cache_hits": 1512,
      "total_tokens": 2520000,
      "avg_processing_time_ms": 2850
    },
    "level7": { ... },
    ...
  },
  "major_events": [
    {
      "type": "discovery",
      "description": "New energy technology discovered",
      "significance": "high"
    }
  ]
}
```

---

## 8. World State Endpoints

### GET /world/state
Get current world state.

**Response: 200 OK**
```json
{
  "cycle_number": 1351,
  "climate": {
    "temperature": 2.5,
    "rainfall": 45,
    "extremeEvents": 35
  },
  "resources": {
    "food": 35,
    "water": 60,
    "energy": 70
  },
  "economic_phase": "recession",
  "technology_level": 75,
  "ideology": {
    "dominant": "environmentalism",
    "values": {
      "tradition": 35,
      "authority": 45,
      "materialism": 40,
      "science": 75
    }
  },
  "war_status": {
    "active": false
  }
}
```

---

### GET /world/trends
Get active cultural trends.

**Response: 200 OK**
```json
{
  "trends": [
    {
      "id": "uuid",
      "name": "Vegetarian Movement",
      "type": "food",
      "strength": 75,
      "start_cycle": 1200,
      "peak_cycle": 1300,
      "end_cycle": 1400,
      "favored_traits": ["environmentalist", "health_conscious"],
      "disfavored_traits": ["traditional_carnivore"],
      "description": "..."
    }
  ],
  "total": 5
}
```

---

### GET /world/events
Get recent world events.

**Query Params:**
- `limit` (int, default 50)
- `significance` (string, optional): low|medium|high|cosmic
- `cycle_start` (int, optional)

**Response: 200 OK**
```json
{
  "events": [
    {
      "id": "uuid",
      "cycle_number": 1350,
      "event_type": "climate_disaster",
      "description": "Severe drought hits agricultural regions",
      "significance": "high",
      "affected_entities": ["uuid1", "uuid2"],
      "timestamp": "timestamp"
    }
  ],
  "total": 120
}
```

---

## 9. Admin Endpoints

### POST /admin/entities
Create new entity (admin only).

**Request Body:**
```json
{
  "level": "organization",
  "name": "New Tech Corp",
  "parent_id": "uuid",
  "initial_metrics": { ... }
}
```

**Response: 201 Created**

---

### POST /admin/simulation/trigger-cycle
Manually trigger simulation cycle (admin only).

**Response: 200 OK**
```json
{
  "message": "Cycle triggered",
  "cycle_number": 1352
}
```

---

### GET /admin/analytics
Get system analytics (admin only).

**Response: 200 OK**
```json
{
  "users": {
    "total": 5000,
    "active_last_7_days": 1200,
    "retention_d7": 0.35
  },
  "actions": {
    "total": 500000,
    "avg_per_user": 100
  },
  "llm_usage": {
    "total_queries": 450000,
    "total_tokens": 360000000,
    "cache_hit_rate": 0.52,
    "estimated_cost": 10800
  }
}
```

---

## WebSocket Events

### Connection
```
ws://localhost:3000/ws?token=<jwt_token>
```

### Events from Server

**cycle_start**
```json
{
  "event": "cycle_start",
  "data": {
    "cycle_number": 1351,
    "start_time": "timestamp"
  }
}
```

**cycle_complete**
```json
{
  "event": "cycle_complete",
  "data": {
    "cycle_number": 1351,
    "duration_ms": 285000,
    "your_actions_processed": 3
  }
}
```

**action_result**
```json
{
  "event": "action_result",
  "data": {
    "action_id": "uuid",
    "character_id": "uuid",
    "result": {
      "narrative": "...",
      "metrics": { ... }
    }
  }
}
```

**world_change**
```json
{
  "event": "world_change",
  "data": {
    "type": "new_trend",
    "trend": {
      "name": "Digital Nomad Lifestyle",
      "strength": 60
    }
  }
}
```

**notification**
```json
{
  "event": "notification",
  "data": {
    "type": "position_change",
    "title": "Elected President!",
    "message": "You have been elected President of Korea!"
  }
}
```

---

## Rate Limiting

- Authentication endpoints: 5 requests per minute
- Action submission: 10 requests per minute per user
- General API: 60 requests per minute per user
- WebSocket: 1 connection per user

---

## Error Response Format

All errors follow this format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {
      "field": "Additional error details"
    }
  }
}
```

**Common Error Codes:**
- `VALIDATION_ERROR`: Request validation failed
- `NOT_FOUND`: Resource not found
- `UNAUTHORIZED`: Authentication required
- `FORBIDDEN`: Insufficient permissions
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `INTERNAL_ERROR`: Server error
