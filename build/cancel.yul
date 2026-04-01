object "Contract" {
  code {
    datacopy(0, dataoffset("runtime"), datasize("runtime"))
    return(0, datasize("runtime"))
  }
  object "runtime" {
    code {
      mstore(64, 128)
      pop(TD_Governance_Yul_Cancel_u_main(0))
      // @source: NONE
      function mk_closure(func_id, arity, arg0, arg1, arg2, arg3) -> ptr {
        ptr := mload(64)
        mstore(64, add(ptr, 192))
        mstore(ptr, func_id)
        mstore(add(ptr, 32), arity)
        mstore(add(ptr, 64), arg0)
        mstore(add(ptr, 96), arg1)
        mstore(add(ptr, 128), arg2)
        mstore(add(ptr, 160), arg3)
      }
      // @source: NONE
      function apply_closure(closure, arg) -> result {
        let func_id := mload(closure)
        switch func_id
        case 1 {
  if eq(mload(add(closure, 32)), 1) {
  result := PrimIO_m_unsafePerformIO_0(mload(add(closure, 64)), mload(add(closure, 96)))
  leave
}
  result := mk_closure(mload(closure), sub(mload(add(closure, 32)), 1), mload(add(closure, 64)), mload(add(closure, 96)), mload(add(closure, 128)), arg)
}
        case 2 {
  if eq(mload(add(closure, 32)), 1) {
  result := Subcontract_Core_Entry_m_dispatch_0(mload(add(closure, 64)), mload(add(closure, 96)))
  leave
}
  result := mk_closure(mload(closure), sub(mload(add(closure, 32)), 1), mload(add(closure, 64)), mload(add(closure, 96)), mload(add(closure, 128)), arg)
}
        case 3 {
  if eq(mload(add(closure, 32)), 1) {
  result := TD_Governance_Yul_Cancel_m_cancelProposalEntry_0(mload(add(closure, 64)), mload(add(closure, 96)))
  leave
}
  result := mk_closure(mload(closure), sub(mload(add(closure, 32)), 1), mload(add(closure, 64)), mload(add(closure, 96)), mload(add(closure, 128)), arg)
}
        case 4 {
  if eq(mload(add(closure, 32)), 1) {
  result := TD_Governance_Yul_Cancel_m_cancelProposalEntry_1(mload(add(closure, 64)))
  leave
}
  result := mk_closure(mload(closure), sub(mload(add(closure, 32)), 1), mload(add(closure, 64)), mload(add(closure, 96)), mload(add(closure, 128)), arg)
}
        case 5 {
  if eq(mload(add(closure, 32)), 1) {
  result := m____mainExpression_0__0(mload(add(closure, 64)))
  leave
}
  result := mk_closure(mload(closure), sub(mload(add(closure, 32)), 1), mload(add(closure, 64)), mload(add(closure, 96)), mload(add(closure, 128)), arg)
}
        default {
  result := 0
}
      }
      // @source: <generated>:0:0--0:0
      function m____mainExpression_0__0(v0) -> result {
        result := TD_Governance_Yul_Cancel_u_main(v0)
      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_u_requireNotExecuted(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        v2 := TD_Governance_Proposal_u_isFullyExecuted(v0, v1)
        switch v2
        case 1 {
  v4 := 18
  /* TD.Governance.Yul.Cancel:73:33--73:44 */
  v3 := 0
  v5 := Subcontract_Core_Evidence_u_tagEvidence(v3)
  result := 1
}
        case 0 {
  result := 0
}

      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_u_requireNotCancelled(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        v2 := TD_Governance_Proposal_u_isProposalCancelled(v0, v1)
        switch v2
        case 1 {
  v4 := 18
  /* TD.Governance.Yul.Cancel:64:33--64:44 */
  v3 := 0
  v5 := Subcontract_Core_Evidence_u_tagEvidence(v3)
  result := 1
}
        case 0 {
  result := 0
}

      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_u_requireAuthor(v0, v1, v2) -> result {
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        let v7 := 0
        v3 := TD_Governance_Yul_Cancel_u_checkAuthor(v0, v1, v2)
        switch mload(v3)
        case 1 {
  v4 := mload(add(v3, 32))
  result := 0
}
        case 0 {
  v6 := 2
  /* TD.Governance.Yul.Cancel:55:35--55:46 */
  v5 := 0
  v7 := Subcontract_Core_Evidence_u_tagEvidence(v5)
  result := 1
}

      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_u_main(v0) -> result {
        let v1 := 0
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        /* TD.Governance.Yul.Cancel:202:4--202:9 */
        v1 := TD_Governance_Yul_Cancel_u_cancelProposalSig()
        /* TD.Governance.Yul.Cancel:202:4--202:9 */
        v2 := TD_Governance_Yul_Cancel_u_cancelProposalEntry()
        /* TD.Governance.Yul.Cancel:202:2--202:3 */
        v3 := Subcontract_Core_Entry_u_entry(v1, v2)
        /* TD.Governance.Yul.Cancel:202:2--202:3 */
        v4 := 0
        v5 := 1
        result := Subcontract_Core_Entry_u_dispatch(v5, v0)
      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_u_freeSlot(v0, v1) -> result {
        let v2 := 0
        v2 := 0
        result := TD_Governance_Proposal_u_setProposalExpiration(v0, v2, v1)
      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_u_checkAuthor(v0, v1, v2) -> result {
        let v3 := 0
        let v4 := 0
        let v5 := 0
        v3 := TD_Governance_Proposal_u_getProposalAuthor(v0, v2)
        v5 := Prelude_EqOrd_u____Eq_Integer(v3, v1)
        switch v5
        case 1 {
  v4 := 1
  result := 1
}
        case 0 {
  result := 0
}

      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_u_cancelWithProof(v0, v1, v2, v3, v4) -> result {
        let v5 := 0
        let v6 := 0
        let v7 := 0
        let v8 := 0
        let v9 := 0
        let v10 := 0
        let v11 := 0
        let v12 := 0
        let v13 := 0
        let v14 := 0
        let v15 := 0
        let v16 := 0
        let v17 := 0
        let v18 := 0
        let v19 := 0
        v5 := TD_Governance_Proposal_u_getApprovedHeaderId(v3, v4)
        v6 := 0
        v19 := Prelude_EqOrd_u___Ord_Integer(v5, v6)
        switch v19
        case 1 {
  result := 0
}
        case 0 {
  /* TD.Governance.Yul.Cancel:136:6--136:26 */
  v8 := 1
  v7 := TD_Governance_Proposal_u_setProposalCancelled(v3, v8, v4)
  v9 := TD_Governance_Yul_Cancel_u_freeSlot(v3, v4)
  v10 := TD_Governance_Proposal_u_getProposalAuthor(v3, v4)
  /* TD.Governance.Yul.Cancel:147:6--147:12 */
  v12 := 0
  v11 := EVM_Primitives_u_mstore(v12, v3, v4)
  /* TD.Governance.Yul.Cancel:148:6--148:12 */
  v14 := 32
  v13 := EVM_Primitives_u_mstore(v14, v10, v4)
  /* TD.Governance.Yul.Cancel:149:6--149:10 */
  v16 := 0
  /* TD.Governance.Yul.Cancel:149:6--149:10 */
  v17 := 64
  /* TD.Governance.Yul.Cancel:149:6--149:10 */
  v18 := 77224998599736155558143098436089755941908938948529740497550885062050548656827
  v15 := EVM_Primitives_u_log1(v16, v17, v18, v4)
  result := 1
}

      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_u_cancelProposalSig() -> result {
        let v0 := 0
        let v1 := 0
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        v4 := 0
        /* TD.Governance.Yul.Cancel:82:43--82:44 */
        v0 := 0
        /* TD.Governance.Yul.Cancel:82:43--82:44 */
        v1 := 0
        v5 := 1
        /* TD.Governance.Yul.Cancel:82:54--82:55 */
        v2 := 3
        /* TD.Governance.Yul.Cancel:82:54--82:55 */
        v3 := 0
        v6 := 1
        result := 0
      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_u_cancelProposalEntry() -> result {
        let v0 := 0
        let v1 := 0
        v0 := 3639050463
        v1 := mk_closure(4, 1, 0, 0, 0, 0)
        result := 1
      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_m_cancelProposalEntry_1(v0) -> result {
        let v1 := 0
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        let v7 := 0
        let v8 := 0
        /* TD.Governance.Yul.Cancel:190:9--190:19 */
        v2 := mk_closure(3, 2, 0, 0, 0, 0)
        v1 := Subcontract_Core_ABI_Decoder_u_runDecoder(v2, v0)
        v3 := TD_Governance_Yul_Cancel_u_cancelProposal(v1, v0)
        switch mload(v3)
        case 0 {
  v4 := mload(add(v3, 32))
  result := EVM_Primitives_u_returnBool(v4, v0)
}
        case 1 {
  v5 := mload(add(v3, 32))
  v6 := mload(add(v3, 64))
  v7 := 0
  v8 := 0
  result := EVM_Primitives_u_evmRevert(v7, v8, v0)
}

      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_m_cancelProposalEntry_0(v1, v0) -> result {
        result := Subcontract_Core_ABI_Decoder_u_decodeUint256(v1, v0)
      }
      // @source: TD.Governance.Yul.Cancel:0:0--0:0
      function TD_Governance_Yul_Cancel_u_cancelProposal(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        let v7 := 0
        let v8 := 0
        let v9 := 0
        let v10 := 0
        let v11 := 0
        let v12 := 0
        let v13 := 0
        let v14 := 0
        let v15 := 0
        let v16 := 0
        let v17 := 0
        let v18 := 0
        let v19 := 0
        v2 := EVM_Primitives_u_caller(v1)
        v3 := TD_Governance_Yul_Cancel_u_requireAuthor(v0, v2, v1)
        switch mload(v3)
        case 1 {
  v4 := mload(add(v3, 32))
  v5 := mload(add(v3, 64))
  result := 1
}
        case 0 {
  v6 := mload(add(v3, 32))
  v7 := TD_Governance_Yul_Cancel_u_requireNotCancelled(v0, v1)
  switch mload(v7)
  case 1 {
  v8 := mload(add(v7, 32))
  v9 := mload(add(v7, 64))
  result := 1
}
  case 0 {
  v10 := mload(add(v7, 32))
  v11 := TD_Governance_Yul_Cancel_u_requireNotExecuted(v0, v1)
  switch mload(v11)
  case 1 {
  v12 := mload(add(v11, 32))
  v13 := mload(add(v11, 64))
  result := 1
}
  case 0 {
  v14 := mload(add(v11, 32))
  v15 := TD_Governance_Yul_Cancel_u_cancelWithProof(v6, v10, v14, v0, v1)
  switch v15
  case 1 {
  v16 := 1
  result := 0
}
  case 0 {
  v18 := 18
  /* TD.Governance.Yul.Cancel:179:51--179:62 */
  v17 := 0
  v19 := Subcontract_Core_Evidence_u_tagEvidence(v17)
  result := 1
}

}

}

}

      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_setProposalExpiration(v0, v1, v2) -> result {
        let v3 := 0
        let v4 := 0
        let v5 := 0
        v3 := TD_Governance_Proposal_u_getProposalMetaSlot(v0, v2)
        v4 := TD_Governance_Proposal_u_META_OFFSET_EXPIRATION()
        v5 := add(v3, v4)
        result := EVM_Primitives_u_sstore(v5, v1, v2)
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_setProposalCancelled(v0, v1, v2) -> result {
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        v3 := TD_Governance_Proposal_u_getProposalMetaSlot(v0, v2)
        v4 := TD_Governance_Proposal_u_META_OFFSET_CANCELLED()
        v5 := add(v3, v4)
        /* TD.Governance.Proposal:364:37--364:41 */
        let case_result_0 := 0
        switch v1
        case 1 {
  case_result_0 := 1
}
        case 0 {
  case_result_0 := 0
}

        v6 := case_result_0
        result := EVM_Primitives_u_sstore(v5, v6, v2)
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_isProposalCancelled(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        v2 := TD_Governance_Proposal_u_getProposalMetaSlot(v0, v1)
        v4 := TD_Governance_Proposal_u_META_OFFSET_CANCELLED()
        /* TD.Governance.Proposal:358:9--358:14 */
        v5 := add(v2, v4)
        v3 := EVM_Primitives_u_sload(v5, v1)
        v6 := 1
        result := Prelude_EqOrd_u____Eq_Integer(v3, v6)
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_isFullyExecuted(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        v2 := TD_Governance_Proposal_u_getProposalMetaSlot(v0, v1)
        v4 := TD_Governance_Proposal_u_META_OFFSET_EXECUTED()
        /* TD.Governance.Proposal:329:9--329:14 */
        v5 := add(v2, v4)
        v3 := EVM_Primitives_u_sload(v5, v1)
        v6 := 1
        result := Prelude_EqOrd_u____Eq_Integer(v3, v6)
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_getProposalSlot(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        let v7 := 0
        let v8 := 0
        /* TD.Governance.Proposal:175:2--175:8 */
        v3 := 0
        v2 := EVM_Primitives_u_mstore(v3, v0, v1)
        /* TD.Governance.Proposal:176:2--176:8 */
        v5 := 32
        /* TD.Governance.Proposal:176:2--176:8 */
        v6 := TD_Governance_Proposal_u_SLOT_DELIBERATION()
        v4 := EVM_Primitives_u_mstore(v5, v6, v1)
        v7 := 0
        v8 := 64
        result := EVM_Primitives_u_keccak256(v7, v8, v1)
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_getProposalMetaSlot(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        v2 := TD_Governance_Proposal_u_getProposalSlot(v0, v1)
        v3 := 48
        result := add(v2, v3)
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_getProposalAuthor(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        v2 := TD_Governance_Proposal_u_getProposalMetaSlot(v0, v1)
        v3 := TD_Governance_Proposal_u_META_OFFSET_AUTHOR()
        v4 := add(v2, v3)
        result := EVM_Primitives_u_sload(v4, v1)
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_getApprovedHeaderId(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        v2 := TD_Governance_Proposal_u_getProposalMetaSlot(v0, v1)
        v3 := TD_Governance_Proposal_u_META_OFFSET_APPROVED_HEADER()
        v4 := add(v2, v3)
        result := EVM_Primitives_u_sload(v4, v1)
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_SLOT_DELIBERATION() -> result {
        result := 4096
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_META_OFFSET_EXPIRATION() -> result {
        result := 1
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_META_OFFSET_EXECUTED() -> result {
        result := 7
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_META_OFFSET_CANCELLED() -> result {
        result := 9
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_META_OFFSET_AUTHOR() -> result {
        result := 8
      }
      // @source: TD.Governance.Proposal:0:0--0:0
      function TD_Governance_Proposal_u_META_OFFSET_APPROVED_HEADER() -> result {
        result := 5
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_sstore(v0, v1, v2) -> result {
        result := EVM_Primitives_u_prim__sstore(v0, v1, v2)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_sload(v0, v1) -> result {
        result := EVM_Primitives_u_prim__sload(v0, v1)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_returnUint(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        /* EVM.Primitives:443:2--443:8 */
        v3 := 0
        v2 := EVM_Primitives_u_mstore(v3, v0, v1)
        v4 := 0
        v5 := 32
        result := EVM_Primitives_u_evmReturn(v4, v5, v1)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_returnBool(v0, v1) -> result {
        let v2 := 0
        /* EVM.Primitives:448:13--448:17 */
        let case_result_0 := 0
        switch v0
        case 1 {
  case_result_0 := 1
}
        case 0 {
  case_result_0 := 0
}

        v2 := case_result_0
        result := EVM_Primitives_u_returnUint(v2, v1)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_prim__sstore(arg0, arg1, arg2) -> result {
        sstore(arg0, arg1)
        result := 0
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_prim__sload(arg0, arg1) -> result {
        result := sload(arg0)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_prim__revert(arg0, arg1, arg2) -> result {
        revert(arg0, arg1)
        result := 0
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_prim__return(arg0, arg1, arg2) -> result {
        return(arg0, arg1)
        result := 0
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_prim__mstore(arg0, arg1, arg2) -> result {
        mstore(arg0, arg1)
        result := 0
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_prim__log1(arg0, arg1, arg2, arg3) -> result {
        log1(arg0, arg1, arg2)
        result := 0
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_prim__keccak256(arg0, arg1, arg2) -> result {
        result := keccak256(arg0, arg1)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_prim__caller(arg0) -> result {
        result := caller()
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_prim__calldataload(arg0, arg1) -> result {
        result := calldataload(arg0)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_mstore(v0, v1, v2) -> result {
        result := EVM_Primitives_u_prim__mstore(v0, v1, v2)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_log1(v0, v1, v2, v3) -> result {
        result := EVM_Primitives_u_prim__log1(v0, v1, v2, v3)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_keccak256(v0, v1, v2) -> result {
        result := EVM_Primitives_u_prim__keccak256(v0, v1, v2)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_getSelector(v0) -> result {
        let v1 := 0
        let v2 := 0
        let v3 := 0
        /* EVM.Primitives:435:11--435:23 */
        v2 := 0
        v1 := EVM_Primitives_u_calldataload(v2, v0)
        v3 := 26959946667150639794667015087019630673637144422540572481103610249216
        result := Prelude_Num_u_div_Integral_Integer(v1, v3)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_evmRevert(v0, v1, v2) -> result {
        result := EVM_Primitives_u_prim__revert(v0, v1, v2)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_evmReturn(v0, v1, v2) -> result {
        result := EVM_Primitives_u_prim__return(v0, v1, v2)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_caller(v0) -> result {
        result := EVM_Primitives_u_prim__caller(v0)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_calldataload(v0, v1) -> result {
        result := EVM_Primitives_u_prim__calldataload(v0, v1)
      }
      // @source: Prelude.Num:0:0--0:0
      function Prelude_Num_u_div_Integral_Integer(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        v2 := 0
        v4 := Prelude_EqOrd_u____Eq_Integer(v1, v2)
        switch v4
        case 0 {
  result := div(v0, v1)
}
        default {
  v3 := 0
  revert(0, 0)
  result := 0
}
      }
      // @source: Prelude.EqOrd:0:0--0:0
      function Prelude_EqOrd_u___Ord_Integer(v0, v1) -> result {
        let v2 := 0
        v2 := gt(v0, v1)
        switch v2
        case 0 {
  result := 0
}
        default {
  result := 1
}
      }
      // @source: Prelude.EqOrd:0:0--0:0
      function Prelude_EqOrd_u____Eq_Integer(v0, v1) -> result {
        let v2 := 0
        v2 := eq(v0, v1)
        switch v2
        case 0 {
  result := 0
}
        default {
  result := 1
}
      }
      // @source: PrimIO:0:0--0:0
      function PrimIO_m_unsafePerformIO_0(v0, v1) -> result {
        result := apply_closure(v0, v1)
      }
      // @source: Data.List:0:0--0:0
      function Data_List_u_find(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        switch mload(v1)
        case 0 {
  result := 0
}
        case 1 {
  v2 := mload(add(v1, 32))
  v3 := mload(add(v1, 64))
  v4 := apply_closure(v0, v2)
  switch v4
  case 1 {
  result := 1
}
  case 0 {
  result := Data_List_u_find(v0, v3)
}

}

      }
      // @source: Subcontract.Core.Evidence:0:0--0:0
      function Subcontract_Core_Evidence_u_tagEvidence(v0) -> result {
        let v1 := 0
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        v2 := 0
        /* Subcontract.Core.Evidence:43:31--43:32 */
        v1 := 0
        v3 := 1
        v4 := 0
        v5 := 0
        v6 := 0
        result := 0
      }
      // @source: Subcontract.Core.ABI.Decoder:0:0--0:0
      function Subcontract_Core_ABI_Decoder_u_runDecoder(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        /* Subcontract.Core.ABI.Decoder:139:13--139:22 */
        v3 := 4
        /* Subcontract.Core.ABI.Decoder:139:13--139:22 */
        v4 := apply_closure(v0, v3)
        v2 := apply_closure(v4, v1)
        switch mload(v2)
        case 1 {
  v5 := mload(add(v2, 32))
  v6 := mload(add(v2, 64))
  result := v5
}

      }
      // @source: Subcontract.Core.ABI.Decoder:0:0--0:0
      function Subcontract_Core_ABI_Decoder_u_prim__calldataload(arg0, arg1) -> result {
        result := calldataload(arg0)
      }
      // @source: Subcontract.Core.ABI.Decoder:0:0--0:0
      function Subcontract_Core_ABI_Decoder_u_decodeUint256(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        v2 := Subcontract_Core_ABI_Decoder_u_calldataload(v0, v1)
        v3 := 32
        v4 := add(v0, v3)
        result := 1
      }
      // @source: Subcontract.Core.ABI.Decoder:0:0--0:0
      function Subcontract_Core_ABI_Decoder_u_calldataload(v0, v1) -> result {
        result := Subcontract_Core_ABI_Decoder_u_prim__calldataload(v0, v1)
      }
      // @source: Subcontract.Core.Entry:0:0--0:0
      function Subcontract_Core_Entry_u_someEntrySelector(v0) -> result {
        let v1 := 0
        let v2 := 0
        let v3 := 0
        let v4 := 0
        switch mload(v0)
        case 1 {
  v1 := mload(add(v0, 32))
  v2 := mload(add(v0, 64))
  switch mload(v2)
  case 1 {
  v3 := mload(add(v2, 32))
  v4 := mload(add(v2, 64))
  result := v3
}

}

      }
      // @source: Subcontract.Core.Entry:0:0--0:0
      function Subcontract_Core_Entry_u_someEntryHandler(v0) -> result {
        let v1 := 0
        let v2 := 0
        let v3 := 0
        let v4 := 0
        switch mload(v0)
        case 1 {
  v1 := mload(add(v0, 32))
  v2 := mload(add(v0, 64))
  switch mload(v2)
  case 1 {
  v3 := mload(add(v2, 32))
  v4 := mload(add(v2, 64))
  result := v4
}

}

      }
      // @source: Subcontract.Core.Entry:0:0--0:0
      function Subcontract_Core_Entry_u_entry(v0, v1) -> result {
        result := 1
      }
      // @source: Subcontract.Core.Entry:0:0--0:0
      function Subcontract_Core_Entry_u_dispatch(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        let v7 := 0
        let v8 := 0
        v2 := EVM_Primitives_u_getSelector(v1)
        /* Subcontract.Core.Entry:67:7--67:11 */
        v3 := mk_closure(2, 1, v2, 0, 0, 0)
        v8 := Data_List_u_find(v3, v0)
        switch mload(v8)
        case 0 {
  v4 := 0
  v5 := 0
  result := EVM_Primitives_u_evmRevert(v4, v5, v1)
}
        case 1 {
  v6 := mload(add(v8, 32))
  v7 := Subcontract_Core_Entry_u_someEntryHandler(v6)
  result := apply_closure(v7, v1)
}

      }
      // @source: Subcontract.Core.Entry:0:0--0:0
      function Subcontract_Core_Entry_m_dispatch_0(v0, v1) -> result {
        let v2 := 0
        v2 := Subcontract_Core_Entry_u_someEntrySelector(v1)
        result := Prelude_EqOrd_u____Eq_Integer(v2, v0)
      }
    }
  }
}