export const examples = [
  {
    name: "alpine_showcase",
    cwd: "examples/alpine_showcase",
    port: 4201,
    kind: "ui",
    readyPath: "/",
    spec: "e2e/specs/alpine_showcase.spec.mjs"
  },
  {
    name: "auth_demo",
    cwd: "examples/auth_demo",
    port: 4202,
    kind: "ui",
    readyPath: "/",
    spec: "e2e/specs/auth_demo.spec.mjs"
  },
  {
    name: "counter",
    cwd: "examples/counter",
    port: 4203,
    kind: "ui",
    readyPath: "/",
    spec: "e2e/specs/counter.spec.mjs"
  },
  {
    name: "dynamic_routes",
    cwd: "examples/dynamic_routes",
    port: 4204,
    kind: "routes",
    readyPath: "/",
    spec: "e2e/specs/dynamic_routes.spec.mjs"
  },
  {
    name: "energy_dashboard",
    cwd: "examples/energy_dashboard",
    port: 4205,
    kind: "realtime",
    readyPath: "/",
    spec: "e2e/specs/energy_dashboard.spec.mjs"
  },
  {
    name: "error_pages",
    cwd: "examples/error_pages",
    port: 4206,
    kind: "routes",
    readyPath: "/",
    spec: "e2e/specs/error_pages.spec.mjs"
  },
  {
    name: "guestbook",
    cwd: "examples/guestbook",
    port: 4207,
    kind: "ui",
    readyPath: "/",
    spec: "e2e/specs/guestbook.spec.mjs"
  },
  {
    name: "ratelimit",
    cwd: "examples/ratelimit",
    port: 4208,
    kind: "routes",
    readyPath: "/",
    spec: "e2e/specs/ratelimit.spec.mjs"
  },
  {
    name: "todos",
    cwd: "examples/todos",
    port: 4209,
    kind: "ui",
    readyPath: "/",
    spec: "e2e/specs/todos.spec.mjs"
  },
  {
    name: "todos_api",
    cwd: "examples/todos_api",
    port: 4210,
    kind: "api",
    readyPath: "/",
    spec: "e2e/specs/todos_api.spec.mjs"
  },
  {
    name: "upload",
    cwd: "examples/upload",
    port: 4211,
    kind: "ui",
    readyPath: "/",
    spec: "e2e/specs/upload.spec.mjs"
  },
  {
    name: "validator",
    cwd: "examples/validator",
    port: 4212,
    kind: "ui",
    readyPath: "/",
    spec: "e2e/specs/validator.spec.mjs"
  },
  {
    name: "websocket",
    cwd: "examples/websocket",
    port: 4213,
    kind: "realtime",
    readyPath: "/",
    spec: "e2e/specs/websocket.spec.mjs"
  }
];

export function getExample(name) {
  return examples.find((example) => example.name === name);
}
