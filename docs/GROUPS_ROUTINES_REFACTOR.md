# RFC: Routine-Centric Collaboration Refactor

## Status

Proposed

## Owner

Dance Analysis Client Team

## Summary

Current functionality works, but the data and UX hierarchy do not match product intent. Users think in terms of **Routines**, not **Groups**. This RFC moves the system to a routine-centric model where:

- `Routine` is the primary user-facing collaboration unit.
- Groups (if retained) are internal implementation details.
- Dancers in routines may be linked to real accounts **or** remain unclaimed/non-user dancers.
- Bottom navigation surfaces `Routines`; `History` is moved into routine context.

---

## Problem Statement

### Current issues

1. Groups are exposed as a top-level concept, but users do not intentionally create/manage groups.
2. Collaboration and permissions are conceptually attached to routines, not groups.
3. The current structure makes it difficult to support dancers without user accounts cleanly.
4. `History` as a global tab is less meaningful than routine-scoped history.

### Product intent

- Creating a routine should “just work” for solo and partnered workflows.
- Inviting collaborators should feel routine-scoped.
- A dancer can exist in a routine even without an app account.
- Linking a dancer to a user account can happen later, without losing notes/history.

---

## Goals

1. Make `Routine` the primary user-facing aggregate.
2. Keep existing behavior working while migrating safely.
3. Support both:
   - account-backed collaborators
   - unclaimed dancers (no account required)
4. Move navigation to routine-first UX.
5. Preserve data integrity for notes, figures, and history.

## Non-Goals

1. Full permissions redesign beyond minimum role support.
2. Rebuilding all history analytics in this phase.
3. Immediate physical deletion of legacy group structures on day one.

---

## Proposed Domain Model

## 1) Routine

Primary container visible to users.

Suggested fields:

- `id`
- `name`
- `createdByUserId`
- `createdAt`
- `updatedAt`
- optional: `style`, `status`, `description`

## 2) RoutineMembership

Controls access/permissions for app users.

Suggested fields:

- `id`
- `routineId`
- `userId`
- `role` (`owner` | `editor` | `viewer`)
- `joinedAt`

Constraints:

- unique (`routineId`, `userId`)
- at least one owner per routine

## 3) RoutineDancer

Logical dancer entities used for choreography, notes, and attribution.

Suggested fields:

- `id`
- `routineId`
- `displayName`
- optional `position` (`lead`, `follow`, `dancer1`, `dancer2`, etc.)
- `linkedUserId` (nullable)
- `createdByUserId`
- `createdAt`
- `updatedAt`

Key behavior:

- `linkedUserId = null` means dancer exists without app account.
- Linking later should not break references.

## 4) RoutineInvite (recommended)

Routine-scoped invitations.

Suggested fields:

- `id`
- `routineId`
- `invitedByUserId`
- `email` and/or `inviteeUserId`
- optional `intendedDancerId`
- `status` (`pending`, `accepted`, `revoked`, `expired`)
- `expiresAt`
- `createdAt`

---

## Business Rules

1. **Create Routine**
   - Automatically creates routine.
   - Automatically creates owner membership for creator.
   - Optionally creates initial dancer slots per template/workflow.

2. **Invite User**
   - Invite is scoped to routine.
   - On accept, create membership.
   - Optionally link invitee to an existing unclaimed dancer.

3. **Add Dancer Without Account**
   - Create `RoutineDancer` with null `linkedUserId`.
   - Dancer remains fully valid for notes/figures/history attribution.

4. **Link Dancer to Account Later**
   - Update `linkedUserId`.
   - Keep dancer ID stable so historical references remain intact.

5. **Authorization**
   - Membership determines access.
   - Dancer linkage does not itself grant access.
   - Only authorized members can create invites or edit dancer links.

---

## UX / Navigation Changes

## Bottom Nav

- Add: `Routines`
- Remove: `History` (top-level)

## History Placement

- Move history into routine detail, e.g.:
  - `Overview | Figures | Notes | History`

## Routine Detail

- Show dancers list with clear states:
  - Linked dancer (has account)
  - Unlinked dancer (name-only)

Actions:

- Add dancer
- Invite collaborator
- Link existing user to dancer
- Rename dancer / update position

---

## API/Service Refactor (target)

Examples (adapt naming to existing conventions):

- `POST /routines`
- `GET /routines/:id`
- `GET /routines`
- `POST /routines/:id/invites`
- `POST /routines/:id/dancers`
- `PATCH /routines/:id/dancers/:dancerId/link-user`
- `DELETE /routines/:id/members/:userId` (if supported)

Authorization helpers (centralized):

- `canReadRoutine(userId, routineId)`
- `canEditRoutine(userId, routineId)`
- `canManageRoutineMembers(userId, routineId)`

---

## Migration Plan

## Phase 1 — Additive Schema

- Add routine-centric tables/fields (`RoutineMembership`, `RoutineDancer`, `RoutineInvite`).
- Keep existing group pathways operational.

## Phase 2 — Backfill

- Backfill memberships from existing collaboration/group records.
- Backfill dancer records from current participant structures.
- Ensure notes/history references remain valid and mapped.

## Phase 3 — Dual Read/Write

- New writes use routine-centric model.
- Reads may temporarily fallback to legacy data where needed.
- Add telemetry for fallback usage and permission failures.

## Phase 4 — Cutover

- Remove group UI exposure.
- Switch client-facing endpoints/queries fully to routines.
- Keep compatibility layer temporarily for rollback safety.

## Phase 5 — Cleanup

- Remove dead code paths.
- Archive or drop obsolete group constructs once stable.

---

## Acceptance Criteria

1. Creating a routine creates owner membership automatically.
2. User can add dancer without account and attach notes/figures/history to that dancer.
3. User can later link that dancer to a registered account without data loss.
4. Invited user gains routine membership upon acceptance.
5. Bottom nav shows `Routines`; global `History` tab is removed.
6. Routine detail contains accessible history view.
7. Existing routines/data remain accessible after migration.
8. No orphaned note/history references after backfill.

---

## Risks & Mitigations

1. **Permission regressions**
   - Mitigation: centralized authorization checks + integration tests.

2. **Broken historical references**
   - Mitigation: preserve dancer IDs; migration validation scripts.

3. **Invite edge cases (duplicate/revoked/expired)**
   - Mitigation: explicit invite status machine + constraints.

4. **Rollout instability**
   - Mitigation: feature flag + staged rollout + observability.

---

## Observability / Rollout

Feature flag:

- `routine_centric_model`

Track metrics:

- Routine creation success/failure
- Invite send/accept rates
- Dancer-link success/failure
- Authorization denials
- Legacy fallback read count

Rollout:

1. Internal/test users
2. Small production cohort
3. Full rollout after stability criteria met

---

## Testing Plan

## Unit

- Routine creation + owner membership.
- Dancer create with null/non-null linked user.
- Link dancer to user conflict cases and constraints.

## Integration

- Invite flow (send -> accept -> membership created).
- Migration integrity against staging snapshot.
- Notes/history continuity with dancer references.

## UI

- Bottom nav changes.
- Routine-first navigation.
- Dancer states and linking interactions.

## Data Validation

- Count checks pre/post migration.
- Orphan reference checks = 0.
- Membership uniqueness checks.

---

## Implementation Checklist

## Backend

- [ ] Add new schema/tables and indexes
- [ ] Add service layer methods for routine memberships and dancers
- [ ] Add invite lifecycle endpoints/handlers
- [ ] Add/centralize authorization guards
- [ ] Add migration scripts + validation scripts
- [ ] Add telemetry/logging

## Frontend

- [ ] Replace bottom nav `History` with `Routines`
- [ ] Build/update routines list and routine detail entry points
- [ ] Add dancers UI (linked/unlinked states)
- [ ] Add invite/link workflows
- [ ] Move history into routine detail

## QA / Release

- [ ] Run staging migration and verify reports
- [ ] Execute regression suite
- [ ] Enable feature flag for internal users
- [ ] Staged rollout with monitoring
- [ ] Cleanup legacy group exposure after stability window
