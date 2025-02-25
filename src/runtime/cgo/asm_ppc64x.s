// Copyright 2014 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build ppc64 || ppc64le

#include "textflag.h"
#include "asm_ppc64x.h"
#include "abi_ppc64x.h"

// Called by C code generated by cmd/cgo.
// func crosscall2(fn, a unsafe.Pointer, n int32, ctxt uintptr)
// Saves C callee-saved registers and calls cgocallback with three arguments.
// fn is the PC of a func(a unsafe.Pointer) function.
// The value of R2 is saved on the new stack frame, and not
// the caller's frame due to issue #43228.
TEXT crosscall2(SB),NOSPLIT|NOFRAME,$0
	// Start with standard C stack frame layout and linkage, allocate
	// 32 bytes of argument space, save callee-save regs, and set R0 to $0.
	STACK_AND_SAVE_HOST_TO_GO_ABI(32)
	// The above will not preserve R2 (TOC). Save it in case Go is
	// compiled without a TOC pointer (e.g -buildmode=default).
	MOVD	R2, 24(R1)

	// Load the current g.
	BL	runtime·load_g(SB)

#ifdef GO_PPC64X_HAS_FUNCDESC
	// Load the real entry address from the first slot of the function descriptor.
	MOVD	8(R3), R2
	MOVD	(R3), R3
#endif
	MOVD	R3, FIXED_FRAME+0(R1)	// fn unsafe.Pointer
	MOVD	R4, FIXED_FRAME+8(R1)	// a unsafe.Pointer
	// Skip R5 = n uint32
	MOVD	R6, FIXED_FRAME+16(R1)	// ctxt uintptr
	BL	runtime·cgocallback(SB)

	// Restore the old frame, and R2.
	MOVD	24(R1), R2
	UNSTACK_AND_RESTORE_GO_TO_HOST_ABI(32)
	RET
