||| REQ_TIMELINE_001: Unit test — timeline returns correct event sequence and timestamps
module TimelineTest

import TimelineStorage

%default total

----------------------------------------------------------------------
-- Test helpers
----------------------------------------------------------------------

assert : Bool -> String -> String
assert True  name = name ++ ": PASS"
assert False name = name ++ ": FAIL"

----------------------------------------------------------------------
-- Tests
----------------------------------------------------------------------

||| Test: eventIndex returns correct indices for all event types
test_eventIndex : String
test_eventIndex =
  assert (eventIndex Propose == 0
       && eventIndex Vote    == 1
       && eventIndex Tally   == 2
       && eventIndex Execute == 3)
    "test_REQ_TIMELINE_001_eventIndex"

||| Test: storage slots are distinct for different events of same proposal
test_slotsDistinct : String
test_slotsDistinct =
  let s0 = eventSlot 1 Propose
      s1 = eventSlot 1 Vote
      s2 = eventSlot 1 Tally
      s3 = eventSlot 1 Execute
  in assert (s0 /= s1 && s1 /= s2 && s2 /= s3 && s0 /= s3)
       "test_REQ_TIMELINE_002_slotsDistinct"

||| Test: storage slots are distinct for different proposals
test_proposalIsolation : String
test_proposalIsolation =
  let s0 = eventSlot 1 Propose
      s1 = eventSlot 2 Propose
  in assert (s0 /= s1)
       "test_REQ_TIMELINE_002_proposalIsolation"

||| Test: slots are sequential within a proposal (4-slot stride)
test_slotStride : String
test_slotStride =
  let s0 = eventSlot 0 Propose
      s1 = eventSlot 0 Vote
      s2 = eventSlot 0 Tally
      s3 = eventSlot 0 Execute
  in assert (s1 == s0 + 1 && s2 == s0 + 2 && s3 == s0 + 3)
       "test_REQ_TIMELINE_002_slotStride"

||| Test: event order is Propose(0) < Vote(1) < Tally(2) < Execute(3)
test_eventOrdering : String
test_eventOrdering =
  assert (eventIndex Propose < eventIndex Vote
       && eventIndex Vote < eventIndex Tally
       && eventIndex Tally < eventIndex Execute)
    "test_REQ_TIMELINE_001_eventOrdering"

----------------------------------------------------------------------
-- Main: run all tests
----------------------------------------------------------------------

main : IO ()
main = do
  putStrLn test_eventIndex
  putStrLn test_slotsDistinct
  putStrLn test_proposalIsolation
  putStrLn test_slotStride
  putStrLn test_eventOrdering
  putStrLn "PASS"
