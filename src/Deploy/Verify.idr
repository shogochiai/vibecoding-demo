||| IcWasm Verification — Artifact EVM matches Deployed EVM
||| REQ_DELEG_005: Verify deployed contract matches compiled artifact
module Deploy.Verify

import Deploy.Base
import Data.String

%default covering

-- =============================================================================
-- Verification Types
-- =============================================================================

||| Verification result
public export
data VerificationResult
  = Verified
      { artifactHash : String
      , deployedHash : String
      , match : Bool
      }
  | VerificationFailed
      { reason : String
      , details : String
      }

||| Artifact source type
public export
data ArtifactSource
  = FromYul { yulSource : String }
  | FromIdris { idrisModule : String }
  | FromBytecode { bytecode : String }

-- =============================================================================
-- Bytecode Comparison
-- =============================================================================

||| Normalize bytecode for comparison (remove metadata, swarm hash)
export
normalizeBytecode : String -> String
normalizeBytecode bc =
  let -- Remove 0x prefix if present
      hexPart = if isPrefixOf "0x" bc then drop 2 bc else bc
      -- Convert to lowercase for case-insensitive comparison
      lower = toLower hexPart
      -- Remove CBOR metadata (last 43 bytes typically)
      -- This is a simplified version
      withoutMetadata = if length lower > 86
                          then take (length lower - 86) lower
                          else lower
  in withoutMetadata

||| Compare two bytecodes for equality
export
bytecodesEqual : String -> String -> Bool
bytecodesEqual bc1 bc2 =
  normalizeBytecode bc1 == normalizeBytecode bc2

||| Calculate bytecode hash (keccak256)
export
calculateBytecodeHash : String -> String
calculateBytecodeHash bytecode =
  -- In production: actual keccak256 hash
  -- For now: simplified hash representation
  "0x" ++ replicate 64 'f'

-- =============================================================================
-- On-Chain Verification
-- =============================================================================

||| Fetch deployed bytecode from Base Mainnet
export
fetchDeployedBytecode : (rpcUrl : String)
                      -> (contractAddress : String)
                      -> IO (Maybe String)
fetchDeployedBytecode rpcUrl address = do
  -- In production: eth_getCode RPC call
  -- eth_getCode params: [address, "latest"]
  -- Returns: bytecode as hex string
  pure (Just "0x6080...deployed_bytecode")

||| Verify deployed contract matches artifact
||| REQ_DELEG_005: IcWasm.Verification confirms Artifact EVM matches Deployed EVM
export
verifyDeployment : ArtifactSource
                -> (deployedAddress : String)
                -> (rpcUrl : String)
                -> IO VerificationResult
verifyDeployment source deployedAddress rpcUrl = do
  -- Step 1: Get expected bytecode from artifact
  let expectedBytecode = case source of
        FromYul yul => compileYul yul
        FromIdris mod => compileIdris mod
        FromBytecode bc => bc

  -- Step 2: Fetch deployed bytecode
  mDeployed <- fetchDeployedBytecode rpcUrl deployedAddress

  case mDeployed of
    Nothing => pure (VerificationFailed
                      { reason = "Failed to fetch deployed bytecode"
                      , details = "RPC call returned empty or error"
                      })
    Just deployed => do
      -- Step 3: Normalize and compare
      let normalizedExpected = normalizeBytecode expectedBytecode
          normalizedDeployed = normalizeBytecode deployed
          match = normalizedExpected == normalizedDeployed

      if match
        then pure (Verified
                    { artifactHash = calculateBytecodeHash expectedBytecode
                    , deployedHash = calculateBytecodeHash deployed
                    , match = True
                    })
        else pure (VerificationFailed
                    { reason = "Bytecode mismatch"
                    , details = "Expected: " ++ take 40 normalizedExpected ++ "..., Got: " ++ take 40 normalizedDeployed ++ "..."
                    })

-- =============================================================================
-- Compilation Helpers
-- =============================================================================

||| Compile Yul source to bytecode
compileYul : String -> String
compileYul yul =
  -- In production: solc --strict-assembly
  "0x6080...compiled_from_yul"

||| Compile Idris2 module to bytecode
compileIdris : String -> String
compileIdris mod =
  -- In production: idris2-evm codegen
  "0x6080...compiled_from_idris"

-- =============================================================================
-- Verification Report
-- =============================================================================

||| Detailed verification report
public export
record VerificationReport where
  constructor MkVerificationReport
  contractAddress : String
  artifactType : String
  artifactHash : String
  deployedHash : String
  matchStatus : String
  timestamp : String
  verificationMethod : String

||| Generate human-readable verification report
export
generateReport : VerificationResult -> String -> VerificationReport
generateReport result address =
  case result of
    Verified artifact deployed True =>
      MkVerificationReport
        { contractAddress = address
        , artifactType = "Yul/Idris2"
        , artifactHash = artifact
        , deployedHash = deployed
        , matchStatus = "MATCH ✓"
        , timestamp = "2026-04-02T00:00:00Z"
        , verificationMethod = "Bytecode hash comparison"
        }
    VerificationFailed reason details =>
      MkVerificationReport
        { contractAddress = address
        , artifactType = "Yul/Idris2"
        , artifactHash = "N/A"
        , deployedHash = "N/A"
        , matchStatus = "FAILED: " ++ reason
        , timestamp = "2026-04-02T00:00:00Z"
        , verificationMethod = details
        }
    _ =>
      MkVerificationReport
        { contractAddress = address
        , artifactType = "Unknown"
        , artifactHash = "N/A"
        , deployedHash = "N/A"
        , matchStatus = "UNKNOWN"
        , timestamp = "2026-04-02T00:00:00Z"
        , verificationMethod = "Unknown"
        }

||| Format report as markdown
export
formatReportMd : VerificationReport -> String
formatReportMd report =
  unlines
    [ "# Verification Report"
    , ""
    , "| Field | Value |"
    , "|-------|-------|"
    , "| Contract Address | " ++ report.contractAddress ++ " |"
    , "| Artifact Type | " ++ report.artifactType ++ " |"
    , "| Artifact Hash | `" ++ report.artifactHash ++ "` |"
    , "| Deployed Hash | `" ++ report.deployedHash ++ "` |"
    , "| Match Status | **" ++ report.matchStatus ++ "** |"
    , "| Timestamp | " ++ report.timestamp ++ " |"
    , "| Method | " ++ report.verificationMethod ++ " |"
    ]
