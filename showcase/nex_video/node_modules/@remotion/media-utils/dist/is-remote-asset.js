"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isRemoteAsset = void 0;
const isRemoteAsset = (asset) => !asset.startsWith(window.location.origin) && !asset.startsWith('data');
exports.isRemoteAsset = isRemoteAsset;
