# Reference: Language & Framework Checklists

Use these checklists during Phase 2 (Systematic Analysis) of the codebase audit. Each language and framework has domain-specific issues that generic scanning will miss.

## When to Use Specialized Agents

For large codebases (>50 files) or multi-language repos, spawn specialized subagents per domain. Each subagent should:

1. Read this reference section for their domain
2. Scan only files matching their language/framework
3. Verify and create issues independently
4. Report findings back to the main auditor for deduplication

---

## Rust

### Bugs
- Unchecked `unwrap()` / `expect()` in production code paths
- `unsafe` blocks without `#[deny(unsafe_code)]` or safety comments
- Integer overflow in release mode (use `wrapping_`, `checked_`, or `saturating_`)
- Iterator invalidation, especially with `Vec::drain` or `split_at_mut`
- `Send`/`Sync` violations across thread boundaries
- `Drop` implementations that panic (causes abort)

### Security
- `unsafe` FFI without input validation or `NonNull` checks
- Path traversal in `std::fs` operations
- Deserialization of untrusted data (`serde` without validation)
- Timing side-channels in crypto/comparison code
- `mem::uninitialized` usage (use `MaybeUninit` instead)

### Performance
- Unnecessary `.clone()` on owned data (use references or `Cow`)
- Missing `#[inline]` on hot generic functions
- `Box` allocation in tight loops (stack-allocate or use `SmallVec`)
- `Arc<Mutex<T>>` where `Arc<RwLock<T>>` or lock-free would work
- Unbounded `mpsc::channel` (use `sync_channel` or `tokio::sync::mpsc` with capacity)
- Missing `#[derive(PartialEq)]` causing slow comparisons

### Architecture
- Overuse of `dyn Trait` where generics suffice (monomorphization)
- Circular module dependencies (split into separate crates)
- Missing `#[non_exhaustive]` on public enums
- Error types using `String` or `Box<dyn Error>` instead of `thiserror`

---

## C++

### Bugs
- Undefined behavior: dangling pointers, use-after-free, double-free
- Signed integer overflow (UB in C++)
- Missing virtual destructors in base classes
- Iterator invalidation after container modification
- `std::move` on const objects (silently copies)
- Exception safety violations (strong/weak/basic guarantees)

### Security
- Buffer overflows (`strcpy`, `sprintf`, `gets` — use `strncpy`, `snprintf`)
- Format string vulnerabilities (`printf(user_input)`)
- Use-after-free from dangling references after reallocation
- TOCTOU race conditions in file operations
- Missing bounds checks on `std::vector::at` vs `operator[]`

### Performance
- Passing large objects by value instead of `const T&` or `std::string_view`
- Unnecessary virtual function calls in hot paths (use CRTP or `final`)
- Missing `reserve()` before repeated `push_back`
- Cache-unfriendly data layouts (SoA vs AoS)
- Unnecessary heap allocations (use `std::array`, placement `new`, or arena allocators)

### Architecture
- God classes with >500 lines (apply SRP)
- Deep inheritance hierarchies (>3 levels — prefer composition)
- Missing RAII wrappers for resource management
- Pimpl idiom not used for ABI-stable libraries

---

## C

### Bugs
- Buffer overflows (`strcpy`, `strcat`, `sprintf` — use `strncpy`, `strncat`, `snprintf`)
- Null pointer dereferences without checks
- Uninitialized variables (especially structs with padding)
- Integer overflow before multiplication/allocation
- Missing `free()` on error paths (memory leaks)
- Double-free after early returns

### Security
- Format string attacks (`printf(user_input)`)
- Integer overflow leading to undersized `malloc`
- Missing bounds checks on array indexing
- Use of `gets()` (always unsafe)
- Missing `const` correctness allowing unintended mutation

### Performance
- Unnecessary `malloc`/`free` in tight loops (use stack allocation or pools)
- Cache-unfriendly linked list traversal (use arrays)
- Missing `inline` on small frequently-called functions
- Unaligned memory access on architectures that penalize it

### Architecture
- Missing error codes from functions (always return status)
- Global mutable state (pass context structs instead)
- No header guards or `#pragma once`
- Mixing declarations and code (C89 compatibility issues)

---

## TypeScript / JavaScript

### Bugs
- Unhandled promise rejections (`async` without `try/catch`)
- `any` type masking type errors
- Missing null/undefined checks (`?.` or `??`)
- Stale closures in `useEffect` / event handlers
- Race conditions from concurrent state updates
- Floating point precision issues (`0.1 + 0.2 !== 0.3`)
- `==` instead of `===` (coercion bugs)

### Security
- XSS via `innerHTML`, `dangerouslySetInnerHTML`, or `document.write`
- Prototype pollution via `Object.assign({}, user_input)`
- SQL injection in raw queries (use parameterized queries)
- SSRF via user-controlled URLs in `fetch`/`axios`
- Insecure `eval()`, `new Function()`, or `setTimeout(string)`
- Missing CSRF tokens on state-changing endpoints
- Exposed secrets in client-side bundles (check `.env` patterns)

### Performance
- Unnecessary re-renders (missing `React.memo`, `useMemo`, `useCallback`)
- N+1 API calls in loops (batch requests)
- Large bundle size from importing entire libraries (use tree-shakeable imports)
- Missing debouncing/throttling on scroll/resize/input handlers
- Blocking the main thread with synchronous operations
- Memory leaks from unremoved event listeners or subscriptions
- Unkeyed or index-keyed lists in React

### Architecture
- Prop drilling (>3 levels — use Context or state management)
- God components (>300 lines — split into smaller components)
- Mixing business logic with UI (extract hooks/services)
- Missing error boundaries around async operations
- Barrel exports causing circular dependencies
- Missing `strict: true` in `tsconfig.json`

---

## Python

### Bugs
- Mutable default arguments (`def f(x=[])` — use `None` + check)
- Late binding closures in loops (`lambda: i` captures last `i`)
- Unhandled exceptions in `__del__` (causes silent failures)
- Iterator exhaustion (calling `next()` on exhausted iterator)
- `is` vs `==` for value comparison
- Missing `super().__init__()` in subclass constructors

### Security
- SQL injection via string formatting (`f"SELECT * FROM {table}"`)
- Pickle deserialization of untrusted data (arbitrary code execution)
- Path traversal in `open(user_input)` (use `pathlib` with validation)
- Command injection via `os.system()` or `subprocess(shell=True)`
- Hardcoded credentials in source code
- Missing rate limiting on authentication endpoints
- YAML `load()` without `Loader=SafeLoader`

### Performance
- Using lists instead of sets/dicts for membership testing (`O(n)` vs `O(1)`)
- String concatenation in loops (use `"".join()`)
- Missing `__slots__` on classes with many instances
- Unnecessary object creation in hot paths
- Global interpreter lock (GIL) contention in CPU-bound threading
- Missing `lru_cache` on expensive pure functions
- Reading entire file into memory (`read()` vs iterating lines)

### Architecture
- Circular imports (restructure modules)
- God modules with >500 lines (apply SRP)
- Missing type hints on public APIs (use `mypy`)
- Mixing sync and async code in the same call chain
- Missing `if __name__ == "__main__"` guard

---

## Go

### Bugs
- Ignored errors (`_ = someFunc()` — always check)
- Goroutine leaks (goroutines that never exit)
- Race conditions on shared state without mutex or channels
- Nil pointer dereference from uninitialized struct fields
- Context cancellation not propagated (`context.Background()` in handlers)
- Missing `defer resp.Body.Close()` after HTTP requests

### Security
- SQL injection via string concatenation (use `database/sql` parameters)
- Path traversal in `os.Open(user_input)`
- Missing authentication on API endpoints
- Insecure random number generation (`math/rand` vs `crypto/rand`)
- Exposed debug endpoints in production (`pprof`, `expvar`)

### Performance
- Unnecessary allocations in hot paths (use `sync.Pool` or pre-allocate)
- Missing connection pooling (reuse `http.Client`, `sql.DB`)
- Large struct copying instead of passing pointers
- Missing index on frequently queried database columns
- Unbuffered channels causing goroutine blocking

### Architecture
- Missing interface definitions for external dependencies (hard to test)
- God packages with >1000 lines (split by responsibility)
- Missing `go.mod` version pinning
- Error handling with string comparison instead of `errors.Is`/`errors.As`

---

## Java

### Bugs
- Null pointer exceptions (missing `@Nullable`/`@NonNull` annotations)
- ConcurrentModificationException from modifying collections during iteration
- Resource leaks (missing try-with-resources for `Closeable`)
- Integer overflow in arithmetic operations
- `equals()` without overriding `hashCode()`
- Missing `serialVersionUID` on `Serializable` classes

### Security
- SQL injection via string concatenation (use `PreparedStatement`)
- XXE injection in XML parsing (disable external entities)
- Deserialization of untrusted data (`ObjectInputStream`)
- Missing CSRF protection on state-changing endpoints
- Hardcoded credentials in configuration files

### Performance
- String concatenation in loops (use `StringBuilder`)
- Unnecessary object creation (use primitives, object pools)
- Missing database connection pooling (use HikariCP)
- N+1 queries in JPA/Hibernate (use `JOIN FETCH` or `@EntityGraph`)
- Missing `@Transactional` causing repeated DB connections

### Architecture
- God classes with >500 lines (apply SRP)
- Deep inheritance hierarchies (>3 levels — prefer composition)
- Missing dependency injection (use Spring or similar)
- Tight coupling to framework-specific types in business logic

---

## Ruby

### Bugs
- Nil errors from missing `&.` safe navigation
- Mutable default arguments in method definitions
- Missing `return` in conditional branches
- `==` vs `eql?` vs `===` confusion
- Missing `super` in overridden methods

### Security
- SQL injection via string interpolation (use Arel or parameterized queries)
- Mass assignment vulnerability (missing `strong_parameters`)
- XSS via unescaped output in views (use `<%= %>` with `html_safe` carefully)
- CSRF missing on forms (ensure `protect_from_forgery`)
- YAML deserialization of untrusted data

### Performance
- N+1 queries in ActiveRecord (use `includes`, `preload`, `eager_load`)
- Missing database indexes on frequently queried columns
- Unnecessary object allocation in hot paths
- Missing caching for expensive computations (`Rails.cache`)
- Loading entire result sets into memory (use `find_each` for batches)

### Architecture
- Fat models (>300 lines — extract service objects)
- God controllers (>200 lines — extract concerns or service objects)
- Missing service layer for business logic
- Circular dependencies between models

---

## Swift

### Bugs
- Force unwrapping (`!`) that can crash at runtime
- Retain cycles from strong reference cycles in closures (use `[weak self]`)
- Missing `try` error handling
- Thread-unsafe access to mutable state from background threads
- `guard` statements that silently exit without cleanup

### Security
- Storing sensitive data in `UserDefaults` (use Keychain)
- Missing certificate pinning for network requests
- Insecure URL schemes accepting arbitrary input
- Missing input validation on user-facing forms

### Performance
- Unnecessary value type copying in hot paths (use `inout` or references)
- Missing `@inline(__always)` on small frequently-called functions
- Large enum cases causing memory bloat
- Unoptimized `Codable` encoding/decoding for large payloads

### Architecture
- Massive View Controllers (>300 lines — use MVVM or VIPER)
- Missing protocol-oriented design for testability
- Tight coupling to UIKit/AppKit in business logic

---

## Frameworks

### React

#### Bugs
- Missing dependency arrays in `useEffect` (stale closures, infinite loops)
- Direct state mutation (`state.value = x` instead of `setState`)
- Using array index as `key` in dynamic lists (causes reconciliation bugs)
- Calling hooks conditionally or inside loops (violates Rules of Hooks)
- `useMemo`/`useCallback` with empty dependency arrays masking stale values
- Missing `async` error handling in event handlers (unhandled promise rejections)
- `useRef` used for reactive state (refs don't trigger re-renders)

#### Security
- `dangerouslySetInnerHTML` with user-controlled content (XSS)
- `href={userInput}` without validation (javascript: protocol injection)
- Passing secrets as props through component trees (visible in React DevTools)
- Missing `rel="noopener noreferrer"` on `target="_blank"` links (tabnabbing)
- Exposing sensitive data in client-side bundles (check imports)

#### Performance
- Missing `React.memo` on components receiving stable props
- Unnecessary re-renders from context providers re-rendering on every parent render
- Large component trees without code splitting (`React.lazy`, `Suspense`)
- Inline object/function creation in JSX props (`style={{}}`, `onClick={() => {}}`)
- Missing virtualization for long lists (use `react-window` or `@tanstack/virtual`)
- Unoptimized images (missing `loading="lazy"`, no `srcSet`)
- Fetching data in render without caching (use React Query, SWR, or TanStack Query)

#### Architecture
- Prop drilling >3 levels (use Context, Zustand, or Redux)
- God components >300 lines (extract custom hooks, split sub-components)
- Mixing business logic with presentational components (extract hooks)
- Missing error boundaries around async/suspense boundaries
- Barrel exports causing circular dependencies
- Missing TypeScript strict mode or `noImplicitAny`

---

### Next.js

#### Bugs
- Using `useEffect` for data fetching instead of Server Components or `fetch`
- Missing `revalidate` configuration causing stale ISR data
- `getServerSideProps` used where `getStaticProps` would suffice (performance)
- Dynamic routes without `generateStaticParams` (SSG fallback issues)
- Missing `loading.tsx` or `not-found.tsx` in App Router
- Client/Server component boundary violations (using client hooks in server components)

#### Security
- Missing authentication on API routes (`/api/*`)
- Exposing server-side secrets in client components
- Missing CSRF protection on API route mutations
- SQL injection in API route handlers (use parameterized queries)
- Missing rate limiting on public API endpoints

#### Performance
- Missing `Image` component optimization (using raw `<img>` tags)
- No font optimization (use `next/font` instead of Google Fonts CDN)
- Missing `dynamic import()` for heavy client-only libraries
- Unoptimized API routes making sequential external calls (parallelize)
- Missing Edge Runtime for latency-sensitive routes
- Large bundle from importing server-only packages in client components

#### Architecture
- Pages Router and App Router mixed in same project (pick one)
- Missing middleware for cross-cutting concerns (auth, redirects, i18n)
- God API routes handling multiple HTTP methods without separation
- Missing `metadata` export for SEO on every page

---

### Vue.js

#### Bugs
- Missing `key` on `v-for` lists (causes DOM reconciliation issues)
- Directly mutating props (Vue 2 silent failure, Vue 3 warning)
- Missing `await` in `setup()` with async data
- `ref` vs `reactive` confusion (losing reactivity on destructuring)
- Missing `emits` declaration (Vue 3) causing silent event drops
- `watch` with deep option causing performance issues on large objects

#### Security
- `v-html` with user input (XSS)
- Missing input sanitization in form handlers
- Exposing Vuex/Pinia store mutations to untrusted input

#### Performance
- Missing `shallowRef`/`shallowReactive` for large immutable data
- Unnecessary reactivity on deeply nested objects (use `markRaw`)
- Missing `keep-alive` for expensive component state preservation
- Unoptimized `v-for` without `key` or with index keys
- Missing lazy loading for routes (`() => import('./Page.vue')`)

#### Architecture
- God components >300 lines (split into composables)
- Missing composables for reusable logic (extract from `setup()`)
- Mixing Options API and Composition API in same project (pick one)
- Missing TypeScript support (`defineProps<T>()`, `defineEmits<T>()`)

---

### Svelte / SvelteKit

#### Bugs
- Missing `$state` reactivity in Svelte 5 (using plain variables)
- Stale closures in `$effect` (missing dependency tracking)
- Direct DOM manipulation conflicting with Svelte's compiler
- Missing `await` blocks for async data in templates
- `beforeUpdate`/`afterUpdate` causing infinite loops

#### Security
- `@html` with user input (XSS)
- Missing CSRF protection on form actions
- Exposing environment variables without `$env/static/private` prefix

#### Performance
- Missing `{#key}` blocks for forcing re-render on state changes
- Unnecessary reactivity from overusing `$state` on derived values (use `$derived`)
- Missing `svelte:component` lazy loading for heavy components
- Unoptimized transitions on large lists

#### Architecture
- Missing route-level code splitting
- God stores (single massive store — split by domain)
- Missing `+page.server.ts` for server-only logic

---

### Angular

#### Bugs
- Missing `trackBy` in `*ngFor` (causes full DOM re-render)
- Memory leaks from unsubscribed Observables (use `async` pipe or `takeUntil`)
- Change detection running on every event (use `OnPush` strategy)
- Missing `standalone: true` causing module resolution issues
- `ngOnDestroy` not cleaning up event listeners or intervals

#### Security
- Missing `DomSanitizer` bypass validation (XSS)
- Template injection via `[innerHTML]` with user content
- Missing HTTP interceptor for CSRF tokens
- Exposing sensitive data in client-side bundles

#### Performance
- Missing `ChangeDetectionStrategy.OnPush` (default triggers on every event)
- Unnecessary `async` pipe subscriptions (cache with `shareReplay`)
- Missing lazy loading for feature modules/routes
- Large bundle from importing entire Angular Material instead of specific modules
- Missing `trackBy` functions in `*ngFor` loops

#### Architecture
- God services >300 lines (split by responsibility)
- Missing facades for complex state management (use NgRx or signals)
- Tight coupling to specific Angular version APIs in shared libraries

---

### Express.js / Node.js

#### Bugs
- Missing error handling middleware (uncaught exceptions crash the process)
- Unhandled promise rejections in route handlers
- Missing `next()` in middleware chains (requests hang)
- Blocking the event loop with synchronous operations
- Missing request timeout configuration (zombie connections)

#### Security
- Missing helmet.js headers (CSP, X-Frame-Options, etc.)
- Missing CORS configuration (overly permissive `*` origins)
- Missing rate limiting on auth/public endpoints
- Missing body parser size limits (DoS via large payloads)
- Exposing stack traces in production error responses
- Missing input validation (use `zod` or `joi`)
- Hardcoded secrets in source code (use environment variables)

#### Performance
- Missing response compression (`compression` middleware)
- Synchronous file I/O in request handlers (use `fs.promises`)
- Missing database connection pooling
- Unoptimized static file serving (missing `express.static` cache headers)
- Missing HTTP/2 or keep-alive configuration

#### Architecture
- God route files (>100 lines — split by resource)
- Missing middleware layer for cross-cutting concerns (auth, logging, validation)
- Mixing business logic with route handlers (extract services)
- Missing graceful shutdown handling (SIGTERM, SIGINT)

---

### NestJS

#### Bugs
- Missing `@Injectable()` on providers (causes resolution errors)
- Circular dependencies between modules (use `forwardRef`)
- Missing exception filters (unhandled exceptions return 500)
- Unhandled async operations in lifecycle hooks (`onModuleInit`)
- Missing validation pipe configuration (`class-validator` not applied globally)

#### Security
- Missing `@UseGuards()` on protected routes
- Missing CSRF protection on state-changing endpoints
- Exposing internal DTOs in API responses (use `class-transformer` `@Expose()`)
- Missing rate limiting (`@nestjs/throttler`)

#### Performance
- Missing database connection pooling configuration
- Unoptimized serialization (missing `class-transformer` for large responses)
- Missing caching (`@nestjs/cache-manager`) for expensive queries
- Missing request-scoped providers where singleton would suffice

#### Architecture
- God modules (>5 providers — split by domain)
- Missing DTOs for request/response typing
- Missing OpenAPI/Swagger documentation (`@nestjs/swagger`)
- Tight coupling to specific database ORM in business logic

---

### Django

#### Bugs
- Missing `select_related`/`prefetch_related` causing N+1 queries
- Unhandled `DoesNotExist` exceptions (use `get_object_or_404`)
- Missing `transaction.atomic()` for multi-step database operations
- Signal handlers causing infinite recursion
- Missing `__str__` methods causing unhelpful admin/debug output

#### Security
- Missing CSRF protection on forms (`{% csrf_token %}`)
- SQL injection via raw queries (`raw()` without parameterization)
- Missing `SECURE_HSTS_SECONDS` in production settings
- Debug mode enabled in production (`DEBUG = True`)
- Missing `ALLOWED_HOSTS` configuration
- Exposed `SECRET_KEY` in source code
- Missing clickjacking protection (`X-Frame-Options`)

#### Performance
- Missing database indexes on frequently queried fields
- Unoptimized ORM queries (use `only()`, `defer()` to limit columns)
- Missing caching (`django.core.cache`) for expensive computations
- Missing `select_related` for ForeignKey access in loops
- Unoptimized template rendering (use template fragment caching)

#### Architecture
- God views >100 lines (extract service functions or class-based views)
- Missing custom model managers for complex queries
- Tight coupling between models and views (extract business logic layer)
- Missing Django REST Framework serializers for API responses

---

### Flask / FastAPI

#### Bugs
- Missing error handlers (`@app.errorhandler`)
- Unhandled exceptions in background tasks
- Missing request context in async operations
- Circular imports between blueprints/routes
- Missing database session cleanup (connection leaks)

#### Security
- Missing CSRF protection on forms (Flask-WTF)
- SQL injection via string formatting in queries
- Missing CORS configuration
- Exposed debug toolbar in production
- Missing input validation (use Pydantic for FastAPI)
- Hardcoded secrets in configuration

#### Performance
- Missing database connection pooling
- Unoptimized SQLAlchemy queries (missing `joinedload`, `selectinload`)
- Missing response caching (`Flask-Caching` or FastAPI `@cache`)
- Synchronous endpoints for I/O-bound operations (use async in FastAPI)
- Missing gzip compression on responses

#### Architecture
- God route files (>100 lines — split into blueprints/routers)
- Missing dependency injection (use FastAPI's `Depends`)
- Mixing business logic with route handlers (extract service layer)
- Missing OpenAPI documentation (FastAPI auto-generates, Flask needs `apispec`)

---

### Spring Boot (Java)

#### Bugs
- Missing `@Transactional` on multi-step database operations
- Unhandled exceptions in `@Async` methods (lost silently)
- Circular dependencies between `@Service` beans (use constructor injection)
- Missing `@Valid` on controller request bodies
- Missing `equals()`/`hashCode()` on JPA entities

#### Security
- Missing `@PreAuthorize` on protected endpoints
- SQL injection via string concatenation (use `@Query` with parameters)
- Missing CSRF protection on state-changing endpoints
- Exposed actuator endpoints (`/actuator/env`, `/actuator/beans`)
- Missing CORS configuration
- Hardcoded credentials in `application.properties`

#### Performance
- Missing database connection pooling (HikariCP default but misconfigured)
- N+1 queries in JPA (use `@EntityGraph` or `JOIN FETCH`)
- Missing `@Cacheable` on expensive service methods
- Unoptimized serialization (Jackson missing `@JsonIgnore` on lazy fields)
- Missing pagination on large result sets (`Pageable`)

#### Architecture
- God services >300 lines (split by domain)
- Missing DTOs (exposing entities directly in API responses)
- Missing exception handling (`@ControllerAdvice`)
- Tight coupling to specific database in business logic

---

### Ruby on Rails

#### Bugs
- Missing `dependent: :destroy` causing orphaned records
- N+1 queries (missing `.includes` or `.preload`)
- Unhandled `ActiveRecord::RecordNotFound` (use `find_by` vs `find`)
- Missing database transactions for multi-step operations
- Callback hell (`before_save`, `after_create` causing hidden side effects)

#### Security
- Missing `protect_from_forgery` on controllers
- Mass assignment vulnerability (missing strong parameters)
- SQL injection via string interpolation in queries
- XSS via unescaped output (`html_safe` on user input)
- Missing authorization (use Pundit or CanCanCan)
- Exposed secrets in `config/credentials.yml.enc`

#### Performance
- Missing database indexes on frequently queried columns
- Unoptimized ActiveRecord queries (use `pluck` instead of `map(&:attribute)`)
- Missing caching (`Rails.cache`) for expensive computations
- Missing `counter_cache` for frequently accessed association counts
- Unoptimized asset pipeline (missing `sprockets` or `esbuild` configuration)

#### Architecture
- Fat models >300 lines (extract service objects, concerns)
- God controllers >200 lines (extract concerns or service objects)
- Missing service layer for business logic
- Circular dependencies between models
- Missing background jobs for long-running operations (use Sidekiq)

---

### Actix / Axum (Rust)

#### Bugs
- Missing error type conversions between layers (causes compilation failures)
- Unhandled `Result` in route handlers (causes 500 instead of proper error)
- Missing `Clone` bounds on shared state (causes borrow checker issues)
- Missing graceful shutdown handling (SIGTERM not propagated)
- Database connection not returned to pool on error paths

#### Security
- Missing CORS configuration (overly permissive `Any`)
- Missing request size limits (DoS via large payloads)
- Exposed sensitive data in error responses (use custom error types)
- Missing authentication middleware on protected routes
- SQL injection via string concatenation (use `sqlx` query macros)

#### Performance
- Missing connection pooling (`sqlx::Pool` instead of single connection)
- Unnecessary serialization/deserialization in middleware chain
- Missing response compression (`tower-http` compression layer)
- Blocking operations in async handlers (use `spawn_blocking`)
- Missing request tracing for debugging (`tower-http` trace layer)

#### Architecture
- God route files (>100 lines — split by resource module)
- Missing extractors for common request patterns (auth, pagination)
- Tight coupling to specific database in route handlers (use repository pattern)
- Missing OpenAPI documentation (`utoipa` or `okapi`)

---

### Gin / Echo (Go)

#### Bugs
- Missing error handling in middleware chains
- Unhandled goroutine leaks in long-running handlers
- Missing context propagation (`c.Request.Context()`)
- Missing request body closing (resource leaks)
- Race conditions on shared state without mutex

#### Security
- Missing CORS configuration
- Missing request size limits (DoS)
- Exposed stack traces in error responses
- Missing authentication middleware on protected routes
- SQL injection via string concatenation (use parameterized queries)
- Missing CSRF protection on state-changing endpoints

#### Performance
- Missing database connection pooling
- Unnecessary JSON marshaling in middleware (cache responses)
- Missing response compression
- Unoptimized static file serving (missing gzip pre-compression)
- Missing request timeout configuration

#### Architecture
- God handler files (>100 lines — split by resource)
- Missing service layer between handlers and database
- Missing middleware for cross-cutting concerns (logging, auth, validation)
- Tight coupling to specific database in handlers (use repository pattern)
