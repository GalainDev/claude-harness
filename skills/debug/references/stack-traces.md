# Reading Stack Traces

## Go

Go stack traces read **top to bottom** — the top is where the panic/error occurred, the bottom is where execution started.

```
goroutine 1 [running]:
main.(*Server).handleOrder(0xc000112000, {0x12a3bc0, 0xc000198000}, 0xc000198000)
        /app/server.go:142 +0x1f4           ← your code — this is where it panicked
github.com/go-chi/chi.(*Mux).routeHTTP(...)
        /go/pkg/mod/github.com/go-chi/chi@v1.5.4/mux.go:431 +0x140   ← library
net/http.(*ServeMux).ServeHTTP(0xc000012180, {0x12a3bc0, 0xc000198000}, 0xc00019c000)
        /usr/local/go/src/net/http/server.go:2486 +0x149              ← stdlib
```

**Reading the trace:**
- Find your code (your module path) — that's where to look first
- `+0x1f4` is the byte offset in the function — ignore it
- The line number after the file path is what matters: `server.go:142`
- `[running]` means this goroutine was active; `[chan receive]` means it was blocked

**Goroutine dump (deadlock or leak):**
```
goroutine 18 [chan receive, 3 minutes]:   ← blocked for 3 minutes — likely deadlock
main.processOrder(0xc000198000)
        /app/worker.go:88 +0x2c4
```

---

## TypeScript / Node.js

Node.js traces read **top to bottom** — top is the actual error site, each subsequent frame is the caller.

```
TypeError: Cannot read properties of undefined (reading 'id')
    at formatUser (/app/src/utils/user.ts:23:18)     ← your code — where it crashed
    at Array.map (<anonymous>)                         ← native
    at getUsers (/app/src/handlers/users.ts:45:28)    ← your code — called formatUser
    at Layer.handle [as handle_request] (/app/node_modules/express/lib/router/layer.js:95:5)
    at next (/app/node_modules/express/lib/router/route.js:137:13)
```

**Reading the trace:**
- Find your code (your source path, not `node_modules`) — focus there
- The error message tells you what went wrong: `Cannot read properties of undefined (reading 'id')` means `something.id` where `something` is undefined
- Line 23, col 18 in `utils/user.ts` — go there directly

**With source maps (TypeScript):**
```
Error: User not found
    at UserService.findById (/app/src/services/user.service.ts:67:13)
    at async UserController.getUser (/app/src/controllers/user.controller.ts:34:20)
```
Source maps let you see TypeScript line numbers directly. If you see `.js` files instead of `.ts`, source maps aren't configured — check `tsconfig.json` `sourceMap: true`.

**Async traces:**
```
Error: connect ECONNREFUSED 127.0.0.1:5432
    at TCPConnectWrap.afterConnect [as oncomplete] (net.js:1141:16)

Node.js v18.0.0
```
Network errors often have thin traces because the error happens in native code. The key info is in the error message itself: `ECONNREFUSED` = nothing listening on that port, `ETIMEDOUT` = network/firewall issue, `ENOTFOUND` = DNS resolution failure.

---

## React

React errors in development include a **component stack** below the JS stack trace:

```
TypeError: Cannot read properties of null (reading 'name')
    at UserCard (UserCard.tsx:18:20)
    at renderWithHooks (react-dom.development.js:14985:18)

The above error occurred in the <UserCard> component:
    at UserCard (http://localhost:3000/src/UserCard.tsx:15:20)
    at div
    at UserList (http://localhost:3000/src/UserList.tsx:42:5)
    at App
```

**Reading it:**
- JS stack: `UserCard.tsx:18:20` — go here first
- Component stack: tells you the render tree — `UserList` rendered `UserCard` which crashed
- The component stack is invaluable for finding where a null prop is coming from

**Common React error messages:**

| Error | Cause |
|-------|-------|
| `Cannot read properties of undefined (reading 'map')` | Prop expected to be array is undefined — add a default or conditional render |
| `Each child in a list should have a unique "key" prop` | Missing `key` in list render |
| `Warning: Can't perform a React state update on an unmounted component` | Async operation completing after unmount — cancel in useEffect cleanup |
| `Too many re-renders` | Unconditional `setState` in render body or useEffect with wrong deps |
| `Hydration failed` | Server and client HTML don't match — usually conditional rendering based on `window` or `Date.now()` |

---

## HTTP Status Codes — Quick Reference

| Status | Meaning | Common cause |
|--------|---------|-------------|
| 400 | Bad Request | Invalid input, malformed JSON, missing required field |
| 401 | Unauthorized | Missing or invalid auth token |
| 403 | Forbidden | Auth is valid but insufficient permissions |
| 404 | Not Found | Resource doesn't exist (or you're returning 404 instead of 403 for security) |
| 409 | Conflict | Duplicate key, concurrent update conflict |
| 422 | Unprocessable Entity | Validation failed |
| 429 | Too Many Requests | Rate limited |
| 500 | Internal Server Error | Unhandled exception server-side — check server logs |
| 502 | Bad Gateway | Upstream service is down or returning garbage |
| 503 | Service Unavailable | Server is up but overloaded or in maintenance |
| 504 | Gateway Timeout | Upstream took too long — check for slow queries or hanging operations |
