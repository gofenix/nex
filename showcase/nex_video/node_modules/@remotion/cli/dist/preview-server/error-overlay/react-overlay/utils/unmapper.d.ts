import type { SomeStackFrame, SymbolicatedStackFrame } from './stack-frame';
export declare const unmap: (frames: SomeStackFrame[], contextLines: number) => Promise<SymbolicatedStackFrame[]>;
