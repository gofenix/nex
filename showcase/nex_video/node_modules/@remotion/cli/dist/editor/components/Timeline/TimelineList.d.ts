import React from 'react';
import type { TrackWithHash } from '../../helpers/get-timeline-sequence-sort-key';
import type { TimelineActionState, TimelineViewState } from './timeline-state-reducer';
export declare const TimelineList: React.FC<{
    timeline: TrackWithHash[];
    viewState: TimelineViewState;
    dispatchStateChange: React.Dispatch<TimelineActionState>;
}>;
