import type { SymbolicatedStackFrame } from '../utils/stack-frame';
import type { ErrorLocation } from './map-error-to-react-stack';
export declare const resolveFileSource: (location: ErrorLocation, contextLines: number) => Promise<SymbolicatedStackFrame>;
