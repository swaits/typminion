-- Require external modules and libraries
require "lib.util.debug"
require "lib.util.list"
require "lib.util.parse_transition"
require "lib.util.validators"

lume = require "lib.lume"

-- Global constants
ROOT_NAME      = "HSM"
TIMER_NAME     = "_HSM_TIMER_"
TERMINAL_STATE = "ExitHSM"

-- Build the path from a given state up to the root.
-- @param state (table) The starting state node.
-- @return (table) Array of nodes from the starting state up to the root.
path_to_root = (state) ->
  path = {}
  while state
    table.insert(path, state)
    state = state.parent
  path

-- Recursively construct a state node.
--
-- Each node is augmented with a reference to its parent, transitions, timers,
-- and, if it is the root, a reference to the full state_map.
--
-- @param name (string) The name of the state.
-- @param def (table) The state definition table.
-- @param parent (table or nil) The parent state node.
-- @param state_map (table) Global mapping of state names to nodes.
-- @return (table) The constructed state node.
build_node = (name, def, parent, state_map) ->
  -- Validate state name (except for the ROOT)
  unless name == ROOT_NAME or is_valid_symbol name
    error "Invalid state name: #{name}"

  -- Initialize node with default properties.
  node =
    name: name
    parent: parent
    transitions: {}
    timers: {}
    default: def.default or nil

  -- Ensure state is defined only once.
  if state_map[name]
    error "State #{name} defined more than once"
  state_map[name] = node

  -- Process transitions defined as array entries.
  for index, transition_str in ipairs def
    transition = parse_transition(transition_str) -- parse_transition does validation
    if transition.type == "on"
      node.transitions[transition.event] = transition.target
    else
      -- For "every" or "after" transitions, generate a unique timer event name.
      event_name = "#{TIMER_NAME}#{name}__#{#node.timers + 1}"
      once = transition.type == "after"
      duration = transition.duration
      node.transitions[event_name] = transition.target
      table.insert(node.timers, {once: once, duration: duration, event: event_name})

  -- Process nested states (ignore keys that are not strings or are "default").
  for key, value in pairs def
    if type(key) == "string" and key != "default"
      build_node(key, value, node, state_map)

  -- If this is the root node, attach the full state_map.
  unless parent
    node.state_map = state_map

  node

-- Build the hierarchical state machine (HSM) graph.
--
-- This function takes a machine definition and recursively constructs the HSM
-- by creating nodes and then converting transition targets (state names) into
-- actual node references.
--
-- @param def (table) The machine definition.
-- @return (table) The root state node of the HSM.
build_hsm = (def) ->
  -- Prepopulate state_map with a terminal state.
  root = build_node(ROOT_NAME, def, nil, {
    [TERMINAL_STATE]: { name: TERMINAL_STATE, transitions: {}, timers: {} }
  })

  -- Grab a reference to the state map
  states = root.state_map

  -- Convert default and normal transitions from state names to node references.
  for name, state in pairs states
    -- update default transitions
    if state.default
      state.default = states[state.default]
    -- update normal transitions
    if state.transitions
      for event, target in pairs state.transitions
        unless states[target]
          error "State #{target} referenced, but never defined"
        state.transitions[event] = states[target] -- change string to node reference here

  root

-- Plan a transition from a source state to a destination state.
--
-- This function follows any default transitions from the destination state,
-- then computes the exit and entry paths by finding the least common ancestor
-- (LCA) of the source and final destination.
--
-- @param src (table) The current state node.
-- @param dst (table) The target state node.
-- @return (table) A table with `exit` (states to exit) and `entry` (states to enter).
plan_transition = lume.memoize (src, dst) ->
  -- Follow default transitions to get the final destination.
  seen = {}
  final_dst = dst
  while final_dst.default
    if seen[final_dst]
      error "Cycle detected in default transitions (in state #{final_dst.name})!"
    seen[final_dst] = true
    final_dst = final_dst.default

  -- Build paths from both source and destination to the root.
  src_path = path_to_root(src)
  dst_path = path_to_root(final_dst)

  -- Remove the common tail to determine the least common ancestor.
  while #src_path > 0 and #dst_path > 0 and src_path[#src_path] == dst_path[#dst_path]
    table.remove(src_path, #src_path)
    table.remove(dst_path, #dst_path)

  plan =
    exit: src_path
    entry: reverse(dst_path)

  -- If transitioning to the terminal state, no entry actions are needed.
  if final_dst.name == TERMINAL_STATE
    plan.entry = {}

  plan

-- Create an HSM runtime class from a machine definition.
--
-- The returned class provides methods for state transitions, updating timers,
-- handling events, and invoking state entry/update/exit actions.
--
-- @param machine_def (table) The machine definition.
-- @return (class) The HSM runtime class.
export create_hsm = (machine_def) ->

  root = build_hsm(machine_def)

  class HSMRuntime
    -- Constructor: initializes the runtime state and binds state action methods.
    new: =>
      @root = root
      @cur_state = nil
      @timers = {}  -- Map: state node -> list of timer objects
      @event_queue = {}
      @is_handling = false
      @in_transition = false
      @MAX_EVENTS_PER_UPDATE = 10

      -- Bind action methods (entry, update, exit) for each state.
      default_msg = (action) -> print "*** WARNING ***  Using default #{action} HSM action function. Override to suppress this message."
      for name, state in pairs @root.state_map
        state.entry  = @["on#{name}Entry"] or (=> default_msg "on#{name}Entry")
        state.update = @["on#{name}Update"] or ((dt) -> default_msg "on#{name}Update")
        state.exit   = @["on#{name}Exit"] or (=> default_msg "on#{name}Exit")

      -- Transition into the initial state and return self.
      @transition(@root)
      @

    -- Initialize timers for a given state.
    --
    -- @param state (table) The state node whose timers should be created.
    init_timers: (state) =>
      if state.timers
        @timers[state] = lume.map state.timers, (t) ->
          {
            once: t.once
            duration: t.duration
            event: t.event -- TODO: change this from event to target state
            elapsed: 0
          }

    -- Destroy timers associated with a state.
    --
    -- @param state (table) The state node whose timers should be removed.
    destroy_timers: (state) =>
      @timers[state] = nil

    -- Update timers across all active states.
    --
    -- Called during each update cycle; increments timer elapsed times,
    -- checks for timer firing (including overshoot), and triggers events.
    --
    -- @param dt (number) The delta time since the last update.
    -- @return (boolean) false if there is no current state, otherwise true.
    update_timers: (dt) =>
      return false unless @cur_state
      max_timer = nil

      -- Iterate over timers for each state.
      for state, timers in pairs @timers
        for timer in *timers
          continue unless timer.duration
          timer.elapsed += dt
          timer.overshoot = timer.elapsed - timer.duration
          if timer.overshoot > 0 and (not max_timer or timer.overshoot > max_timer.overshoot)
            max_timer = timer

      -- If a timer fired, trigger its event.
      if max_timer
        if max_timer.once
          max_timer.duration = nil
          max_timer.elapsed = nil
        else
          max_timer.elapsed = max_timer.elapsed % max_timer.duration
        @trigger(max_timer.event)

      true

    -- Transition from the current state to a destination state.
    --
    -- This method computes the exit/entry plan, calls exit actions (and destroys timers)
    -- for states being exited, then calls entry actions (and initializes timers) for states
    -- being entered.
    --
    -- @param dst (table) The target state node.
    -- @return (boolean) true if no actual state change occurred.
    transition: (dst) =>
      @in_transition = true
      starting_state = @cur_state
      plan = plan_transition(@cur_state, dst)

      -- Exit states: destroy timers and invoke exit actions.
      for state in *plan.exit
        @destroy_timers(state)
        @cur_state = state
        if state.exit then state.exit(self)
        if state == @root
          @cur_state = nil  -- HSM terminated
          @in_transition = false
          return

      -- Enter new states: initialize timers and invoke entry actions.
      for state in *plan.entry
        @init_timers(state)
        if state.entry then state.entry(self)
        @cur_state = state

      @in_transition = false

      -- process events that we might've accumulated during transition
      @drain_events()

      starting_state == @cur_state

    -- Update the HSM.
    --
    -- Processes timers and then calls update actions from the current state upward.
    --
    -- @param dt (number) Delta time.
    -- @return (boolean) true if there is a current state; false otherwise.
    update: (dt) =>
      -- exit if the HSM is terminated
      return false unless @cur_state

      -- update our timers
      @update_timers(dt)

      -- Propagate update actions from current state up through ancestors.
      s = @cur_state
      while s
        if s.update then s.update(self, dt)
        s = s.parent

      -- Process any events in our queue, some of which might've just happened
      @drain_events()

      true

    -- Process an event.
    --
    -- Processes an event by checking to see if the current state or any of its
    -- parents handles it. If none, the event is just discarded. Once an event
    -- is handled by any state, it's discarded.
    --
    -- @param event (string) Event.
    process_event: (event) =>
      -- search from current state to root looking for one to handle this
      s = @cur_state
      while s
        if s.transitions[event]
          -- found a state that handles event, transition
          @transition(s.transitions[event])
          return
        s = s.parent

    -- Drain events in the @event_queue.
    --
    -- Processes events in the queue up to @MAX_EVENTS_PER_UPDATE.
    drain_events: () =>
      num = math.min(@MAX_EVENTS_PER_UPDATE, #@event_queue)
      count = 0
      while count < num and #@event_queue > 0
        @process_event(table.remove(@event_queue, 1))

    -- Handle an event by checking the current state and its ancestors.
    --
    -- If a transition for the event is found, the HSM will transition accordingly.
    --
    -- @param event (string) The event to trigger.
    -- @return (boolean) false if there is no current state; true otherwise.
    trigger: (event) =>
      return false unless @cur_state

      if @is_handling or @in_transition
        -- if we're processing an event now, just queue it up
        table.insert(@event_queue, event)
      else
        -- if we're not processing anything, do it immediately
        @is_handling = true
        @process_event(event)
        @is_handling = false

      true

  HSMRuntime
