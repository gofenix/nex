"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getPreferredVolume = exports.persistVolume = void 0;
const VOLUME_PERSISTANCE_KEY = 'remotion.volumePreference';
const persistVolume = (volume) => {
    if (typeof window === 'undefined') {
        return;
    }
    window.localStorage.setItem(VOLUME_PERSISTANCE_KEY, String(volume));
};
exports.persistVolume = persistVolume;
const getPreferredVolume = () => {
    if (typeof window === 'undefined') {
        return 1;
    }
    const val = window.localStorage.getItem(VOLUME_PERSISTANCE_KEY);
    return val ? Number(val) : 1;
};
exports.getPreferredVolume = getPreferredVolume;
