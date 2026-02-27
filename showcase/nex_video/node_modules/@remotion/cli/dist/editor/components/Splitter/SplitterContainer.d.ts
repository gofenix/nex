import React from 'react';
import type { SplitterOrientation } from './SplitterContext';
export declare const SplitterContainer: React.FC<{
    orientation: SplitterOrientation;
    maxFlex: number;
    minFlex: number;
    id: string;
    defaultFlex: number;
    children: React.ReactNode;
}>;
