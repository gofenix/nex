import type { SymbolicatedStackFrame } from './stack-frame';
export declare const getStackFrames: (error: Error, contextSize: number) => Promise<SymbolicatedStackFrame[] | null>;
