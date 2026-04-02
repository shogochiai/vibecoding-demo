||| Voting Module — Delegation-Aware Voting Power
||| REQ_DELEG_005: Integrate delegation into Voting module power calculation
|||
||| This module wraps the core Vote functionality with delegation awareness.
||| When calculating voting power for a voter, it reads the delegated power
||| from the delegation storage to produce the correct aggregated result.
module Voting

import public TextDAO.Storages.Schema
import public TextDAO.Functions.Vote.Vote
import public TextDAO.Functions.Delegation.DelegationView

%default covering

-- =============================================================================
-- Delegation-Aware Voting Power (REQ_DELEG_005)
-- =============================================================================

||| Base voting power per member (1 share = 1 vote)
BASE_VOTING_POWER : Integer
BASE_VOTING_POWER = 1

||| Calculate effective voting power for an address, including delegated power.
||| REQ_DELEG_005: Voting reads delegation state for power calculation.
|||
||| The effective power is:
|||   - If the voter has delegated: 0 (power transferred to delegatee)
|||   - Otherwise: BASE_VOTING_POWER + accumulated delegatedPower from others
export
delegatedPower : EvmAddr -> IO Integer
delegatedPower addr = do
  -- Check if this address has delegated their power away
  active <- isDelegationActive addr
  if active
    then pure 0  -- Delegator has no voting power (transferred to delegatee)
    else do
      -- Base power + any power delegated to this address by others
      accumulated <- votingPowerOf addr
      pure (BASE_VOTING_POWER + accumulated)

||| Get the total effective voting power for a voter address.
||| REQ_DELEG_005: Combines base power with delegated power.
||| This is the function that the tally/voting system should use.
export
effectiveVotingPower : EvmAddr -> IO Integer
effectiveVotingPower = delegatedPower

||| Check if the voter's vote should count with delegation weight.
||| REQ_DELEG_005: A voter who has delegated away has 0 power.
export
canVoteWithPower : EvmAddr -> IO Bool
canVoteWithPower addr = do
  power <- delegatedPower addr
  pure (power > 0)
