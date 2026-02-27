import type { SomeStackFrame } from './stack-frame';
export declare const parseError: (error: Error | string | string[], contextLines: number) => Promise<SomeStackFrame[]>;
