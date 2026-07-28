# Thought Circle 0.2 — Reality-Respecting Cycles

This release deepens the central loop-breaking workflow while keeping the app local-first and cross-platform.

## Added

- Explicit linked loop nodes using `>>>`, arrows, or line breaks.
- Reality check fields for valid evidence and unresolved uncertainty.
- Constructive cycles that move from clarification to evidence, testing, learning, action, or closure.
- Persisted user-owned conclusion labels: Valid, Partly valid, Uncertain, and Closed for now.
- Small experiments and attention-protecting stopping rules.
- Desktop read-only project mapper for downloaded repositories.
- Project-map-to-guide workflow for testing beliefs through a prototype or inspection.
- Review-first Guide voice capture with local Gemma transcription.
- Backward-compatible migration of existing saved plans.
- Unit coverage for cycle serialization, linked-node extraction, and safe project mapping.

## Changed

- Rewrote Gemma planning, guide, and journal prompts to prohibit psychoanalysis.
- Removed language that asks the model to infer or name emotions.
- Renamed Guide modes to Support, Reality check, and Next move.
- Replaced forced-positive framing with valid / partly valid / uncertain / close-for-now outcomes.
- Renamed the anti-looping chain to Progress chain.

## Safety and privacy

- Repository mapping never executes code.
- Generated and dependency folders are ignored.
- Project files stay local; only a user-reviewed structure summary is placed in the local Gemma composer.
- Thought Circle remains general supportive planning software, not medical care, diagnosis, crisis support, or a replacement for qualified professionals.
