# Orbital Cognition System

> A design expansion for Thought Circle: glassmorphic thought spheres, spinable cognitive rings, interactive moons, linked reasoning paths, constructive challenge mode, and local-first multi-agent planning.

## Core metaphor

The interface treats a person’s active thinking space as a dynamic orbital system:

- The **central sphere** represents the current cognitive field.
- Each **orbital ring** represents one thought loop, goal, question, design problem, relationship concern, or planning surface.
- Each **moon** represents an observation, evidence item, emotion, assumption, constraint, action, alternative, or unresolved question.
- A **link** between moons or rings represents a dependency, contradiction, causal hypothesis, analogy, shared resource, or planning handoff.
- A **spawned agent** is a bounded reasoning process created from one or more linked moons.

A useful mental model is:

\[
\mathcal{C} = (R, M, E, A, S)
\]

where:

- \(R\) is the set of orbital rings,
- \(M\) is the set of moons,
- \(E\) is the set of links,
- \(A\) is the set of active agents,
- \(S\) is the user-visible state of the cognitive system.

Each ring may have a loop intensity:

\[
L_i = \alpha f_i + \beta e_i + \gamma u_i + \delta r_i
\]

where frequency \(f_i\), emotional charge \(e_i\), uncertainty \(u_i\), and recurrence \(r_i\) are user-controlled or inferred only from local interaction history.

---

# 150 Feature and Research Ideas

## I. Orbital interaction and visual language

### 1. Spinable thought rings
Each ring can be dragged directly with angular momentum, continuing to rotate after release and slowing under configurable friction.

\[
\omega_{t+1}=\lambda\omega_t+\tau_{drag}
\]

### 2. Independent ring planes
Allow rings to tilt independently in pseudo-3D, giving each loop a distinct spatial identity without requiring a full 3D engine.

### 3. Glass refraction sphere
Render the central sphere with layered gradients, soft bloom, refractive highlights, and a subtle parallax response to device motion or pointer movement.

### 4. Moon tap hierarchy
Single tap previews, double tap opens detail, long press activates a radial action menu, and drag begins ring-to-ring linking.

### 5. Moon magnetism
Nearby moons gently attract during drag operations so relationships are easy to express without pixel-perfect placement.

### 6. Orbital resonance animation
When two rings are related, their motion periodically synchronizes for a few seconds, visually exposing hidden structure.

### 7. Ring tension visualization
Conflicted loops become slightly eccentric or uneven, while stable loops settle into smooth circular motion.

### 8. Ring thickness as salience
A ring grows thicker when it is revisited often, challenged repeatedly, or linked to many active decisions.

### 9. Moon size as importance
Moon radius maps to user-rated importance, urgency, or evidence weight.

### 10. Moon glow as emotional charge
Glow intensity reflects self-reported emotional activation rather than inferred diagnosis.

### 11. Orbit speed as cognitive recurrence
Fast rotation represents a frequently returning thought; users can manually slow it as a symbolic calming interaction.

### 12. Freeze ring gesture
Pinch a ring inward to pause it temporarily and place it in a quiet review state.

### 13. Ring scrub timeline
Dragging along the ring reveals prior versions of that thought loop and how its moons changed over time.

### 14. Orbital depth layers
Loops may sit in foreground, middle distance, or background to represent now, soon, and later.

### 15. Ring collapse into token
A resolved loop compresses into a tiny polished token stored in a “settled constellation.”

### 16. Loop bloom animation
When a new thought is added, the ring grows from a point into a luminous orbit rather than simply appearing.

### 17. Moon birth animation
New moons emerge from the central sphere and settle into a chosen ring, making creation feel spatial and intentional.

### 18. Moon docking
Drag a moon into the center sphere to mark it as the current focus.

### 19. Orbital focus lens
Tapping the center enlarges one chosen ring while dimming the others, creating a low-distraction focus mode.

### 20. Constellation overview
Zooming out transforms loops into a constellation map, showing groups of related cognitive systems.

## II. Moon semantics and data modeling

### 21. Evidence moons
A moon can contain a fact, quote, measurement, memory, screenshot reference, or external observation.

### 22. Assumption moons
Assumptions use a faint dashed halo and are explicitly marked as unverified.

### 23. Constraint moons
Constraints represent time, money, energy, safety, tools, obligations, or technical limitations.

### 24. Action moons
Action moons contain one concrete next step and can be checked off directly from the orbit.

### 25. Question moons
Question moons hold unknowns that block progress and can spawn a research agent.

### 26. Emotion moons
Emotion moons record feelings without treating them as proof for or against a conclusion.

### 27. Perspective moons
A perspective moon stores how another person, role, stakeholder, or future self might view the situation.

### 28. Counterexample moons
Counterexamples are attached to claims and visually orbit in the opposite direction.

### 29. Risk moons
Risk moons contain probability, impact, detectability, and mitigation fields.

\[
R = P \times I \times D
\]

### 30. Resource moons
Resources represent people, tools, money, time windows, documents, or available skills.

### 31. Decision moons
Decision moons capture a choice, deadline, alternatives, and confidence score.

### 32. Experiment moons
An experiment moon defines a test, expected signal, cost, duration, and stopping condition.

### 33. Value moons
Value moons state what matters in the situation so optimization does not drift away from the user’s priorities.

### 34. Memory moons
Memory moons reference past experiences while remaining distinct from current evidence.

### 35. Boundary moons
These represent personal, ethical, physical, emotional, financial, or project boundaries.

### 36. Contradiction moons
Contradictory beliefs are linked with a pulsing bridge instead of being forcibly merged.

### 37. Hypothesis moons
A hypothesis moon has confidence, supporting evidence, opposing evidence, and proposed tests.

### 38. Dependency moons
Dependencies identify what must happen before another action can proceed.

### 39. Outcome moons
Outcome moons describe desired results, acceptable results, and failure signals.

### 40. Unknown-unknown moon
A special moon prompts the agent to search for missing categories rather than only missing details.

## III. Ring-to-ring cognitive structures

### 41. Causal bridges
Link rings with directional arrows representing “may cause,” “contributes to,” or “depends on.”

### 42. Shared-moon bridges
One moon may belong to multiple rings, preventing duplicate facts from diverging.

### 43. Conflict bridges
A red-violet bridge shows where two loops compete for the same resource or imply incompatible actions.

### 44. Support bridges
A warm gold bridge shows where one loop provides motivation, evidence, or resources to another.

### 45. Analogy bridges
Link an engineering concept to a personal situation through shared structural patterns without claiming they are identical.

### 46. Temporal bridges
Connect “before,” “during,” and “after” loops into a sequence.

### 47. Conditional bridges
A bridge activates only when a condition is met.

\[
E_{ij}=1 \iff c(x)\ge\theta
\]

### 48. Feedback-loop detection
The graph engine identifies cycles and asks whether they are reinforcing, balancing, or accidental.

### 49. Bridge confidence
Every inferred link carries a confidence score and can be confirmed, weakened, or deleted by the user.

### 50. Bridge explanation panel
Tapping a link explains why it exists and which moons created it.

### 51. Ring fusion
Merge two duplicate or strongly overlapping loops while preserving the original history.

### 52. Ring fission
Split one overloaded loop into smaller loops based on moon clusters.

### 53. Parent-child rings
A broad goal ring may contain smaller subproblem rings.

### 54. Ring dependency graph
A planning overlay shows the critical path across thought loops.

### 55. Ring coalition
Temporarily group rings to create a shared agent workspace.

### 56. Ring isolation chamber
Detach a loop from all influence to test whether the conclusion changes without surrounding context.

### 57. Cross-ring assumption audit
Find assumptions shared by multiple loops that could be causing repeated downstream errors.

### 58. Cross-ring resource contention
Detect when multiple plans depend on the same limited time, energy, money, or person.

### 59. Cross-ring contradiction scan
Surface when two loops hold incompatible beliefs about the same fact.

### 60. Cross-ring opportunity scan
Find where solving one loop could resolve or simplify several others.

## IV. Constructive challenge mode

### 61. Negative-pattern challenge
The system asks for evidence, alternative explanations, controllable actions, and a fair stopping rule.

### 62. Positive-pattern challenge
Constructively stress-test optimism for missing risks, overconfidence, hidden costs, or unrealistic timelines.

### 63. Engineering challenge mode
Test a design using failure modes, load cases, constraints, observability, maintainability, and fallback plans.

### 64. Friendship challenge mode
Explore interpretations, boundaries, communication options, and uncertainty without assigning motives as fact.

### 65. Life-planning challenge mode
Evaluate alignment with values, reversibility, opportunity cost, energy, and long-term consequences.

### 66. Advice challenge mode
Inspect advice for assumptions, applicability, evidence quality, incentives, and possible harm.

### 67. Concept challenge mode
Ask what would falsify the idea, what adjacent ideas already exist, and what unique contribution remains.

### 68. Plan pre-mortem
Imagine the plan failed and generate likely causes before execution.

### 69. Plan post-mortem
After completion, compare predicted and actual outcomes and update future planning priors.

### 70. Steelman pass
An agent reconstructs the strongest reasonable version of the thought before criticizing it.

### 71. Red-team pass
A bounded critic searches for flaws, contradictions, missing evidence, and unsafe assumptions.

### 72. Blue-team pass
A defender improves robustness, observability, fallback logic, and recovery options.

### 73. Purple-team synthesis
A mediator integrates criticism and defense into a stronger next version.

### 74. Reversibility test
Classify decisions as reversible, partly reversible, or hard to reverse.

### 75. Time-horizon challenge
Ask how the thought changes over one day, one month, one year, and five years.

### 76. Scale challenge
Test whether the idea works for one person, ten users, ten thousand users, or a constrained device.

### 77. Incentive challenge
Ask who benefits, who pays, who maintains it, and what behavior the system rewards.

### 78. Boundary challenge
Check whether the plan crosses a stated personal, ethical, legal, financial, or technical boundary.

### 79. Evidence quality challenge
Rate evidence by source, recency, directness, sample size, and relevance.

### 80. Closure challenge
Require an explicit stopping rule so reflection does not become another endless loop.

## V. Agent spawning architecture

### 81. Moon-to-agent spawn
Long-press a moon and choose a role: researcher, planner, critic, synthesizer, explainer, estimator, or experiment designer.

### 82. Ring-to-agent spawn
Spawn an agent using the entire loop context while excluding unrelated rings.

### 83. Bridge-to-agent spawn
Create an agent specifically to investigate the relationship between two rings.

### 84. Multi-moon spawn tray
Drag several moons into a temporary tray, then spawn one agent from the selected subset.

### 85. Agent orbit
Active agents appear as small satellites outside the main rings, with visible progress and bounded scope.

### 86. Agent lifetime controls
Each agent has a token budget, iteration cap, time cap, and completion condition.

### 87. Agent contract
Every spawn must declare input, role, allowed tools, forbidden actions, expected output, and stop rule.

### 88. Agent lineage
Outputs retain links to the moons, rings, and assumptions that produced them.

### 89. Agent disagreement surface
When agents disagree, the system displays the disputed premise rather than averaging conclusions.

### 90. Agent confidence calibration
Agents separate confidence in facts, reasoning, recommendation, and prediction.

### 91. Research agent
Collects candidate facts and clearly labels what is verified, inferred, missing, or uncertain.

### 92. Planning agent
Produces staged actions, dependencies, fallback paths, and validation checkpoints.

### 93. Challenge agent
Runs a selected challenge mode without changing the original thought automatically.

### 94. Synthesis agent
Combines multiple agent outputs into one concise map with unresolved disagreements preserved.

### 95. Experiment-design agent
Creates minimal tests that maximize information gain per unit cost.

\[
U(a)=\frac{\mathbb{E}[\Delta H]}{cost(a)+\epsilon}
\]

### 96. Reflection agent
Summarizes what changed in the user’s understanding without claiming psychological diagnosis.

### 97. Compression agent
Turns a dense ring into a smaller set of representative moons while retaining links to archived detail.

### 98. Counterfactual agent
Explores how the plan changes if a major assumption is false.

### 99. Stakeholder agent
Models multiple stakeholder needs as explicit perspectives, not hidden truth claims.

### 100. Local-only agent scheduler
Runs agents sequentially or concurrently depending on device capacity, model state, thermal constraints, and battery.

## VI. Agent orchestration and safety

### 101. Cognitive DAG scheduler
Agent tasks form a directed acyclic graph with dependency-aware execution.

### 102. Budget-aware spawning
The system estimates whether a requested agent coalition fits the available context and compute budget.

### 103. Agent lease system
Only one agent may modify a moon or ring at a time, preventing silent overwrites.

### 104. Read-only critic agents
Challenge agents default to read-only and propose changes rather than applying them.

### 105. Human approval gates
Any merge, deletion, major reinterpretation, or cross-ring restructuring requires explicit confirmation.

### 106. Provenance ledger
Every generated moon includes source agent, input set, timestamp, model, and confidence.

### 107. Hallucination quarantine
Unsupported claims are placed in a translucent quarantine orbit until confirmed or removed.

### 108. Contradiction quarantine
Conflicting outputs remain separated until the user or a verification agent resolves them.

### 109. Model fallback ladder
If the local model is unavailable, the app falls back to rule-based prompts and manual reflection templates.

### 110. Agent cancellation gesture
Flick an active agent satellite outward to cancel it immediately.

### 111. Agent pause and inspect
Pause an agent, inspect its current inputs and intermediate summary, then resume or revise the contract.

### 112. Spawn preview
Before creation, show estimated tokens, time, memory use, and expected artifacts.

### 113. Duplicate-agent detection
Prevent spawning nearly identical agents unless the user explicitly wants independent replication.

### 114. Agent diversity knob
Choose between convergence, balanced viewpoints, or maximum exploratory diversity.

### 115. Consensus threshold
Require a configurable number of independent agents to support a recommendation before promotion.

\[
C = \frac{\sum_i w_i s_i}{\sum_i w_i}
\]

### 116. Uncertainty budget
Agents must reserve a portion of output for unknowns, assumptions, and disconfirming evidence.

### 117. No-infinite-loop rule
Every agent must terminate after a fixed number of refinement cycles.

### 118. Recovery checkpoint
Store intermediate output so interrupted local inference can resume safely.

### 119. Agent sandbox profiles
Research, coding, journaling, planning, and challenge agents receive different permissions.

### 120. Final-answer trace map
The user can tap any conclusion and see the exact moons and agent outputs that support it.

## VII. Planning and reasoning mechanics

### 121. Information gain scoring
Prioritize moons that would reduce the most uncertainty if answered.

### 122. Expected value of action
Rank actions by expected benefit, cost, reversibility, and confidence.

\[
EVA(a)=P_sV_s-P_fC_f-C_a+\rho R_a
\]

### 123. Cognitive load score
Estimate how overloaded a loop is based on moon count, unresolved links, emotional charge, and dependency depth.

### 124. Ring entropy
Use normalized category entropy to show whether a loop is dominated by one type of thought or fragmented across many.

\[
H(R_i)=-\sum_k p_k\log p_k
\]

### 125. Closure readiness
Estimate whether a loop has enough evidence, a chosen action, and a stopping rule to settle.

### 126. Decision confidence decomposition
Separate confidence into evidence quality, model agreement, user certainty, and plan testability.

### 127. Goal drift detector
Compare current ring state to the original stated goal and surface semantic drift.

### 128. Loop recurrence prediction
Estimate which unresolved loops are likely to return based on user-created history, without claiming medical prediction.

### 129. Minimum viable next step
Generate the smallest action that produces useful information or momentum.

### 130. Constraint relaxation explorer
Ask which constraint is truly fixed and which might be negotiated, delayed, outsourced, or reframed.

### 131. Option frontier
Plot candidate actions by expected benefit and effort to expose Pareto-efficient choices.

### 132. Regret-aware planning
Compare likely regret from acting, delaying, or doing nothing.

### 133. Robust plan generation
Prefer plans that still work under several plausible future states.

### 134. Sensitivity analysis
Show which assumptions most strongly affect the recommendation.

### 135. Bottleneck moon
Automatically identify the unresolved item blocking the largest number of downstream actions.

## VIII. Reflection, accessibility, and long-term use

### 136. Quiet orbit mode
Reduce motion, glow, and visual density for users who prefer a calmer interface.

### 137. Full reduced-motion mode
Replace continuous animation with state transitions while preserving all interactions.

### 138. Haptic ring feedback
Use subtle haptics for moon docking, bridge creation, ring settling, and agent completion.

### 139. Audio orbit cues
Optional spatial audio indicates which ring is active, challenged, or resolved.

### 140. Voice-created moons
Speak a thought and let the app split it into candidate moons for review before saving.

### 141. Reflection replay
Replay how a loop changed over time using a controlled visual timeline.

### 142. Daily orbital snapshot
Save a privacy-preserving local snapshot showing ring count, settled loops, completed actions, and unresolved questions.

### 143. Weekly constellation review
Group related loops and surface recurring resources, assumptions, or unresolved dependencies.

### 144. Adaptive visual density
Automatically simplify the interface when many loops are active, while keeping all data accessible.

### 145. Semantic zoom
At far zoom, show rings; at medium zoom, show moons; at close zoom, show content, links, provenance, and actions.

### 146. Private export bundle
Export selected rings, moons, links, and agent traces as encrypted JSON or human-readable Markdown.

### 147. Shared-session mode
Allow a user to display a read-only subset during a coaching, friendship, design, or planning conversation.

### 148. Template constellations
Offer unlabeled structural templates such as decision, relationship, engineering design, project planning, uncertainty, and idea exploration.

### 149. Constructive challenge journal
Record which challenges changed the thought, which failed, and which generated useful experiments.

### 150. Cognitive world model
Evolve the orbit into a local-first personal reasoning graph that tracks not only thoughts, but their evidence, uncertainty, dependencies, values, experiments, and verified outcomes over time.

---

# Suggested system architecture

## Data graph

```text
ThoughtRing
  id
  title
  detail
  state
  priority
  recurrence
  emotionalCharge
  planeTilt
  angularVelocity
  moonIds[]

ThoughtMoon
  id
  ringIds[]
  kind
  title
  body
  confidence
  importance
  evidenceStatus
  provenance

ThoughtLink
  id
  sourceId
  targetId
  relation
  direction
  confidence
  userConfirmed

AgentSpawn
  id
  role
  inputMoonIds[]
  inputRingIds[]
  budget
  status
  outputMoonIds[]
  stopReason
```

## Agent utility objective

A bounded agent can optimize:

\[
J(a)=w_1\Delta clarity+w_2\Delta actionability+w_3\Delta verification-w_4 cost-w_5 risk
\]

subject to:

\[
iterations \le I_{max},\quad tokens \le T_{max},\quad writes \subseteq W_{allowed}
\]

## Challenge score

For any thought or plan:

\[
Q = 0.25E + 0.20A + 0.20R + 0.20T + 0.15B
\]

where:

- \(E\): evidence strength,
- \(A\): assumption transparency,
- \(R\): reversibility,
- \(T\): testability,
- \(B\): boundary alignment.

The score should never be presented as truth. It is a structured reflection aid.

---

# Recommended first implementation wave

1. Replace the static orbit painter with an animated, gesture-driven orbital canvas.
2. Introduce `ThoughtRing`, `ThoughtMoon`, and `ThoughtLink` models while maintaining migration from the existing `Thought` model.
3. Add moon creation, dragging, docking, deletion, and direct ring spin.
4. Add link mode between moons and rings.
5. Add an agent spawn preview sheet with role, scope, token budget, and stop condition.
6. Implement challenge mode with negative, positive, engineering, planning, advice, and relationship templates.
7. Preserve local-first storage, explicit approval, and provenance.
8. Add reduced-motion support before enabling continuous orbit animation by default.

---

# Design principle

The system should not tell the user what their thoughts “really mean.” It should help them externalize structure, test assumptions, generate alternatives, create bounded experiments, and choose a next action while preserving uncertainty and user control.
