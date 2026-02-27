"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.invalidCompositionErrorMessage = exports.isCompositionIdValid = exports.validateCompositionId = void 0;
const validateCompositionId = (id) => {
    if (!(0, exports.isCompositionIdValid)(id)) {
        throw new Error(`Composition id can only contain a-z, A-Z, 0-9 and -. You passed ${id}`);
    }
};
exports.validateCompositionId = validateCompositionId;
const getRegex = () => /^([a-zA-Z0-9-])+$/g;
const isCompositionIdValid = (id) => id.match(getRegex());
exports.isCompositionIdValid = isCompositionIdValid;
exports.invalidCompositionErrorMessage = `Composition ID must match ${String(getRegex())}`;
