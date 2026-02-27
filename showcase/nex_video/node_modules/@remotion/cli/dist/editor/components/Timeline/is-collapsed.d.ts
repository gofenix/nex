import type { TrackWithHash } from '../../helpers/get-timeline-sequence-sort-key';
import type { TimelineViewState } from './timeline-state-reducer';
export declare const isTrackCollapsed: (hash: string, viewState: TimelineViewState) => boolean;
export declare const isTrackHidden: (track: TrackWithHash, allTracks: TrackWithHash[], viewState: TimelineViewState) => boolean;
