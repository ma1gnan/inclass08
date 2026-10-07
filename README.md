# In-Class 08 / Fall Festival Roster
Deborah / CSC4360 / pathway:
Flutter / Dart versions; device / OS:
Setup/run commands:

## Storage notes
- Schema and initialization:
- Input policy, IDs, CRUD source locations:
- Memory example / preference example / SQLite example:

## Actual tests
| Test | Action/input | Expected | Observed IDs/ages/count | Pass/fail |
| --- | --- | --- | --- | --- |
| T1 | added Jane doe, age 24|One guest saved with database generated ID | ID 1, age 24, count 1 | pass |
| T2 | Edited guest ID 1 by changing the age from 24 to 25 | Same ID, updated age, count remain 1 | ID 1, age 25, count 1, feedback "Updated guest ID 1" | pass |
| T3 | added john doe, age 19|now Two guest saved with database | ID 2, age 19 count 2 | pass |
| T4 | opened delete confirmation for jordan and tapped cancel | no database change | both guest remained; count 2 | pass |
| T5 | | confirmed deletion of john doe | john removed, jane remains | jane ID:1, age:25, count:1 | pass |
| T6 | List every invalid/boundary input | | | |
T4 stop/relaunch method:
Evidence: evidence/T4_before.png, evidence/T4_after.png,
          evidence/T6_invalid.png, evidence/analysis_output.txt
Analyzer command/result; known limitations:

## Short reflections
1. Prediction I predicite there will not be any database changes since the action was canceled
2. My two IDs and update result; why identity matters:
3. My self-walkthrough observation and proposed improvement:
4. Graduate only: validation/schema design reasoning:

## Attribution
Starter source / references / AI assistance used: