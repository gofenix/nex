export declare const getExpectedMediaFrameUncorrected: ({ frame, playbackRate, startFrom, }: {
    frame: number;
    playbackRate: number;
    startFrom: number;
}) => number;
export declare const getMediaTime: ({ fps, frame, src, playbackRate, startFrom, mediaType, }: {
    fps: number;
    frame: number;
    src: string;
    playbackRate: number;
    startFrom: number;
    mediaType: 'video' | 'audio';
}) => number;
