# 1. Intro & Goal

**Title:** Add swapExactInputSingle to td

**Goal:** Enable td treasury to swap tokens via Uniswap V3 on Base Mainnet.

# 2. Concept / Value Proposition

DAOs accumulate tokens but need to rebalance. Direct Uniswap V3 integration
keeps funds non-custodial and fully governed through the IP proposal mechanism.

# 6. What is it?

## Target Contract

- **Base Mainnet SwapRouter**: `0x2626664c2603336E57B271c5C0b26F421741e481`

## Function Signature

```
swapExactInputSingle(tokenIn, tokenOut, amountIn, amountOutMinimum) -> amountOut
```

## Security

- Member-only access control
- amountOutMinimum > 0 (slippage protection)
- Approve exact amountIn to SwapRouter (no infinite approval)

## Upgrade Path

1. Colony implements in Idris2
2. idris2-evm compiles to Yul -> solc -> bytecode
3. Release proposal bundles bytecode with verification hash
4. t-ECDSA signs upgradeTo(newImpl)
5. TheWorld records verification chain
