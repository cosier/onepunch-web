# TODO: Enable CORS for Desktop App OAuth

**Priority:** 🔴 **CRITICAL** - Blocking desktop app authentication
**Status:** ⏳ Pending
**Assignee:** Backend Team
**Estimated Time:** 5 minutes

## Summary

The OnePunch Desktop app (Tauri) cannot complete OAuth authentication due to CORS restrictions. The OAuth token endpoint returns `403 Forbidden` for CORS preflight requests from the desktop app's webview.

## Problem

When users click "Accept" in the OAuth flow, the desktop app attempts to exchange the authorization code for an access token by making a POST request to `/oauth/token`. This request is blocked by CORS:

```
[Error] Preflight response is not successful. Status code: 403
[Error] Fetch API cannot load https://dev.onepunch.work/oauth/token due to access control checks.
```

## Solution Required

Add CORS support for the OAuth endpoints to allow requests from Tauri app origins.

### Required Changes

Add to CORS configuration (e.g., `config/initializers/cors.rb`):

```ruby
# Allow Tauri desktop app origins for OAuth endpoints
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Tauri development and production origins
    origins 'http://localhost:1420',      # Dev mode
            'tauri://localhost',           # Production (Linux/Windows)
            'http://tauri.localhost'       # Production (alternative)

    resource '/oauth/*',
      headers: :any,
      methods: [:get, :post, :options],
      credentials: true
  end
end
```

### Affected Endpoints

- `POST /oauth/token` - Token exchange (authorization_code grant)
- `POST /oauth/token` - Token refresh (refresh_token grant)
- `POST /oauth/authorize` - Authorization endpoint (GET typically, but allow POST)

## Why This Is Safe

1. **PKCE Protection:** The OAuth flow uses PKCE (Proof Key for Code Exchange), which is designed for public clients
2. **Deep Link Callbacks:** The desktop app uses `onepunch://` protocol for callbacks, which cannot be intercepted by web browsers
3. **Standard Practice:** This is the standard approach for desktop OAuth with embedded webviews
4. **No Secrets Exposed:** The desktop client has no client secret; security comes from PKCE + platform isolation

## Testing

After implementing:

1. Launch desktop app: `cd onepunch-desktop && WAYLAND_DISPLAY=wayland-1 npm run tauri dev`
2. Click "Sign in with OnePunch"
3. Browser opens to OAuth page
4. Click "Accept"
5. Desktop app should successfully authenticate and show dashboard

## Documentation

See detailed documentation: [`docs/planning/cors.md`](../planning/cors.md)

## Acceptance Criteria

- [ ] CORS configuration added for `/oauth/*` endpoints
- [ ] Desktop app can successfully exchange authorization code for tokens
- [ ] Desktop app can successfully refresh tokens
- [ ] No CORS errors in browser console during OAuth flow
- [ ] Configuration tested on both dev and production environments

## Dependencies

None - this is a configuration change only.

## Related Files

- `config/initializers/cors.rb` (or equivalent CORS configuration)
- `app/controllers/oauth/*` (OAuth controllers)

## Notes

If adding CORS is not acceptable for security reasons, alternative approaches include:

1. **Backend Token Exchange:** Move token exchange to Rust backend (Tauri commands)
2. **Proxy Through Backend:** Route all OAuth requests through Rust to avoid CORS

However, the CORS approach is simpler and follows industry standards for desktop OAuth.

---

**Created:** 2025-10-15
**Last Updated:** 2025-10-15
**Reporter:** Desktop Team
