# OAuth 2.0 Integration Guide for OnePunch Desktop

This guide explains how to integrate OAuth 2.0 authentication with PKCE (Proof Key for Code Exchange) into the OnePunch desktop application.

## Overview

OnePunch now supports OAuth 2.0 authentication using the Authorization Code flow with PKCE. This provides a secure way for desktop applications to authenticate users without requiring them to enter API tokens manually.

## Flow Diagram

```
Desktop App → Browser (Login) → Redirect → Desktop App (Token)
```

## OAuth Configuration

### Development Environment

- **Authorization Endpoint**: `http://localhost:2030/oauth/authorize`
- **Token Endpoint**: `http://localhost:2030/oauth/token`
- **Client ID**: `onepunch_desktop_client`
- **Client Secret**: `desktop_secret_dev_only` (not used for public clients)
- **Redirect URI**: `onepunch://oauth/callback`

### Production Environment

- **Authorization Endpoint**: `https://onepunch.work/oauth/authorize`
- **Token Endpoint**: `https://onepunch.work/oauth/token`
- **Client ID**: (same as development)
- **Redirect URI**: `onepunch://oauth/callback`

## Implementation Steps

### 1. Generate PKCE Parameters

Before starting the OAuth flow, generate PKCE parameters:

```javascript
// Generate code_verifier (random string, 43-128 characters)
const code_verifier = generateRandomString(64); // Use crypto-safe random

// Generate code_challenge (SHA256 hash of code_verifier, base64url encoded)
const code_challenge = base64url(sha256(code_verifier));
const code_challenge_method = "S256";
```

### 2. Open Authorization URL in Browser

Build the authorization URL and open it in the user's default browser:

```javascript
const authUrl = new URL("http://localhost:2030/oauth/authorize");
authUrl.searchParams.append("client_id", "onepunch_desktop_client");
authUrl.searchParams.append("redirect_uri", "onepunch://oauth/callback");
authUrl.searchParams.append("response_type", "code");
authUrl.searchParams.append("scope", "api");
authUrl.searchParams.append("state", generateRandomString(32)); // CSRF protection
authUrl.searchParams.append("code_challenge", code_challenge);
authUrl.searchParams.append("code_challenge_method", "S256");

// Open in browser
openExternalBrowser(authUrl.toString());
```

### 3. Handle Redirect Callback

Register your application to handle the `onepunch://` URL scheme. When the user approves access, they'll be redirected to:

```
onepunch://oauth/callback?code=AUTH_CODE&state=STATE
```

Parse the authorization code from the URL:

```javascript
// Example callback URL
const callbackUrl = "onepunch://oauth/callback?code=abc123...&state=xyz789";
const url = new URL(callbackUrl);
const code = url.searchParams.get("code");
const state = url.searchParams.get("state");

// Verify state matches what you sent (CSRF protection)
if (state !== originalState) {
  throw new Error("State mismatch - possible CSRF attack");
}
```

### 4. Exchange Code for Access Token

Make a POST request to the token endpoint:

```javascript
const response = await fetch("http://localhost:2030/oauth/token", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    grant_type: "authorization_code",
    code: code,
    client_id: "onepunch_desktop_client",
    redirect_uri: "onepunch://oauth/callback",
    code_verifier: code_verifier, // Same as step 1
  }),
});

const tokens = await response.json();
```

**Response:**

```json
{
  "access_token": "abc123...",
  "token_type": "Bearer",
  "expires_in": 2592000,
  "refresh_token": "xyz789...",
  "scope": "api",
  "created_at": 1234567890
}
```

### 5. Store and Use Access Token

Store the access token securely (use OS keychain/credential manager) and use it for API requests:

```javascript
const response = await fetch("http://localhost:2030/api/v1/users/me", {
  headers: {
    Authorization: `Bearer ${access_token}`,
  },
});

const user = await response.json();
```

### 6. Refresh Token (Optional)

When the access token expires (after 30 days), use the refresh token to get a new one:

```javascript
const response = await fetch("http://localhost:2030/oauth/token", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    grant_type: "refresh_token",
    refresh_token: refresh_token,
    client_id: "onepunch_desktop_client",
  }),
});

const newTokens = await response.json();
// Store new tokens (old tokens are now revoked)
```

## Tauri Implementation Example

### Register URL Scheme

In `tauri.conf.json`:

```json
{
  "tauri": {
    "allowlist": {
      "shell": {
        "open": true
      }
    }
  }
}
```

### JavaScript/TypeScript Code

```typescript
import { invoke } from "@tauri-apps/api/tauri";
import { listen } from "@tauri-apps/api/event";
import { open as openBrowser } from "@tauri-apps/api/shell";

// PKCE helper functions
function generateRandomString(length: number): string {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  return Array.from(array, (byte) => chars[byte % chars.length]).join("");
}

async function sha256(message: string): Promise<ArrayBuffer> {
  const encoder = new TextEncoder();
  const data = encoder.encode(message);
  return await crypto.subtle.digest("SHA-256", data);
}

function base64url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}

// OAuth flow
async function startOAuthFlow() {
  // Generate PKCE parameters
  const codeVerifier = generateRandomString(64);
  const state = generateRandomString(32);

  const challengeBuffer = await sha256(codeVerifier);
  const codeChallenge = base64url(challengeBuffer);

  // Store for later use
  sessionStorage.setItem("code_verifier", codeVerifier);
  sessionStorage.setItem("oauth_state", state);

  // Build authorization URL
  const authUrl = new URL("http://localhost:2030/oauth/authorize");
  authUrl.searchParams.append("client_id", "onepunch_desktop_client");
  authUrl.searchParams.append("redirect_uri", "onepunch://oauth/callback");
  authUrl.searchParams.append("response_type", "code");
  authUrl.searchParams.append("scope", "api");
  authUrl.searchParams.append("state", state);
  authUrl.searchParams.append("code_challenge", codeChallenge);
  authUrl.searchParams.append("code_challenge_method", "S256");

  // Open in browser
  await openBrowser(authUrl.toString());
}

// Handle callback (you'll need to set up deep link handling)
async function handleOAuthCallback(callbackUrl: string) {
  const url = new URL(callbackUrl);
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");

  // Verify state
  const storedState = sessionStorage.getItem("oauth_state");
  if (state !== storedState) {
    throw new Error("State mismatch");
  }

  // Get code verifier
  const codeVerifier = sessionStorage.getItem("code_verifier");

  // Exchange code for token
  const response = await fetch("http://localhost:2030/oauth/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      grant_type: "authorization_code",
      code: code,
      client_id: "onepunch_desktop_client",
      redirect_uri: "onepunch://oauth/callback",
      code_verifier: codeVerifier,
    }),
  });

  const tokens = await response.json();

  // Store tokens securely
  // TODO: Use Tauri's store plugin or OS keychain
  localStorage.setItem("access_token", tokens.access_token);
  localStorage.setItem("refresh_token", tokens.refresh_token);

  // Clean up
  sessionStorage.removeItem("code_verifier");
  sessionStorage.removeItem("oauth_state");

  return tokens;
}
```

## API Endpoints

### Available API Endpoints (with OAuth)

Once authenticated, you can use these endpoints with the Bearer token:

- `GET /api/v1/users/me` - Get current user info
- `GET /api/v1/timer/current` - Get current running timer
- `POST /api/v1/timer/start` - Start a new timer
- `POST /api/v1/timer/stop` - Stop the current timer
- `GET /api/v1/time_entries` - List time entries
- `POST /api/v1/time_entries` - Create a time entry
- `GET /api/v1/projects` - List projects
- `POST /api/v1/projects` - Create a project

## Security Considerations

1. **PKCE is Required**: The server enforces PKCE for all OAuth flows. This protects against authorization code interception attacks.

2. **Store Tokens Securely**:
   - Use OS keychain/credential manager
   - Never store tokens in plain text files
   - Clear tokens on logout

3. **State Parameter**: Always verify the `state` parameter to prevent CSRF attacks.

4. **HTTPS in Production**: The production server uses HTTPS, which is required for OAuth security.

5. **Token Expiry**: Access tokens expire after 30 days. Implement automatic refresh or prompt user to re-authenticate.

## Testing

### Manual Testing with cURL

You can test the flow manually (without desktop app):

1. Get an authorization code by visiting in browser:
```
http://localhost:2030/oauth/authorize?client_id=onepunch_desktop_client&redirect_uri=http://localhost:3000/oauth/callback&response_type=code&scope=api&state=test123&code_challenge=E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM&code_challenge_method=S256
```

2. After login and approval, copy the `code` from the redirect URL

3. Exchange for token:
```bash
curl -X POST http://localhost:2030/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "authorization_code",
    "code": "YOUR_CODE_HERE",
    "client_id": "onepunch_desktop_client",
    "redirect_uri": "http://localhost:3000/oauth/callback",
    "code_verifier": "test"
  }'
```

4. Use the access token:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  http://localhost:2030/api/v1/users/me
```

## Troubleshooting

### "Invalid code_verifier"

The `code_verifier` used in token exchange must match the hashed `code_challenge` from authorization. Make sure you're storing and using the same verifier.

### "Authorization code has been expired"

Authorization codes expire after 10 minutes. Complete the token exchange quickly after authorization.

### "Invalid redirect_uri"

The `redirect_uri` must exactly match one of the URIs configured in the OAuth application. Check for trailing slashes and URL encoding.

### "Invalid or missing API token"

Make sure you're sending the Bearer token in the Authorization header:
```
Authorization: Bearer YOUR_TOKEN_HERE
```

## Support

For issues or questions:
- GitHub: https://github.com/yourusername/onepunch-desktop
- Email: support@onepunch.work
