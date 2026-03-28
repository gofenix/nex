# Internal Assets

`internal/` stores versioned repository assets that should not live inside the public Nex gallery or website.

Current usage:

- `internal/examples/` holds example-specific agent rules, workflow notes, and editor metadata that would otherwise pollute `examples/`.

Rules:

- Do not place public documentation or website content here.
- Do not add runnable product code here when it belongs in a published package or example.
- Keep `examples/` and `website/` free of operational notes, agent instructions, and editor-specific rule files.
