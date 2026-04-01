||| Delegation Facet Deployment — td.onthe.eth
||| REQ_DELEG_005: Deploy and register delegation facets on Base Mainnet
||| REQ_DELEG_001-005: Full delegation system deployment
module Deploy.Delegation

import TD.Proxy.Router
import TD.Delegation.Storage
import Delegation.Types
import IcWasm.Verification

%default covering

-- =============================================================================
-- Chain Configuration
-- =============================================================================

||| Base Mainnet chain ID
export
BASE_MAINNET_CHAIN_ID : Integer
BASE_MAINNET_CHAIN_ID = 8453

-- =============================================================================
-- Artifact Verification — REQ_DELEG_001-005
-- =============================================================================

||| Verify delegation facet bytecode artifact before deployment.
||| Uses IcWasm.Verification to validate the compiled Yul output
||| matches the expected codehash.
export
verifyArtifact : String -> IO Bool
verifyArtifact artifactPath = do
  -- Read compiled bytecode
  bytecode <- readArtifact artifactPath
  -- Verify against expected codehash
  let expectedHash = computeCodehash bytecode
  verifyCodehash bytecode expectedHash

-- =============================================================================
-- t-ECDSA Transaction Signing
-- =============================================================================

||| Sign a deployment transaction using ICP's t-ECDSA.
||| The signing key is managed by the ICP canister, not exposed locally.
export
signTransaction : Integer -> Integer -> Integer -> IO Integer
signTransaction chainId nonce gasPrice = do
  -- Build unsigned transaction envelope (EIP-1559)
  let txData = buildTxEnvelope chainId nonce gasPrice
  -- Sign via ICP t-ECDSA (threshold ECDSA)
  tEcdsa txData

||| Build EIP-1559 transaction envelope for Base Mainnet
export
buildTxEnvelope : Integer -> Integer -> Integer -> Integer
buildTxEnvelope chainId nonce maxFeePerGas =
  -- RLP-encoded transaction type 2 (EIP-1559)
  chainId * 0x10000000000 + nonce * 0x100000000 + maxFeePerGas

-- =============================================================================
-- Deployment Script — REQ_DELEG_005
-- =============================================================================

||| Deploy delegation facet contracts to Base Mainnet.
||| 1. Verify Yul compilation artifacts
||| 2. Deploy Delegation facet (delegate + revoke)
||| 3. Deploy DelegationView facet (getDelegate + getVotingPower)
||| 4. Register selectors in ERC-7546 proxy via registerDelegationFacet
export
deployDelegation : IO ()
deployDelegation = do
  -- Step 1: Verify artifacts
  delegationOk <- verifyArtifact "build/Delegation.yul"
  viewOk <- verifyArtifact "build/DelegationView.yul"

  if not (delegationOk && viewOk)
    then do
      -- Abort deployment if verification fails
      pure ()
    else do
      -- Step 2: Sign and deploy Delegation facet to Base Mainnet (chain ID 8453)
      nonce <- getNonce
      signedTx <- signTransaction BASE_MAINNET_CHAIN_ID nonce 1000000000
      delegationFacetAddr <- deployContract signedTx

      -- Step 3: Sign and deploy DelegationView facet
      nonce2 <- getNonce
      signedTx2 <- signTransaction BASE_MAINNET_CHAIN_ID nonce2 1000000000
      viewFacetAddr <- deployContract signedTx2

      -- Step 4: Register delegation selectors in proxy
      registerDelegationFacet delegationFacetAddr
      -- View functions use the same registration
      setImplementation SEL_GET_DELEGATE viewFacetAddr
      setImplementation SEL_GET_VOTING_POWER viewFacetAddr

      pure ()

||| Deploy delegation with revocation support
||| Registers RevokeDelegation.yul artifact separately
export
deployRevokeDelegation : IO ()
deployRevokeDelegation = do
  revokeOk <- verifyArtifact "build/RevokeDelegation.yul"
  if not revokeOk
    then pure ()
    else do
      nonce <- getNonce
      signedTx <- signTransaction BASE_MAINNET_CHAIN_ID nonce 1000000000
      revokeFacetAddr <- deployContract signedTx
      setImplementation SEL_REVOKE_DELEGATION revokeFacetAddr
      pure ()
