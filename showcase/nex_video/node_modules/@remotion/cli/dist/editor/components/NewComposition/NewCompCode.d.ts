/// <reference types="react" />
export declare const getNewCompositionCode: ({ type, height, width, fps, durationInFrames, name, raw, }: {
    type: 'still' | 'composition';
    height: number;
    width: number;
    fps: number;
    durationInFrames: number;
    name: string;
    raw: boolean;
}) => string | (string | JSX.Element | (string | JSX.Element)[])[];
