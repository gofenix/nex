import React from 'react';
import type { SymbolicatedStackFrame } from '../react-overlay/utils/stack-frame';
export declare const StackElement: React.FC<{
    s: SymbolicatedStackFrame;
    lineNumberWidth: number;
    isFirst: boolean;
    defaultFunctionName: string;
}>;
