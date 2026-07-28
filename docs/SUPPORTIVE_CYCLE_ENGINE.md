# Supportive Cycle Engine

Thought Circle 0.2 changes the app from a generic reflection helper into a reality-respecting supportive thinking system.

## Core rule

The local model must not psychoanalyze the user. It may not infer hidden emotions, motives, trauma, personality traits, disorders, or the reason a person holds a belief. It works only with the words the user supplied.

## Loop model

A loop can be entered as a normal sentence or as linked nodes separated by `>>>`, `->`, an arrow, or line breaks.

Example:

```text
AI is not useful >>> I may be prompting poorly >>> Claude is the worst >>> I do not see useful cases >>> AI is not useful
```

The planner converts this into:

1. A neutral map of the stated loop.
2. A **valid signal** that preserves evidence or criticism that may be correct.
3. An **uncertainty boundary** for broad claims, assumptions, predictions, or untested conclusions.
4. A **constructive cycle**: clarify, separate evidence, test, learn, choose, close.
5. A small, reversible experiment.
6. A stopping rule that prevents endless rechecking.
7. A progress chain of concrete actions.

## Valid outcomes

The engine does not force a positive conclusion. Any of these are acceptable:

- The concern is valid and needs action.
- The concern is partly valid and needs a narrower statement.
- The concern is uncertain and needs a small test.
- The concern is not useful to keep rehearsing today and can be classified, scheduled, or closed.

## Voice-to-cycle flow

The Guide can record up to 75 seconds of speech. Gemma first performs transcription only: it is explicitly instructed not to analyze, summarize, diagnose, reframe, or infer emotions. The transcript is placed in the composer for user review. Supportive-cycle guidance starts only after the user chooses to send the reviewed text.

## Project mapper

On Linux, Windows, and macOS, the Guide can open a downloaded project folder and build a read-only map. The mapper:

- Does not execute project code.
- Does not upload repository contents.
- Ignores `.git`, build output, dependency folders, IDE state, and other generated directories.
- Indexes file paths, sizes, top-level structure, and language counts.
- Stops at 2,500 files or 64 MB of indexed file metadata.
- Produces a concise context block the user can review before sending to Gemma.

This makes it possible to convert a belief such as “AI is not useful” into a concrete project inspection or prototype experiment rather than an argument or motivational slogan.

## Prompt safety

The system prompts explicitly prohibit:

- Diagnosis or therapist roleplay.
- Claims about what the user “really feels.”
- Forced optimism or invalidation.
- Treating mood colors as proof.
- Claiming code was executed when only a repository map was inspected.

For urgent danger, the guide still directs the person toward immediate local emergency help and a trusted person.
