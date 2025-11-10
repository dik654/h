# Frontend Architecture

This document defines the complete frontend architecture for the hierarchical world simulation game.

## Table of Contents

1. [Technology Stack](#technology-stack)
2. [State Management](#state-management)
3. [Component Hierarchy](#component-hierarchy)
4. [Core Components](#core-components)
5. [Visualization Components](#visualization-components)
6. [Data Flow](#data-flow)
7. [Routing Structure](#routing-structure)
8. [Performance Optimization](#performance-optimization)
9. [Testing Strategy](#testing-strategy)

---

## Technology Stack

### Core Framework
- **React 18.2+** with TypeScript
- **Vite** for build tooling
- **React Router v6** for routing

### State Management
- **Zustand** for global state (lightweight, minimal boilerplate)
- **React Query** for server state management and caching
- **Jotai** for atomic component-level state

### Visualization
- **Three.js + React Three Fiber** for 3D cosmic/planetary visualization
- **D3.js** for data visualization (charts, graphs, hierarchies)
- **Recharts** for standard charts (metrics over time)
- **vis-network** for relationship graphs

### UI Components
- **Tailwind CSS** for styling
- **Headless UI** for accessible components
- **Framer Motion** for animations
- **React Spring** for physics-based animations

### Real-time Communication
- **Socket.IO Client** for WebSocket connections
- **EventSource** for SSE fallback

### Utilities
- **date-fns** for date formatting
- **zod** for runtime validation
- **react-hook-form** for forms
- **react-virtuoso** for virtual scrolling (long lists)

---

## State Management

### Global State (Zustand)

```typescript
// stores/useAuthStore.ts
interface AuthState {
  user: User | null;
  character: Character | null;
  token: string | null;
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => void;
  updateCharacter: (character: Character) => void;
}

// stores/useSimulationStore.ts
interface SimulationState {
  currentCycle: number;
  cycleStatus: 'idle' | 'processing' | 'completed';
  cycleProgress: number; // 0-100
  nextCycleTimestamp: number;
  subscribeToSimulation: () => void;
  unsubscribeFromSimulation: () => void;
}

// stores/useUIStore.ts
interface UIState {
  sidebarOpen: boolean;
  currentView: 'individual' | 'household' | 'organization' | 'nation' | 'planet' | 'cosmic';
  selectedEntity: string | null;
  notifications: Notification[];
  toggleSidebar: () => void;
  setView: (view: string) => void;
  selectEntity: (id: string) => void;
  addNotification: (notification: Notification) => void;
  dismissNotification: (id: string) => void;
}

// stores/useHierarchyStore.ts
interface HierarchyState {
  currentLevel: number; // 1-8
  entityPath: Entity[]; // Path from Universe to current entity
  navigateToEntity: (entityId: string) => Promise<void>;
  navigateUp: () => void;
  navigateDown: (childId: string) => void;
  breadcrumbs: Entity[];
}
```

### Server State (React Query)

```typescript
// hooks/queries/useCharacterQuery.ts
export function useCharacterQuery(characterId: string) {
  return useQuery({
    queryKey: ['character', characterId],
    queryFn: () => api.getCharacter(characterId),
    staleTime: 30000, // 30 seconds
    cacheTime: 300000, // 5 minutes
  });
}

// hooks/queries/useActionsQuery.ts
export function useActionsQuery(characterId: string, limit: number = 20) {
  return useQuery({
    queryKey: ['actions', characterId, limit],
    queryFn: () => api.getActions(characterId, limit),
    staleTime: 10000,
  });
}

// hooks/queries/useEntityQuery.ts
export function useEntityQuery(entityId: string) {
  return useQuery({
    queryKey: ['entity', entityId],
    queryFn: () => api.getEntity(entityId),
    staleTime: 60000, // Entities change slowly
  });
}

// hooks/queries/useHierarchyQuery.ts
export function useHierarchyQuery(entityId: string) {
  return useQuery({
    queryKey: ['hierarchy', entityId],
    queryFn: () => api.getHierarchy(entityId),
    staleTime: 120000, // 2 minutes
  });
}

// hooks/mutations/useSubmitAction.ts
export function useSubmitAction() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (action: ActionSubmit) => api.submitAction(action),
    onSuccess: (data, variables) => {
      // Invalidate relevant queries
      queryClient.invalidateQueries(['actions', variables.characterId]);
      queryClient.invalidateQueries(['character', variables.characterId]);
    },
  });
}
```

### Atomic State (Jotai)

```typescript
// atoms/filterAtoms.ts
export const actionFilterAtom = atom<ActionFilter>({
  type: 'all',
  startCycle: null,
  endCycle: null,
});

export const metricTimeRangeAtom = atom<TimeRange>({
  start: Date.now() - 30 * 24 * 60 * 60 * 1000, // 30 days ago
  end: Date.now(),
});

// atoms/uiAtoms.ts
export const selectedCharacterAtom = atom<string | null>(null);
export const hoveredEntityAtom = atom<string | null>(null);
export const modalOpenAtom = atom<boolean>(false);
```

---

## Component Hierarchy

```
App
├── AuthProvider
│   └── SocketProvider
│       └── Router
│           ├── LoginPage
│           ├── CharacterCreationPage
│           └── MainLayout
│               ├── TopBar
│               │   ├── CycleIndicator
│               │   ├── NotificationBell
│               │   └── UserMenu
│               ├── Sidebar
│               │   ├── NavigationMenu
│               │   ├── HierarchyExplorer
│               │   └── QuickStats
│               ├── MainContent
│               │   └── Routes
│               │       ├── /dashboard → DashboardPage
│               │       ├── /character/:id → CharacterPage
│               │       ├── /entity/:level/:id → EntityPage
│               │       ├── /cosmos → CosmosVisualizationPage
│               │       ├── /actions → ActionsPage
│               │       ├── /positions → PositionsPage
│               │       └── /history → HistoryPage
│               └── FloatingActionButton (submit action)
```

---

## Core Components

### TopBar Component

**Path**: `src/components/layout/TopBar.tsx`

```typescript
interface TopBarProps {
  className?: string;
}

export function TopBar({ className }: TopBarProps) {
  const { currentCycle, cycleStatus, cycleProgress } = useSimulationStore();
  const { notifications } = useUIStore();
  const { character } = useAuthStore();

  return (
    <header className={cn("top-bar", className)}>
      <div className="left-section">
        <Logo />
        <CycleIndicator
          cycle={currentCycle}
          status={cycleStatus}
          progress={cycleProgress}
        />
      </div>

      <div className="center-section">
        <SearchBar placeholder="Search entities, characters, events..." />
      </div>

      <div className="right-section">
        <NotificationBell
          count={notifications.length}
          notifications={notifications}
        />
        <CharacterAvatar character={character} />
        <UserMenu />
      </div>
    </header>
  );
}
```

**Subcomponents**:

```typescript
// CycleIndicator.tsx
interface CycleIndicatorProps {
  cycle: number;
  status: 'idle' | 'processing' | 'completed';
  progress: number;
}

export function CycleIndicator({ cycle, status, progress }: CycleIndicatorProps) {
  const timeUntilNextCycle = useTimeUntilNextCycle();

  return (
    <div className="cycle-indicator">
      <div className="cycle-number">Cycle {cycle}</div>
      <div className="cycle-status">
        {status === 'processing' && (
          <>
            <Spinner size="sm" />
            <span>Processing... {progress}%</span>
          </>
        )}
        {status === 'idle' && (
          <span>Next cycle in {formatDuration(timeUntilNextCycle)}</span>
        )}
      </div>
    </div>
  );
}

// NotificationBell.tsx
interface NotificationBellProps {
  count: number;
  notifications: Notification[];
}

export function NotificationBell({ count, notifications }: NotificationBellProps) {
  const [open, setOpen] = useState(false);
  const { dismissNotification } = useUIStore();

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger>
        <button className="notification-bell">
          <BellIcon />
          {count > 0 && <Badge>{count}</Badge>}
        </button>
      </PopoverTrigger>
      <PopoverContent>
        <NotificationList
          notifications={notifications}
          onDismiss={dismissNotification}
        />
      </PopoverContent>
    </Popover>
  );
}
```

### Sidebar Component

**Path**: `src/components/layout/Sidebar.tsx`

```typescript
export function Sidebar() {
  const { sidebarOpen } = useUIStore();
  const { character } = useAuthStore();
  const { entityPath } = useHierarchyStore();

  return (
    <aside className={cn("sidebar", { open: sidebarOpen })}>
      <NavigationMenu />

      <Divider />

      <HierarchyExplorer
        currentPath={entityPath}
        characterEntity={character?.household}
      />

      <Divider />

      <QuickStats character={character} />
    </aside>
  );
}
```

**Subcomponents**:

```typescript
// HierarchyExplorer.tsx
interface HierarchyExplorerProps {
  currentPath: Entity[];
  characterEntity: string;
}

export function HierarchyExplorer({ currentPath, characterEntity }: HierarchyExplorerProps) {
  const { navigateToEntity, navigateUp } = useHierarchyStore();

  return (
    <div className="hierarchy-explorer">
      <h3>Your Location</h3>
      <Breadcrumbs path={currentPath} onNavigate={navigateToEntity} />

      <EntityTree
        rootId={characterEntity}
        expandedLevels={2}
        onSelect={navigateToEntity}
      />

      <button onClick={navigateUp} disabled={currentPath.length <= 1}>
        <ArrowUpIcon /> View Parent Entity
      </button>
    </div>
  );
}

// QuickStats.tsx
interface QuickStatsProps {
  character: Character;
}

export function QuickStats({ character }: QuickStatsProps) {
  const stats = [
    { label: 'Age', value: character.age, color: 'blue' },
    { label: 'Reputation', value: character.reputation.overall, max: 100, color: 'green' },
    { label: 'Happiness', value: character.metrics.happiness, max: 100, color: 'yellow' },
    { label: 'Energy', value: character.metrics.energy, max: 100, color: 'red' },
  ];

  return (
    <div className="quick-stats">
      <h3>Quick Stats</h3>
      {stats.map(stat => (
        <StatBar key={stat.label} {...stat} />
      ))}
    </div>
  );
}
```

### DashboardPage

**Path**: `src/pages/DashboardPage.tsx`

```typescript
export function DashboardPage() {
  const { character } = useAuthStore();
  const { data: recentActions } = useActionsQuery(character.id, 10);
  const { data: household } = useEntityQuery(character.householdId);
  const { data: organization } = useEntityQuery(character.organizationId);

  return (
    <div className="dashboard-page">
      <PageHeader
        title={`Welcome, ${character.name}`}
        subtitle={`${character.life_stage} • Cycle ${character.current_cycle}`}
      />

      <div className="dashboard-grid">
        {/* Character Overview */}
        <Card className="character-overview">
          <CharacterCard character={character} detailed />
        </Card>

        {/* Recent Actions */}
        <Card className="recent-actions">
          <CardHeader>
            <h2>Recent Actions</h2>
            <Link to="/actions">View All</Link>
          </CardHeader>
          <ActionTimeline actions={recentActions} limit={5} />
        </Card>

        {/* Metrics Over Time */}
        <Card className="metrics-chart">
          <CardHeader>
            <h2>Metrics Trend</h2>
          </CardHeader>
          <MetricsChart
            characterId={character.id}
            metrics={['happiness', 'reputation', 'economy']}
            timeRange={{ cycles: 100 }}
          />
        </Card>

        {/* Household Summary */}
        <Card className="household-summary">
          <EntitySummaryCard
            entity={household}
            linkTo={`/entity/household/${household.id}`}
          />
        </Card>

        {/* Organization Summary */}
        <Card className="organization-summary">
          <EntitySummaryCard
            entity={organization}
            linkTo={`/entity/organization/${organization.id}`}
          />
        </Card>

        {/* Active Positions */}
        <Card className="active-positions">
          <CardHeader>
            <h2>Your Positions</h2>
          </CardHeader>
          <PositionList positions={character.positions} />
        </Card>

        {/* Upcoming Events */}
        <Card className="upcoming-events">
          <CardHeader>
            <h2>Upcoming Events</h2>
          </CardHeader>
          <EventList
            entityId={character.householdId}
            filter={{ upcoming: true }}
            limit={5}
          />
        </Card>
      </div>

      <FloatingActionButton
        actions={[
          { label: 'Submit Action', icon: PlusIcon, onClick: () => openActionModal() },
          { label: 'View Hierarchy', icon: TreeIcon, onClick: () => navigate('/cosmos') },
        ]}
      />
    </div>
  );
}
```

### CharacterPage

**Path**: `src/pages/CharacterPage.tsx`

```typescript
export function CharacterPage() {
  const { characterId } = useParams();
  const { data: character, isLoading } = useCharacterQuery(characterId);
  const { data: actions } = useActionsQuery(characterId, 50);
  const { data: relationships } = useRelationshipsQuery(characterId);

  if (isLoading) return <LoadingSpinner />;
  if (!character) return <NotFound />;

  return (
    <div className="character-page">
      <PageHeader
        title={character.name}
        subtitle={`${character.age} years • ${character.life_stage}`}
        breadcrumbs={[
          { label: 'Dashboard', href: '/dashboard' },
          { label: character.name },
        ]}
      />

      <Tabs defaultValue="overview">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="actions">Actions</TabsTrigger>
          <TabsTrigger value="relationships">Relationships</TabsTrigger>
          <TabsTrigger value="positions">Positions</TabsTrigger>
          <TabsTrigger value="history">Life History</TabsTrigger>
        </TabsList>

        <TabsContent value="overview">
          <div className="character-overview-grid">
            <AttributesCard attributes={character.attributes} />
            <TraitsCard traits={character.traits} worldState={currentWorldState} />
            <MetricsCard metrics={character.metrics} />
            <ReputationCard reputation={character.reputation} />
            <LifeStageCard character={character} />
          </div>
        </TabsContent>

        <TabsContent value="actions">
          <ActionFilters />
          <ActionTimeline actions={actions} detailed />
        </TabsContent>

        <TabsContent value="relationships">
          <RelationshipGraph
            characterId={characterId}
            relationships={relationships}
            interactive
          />
          <RelationshipList relationships={relationships} />
        </TabsContent>

        <TabsContent value="positions">
          <CurrentPositions positions={character.positions} />
          <PositionHistory characterId={characterId} />
          <AvailablePositions characterId={characterId} />
        </TabsContent>

        <TabsContent value="history">
          <LifeTimeline characterId={characterId} />
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

### EntityPage

**Path**: `src/pages/EntityPage.tsx`

```typescript
export function EntityPage() {
  const { level, entityId } = useParams();
  const { data: entity, isLoading } = useEntityQuery(entityId);
  const { data: children } = useEntityChildrenQuery(entityId);
  const { data: cycleHistory } = useEntityHistoryQuery(entityId, { cycles: 100 });

  if (isLoading) return <LoadingSpinner />;
  if (!entity) return <NotFound />;

  return (
    <div className="entity-page">
      <PageHeader
        title={entity.name}
        subtitle={`Level ${level}: ${entity.level}`}
        breadcrumbs={getBreadcrumbs(entity)}
      />

      <Tabs defaultValue="overview">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="structure">Structure</TabsTrigger>
          <TabsTrigger value="metrics">Metrics</TabsTrigger>
          <TabsTrigger value="events">Events</TabsTrigger>
          <TabsTrigger value="positions">Leadership</TabsTrigger>
        </TabsList>

        <TabsContent value="overview">
          <div className="entity-overview-grid">
            <EntityInfoCard entity={entity} />
            <EntityMetricsCard metrics={entity.metrics} />
            <PopulationCard entity={entity} />
            <RecentEventsCard entityId={entityId} limit={10} />
          </div>
        </TabsContent>

        <TabsContent value="structure">
          {level >= 6 && (
            <OrganizationChart
              entityId={entityId}
              depth={2}
              interactive
            />
          )}
          <ChildEntitiesList
            children={children}
            level={level}
            sortBy="population"
          />
        </TabsContent>

        <TabsContent value="metrics">
          <MetricsComparison
            entity={entity}
            compareWith="siblings" // or "global_average"
          />
          <MetricsTimeSeriesChart
            entityId={entityId}
            metrics={['economy', 'politics', 'culture', 'science', 'military', 'happiness']}
            timeRange={{ cycles: 500 }}
          />
          <MetricsBreakdown entity={entity} />
        </TabsContent>

        <TabsContent value="events">
          <EventTimeline entityId={entityId} />
          <EventFilters />
        </TabsContent>

        <TabsContent value="positions">
          <LeadershipCard entity={entity} />
          <PositionHolders entityId={entityId} />
          <UpcomingElections entityId={entityId} />
        </TabsContent>
      </Tabs>
    </div>
  );
}
```

### ActionSubmitModal

**Path**: `src/components/actions/ActionSubmitModal.tsx`

```typescript
interface ActionSubmitModalProps {
  characterId: string;
  open: boolean;
  onClose: () => void;
}

export function ActionSubmitModal({ characterId, open, onClose }: ActionSubmitModalProps) {
  const { character } = useAuthStore();
  const { data: worldState } = useWorldStateQuery();
  const submitAction = useSubmitAction();

  const form = useForm<ActionSubmit>({
    defaultValues: {
      character_id: characterId,
      action_type: 'social',
      description: '',
    },
  });

  const selectedType = form.watch('action_type');
  const relevantTraits = getRelevantTraits(character.traits, selectedType, worldState);

  const onSubmit = async (data: ActionSubmit) => {
    try {
      await submitAction.mutateAsync(data);
      toast.success('Action submitted successfully!');
      onClose();
      form.reset();
    } catch (error) {
      toast.error('Failed to submit action');
    }
  };

  return (
    <Modal open={open} onClose={onClose}>
      <ModalHeader>
        <h2>Submit Action</h2>
        <p>Choose an action for {character.name}</p>
      </ModalHeader>

      <Form {...form}>
        <form onSubmit={form.handleSubmit(onSubmit)}>
          <FormField name="action_type">
            <FormLabel>Action Type</FormLabel>
            <Select>
              <SelectOption value="scientific">Scientific Research</SelectOption>
              <SelectOption value="social">Social Interaction</SelectOption>
              <SelectOption value="economic">Economic Activity</SelectOption>
              <SelectOption value="political">Political Action</SelectOption>
              <SelectOption value="cultural">Cultural Pursuit</SelectOption>
              <SelectOption value="military">Military Action</SelectOption>
            </Select>
          </FormField>

          <FormField name="description">
            <FormLabel>Action Description</FormLabel>
            <Textarea
              placeholder="Describe what your character wants to do..."
              maxLength={500}
              rows={4}
            />
            <FormHelp>
              Be specific. Better descriptions lead to better outcomes.
            </FormHelp>
          </FormField>

          <FormField name="target_id">
            <FormLabel>Target (Optional)</FormLabel>
            <CharacterSearch
              placeholder="Select a character to interact with..."
              onSelect={(id) => form.setValue('target_id', id)}
            />
          </FormField>

          <div className="trait-preview">
            <h4>Relevant Traits</h4>
            <TraitList
              traits={relevantTraits}
              worldState={worldState}
              showAdvantages
            />
          </div>

          <ModalFooter>
            <Button variant="outline" onClick={onClose}>Cancel</Button>
            <Button type="submit" loading={submitAction.isLoading}>
              Submit Action
            </Button>
          </ModalFooter>
        </form>
      </Form>
    </Modal>
  );
}
```

---

## Visualization Components

### CosmosVisualization

**Path**: `src/components/visualization/CosmosVisualization.tsx`

Uses React Three Fiber for 3D rendering of the cosmic hierarchy.

```typescript
export function CosmosVisualization() {
  const { data: hierarchy } = useHierarchyQuery('universe');
  const { selectEntity } = useHierarchyStore();
  const [selectedNode, setSelectedNode] = useState<string | null>(null);

  return (
    <div className="cosmos-visualization">
      <Canvas camera={{ position: [0, 0, 50], fov: 75 }}>
        <ambientLight intensity={0.5} />
        <pointLight position={[10, 10, 10]} />

        <Suspense fallback={<LoadingPlaceholder />}>
          <HierarchyTree
            data={hierarchy}
            onNodeClick={(nodeId) => {
              setSelectedNode(nodeId);
              selectEntity(nodeId);
            }}
            selectedNode={selectedNode}
          />
        </Suspense>

        <OrbitControls />
      </Canvas>

      <EntityInfoPanel entityId={selectedNode} />
      <ZoomControls />
      <LevelFilter />
    </div>
  );
}

// HierarchyTree.tsx (Three.js component)
function HierarchyTree({ data, onNodeClick, selectedNode }) {
  const nodes = useMemo(() => {
    return layoutHierarchyNodes(data, {
      universeRadius: 40,
      levelSpacing: 8,
      nodeSpacing: 2,
    });
  }, [data]);

  return (
    <group>
      {nodes.map(node => (
        <Fragment key={node.id}>
          {/* Node sphere */}
          <NodeSphere
            position={node.position}
            radius={node.radius}
            color={getNodeColor(node.level, node.metrics)}
            onClick={() => onNodeClick(node.id)}
            selected={selectedNode === node.id}
          />

          {/* Connection to parent */}
          {node.parent && (
            <ConnectionLine
              start={node.position}
              end={node.parent.position}
              opacity={0.3}
            />
          )}

          {/* Label */}
          <Text
            position={[node.position[0], node.position[1] + node.radius + 1, node.position[2]]}
            fontSize={0.5}
            color="white"
          >
            {node.name}
          </Text>
        </Fragment>
      ))}
    </group>
  );
}
```

### MetricsChart

**Path**: `src/components/visualization/MetricsChart.tsx`

Uses Recharts for time-series visualization.

```typescript
interface MetricsChartProps {
  characterId?: string;
  entityId?: string;
  metrics: string[];
  timeRange: { cycles: number } | { startCycle: number; endCycle: number };
}

export function MetricsChart({ characterId, entityId, metrics, timeRange }: MetricsChartProps) {
  const { data, isLoading } = useMetricsHistoryQuery({
    characterId,
    entityId,
    timeRange,
  });

  if (isLoading) return <ChartSkeleton />;

  const chartData = transformMetricsForChart(data, metrics);

  return (
    <ResponsiveContainer width="100%" height={400}>
      <LineChart data={chartData}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis
          dataKey="cycle"
          label={{ value: 'Cycle', position: 'insideBottom', offset: -5 }}
        />
        <YAxis
          label={{ value: 'Value', angle: -90, position: 'insideLeft' }}
          domain={[0, 100]}
        />
        <Tooltip content={<CustomTooltip />} />
        <Legend />

        {metrics.map(metric => (
          <Line
            key={metric}
            type="monotone"
            dataKey={metric}
            stroke={getMetricColor(metric)}
            strokeWidth={2}
            dot={false}
            activeDot={{ r: 6 }}
          />
        ))}
      </LineChart>
    </ResponsiveContainer>
  );
}
```

### RelationshipGraph

**Path**: `src/components/visualization/RelationshipGraph.tsx`

Uses vis-network for interactive relationship graphs.

```typescript
interface RelationshipGraphProps {
  characterId: string;
  relationships: Relationship[];
  interactive?: boolean;
}

export function RelationshipGraph({ characterId, relationships, interactive = false }: RelationshipGraphProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const networkRef = useRef<Network | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    const nodes = buildNodes(characterId, relationships);
    const edges = buildEdges(relationships);

    const data = { nodes, edges };

    const options = {
      nodes: {
        shape: 'dot',
        size: 16,
        font: {
          size: 12,
          color: '#ffffff',
        },
        borderWidth: 2,
      },
      edges: {
        width: 2,
        arrows: { to: { enabled: false } },
        smooth: {
          type: 'continuous',
        },
      },
      physics: {
        stabilization: false,
        barnesHut: {
          gravitationalConstant: -2000,
          springConstant: 0.001,
          springLength: 200,
        },
      },
      interaction: {
        hover: true,
        tooltipDelay: 100,
        zoomView: interactive,
        dragView: interactive,
      },
    };

    networkRef.current = new Network(containerRef.current, data, options);

    if (interactive) {
      networkRef.current.on('click', (params) => {
        if (params.nodes.length > 0) {
          const nodeId = params.nodes[0];
          // Navigate to character page
          navigate(`/character/${nodeId}`);
        }
      });
    }

    return () => {
      networkRef.current?.destroy();
    };
  }, [characterId, relationships, interactive]);

  return (
    <div className="relationship-graph">
      <div ref={containerRef} className="graph-container" />
      <RelationshipLegend />
    </div>
  );
}

function buildNodes(characterId: string, relationships: Relationship[]) {
  const nodes = new Map();

  // Add main character
  nodes.set(characterId, {
    id: characterId,
    label: 'You',
    color: '#3b82f6',
    size: 24,
  });

  // Add related characters
  relationships.forEach(rel => {
    const otherId = rel.character_id === characterId ? rel.target_id : rel.character_id;
    if (!nodes.has(otherId)) {
      nodes.set(otherId, {
        id: otherId,
        label: rel.target_name,
        color: getRelationshipColor(rel.relationship_type),
        size: 16,
      });
    }
  });

  return Array.from(nodes.values());
}

function buildEdges(relationships: Relationship[]) {
  return relationships.map(rel => ({
    from: rel.character_id,
    to: rel.target_id,
    value: Math.abs(rel.score) / 20, // Edge width based on relationship strength
    color: rel.score > 0 ? '#10b981' : '#ef4444',
    title: `${rel.relationship_type}: ${rel.score}`,
  }));
}
```

### ActionTimeline

**Path**: `src/components/actions/ActionTimeline.tsx`

```typescript
interface ActionTimelineProps {
  actions: Action[];
  detailed?: boolean;
  limit?: number;
}

export function ActionTimeline({ actions, detailed = false, limit }: ActionTimelineProps) {
  const displayActions = limit ? actions.slice(0, limit) : actions;

  return (
    <div className="action-timeline">
      {displayActions.map((action, index) => (
        <div key={action.id} className="timeline-item">
          <div className="timeline-marker">
            <div className={cn("marker-dot", getActionTypeClass(action.action_type))} />
            {index < displayActions.length - 1 && <div className="marker-line" />}
          </div>

          <div className="timeline-content">
            <ActionCard action={action} detailed={detailed} />
          </div>
        </div>
      ))}
    </div>
  );
}

// ActionCard.tsx
interface ActionCardProps {
  action: Action;
  detailed: boolean;
}

function ActionCard({ action, detailed }: ActionCardProps) {
  const [expanded, setExpanded] = useState(false);

  return (
    <Card className="action-card">
      <div className="action-header">
        <Badge variant={getActionTypeVariant(action.action_type)}>
          {action.action_type}
        </Badge>
        <span className="action-cycle">Cycle {action.cycle_number}</span>
        <span className="action-timestamp">
          {formatRelativeTime(action.created_at)}
        </span>
      </div>

      <div className="action-body">
        <p className="action-description">{action.description}</p>

        {action.result && (
          <>
            <div className="action-result">
              <p className="result-narrative">{action.result.narrative.result}</p>
              <span className="result-mood">
                <MoodIcon mood={action.result.narrative.mood} />
                {action.result.narrative.mood}
              </span>
            </div>

            {detailed && (
              <button
                className="expand-button"
                onClick={() => setExpanded(!expanded)}
              >
                {expanded ? 'Show Less' : 'Show More'}
              </button>
            )}

            {expanded && (
              <div className="action-details">
                <MetricsDelta metrics={action.result.metrics} />
                {action.result.events.length > 0 && (
                  <EventsList events={action.result.events} />
                )}
                {action.result.trait_activations && (
                  <TraitActivations activations={action.result.trait_activations} />
                )}
              </div>
            )}
          </>
        )}

        {!action.result && action.status === 'queued' && (
          <div className="action-pending">
            <Spinner size="sm" />
            <span>Queued for processing...</span>
          </div>
        )}
      </div>
    </Card>
  );
}
```

---

## Data Flow

### WebSocket Integration

```typescript
// hooks/useSimulationSocket.ts
export function useSimulationSocket() {
  const { token } = useAuthStore();
  const { updateCharacter } = useAuthStore();
  const { addNotification } = useUIStore();
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!token) return;

    const socket = io(WS_URL, {
      auth: { token },
    });

    // Cycle events
    socket.on('cycle_started', (data) => {
      useSimulationStore.setState({
        currentCycle: data.cycle_number,
        cycleStatus: 'processing',
        cycleProgress: 0,
      });
    });

    socket.on('cycle_progress', (data) => {
      useSimulationStore.setState({
        cycleProgress: data.progress,
      });
    });

    socket.on('cycle_completed', (data) => {
      useSimulationStore.setState({
        cycleStatus: 'completed',
        cycleProgress: 100,
      });

      // Invalidate all queries to refresh data
      queryClient.invalidateQueries();

      addNotification({
        type: 'info',
        title: 'Cycle Completed',
        message: `Cycle ${data.cycle_number} has been processed.`,
      });
    });

    // Action events
    socket.on('action_result', (data) => {
      queryClient.setQueryData(
        ['action', data.action_id],
        (old: Action) => ({ ...old, result: data.result, status: 'completed' })
      );

      addNotification({
        type: 'success',
        title: 'Action Result',
        message: data.result.narrative.result,
        actionId: data.action_id,
      });
    });

    // Character updates
    socket.on('character_update', (data) => {
      updateCharacter(data.character);
      queryClient.invalidateQueries(['character', data.character.id]);
    });

    // World events
    socket.on('world_event', (data) => {
      addNotification({
        type: 'warning',
        title: data.event.name,
        message: data.event.description,
      });
    });

    // Election results
    socket.on('election_result', (data) => {
      queryClient.invalidateQueries(['position', data.position_id]);

      addNotification({
        type: 'info',
        title: 'Election Results',
        message: `${data.winner.name} has been elected as ${data.position_title}`,
      });
    });

    return () => {
      socket.disconnect();
    };
  }, [token]);
}
```

### Optimistic Updates

```typescript
// hooks/mutations/useSubmitAction.ts
export function useSubmitAction() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (action: ActionSubmit) => api.submitAction(action),

    onMutate: async (newAction) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries(['actions', newAction.character_id]);

      // Snapshot previous value
      const previousActions = queryClient.getQueryData(['actions', newAction.character_id]);

      // Optimistically update
      queryClient.setQueryData(['actions', newAction.character_id], (old: Action[]) => {
        const optimisticAction: Action = {
          id: 'temp-' + Date.now(),
          ...newAction,
          status: 'queued',
          created_at: Date.now(),
          result: null,
        };
        return [optimisticAction, ...old];
      });

      return { previousActions };
    },

    onError: (err, newAction, context) => {
      // Rollback on error
      queryClient.setQueryData(
        ['actions', newAction.character_id],
        context.previousActions
      );
    },

    onSettled: (data, error, variables) => {
      // Always refetch after error or success
      queryClient.invalidateQueries(['actions', variables.character_id]);
    },
  });
}
```

---

## Routing Structure

```typescript
// router.tsx
export const router = createBrowserRouter([
  {
    path: '/',
    element: <RootLayout />,
    errorElement: <ErrorPage />,
    children: [
      {
        path: 'login',
        element: <LoginPage />,
      },
      {
        path: 'register',
        element: <RegisterPage />,
      },
      {
        path: 'character-creation',
        element: <CharacterCreationPage />,
      },
      {
        path: '/',
        element: <ProtectedRoute />,
        children: [
          {
            element: <MainLayout />,
            children: [
              {
                path: 'dashboard',
                element: <DashboardPage />,
              },
              {
                path: 'character/:characterId',
                element: <CharacterPage />,
              },
              {
                path: 'entity/:level/:entityId',
                element: <EntityPage />,
              },
              {
                path: 'cosmos',
                element: <CosmosVisualizationPage />,
              },
              {
                path: 'actions',
                element: <ActionsPage />,
              },
              {
                path: 'positions',
                element: <PositionsPage />,
              },
              {
                path: 'history',
                element: <HistoryPage />,
              },
              {
                path: 'world',
                element: <WorldStatePage />,
              },
              {
                path: 'settings',
                element: <SettingsPage />,
              },
            ],
          },
        ],
      },
    ],
  },
]);
```

---

## Performance Optimization

### Code Splitting

```typescript
// Lazy load heavy visualization components
const CosmosVisualization = lazy(() => import('./components/visualization/CosmosVisualization'));
const MetricsChart = lazy(() => import('./components/visualization/MetricsChart'));
const RelationshipGraph = lazy(() => import('./components/visualization/RelationshipGraph'));

// Use Suspense boundaries
<Suspense fallback={<LoadingSpinner />}>
  <CosmosVisualization />
</Suspense>
```

### Virtual Scrolling

```typescript
// For long lists of actions, entities, etc.
import { Virtuoso } from 'react-virtuoso';

function ActionList({ actions }: { actions: Action[] }) {
  return (
    <Virtuoso
      style={{ height: '600px' }}
      data={actions}
      itemContent={(index, action) => (
        <ActionCard key={action.id} action={action} />
      )}
    />
  );
}
```

### Memoization

```typescript
// Expensive computations
const processedData = useMemo(() => {
  return processHierarchyData(rawHierarchy);
}, [rawHierarchy]);

// Expensive components
const MemoizedMetricsChart = memo(MetricsChart, (prev, next) => {
  return (
    prev.characterId === next.characterId &&
    prev.timeRange.cycles === next.timeRange.cycles
  );
});
```

### React Query Configuration

```typescript
// queryClient.ts
export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 30000, // 30 seconds
      cacheTime: 300000, // 5 minutes
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

// Prefetching for better UX
function useCharacterPagePrefetch() {
  const queryClient = useQueryClient();

  const prefetchCharacter = useCallback((characterId: string) => {
    queryClient.prefetchQuery({
      queryKey: ['character', characterId],
      queryFn: () => api.getCharacter(characterId),
    });
  }, [queryClient]);

  return prefetchCharacter;
}
```

---

## Testing Strategy

### Unit Tests (Vitest)

```typescript
// components/__tests__/ActionCard.test.tsx
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { ActionCard } from '../ActionCard';

describe('ActionCard', () => {
  it('renders action description', () => {
    const action = {
      id: '1',
      action_type: 'scientific',
      description: 'Research quantum physics',
      status: 'queued',
    };

    render(<ActionCard action={action} detailed={false} />);

    expect(screen.getByText('Research quantum physics')).toBeInTheDocument();
  });

  it('shows result when available', () => {
    const action = {
      id: '1',
      action_type: 'scientific',
      description: 'Research quantum physics',
      status: 'completed',
      result: {
        narrative: {
          result: 'Made a breakthrough discovery!',
          mood: 'excited',
        },
      },
    };

    render(<ActionCard action={action} detailed={false} />);

    expect(screen.getByText('Made a breakthrough discovery!')).toBeInTheDocument();
  });
});
```

### Integration Tests (React Testing Library)

```typescript
// pages/__tests__/DashboardPage.test.tsx
import { describe, it, expect, vi } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { DashboardPage } from '../DashboardPage';

describe('DashboardPage', () => {
  it('loads and displays character data', async () => {
    const queryClient = new QueryClient();

    render(
      <QueryClientProvider client={queryClient}>
        <DashboardPage />
      </QueryClientProvider>
    );

    await waitFor(() => {
      expect(screen.getByText(/Welcome/)).toBeInTheDocument();
    });
  });
});
```

### E2E Tests (Playwright)

```typescript
// e2e/action-submission.spec.ts
import { test, expect } from '@playwright/test';

test('submit action flow', async ({ page }) => {
  await page.goto('/dashboard');

  // Open action modal
  await page.click('[data-testid="submit-action-button"]');

  // Fill form
  await page.selectOption('[name="action_type"]', 'scientific');
  await page.fill('[name="description"]', 'Research quantum computing');

  // Submit
  await page.click('button[type="submit"]');

  // Verify success
  await expect(page.locator('.toast-success')).toBeVisible();
  await expect(page.locator('.action-timeline')).toContainText('Research quantum computing');
});
```

---

## File Structure

```
src/
├── components/
│   ├── layout/
│   │   ├── TopBar.tsx
│   │   ├── Sidebar.tsx
│   │   ├── MainLayout.tsx
│   │   └── PageHeader.tsx
│   ├── actions/
│   │   ├── ActionCard.tsx
│   │   ├── ActionTimeline.tsx
│   │   ├── ActionSubmitModal.tsx
│   │   └── ActionFilters.tsx
│   ├── character/
│   │   ├── CharacterCard.tsx
│   │   ├── AttributesCard.tsx
│   │   ├── TraitsCard.tsx
│   │   └── LifeStageCard.tsx
│   ├── entity/
│   │   ├── EntityCard.tsx
│   │   ├── EntityMetricsCard.tsx
│   │   └── ChildEntitiesList.tsx
│   ├── visualization/
│   │   ├── CosmosVisualization.tsx
│   │   ├── MetricsChart.tsx
│   │   ├── RelationshipGraph.tsx
│   │   └── HierarchyTree.tsx
│   └── ui/
│       ├── Button.tsx
│       ├── Card.tsx
│       ├── Modal.tsx
│       ├── Form.tsx
│       └── ...
├── pages/
│   ├── DashboardPage.tsx
│   ├── CharacterPage.tsx
│   ├── EntityPage.tsx
│   ├── CosmosVisualizationPage.tsx
│   ├── ActionsPage.tsx
│   └── ...
├── hooks/
│   ├── queries/
│   │   ├── useCharacterQuery.ts
│   │   ├── useActionsQuery.ts
│   │   └── useEntityQuery.ts
│   ├── mutations/
│   │   ├── useSubmitAction.ts
│   │   └── useUpdateCharacter.ts
│   └── useSimulationSocket.ts
├── stores/
│   ├── useAuthStore.ts
│   ├── useSimulationStore.ts
│   ├── useUIStore.ts
│   └── useHierarchyStore.ts
├── atoms/
│   ├── filterAtoms.ts
│   └── uiAtoms.ts
├── lib/
│   ├── api.ts
│   ├── socket.ts
│   └── utils.ts
├── types/
│   ├── character.ts
│   ├── action.ts
│   ├── entity.ts
│   └── index.ts
└── App.tsx
```

---

## Implementation Priority

### Phase 1: Core Infrastructure (Weeks 1-2)
1. Set up Vite + React + TypeScript
2. Implement routing structure
3. Set up Zustand stores
4. Set up React Query
5. Create basic layout components (TopBar, Sidebar, MainLayout)
6. Implement authentication flow

### Phase 2: Essential Features (Weeks 3-4)
1. Dashboard page
2. Character page
3. Action submission modal
4. Action timeline
5. WebSocket integration
6. Basic metrics charts

### Phase 3: Hierarchy & Visualization (Weeks 5-6)
1. Entity page
2. Hierarchy explorer
3. Basic cosmos visualization
4. Relationship graph
5. Organization chart

### Phase 4: Advanced Features (Weeks 7-8)
1. Elections & competitions UI
2. Position management
3. World state visualization
4. Event timeline
5. Life stage transitions UI

### Phase 5: Polish & Optimization (Weeks 9-10)
1. Performance optimization
2. Accessibility improvements
3. Mobile responsiveness
4. Error handling refinement
5. Loading states polish

---

## Version History

- v1.0: Initial frontend architecture specification
