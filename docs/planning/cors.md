# CORS Configuration Needed for Desktop OAuth

## Issue

The OnePunch Desktop app (Tauri) is experiencing CORS errors when attempting to exchange OAuth authorization codes for access tokens.

### Error Details

```
[Error] Preflight response is not successful. Status code: 403
[Error] Fetch API cannot load https://dev.onepunch.work/oauth/token due to access control checks.
[Error] Failed to load resource: Preflight response is not successful. Status code: 403 (token, line 0)
```

### Root Cause

The desktop app makes OAuth token requests from its frontend (running in a Tauri webview at `http://localhost:1420`). The server is rejecting these requests during the CORS preflight check.

### Request Details

- **Origin:** `http://localhost:1420` (Tauri development webview)
- **Target Endpoint:** `POST https://dev.onepunch.work/oauth/token`
- **Content-Type:** `application/json`
- **Method:** POST with JSON body containing:
  - `grant_type: "authorization_code"`
  - `code: "<auth_code>"`
  - `client_id: "onepunch_desktop_client"`
  - `redirect_uri: "onepunch://oauth/callback"`
  - `code_verifier: "<pkce_verifier>"`

## Required Fix

The OAuth token endpoint needs to allow CORS requests from:

1. **Development:** `http://localhost:1420` (Tauri dev server)
2. **Production:** `tauri://localhost` (Tauri production origin on Linux)
3. **Production (alternative):** May also use `http://tauri.localhost` depending on platform

### Rails CORS Configuration

Add to the CORS middleware configuration (likely in `config/initializers/cors.rb` or similar):

```ruby
# Allow Tauri desktop app origins for OAuth endpoints
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:1420', 'tauri://localhost', 'http://tauri.localhost'

    resource '/oauth/*',
      headers: :any,
      methods: [:get, :post, :options],
      credentials: true
  end
end
```

### Security Considerations

- The OAuth flow uses PKCE (Proof Key for Code Exchange), which is secure even without client secrets
- The desktop app uses the `onepunch://` deep link scheme for callbacks, which cannot be intercepted by web apps
- CORS is needed because the token exchange happens from the frontend webview, not from Rust backend

### Alternative Solutions

If CORS is not acceptable, we could:

1. **Move token exchange to Rust backend** - Have Tauri commands handle the token exchange server-side
2. **Use a proxy** - Route requests through the Rust backend to avoid CORS

However, the current approach (frontend fetch with CORS) is simpler and standard for desktop OAuth flows.

## Status

🔴 **Blocking:** Desktop app OAuth flow is completely broken without this fix.

**Affects:**
- Desktop app development (dev.onepunch.work)
- Desktop app production (onepunch.work)

**Priority:** High - Required for desktop app authentication

---

**Created:** 2025-10-15
**Reporter:** Desktop team
**Assigned to:** Backend/Rails team
