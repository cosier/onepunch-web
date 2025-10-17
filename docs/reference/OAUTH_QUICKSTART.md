# OAuth Quick Start Guide

Quick reference for implementing OAuth in the desktop app.

## TL;DR - What You Need

1. **Register URL scheme**: `onepunch://oauth/callback`
2. **Generate PKCE**: code_verifier + SHA256 hash
3. **Open browser**: `/oauth/authorize` with PKCE params
4. **Handle callback**: Parse code from deep link
5. **Exchange code**: POST to `/oauth/token`
6. **Store tokens**: Use for all API calls

## Configuration

```typescript
// Development
const config = {
  authUrl: 'http://localhost:2030/oauth/authorize',
  tokenUrl: 'http://localhost:2030/oauth/token',
  clientId: 'onepunch_desktop_client',
  redirectUri: 'onepunch://oauth/callback',
};

// Production
const config = {
  authUrl: 'https://onepunch.work/oauth/authorize',
  tokenUrl: 'https://onepunch.work/oauth/token',
  clientId: 'onepunch_desktop_client',
  redirectUri: 'onepunch://oauth/callback',
};
```

## PKCE Generation (JavaScript/TypeScript)

```javascript
// 1. Generate random code_verifier
function generateCodeVerifier() {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return base64UrlEncode(array);
}

// 2. Generate code_challenge from verifier
async function generateCodeChallenge(verifier) {
  const encoder = new TextEncoder();
  const data = encoder.encode(verifier);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return base64UrlEncode(hash);
}

// 3. Base64 URL encode
function base64UrlEncode(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}
```

## Authorization Flow

### Step 1: Start Authorization

```javascript
// Generate PKCE
const verifier = generateCodeVerifier();
const challenge = await generateCodeChallenge(verifier);
const state = generateCodeVerifier(); // For CSRF protection

// Store verifier and state
sessionStorage.setItem('code_verifier', verifier);
sessionStorage.setItem('state', state);

// Build URL
const url = new URL('http://localhost:2030/oauth/authorize');
url.searchParams.append('client_id', 'onepunch_desktop_client');
url.searchParams.append('redirect_uri', 'onepunch://oauth/callback');
url.searchParams.append('response_type', 'code');
url.searchParams.append('scope', 'api');
url.searchParams.append('state', state);
url.searchParams.append('code_challenge', challenge);
url.searchParams.append('code_challenge_method', 'S256');

// Open in browser
window.open(url.toString());
```

### Step 2: Handle Callback

```javascript
// Parse deep link: onepunch://oauth/callback?code=ABC&state=XYZ
function handleCallback(deepLinkUrl) {
  const url = new URL(deepLinkUrl);
  const code = url.searchParams.get('code');
  const state = url.searchParams.get('state');

  // Verify state
  const storedState = sessionStorage.getItem('state');
  if (state !== storedState) {
    throw new Error('State mismatch - CSRF attack?');
  }

  return code;
}
```

### Step 3: Exchange Code for Token

```javascript
async function exchangeCodeForToken(code) {
  const verifier = sessionStorage.getItem('code_verifier');

  const response = await fetch('http://localhost:2030/oauth/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      grant_type: 'authorization_code',
      code: code,
      client_id: 'onepunch_desktop_client',
      redirect_uri: 'onepunch://oauth/callback',
      code_verifier: verifier,
    }),
  });

  const tokens = await response.json();

  // Store tokens
  localStorage.setItem('access_token', tokens.access_token);
  localStorage.setItem('refresh_token', tokens.refresh_token);

  // Clean up
  sessionStorage.removeItem('code_verifier');
  sessionStorage.removeItem('state');

  return tokens;
}
```

## Using Access Token

```javascript
// All API requests
const response = await fetch('http://localhost:2030/api/v1/users/me', {
  headers: {
    'Authorization': `Bearer ${accessToken}`,
  },
});

const user = await response.json();
```

## Token Refresh

```javascript
async function refreshToken(refreshToken) {
  const response = await fetch('http://localhost:2030/oauth/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: 'onepunch_desktop_client',
    }),
  });

  const tokens = await response.json();

  // Store new tokens (old ones are now invalid)
  localStorage.setItem('access_token', tokens.access_token);
  localStorage.setItem('refresh_token', tokens.refresh_token);

  return tokens;
}
```

## Test Credentials

```
Email: demo@onepunch.app
Password: password123
```

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Invalid code_verifier` | Verifier doesn't match challenge | Ensure you're using the same verifier from step 1 |
| `State mismatch` | CSRF protection triggered | Verify state parameter matches |
| `Authorization code expired` | Took too long | Complete exchange within 10 minutes |
| `Invalid redirect_uri` | URI doesn't match | Use exact URI: `onepunch://oauth/callback` |

## API Endpoints

With OAuth token (`Authorization: Bearer {token}`):

- `GET /api/v1/users/me` - Current user
- `GET /api/v1/timer/current` - Running timer
- `POST /api/v1/timer/start` - Start timer
- `POST /api/v1/timer/stop` - Stop timer
- `GET /api/v1/time_entries` - List entries
- `GET /api/v1/projects` - List projects

## Files to Create

1. `src/lib/oauth.ts` - Configuration
2. `src/lib/pkce.ts` - PKCE helpers
3. `src/lib/tokenStorage.ts` - Token management
4. `src/lib/oauthFlow.ts` - OAuth flow manager
5. `src/lib/apiClient.ts` - API client
6. `src/lib/authService.ts` - Auth service
7. `src/hooks/useAuth.ts` - React hook
8. `src/components/LoginScreen.tsx` - Login UI

## Tauri Setup

### tauri.conf.json
```json
{
  "tauri": {
    "allowlist": {
      "shell": { "open": true }
    },
    "bundle": {
      "windows": {
        "customProtocols": ["onepunch"]
      }
    }
  }
}
```

### src-tauri/src/main.rs
```rust
use tauri::Manager;

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_deep_link::init())
        .setup(|app| {
            let handle = app.handle();
            tauri_plugin_deep_link::register("onepunch", move |request| {
                handle.emit_all("deep-link", request).unwrap();
            })?;
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

## Next Steps

1. Read full implementation guide: `DESKTOP_OAUTH_IMPLEMENTATION.md`
2. Copy code from Step 1-9 in the guide
3. Test with development server running
4. Verify deep links work on your platform

## Support

- Full guide: [DESKTOP_OAUTH_IMPLEMENTATION.md](./DESKTOP_OAUTH_IMPLEMENTATION.md)
- OAuth details: [OAUTH_INTEGRATION.md](./OAUTH_INTEGRATION.md)
- Issues: GitHub with [OAuth] tag
