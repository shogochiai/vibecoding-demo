# 1. Intro & Goal

**Title:** Add cancelProposal to td

**Goal:** Allow proposal authors to cancel their own proposals before voting ends,
freeing up governance bandwidth for active proposals.

# 2. Concept / Value Proposition

Proposals sometimes become outdated or are superseded by better alternatives.
Currently there is no way to withdraw a proposal once submitted. This wastes
voters' attention and clutters the active proposal list.

cancelProposal lets the original author retract their proposal, moving it to
a "cancelled" state that excludes it from tally and frees the voting slot.

# 3. Product Vision

Part of the governance UX improvements roadmap. Future extensions:
- Batch cancel (author cancels all their draft proposals)
- Admin cancel (governance can cancel spam proposals via vote)

# 4. Who's it for?

- **Shareholders** who submitted a proposal and want to retract it
- **Colony operators** who want a clean active proposal list

# 5. Why build it?

Without cancel, abandoned proposals sit in "active" until voting period expires.
This creates noise in `etherclaw flow` output and wastes tally compute cycles.
Low implementation cost (single canister method + CLI command) with immediate UX benefit.

---

# 6. What is it?

## Glossary

| Term | Definition |
|------|------------|
| Proposal | An IP (Improvement Proposal) submitted to TheWorld |
| Author | The principal who called postIpProposal |
| Cancelled | Terminal state — proposal excluded from tally |

## User Types

| Type | Description |
|------|-------------|
| Shareholder | Holds G_token, submits and votes on proposals |

## UI / Screens / Functionalities

CLI: `etherclaw ip cancel <ipId>`
Canister: `cancelIpProposal(text) -> (text)` (JSON arg: `{"ipId": N}`)

# 7. Brainstormed Ideas

- Allow cancel only if no votes have been cast yet
- Allow cancel anytime before finalization (chosen approach — simpler)
- Emit a cancellation event to mmnt for audit trail

# 8. Competitors & Product Inspiration

- Nouns DAO: proposals can be cancelled by proposer before voting starts
- Snapshot: off-chain proposals can be deleted by author anytime

# 11. Tech Notes

- TheWorld canister: add `cancelIpProposal` update method
- Check `msg_caller == proposal.author` for authorization
- Set `ip_proposals.status = 'cancelled'` in SQLite
- Exclude cancelled proposals from `tallyAllDueIps`
- CLI: `etherclaw ip cancel <ipId>` calls the canister method
