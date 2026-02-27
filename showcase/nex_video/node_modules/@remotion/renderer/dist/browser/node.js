"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.puppeteer = void 0;
const PuppeteerNode_1 = require("./PuppeteerNode");
const revisions_1 = require("./revisions");
exports.puppeteer = new PuppeteerNode_1.PuppeteerNode({
    preferredRevision: revisions_1.PUPPETEER_REVISIONS.chromium,
    productName: undefined,
});
