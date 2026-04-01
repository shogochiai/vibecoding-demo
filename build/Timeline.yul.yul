object "Contract" {
  code {
    datacopy(0, dataoffset("runtime"), datasize("runtime"))
    return(0, datasize("runtime"))
  }
  object "runtime" {
    code {
      mstore(64, 128)
      pop(Timeline_u_main(0))
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
  result := Timeline_m_loadEventTimestamp_0(mload(add(closure, 64)), mload(add(closure, 96)))
  leave
}
  result := mk_closure(mload(closure), sub(mload(add(closure, 32)), 1), mload(add(closure, 64)), mload(add(closure, 96)), mload(add(closure, 128)), arg)
}
        case 3 {
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
        result := Timeline_u_main(v0)
      }
      // @source: Timeline:0:0--0:0
      function Timeline_u_main(v0) -> result {
        result := Timeline_u_dispatch(v0)
      }
      // @source: Timeline:0:0--0:0
      function Timeline_u_loadEventTimestamp(v0, v1) -> result {
        let v2 := 0
        v2 := TimelineStorage_u_eventSlot(v0, v1)
        result := mk_closure(2, 1, v2, 0, 0, 0)
      }
      // @source: Timeline:0:0--0:0
      function Timeline_m_loadEventTimestamp_0(v0, v1) -> result {
        result := EVM_Primitives_u_sload(v0, v1)
      }
      // @source: Timeline:0:0--0:0
      function Timeline_u_getProposalTimeline(v0) -> result {
        let v1 := 0
        let v2 := 0
        let v3 := 0
        /* Timeline:79:16--79:28 */
        v2 := 4
        v1 := EVM_Primitives_u_calldataload(v2, v0)
        v3 := Timeline_u_buildTimeline(v1, v0)
        result := Timeline_u_encodeTimeline(v3, v0)
      }
      // @source: Timeline:0:0--0:0
      function Timeline_u_encodeTimeline(v0, v1) -> result {
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
        let v20 := 0
        let v21 := 0
        let v22 := 0
        let v23 := 0
        let v24 := 0
        let v25 := 0
        let v26 := 0
        let v27 := 0
        let v28 := 0
        let v29 := 0
        let v30 := 0
        let v31 := 0
        let v32 := 0
        let v33 := 0
        let v34 := 0
        let v35 := 0
        let v36 := 0
        let v37 := 0
        let v38 := 0
        let v39 := 0
        let v40 := 0
        let v41 := 0
        let v42 := 0
        let v43 := 0
        let v44 := 0
        let v45 := 0
        let v46 := 0
        let v47 := 0
        let v48 := 0
        let v49 := 0
        let v50 := 0
        let v51 := 0
        let v52 := 0
        let v53 := 0
        let v54 := 0
        let v55 := 0
        let v56 := 0
        let v57 := 0
        let v58 := 0
        let v59 := 0
        let v60 := 0
        let v61 := 0
        let v62 := 0
        let v63 := 0
        let v64 := 0
        let v65 := 0
        let v66 := 0
        let v67 := 0
        let v68 := 0
        let v69 := 0
        let v70 := 0
        let v71 := 0
        let v72 := 0
        let v73 := 0
        let v74 := 0
        let v75 := 0
        let v76 := 0
        let v77 := 0
        let v78 := 0
        let v79 := 0
        /* Timeline:60:2--60:8 */
        v10 := 0
        /* Timeline:22:0--30:31 */
        let case_result_0 := 0
        switch mload(v0)
        case 0 {
  v3 := mload(add(v0, 32))
  v4 := mload(add(v0, 64))
  v5 := mload(add(v0, 96))
  v6 := mload(add(v0, 128))
  /* Timeline:22:0--30:31 */
  let case_result_1 := 0
  switch mload(v3)
  case 1 {
  v7 := mload(add(v3, 32))
  v8 := mload(add(v3, 64))
  case_result_1 := v7
}

  case_result_0 := case_result_1
}

        /* Timeline:60:12--60:22 */
        v9 := case_result_0
        /* Timeline:60:2--60:8 */
        v11 := TimelineStorage_u_eventIndex(v9)
        v2 := EVM_Primitives_u_mstore(v10, v11, v1)
        /* Timeline:61:2--61:8 */
        v19 := 32
        /* Timeline:22:0--30:31 */
        let case_result_2 := 0
        switch mload(v0)
        case 0 {
  v13 := mload(add(v0, 32))
  v14 := mload(add(v0, 64))
  v15 := mload(add(v0, 96))
  v16 := mload(add(v0, 128))
  /* Timeline:22:0--30:31 */
  let case_result_3 := 0
  switch mload(v13)
  case 1 {
  v17 := mload(add(v13, 32))
  v18 := mload(add(v13, 64))
  case_result_3 := v18
}

  case_result_2 := case_result_3
}

        /* Timeline:61:2--61:8 */
        v20 := case_result_2
        v12 := EVM_Primitives_u_mstore(v19, v20, v1)
        /* Timeline:63:2--63:8 */
        v29 := 64
        /* Timeline:22:0--30:31 */
        let case_result_4 := 0
        switch mload(v0)
        case 0 {
  v22 := mload(add(v0, 32))
  v23 := mload(add(v0, 64))
  v24 := mload(add(v0, 96))
  v25 := mload(add(v0, 128))
  /* Timeline:22:0--30:31 */
  let case_result_5 := 0
  switch mload(v23)
  case 1 {
  v26 := mload(add(v23, 32))
  v27 := mload(add(v23, 64))
  case_result_5 := v26
}

  case_result_4 := case_result_5
}

        /* Timeline:63:13--63:23 */
        v28 := case_result_4
        /* Timeline:63:2--63:8 */
        v30 := TimelineStorage_u_eventIndex(v28)
        v21 := EVM_Primitives_u_mstore(v29, v30, v1)
        /* Timeline:64:2--64:8 */
        v38 := 96
        /* Timeline:22:0--30:31 */
        let case_result_6 := 0
        switch mload(v0)
        case 0 {
  v32 := mload(add(v0, 32))
  v33 := mload(add(v0, 64))
  v34 := mload(add(v0, 96))
  v35 := mload(add(v0, 128))
  /* Timeline:22:0--30:31 */
  let case_result_7 := 0
  switch mload(v33)
  case 1 {
  v36 := mload(add(v33, 32))
  v37 := mload(add(v33, 64))
  case_result_7 := v37
}

  case_result_6 := case_result_7
}

        /* Timeline:64:2--64:8 */
        v39 := case_result_6
        v31 := EVM_Primitives_u_mstore(v38, v39, v1)
        /* Timeline:66:2--66:8 */
        v48 := 128
        /* Timeline:22:0--30:31 */
        let case_result_8 := 0
        switch mload(v0)
        case 0 {
  v41 := mload(add(v0, 32))
  v42 := mload(add(v0, 64))
  v43 := mload(add(v0, 96))
  v44 := mload(add(v0, 128))
  /* Timeline:22:0--30:31 */
  let case_result_9 := 0
  switch mload(v43)
  case 1 {
  v45 := mload(add(v43, 32))
  v46 := mload(add(v43, 64))
  case_result_9 := v45
}

  case_result_8 := case_result_9
}

        /* Timeline:66:14--66:24 */
        v47 := case_result_8
        /* Timeline:66:2--66:8 */
        v49 := TimelineStorage_u_eventIndex(v47)
        v40 := EVM_Primitives_u_mstore(v48, v49, v1)
        /* Timeline:67:2--67:8 */
        v57 := 160
        /* Timeline:22:0--30:31 */
        let case_result_10 := 0
        switch mload(v0)
        case 0 {
  v51 := mload(add(v0, 32))
  v52 := mload(add(v0, 64))
  v53 := mload(add(v0, 96))
  v54 := mload(add(v0, 128))
  /* Timeline:22:0--30:31 */
  let case_result_11 := 0
  switch mload(v53)
  case 1 {
  v55 := mload(add(v53, 32))
  v56 := mload(add(v53, 64))
  case_result_11 := v56
}

  case_result_10 := case_result_11
}

        /* Timeline:67:2--67:8 */
        v58 := case_result_10
        v50 := EVM_Primitives_u_mstore(v57, v58, v1)
        /* Timeline:69:2--69:8 */
        v67 := 192
        /* Timeline:22:0--30:31 */
        let case_result_12 := 0
        switch mload(v0)
        case 0 {
  v60 := mload(add(v0, 32))
  v61 := mload(add(v0, 64))
  v62 := mload(add(v0, 96))
  v63 := mload(add(v0, 128))
  /* Timeline:22:0--30:31 */
  let case_result_13 := 0
  switch mload(v63)
  case 1 {
  v64 := mload(add(v63, 32))
  v65 := mload(add(v63, 64))
  case_result_13 := v64
}

  case_result_12 := case_result_13
}

        /* Timeline:69:14--69:24 */
        v66 := case_result_12
        /* Timeline:69:2--69:8 */
        v68 := TimelineStorage_u_eventIndex(v66)
        v59 := EVM_Primitives_u_mstore(v67, v68, v1)
        /* Timeline:70:2--70:8 */
        v76 := 224
        /* Timeline:22:0--30:31 */
        let case_result_14 := 0
        switch mload(v0)
        case 0 {
  v70 := mload(add(v0, 32))
  v71 := mload(add(v0, 64))
  v72 := mload(add(v0, 96))
  v73 := mload(add(v0, 128))
  /* Timeline:22:0--30:31 */
  let case_result_15 := 0
  switch mload(v73)
  case 1 {
  v74 := mload(add(v73, 32))
  v75 := mload(add(v73, 64))
  case_result_15 := v75
}

  case_result_14 := case_result_15
}

        /* Timeline:70:2--70:8 */
        v77 := case_result_14
        v69 := EVM_Primitives_u_mstore(v76, v77, v1)
        v78 := 0
        v79 := 256
        result := EVM_Primitives_u_evmReturn(v78, v79, v1)
      }
      // @source: Timeline:0:0--0:0
      function Timeline_u_dispatch(v0) -> result {
        let v1 := 0
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        v1 := EVM_Primitives_u_getSelector(v0)
        v2 := 3013650640
        v5 := Prelude_EqOrd_u____Eq_Integer(v1, v2)
        switch v5
        case 1 {
  result := Timeline_u_getProposalTimeline(v0)
}
        case 0 {
  v3 := 0
  v4 := 0
  result := EVM_Primitives_u_evmRevert(v3, v4, v0)
}

      }
      // @source: Timeline:0:0--0:0
      function Timeline_u_buildTimeline(v0, v1) -> result {
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
        let v20 := 0
        let v21 := 0
        /* Timeline:45:14--45:32 */
        v3 := 0
        /* Timeline:45:14--45:32 */
        v4 := Timeline_u_loadEventTimestamp(v0, v3)
        v2 := apply_closure(v4, v1)
        /* Timeline:46:14--46:32 */
        v6 := 1
        /* Timeline:46:14--46:32 */
        v7 := Timeline_u_loadEventTimestamp(v0, v6)
        v5 := apply_closure(v7, v1)
        /* Timeline:47:14--47:32 */
        v9 := 2
        /* Timeline:47:14--47:32 */
        v10 := Timeline_u_loadEventTimestamp(v0, v9)
        v8 := apply_closure(v10, v1)
        /* Timeline:48:14--48:32 */
        v12 := 3
        /* Timeline:48:14--48:32 */
        v13 := Timeline_u_loadEventTimestamp(v0, v12)
        v11 := apply_closure(v13, v1)
        /* Timeline:50:5--50:20 */
        v14 := 0
        v18 := 1
        /* Timeline:51:5--51:20 */
        v15 := 1
        v19 := 1
        /* Timeline:52:5--52:20 */
        v16 := 2
        v20 := 1
        /* Timeline:53:5--53:20 */
        v17 := 3
        v21 := 1
        result := 0
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_sload(v0, v1) -> result {
        result := EVM_Primitives_u_prim__sload(v0, v1)
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
      function EVM_Primitives_u_prim__calldataload(arg0, arg1) -> result {
        result := calldataload(arg0)
      }
      // @source: EVM.Primitives:0:0--0:0
      function EVM_Primitives_u_mstore(v0, v1, v2) -> result {
        result := EVM_Primitives_u_prim__mstore(v0, v1, v2)
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
      // @source: TimelineStorage:0:0--0:0
      function TimelineStorage_u_eventSlot(v0, v1) -> result {
        let v2 := 0
        let v3 := 0
        let v4 := 0
        let v5 := 0
        let v6 := 0
        v2 := 4
        v3 := mul(v0, v2)
        v4 := 62514009886607029107290561805838585334079798074568712924583230797734656856475
        v5 := add(v3, v4)
        v6 := TimelineStorage_u_eventIndex(v1)
        result := add(v5, v6)
      }
      // @source: TimelineStorage:0:0--0:0
      function TimelineStorage_u_eventIndex(v0) -> result {
        switch v0
        case 0 {
  result := 0
}
        case 1 {
  result := 1
}
        case 2 {
  result := 2
}
        case 3 {
  result := 3
}

      }
    }
  }
}