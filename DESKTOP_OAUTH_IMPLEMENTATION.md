# OnePunch Desktop - OAuth 2.0 Implementation Reference

This document provides a complete implementation guide for integrating OAuth 2.0 authentication into the OnePunch Desktop (Tauri) application.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Implementation Steps](#implementation-steps)
5. [Code Reference](#code-reference)
6. [Testing](#testing)
7. [Error Handling](#error-handling)
8. [Security Considerations](#security-considerations)

---

## Overview

### What We're Building

A secure OAuth 2.0 authentication flow that allows users to:
1. Click "Sign in with OnePunch" in the desktop app
2. Browser opens to OnePunch web login page
3. User logs in with Google OAuth or email/password
4. User approves desktop app access
5. Browser redirects back to desktop app with authorization code
6. Desktop app exchanges code for access token
7. Desktop app uses token for all API requests

### Why OAuth Instead of API Tokens?

- **Better UX**: No manual copying of tokens
- **More Secure**: PKCE prevents token interception
- **Familiar Flow**: Users know "Sign in with..." pattern
- **Refresh Support**: Automatic token renewal
- **Revocable**: Users can revoke access from web dashboard

---

## Architecture

### OAuth 2.0 Authorization Code Flow with PKCE

```
┌─────────────────┐
│  Desktop App    │
│  (Tauri)        │
└────────┬────────┘
         │ 1. Generate PKCE params
         │    code_verifier (random)
         │    code_challenge = SHA256(code_verifier)
         │
         │ 2. Open browser with authorization URL
         ▼
┌─────────────────────────────────────────────┐
│  Browser → OnePunch Web                     │
│  http://localhost:2030/oauth/authorize      │
│  ?client_id=...                            │
│  &redirect_uri=onepunch://oauth/callback   │
│  &code_challenge=...                       │
└────────┬────────────────────────────────────┘
         │ 3. User logs in & approves
         │
         │ 4. Redirect with code
         │    onepunch://oauth/callback?code=ABC123
         ▼
┌─────────────────┐
│  Desktop App    │
│  Deep Link      │
└────────┬────────┘
         │ 5. Exchange code + code_verifier for token
         │    POST /oauth/token
         │
         ▼
┌─────────────────────────────────────────────┐
│  Response: access_token, refresh_token      │
└─────────────────────────────────────────────┘
         │
         │ 6. Store tokens securely
         │ 7. Use token for API calls
         ▼
┌─────────────────────────────────────────────┐
│  All API requests:                          │
│  Authorization: Bearer {access_token}       │
└─────────────────────────────────────────────┘
```

---

## Prerequisites

### Tauri Configuration

#### 1. Install Required Dependencies

```bash
cd onepunch-desktop
npm install @tauri-apps/api
npm install --save-dev @tauri-apps/cli
```

#### 2. Enable Required Tauri Features

In `src-tauri/Cargo.toml`:

```toml
[dependencies]
tauri = { version = "1.5", features = ["shell-open", "protocol-all"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
```

#### 3. Configure Deep Linking

In `src-tauri/tauri.conf.json`:

```json
{
  "tauri": {
    "allowlist": {
      "shell": {
        "open": true
      },
      "protocol": {
        "asset": true,
        "assetScope": ["**"]
      }
    },
    "windows": [
      {
        "title": "OnePunch",
        "width": 1200,
        "height": 800
      }
    ],
    "security": {
      "csp": null
    }
  }
}
```

#### 4. Register Custom URL Scheme

**macOS** (`src-tauri/Info.plist`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLName</key>
      <string>com.onepunch.desktop</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>onepunch</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
```

**Windows** (`src-tauri/tauri.conf.json`):
```json
{
  "tauri": {
    "bundle": {
      "windows": {
        "customProtocols": ["onepunch"]
      }
    }
  }
}
```

**Linux** - URL scheme registration happens automatically via `.desktop` file.

---

## Implementation Steps

### Step 1: Create OAuth Configuration

Create `src/lib/oauth.ts`:

```typescript
export const OAUTH_CONFIG = {
  // Development
  development: {
    authorizationEndpoint: 'http://localhost:2030/oauth/authorize',
    tokenEndpoint: 'http://localhost:2030/oauth/token',
    clientId: 'onepunch_desktop_client',
    redirectUri: 'onepunch://oauth/callback',
    scope: 'api',
  },

  // Production
  production: {
    authorizationEndpoint: 'https://onepunch.work/oauth/authorize',
    tokenEndpoint: 'https://onepunch.work/oauth/token',
    clientId: 'onepunch_desktop_client',
    redirectUri: 'onepunch://oauth/callback',
    scope: 'api',
  },
};

// Auto-detect environment
export const getOAuthConfig = () => {
  const isDev = import.meta.env.DEV;
  return isDev ? OAUTH_CONFIG.development : OAUTH_CONFIG.production;
};
```

### Step 2: Implement PKCE Helper Functions

Create `src/lib/pkce.ts`:

```typescript
/**
 * Generate a cryptographically secure random string
 * @param length - Length of the string (43-128 characters for PKCE)
 */
export function generateRandomString(length: number): string {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  const randomValues = new Uint8Array(length);
  crypto.getRandomValues(randomValues);

  return Array.from(randomValues)
    .map(value => charset[value % charset.length])
    .join('');
}

/**
 * Generate SHA-256 hash of a string
 * @param message - String to hash
 * @returns ArrayBuffer containing the hash
 */
export async function sha256(message: string): Promise<ArrayBuffer> {
  const encoder = new TextEncoder();
  const data = encoder.encode(message);
  return await crypto.subtle.digest('SHA-256', data);
}

/**
 * Base64 URL encode (without padding)
 * @param buffer - ArrayBuffer to encode
 * @returns Base64 URL encoded string
 */
export function base64UrlEncode(buffer: ArrayBuffer): string {
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

/**
 * Generate PKCE code verifier and challenge
 * @returns Object containing verifier and challenge
 */
export async function generatePKCE(): Promise<{
  codeVerifier: string;
  codeChallenge: string;
}> {
  // Generate random code verifier (43-128 characters)
  const codeVerifier = generateRandomString(64);

  // Generate code challenge (SHA256 hash of verifier)
  const hashedVerifier = await sha256(codeVerifier);
  const codeChallenge = base64UrlEncode(hashedVerifier);

  return {
    codeVerifier,
    codeChallenge,
  };
}
```

### Step 3: Implement Token Storage

Create `src/lib/tokenStorage.ts`:

```typescript
import { invoke } from '@tauri-apps/api/tauri';

export interface TokenData {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  tokenType: string;
  scope: string;
  createdAt: number;
}

/**
 * Store tokens securely using Tauri's store plugin
 * For production, consider using OS keychain via tauri-plugin-stronghold
 */
export class TokenStorage {
  private static STORAGE_KEY = 'onepunch_tokens';

  /**
   * Save tokens to secure storage
   */
  static async saveTokens(tokens: TokenData): Promise<void> {
    try {
      // For now, use localStorage (upgrade to secure storage in production)
      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(tokens));

      // TODO: Use Tauri's secure storage
      // await invoke('save_secure_tokens', { tokens });
    } catch (error) {
      console.error('Failed to save tokens:', error);
      throw new Error('Failed to save authentication tokens');
    }
  }

  /**
   * Retrieve tokens from secure storage
   */
  static async getTokens(): Promise<TokenData | null> {
    try {
      const tokensJson = localStorage.getItem(this.STORAGE_KEY);
      if (!tokensJson) return null;

      const tokens = JSON.parse(tokensJson) as TokenData;

      // Check if token is expired
      const expiresAt = tokens.createdAt + tokens.expiresIn * 1000;
      if (Date.now() >= expiresAt) {
        console.log('Token expired');
        return null;
      }

      return tokens;
    } catch (error) {
      console.error('Failed to retrieve tokens:', error);
      return null;
    }
  }

  /**
   * Check if user has valid tokens
   */
  static async hasValidTokens(): Promise<boolean> {
    const tokens = await this.getTokens();
    return tokens !== null;
  }

  /**
   * Get access token for API requests
   */
  static async getAccessToken(): Promise<string | null> {
    const tokens = await this.getTokens();
    return tokens?.accessToken ?? null;
  }

  /**
   * Clear stored tokens (logout)
   */
  static async clearTokens(): Promise<void> {
    try {
      localStorage.removeItem(this.STORAGE_KEY);
      // TODO: Clear from secure storage
      // await invoke('clear_secure_tokens');
    } catch (error) {
      console.error('Failed to clear tokens:', error);
    }
  }
}
```

### Step 4: Implement OAuth Flow Manager

Create `src/lib/oauthFlow.ts`:

```typescript
import { open as openBrowser } from '@tauri-apps/api/shell';
import { listen } from '@tauri-apps/api/event';
import { getOAuthConfig } from './oauth';
import { generatePKCE, generateRandomString } from './pkce';
import { TokenStorage, type TokenData } from './tokenStorage';

export class OAuthFlowManager {
  private codeVerifier: string | null = null;
  private state: string | null = null;
  private unlisten: (() => void) | null = null;

  /**
   * Start the OAuth authorization flow
   * Opens browser to OnePunch login page
   */
  async startAuthFlow(): Promise<void> {
    const config = getOAuthConfig();

    try {
      // Generate PKCE parameters
      const { codeVerifier, codeChallenge } = await generatePKCE();
      this.codeVerifier = codeVerifier;

      // Generate state for CSRF protection
      this.state = generateRandomString(32);

      // Store in session for validation
      sessionStorage.setItem('oauth_code_verifier', codeVerifier);
      sessionStorage.setItem('oauth_state', this.state);

      // Build authorization URL
      const authUrl = new URL(config.authorizationEndpoint);
      authUrl.searchParams.append('client_id', config.clientId);
      authUrl.searchParams.append('redirect_uri', config.redirectUri);
      authUrl.searchParams.append('response_type', 'code');
      authUrl.searchParams.append('scope', config.scope);
      authUrl.searchParams.append('state', this.state);
      authUrl.searchParams.append('code_challenge', codeChallenge);
      authUrl.searchParams.append('code_challenge_method', 'S256');

      console.log('Opening authorization URL:', authUrl.toString());

      // Open in default browser
      await openBrowser(authUrl.toString());

      // Set up deep link listener
      await this.setupDeepLinkListener();

    } catch (error) {
      console.error('Failed to start OAuth flow:', error);
      throw new Error('Failed to initiate authentication');
    }
  }

  /**
   * Set up listener for deep link callback
   */
  private async setupDeepLinkListener(): Promise<void> {
    try {
      // Listen for deep link events from Tauri
      this.unlisten = await listen('deep-link', async (event: any) => {
        const url = event.payload as string;
        console.log('Received deep link:', url);

        try {
          await this.handleCallback(url);
        } catch (error) {
          console.error('Failed to handle callback:', error);
          throw error;
        }
      });
    } catch (error) {
      console.error('Failed to set up deep link listener:', error);
      throw error;
    }
  }

  /**
   * Handle OAuth callback from deep link
   */
  private async handleCallback(callbackUrl: string): Promise<TokenData> {
    try {
      // Parse callback URL
      const url = new URL(callbackUrl);
      const code = url.searchParams.get('code');
      const state = url.searchParams.get('state');
      const error = url.searchParams.get('error');
      const errorDescription = url.searchParams.get('error_description');

      // Check for error response
      if (error) {
        throw new Error(errorDescription || `OAuth error: ${error}`);
      }

      // Validate required parameters
      if (!code) {
        throw new Error('Authorization code not received');
      }

      if (!state) {
        throw new Error('State parameter not received');
      }

      // Verify state (CSRF protection)
      const storedState = sessionStorage.getItem('oauth_state');
      if (state !== storedState) {
        throw new Error('State mismatch - possible CSRF attack');
      }

      // Get code verifier
      const codeVerifier = sessionStorage.getItem('oauth_code_verifier');
      if (!codeVerifier) {
        throw new Error('Code verifier not found');
      }

      // Exchange code for tokens
      const tokens = await this.exchangeCodeForTokens(code, codeVerifier);

      // Store tokens securely
      await TokenStorage.saveTokens(tokens);

      // Clean up session storage
      sessionStorage.removeItem('oauth_code_verifier');
      sessionStorage.removeItem('oauth_state');

      // Clean up listener
      if (this.unlisten) {
        this.unlisten();
        this.unlisten = null;
      }

      return tokens;

    } catch (error) {
      console.error('Failed to handle OAuth callback:', error);
      throw error;
    }
  }

  /**
   * Exchange authorization code for access token
   */
  private async exchangeCodeForTokens(
    code: string,
    codeVerifier: string
  ): Promise<TokenData> {
    const config = getOAuthConfig();

    try {
      const response = await fetch(config.tokenEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          grant_type: 'authorization_code',
          code: code,
          client_id: config.clientId,
          redirect_uri: config.redirectUri,
          code_verifier: codeVerifier,
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Token exchange failed');
      }

      const data = await response.json();

      return {
        accessToken: data.access_token,
        refreshToken: data.refresh_token,
        expiresIn: data.expires_in,
        tokenType: data.token_type,
        scope: data.scope,
        createdAt: data.created_at * 1000, // Convert to milliseconds
      };

    } catch (error) {
      console.error('Failed to exchange code for tokens:', error);
      throw new Error('Failed to obtain access token');
    }
  }

  /**
   * Refresh access token using refresh token
   */
  static async refreshAccessToken(): Promise<TokenData> {
    const config = getOAuthConfig();
    const currentTokens = await TokenStorage.getTokens();

    if (!currentTokens?.refreshToken) {
      throw new Error('No refresh token available');
    }

    try {
      const response = await fetch(config.tokenEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          grant_type: 'refresh_token',
          refresh_token: currentTokens.refreshToken,
          client_id: config.clientId,
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.error || 'Token refresh failed');
      }

      const data = await response.json();

      const newTokens: TokenData = {
        accessToken: data.access_token,
        refreshToken: data.refresh_token,
        expiresIn: data.expires_in,
        tokenType: data.token_type,
        scope: data.scope,
        createdAt: data.created_at * 1000,
      };

      // Store new tokens
      await TokenStorage.saveTokens(newTokens);

      return newTokens;

    } catch (error) {
      console.error('Failed to refresh token:', error);

      // If refresh fails, clear tokens and require re-authentication
      await TokenStorage.clearTokens();

      throw new Error('Session expired. Please sign in again.');
    }
  }
}
```

### Step 5: Create API Client with Authentication

Create `src/lib/apiClient.ts`:

```typescript
import { TokenStorage } from './tokenStorage';
import { OAuthFlowManager } from './oauthFlow';
import { getOAuthConfig } from './oauth';

export class ApiClient {
  private baseUrl: string;

  constructor() {
    const config = getOAuthConfig();
    this.baseUrl = config.authorizationEndpoint.replace('/oauth/authorize', '');
  }

  /**
   * Make authenticated API request
   */
  async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const accessToken = await TokenStorage.getAccessToken();

    if (!accessToken) {
      throw new Error('Not authenticated');
    }

    const url = `${this.baseUrl}${endpoint}`;

    try {
      const response = await fetch(url, {
        ...options,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${accessToken}`,
          ...options.headers,
        },
      });

      // Handle 401 - try to refresh token
      if (response.status === 401) {
        console.log('Access token expired, attempting refresh...');

        try {
          await OAuthFlowManager.refreshAccessToken();

          // Retry request with new token
          const newAccessToken = await TokenStorage.getAccessToken();
          const retryResponse = await fetch(url, {
            ...options,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${newAccessToken}`,
              ...options.headers,
            },
          });

          if (!retryResponse.ok) {
            throw new Error(`API request failed: ${retryResponse.statusText}`);
          }

          return await retryResponse.json();

        } catch (refreshError) {
          // Refresh failed - user needs to re-authenticate
          throw new Error('Session expired. Please sign in again.');
        }
      }

      if (!response.ok) {
        throw new Error(`API request failed: ${response.statusText}`);
      }

      return await response.json();

    } catch (error) {
      console.error('API request failed:', error);
      throw error;
    }
  }

  /**
   * GET request
   */
  async get<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'GET' });
  }

  /**
   * POST request
   */
  async post<T>(endpoint: string, data: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * PATCH request
   */
  async patch<T>(endpoint: string, data: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * DELETE request
   */
  async delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, { method: 'DELETE' });
  }
}

// Singleton instance
export const apiClient = new ApiClient();
```

### Step 6: Implement Authentication Service

Create `src/lib/authService.ts`:

```typescript
import { TokenStorage } from './tokenStorage';
import { OAuthFlowManager } from './oauthFlow';
import { apiClient } from './apiClient';

export interface User {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  avatar_url: string | null;
}

export class AuthService {
  private oauthFlow: OAuthFlowManager | null = null;

  /**
   * Check if user is authenticated
   */
  async isAuthenticated(): Promise<boolean> {
    return await TokenStorage.hasValidTokens();
  }

  /**
   * Start sign-in flow
   */
  async signIn(): Promise<void> {
    try {
      this.oauthFlow = new OAuthFlowManager();
      await this.oauthFlow.startAuthFlow();
    } catch (error) {
      console.error('Sign in failed:', error);
      throw new Error('Failed to start sign-in process');
    }
  }

  /**
   * Sign out
   */
  async signOut(): Promise<void> {
    await TokenStorage.clearTokens();
  }

  /**
   * Get current user
   */
  async getCurrentUser(): Promise<User> {
    try {
      const response = await apiClient.get<{ data: User }>('/api/v1/users/me');
      return response.data;
    } catch (error) {
      console.error('Failed to get current user:', error);
      throw new Error('Failed to fetch user information');
    }
  }
}

// Singleton instance
export const authService = new AuthService();
```

### Step 7: Create React Hook for Authentication

Create `src/hooks/useAuth.ts`:

```typescript
import { useState, useEffect } from 'react';
import { authService, type User } from '../lib/authService';

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    checkAuth();
  }, []);

  async function checkAuth() {
    try {
      setIsLoading(true);
      const authenticated = await authService.isAuthenticated();
      setIsAuthenticated(authenticated);

      if (authenticated) {
        const currentUser = await authService.getCurrentUser();
        setUser(currentUser);
      }
    } catch (err) {
      console.error('Auth check failed:', err);
      setError(err instanceof Error ? err.message : 'Authentication failed');
      setIsAuthenticated(false);
    } finally {
      setIsLoading(false);
    }
  }

  async function signIn() {
    try {
      setError(null);
      setIsLoading(true);
      await authService.signIn();

      // After OAuth flow completes, check auth again
      await checkAuth();
    } catch (err) {
      console.error('Sign in failed:', err);
      setError(err instanceof Error ? err.message : 'Sign in failed');
      throw err;
    } finally {
      setIsLoading(false);
    }
  }

  async function signOut() {
    try {
      setError(null);
      await authService.signOut();
      setUser(null);
      setIsAuthenticated(false);
    } catch (err) {
      console.error('Sign out failed:', err);
      setError(err instanceof Error ? err.message : 'Sign out failed');
    }
  }

  return {
    user,
    isLoading,
    isAuthenticated,
    error,
    signIn,
    signOut,
    refreshAuth: checkAuth,
  };
}
```

### Step 8: Create UI Components

Create `src/components/LoginScreen.tsx`:

```tsx
import React from 'react';
import { useAuth } from '../hooks/useAuth';

export function LoginScreen() {
  const { signIn, isLoading, error } = useAuth();

  const handleSignIn = async () => {
    try {
      await signIn();
    } catch (err) {
      // Error is already handled in useAuth
      console.error('Login failed:', err);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8 p-8 bg-white rounded-lg shadow">
        {/* Logo */}
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">
            OnePunch
          </h1>
          <p className="text-gray-600">
            Time tracking that actually works
          </p>
        </div>

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-800 rounded-lg p-4">
            <p className="text-sm">{error}</p>
          </div>
        )}

        {/* Sign In Button */}
        <button
          onClick={handleSignIn}
          disabled={isLoading}
          className="w-full flex justify-center items-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {isLoading ? (
            <>
              <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Signing in...
            </>
          ) : (
            'Sign in with OnePunch'
          )}
        </button>

        {/* Info Text */}
        <p className="text-xs text-gray-500 text-center">
          A browser window will open for you to sign in securely.
          <br />
          You can use Google or email/password.
        </p>
      </div>
    </div>
  );
}
```

Create `src/App.tsx`:

```tsx
import React from 'react';
import { useAuth } from './hooks/useAuth';
import { LoginScreen } from './components/LoginScreen';
import { MainApp } from './components/MainApp';

export function App() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <LoginScreen />;
  }

  return <MainApp />;
}
```

### Step 9: Handle Deep Links in Tauri

Create `src-tauri/src/main.rs`:

```rust
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::{Manager, Window};

#[tauri::command]
fn save_secure_tokens(tokens: String) -> Result<(), String> {
    // TODO: Implement secure token storage using system keychain
    // For now, this is a placeholder
    Ok(())
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_deep_link::init())
        .setup(|app| {
            // Register deep link handler
            let handle = app.handle();

            tauri_plugin_deep_link::register("onepunch", move |request| {
                handle.emit_all("deep-link", request).unwrap();
            })
            .expect("Failed to register deep link handler");

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![save_secure_tokens])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

---

## Testing

### Manual Testing Steps

1. **Start Development Server**:
   ```bash
   cd ../onepunch
   ./bin/dev
   ```

2. **Build and Run Desktop App**:
   ```bash
   cd ../onepunch-desktop
   npm run tauri dev
   ```

3. **Test OAuth Flow**:
   - Click "Sign in with OnePunch"
   - Browser should open to `http://localhost:2030/oauth/authorize`
   - Log in with: `demo@onepunch.app` / `password123`
   - Approve access on consent page
   - Desktop app should receive token and load main interface

4. **Verify Token Works**:
   - Check that user info loads
   - Try making API calls (start timer, etc.)
   - Check browser console for any errors

### Automated Testing

Create `src/__tests__/pkce.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { generateRandomString, generatePKCE } from '../lib/pkce';

describe('PKCE', () => {
  it('generates random string of correct length', () => {
    const str = generateRandomString(64);
    expect(str).toHaveLength(64);
  });

  it('generates unique random strings', () => {
    const str1 = generateRandomString(64);
    const str2 = generateRandomString(64);
    expect(str1).not.toBe(str2);
  });

  it('generates PKCE parameters', async () => {
    const { codeVerifier, codeChallenge } = await generatePKCE();

    expect(codeVerifier).toBeDefined();
    expect(codeChallenge).toBeDefined();
    expect(codeVerifier.length).toBeGreaterThanOrEqual(43);
    expect(codeChallenge.length).toBeGreaterThan(0);
  });

  it('generates different challenges for different verifiers', async () => {
    const pkce1 = await generatePKCE();
    const pkce2 = await generatePKCE();

    expect(pkce1.codeVerifier).not.toBe(pkce2.codeVerifier);
    expect(pkce1.codeChallenge).not.toBe(pkce2.codeChallenge);
  });
});
```

---

## Error Handling

### Common Errors and Solutions

#### 1. "Deep link not registered"

**Problem**: App doesn't respond to `onepunch://` URLs

**Solution**:
- Verify URL scheme is registered in `tauri.conf.json`
- On macOS: Check `Info.plist`
- On Windows: Reinstall app to register protocol
- On Linux: Check `.desktop` file

#### 2. "State mismatch"

**Problem**: CSRF protection triggered

**Solution**:
- Ensure state parameter is stored before opening browser
- Check that sessionStorage is working correctly
- Verify no page reloads between auth start and callback

#### 3. "Invalid code_verifier"

**Problem**: PKCE validation failed

**Solution**:
- Ensure `code_verifier` matches the hashed `code_challenge`
- Check that SHA-256 and base64url encoding are correct
- Verify no extra characters or padding in challenge

#### 4. "Authorization code expired"

**Problem**: Took too long to exchange code

**Solution**:
- Complete token exchange within 10 minutes
- Check for network issues
- Ensure no delays in deep link handling

#### 5. "Token refresh failed"

**Problem**: Can't get new access token

**Solution**:
- User must sign in again
- Clear stored tokens
- Show login screen

### Error Handling Best Practices

```typescript
// Always wrap OAuth operations in try-catch
try {
  await authService.signIn();
} catch (error) {
  if (error.message.includes('expired')) {
    // Show "Session expired" message
    showNotification('Your session expired. Please sign in again.');
  } else if (error.message.includes('denied')) {
    // User denied access
    showNotification('Authorization denied. Please approve access to continue.');
  } else {
    // Generic error
    showNotification('Sign in failed. Please try again.');
  }
}
```

---

## Security Considerations

### ✅ DO

1. **Use PKCE**: Always generate unique `code_verifier` and `code_challenge`
2. **Validate State**: Check state parameter to prevent CSRF
3. **Secure Storage**: Use OS keychain for tokens (upgrade from localStorage)
4. **HTTPS in Production**: Never use HTTP for OAuth in production
5. **Token Expiry**: Handle expired tokens gracefully with refresh
6. **Clear on Logout**: Remove all tokens when user signs out
7. **Rate Limiting**: Handle rate limits from API gracefully

### ❌ DON'T

1. **Don't Store Tokens Plainly**: Upgrade from localStorage to secure storage
2. **Don't Log Tokens**: Never console.log tokens or sensitive data
3. **Don't Skip State**: Always validate state parameter
4. **Don't Reuse Verifiers**: Generate new PKCE params for each flow
5. **Don't Ignore Errors**: Always handle OAuth errors properly
6. **Don't Trust Redirects**: Validate redirect URI matches registered URI

### Secure Token Storage (TODO)

For production, implement secure token storage:

```bash
npm install tauri-plugin-stronghold
```

Update `src-tauri/Cargo.toml`:
```toml
[dependencies]
tauri-plugin-stronghold = "1.0"
```

Then use Stronghold for encrypted token storage instead of localStorage.

---

## Production Checklist

Before releasing:

- [ ] Replace localStorage with secure storage (Stronghold)
- [ ] Test on all platforms (macOS, Windows, Linux)
- [ ] Verify deep links work on all platforms
- [ ] Test token refresh flow
- [ ] Test network error handling
- [ ] Add analytics for OAuth flow (optional)
- [ ] Add user feedback for all error states
- [ ] Test with slow network conditions
- [ ] Verify HTTPS is used in production
- [ ] Add logout functionality
- [ ] Test token revocation from web dashboard
- [ ] Add "About" screen with OAuth info
- [ ] Document troubleshooting steps for users

---

## API Endpoints Reference

All endpoints require `Authorization: Bearer {token}` header.

### User
- `GET /api/v1/users/me` - Get current user

### Timer
- `GET /api/v1/timer/current` - Get running timer
- `POST /api/v1/timer/start` - Start timer
- `POST /api/v1/timer/stop` - Stop timer

### Time Entries
- `GET /api/v1/time_entries` - List entries
- `POST /api/v1/time_entries` - Create entry
- `PATCH /api/v1/time_entries/:id` - Update entry
- `DELETE /api/v1/time_entries/:id` - Delete entry

### Projects
- `GET /api/v1/projects` - List projects
- `POST /api/v1/projects` - Create project
- `PATCH /api/v1/projects/:id` - Update project

---

## Support

For questions or issues:
- **Documentation**: Check OAUTH_INTEGRATION.md for detailed OAuth flow
- **GitHub**: Open an issue with [OAuth] prefix
- **Email**: dev@onepunch.work

---

## Next Steps

1. Follow implementation steps 1-9 above
2. Test OAuth flow in development
3. Implement secure token storage (Stronghold)
4. Add error handling and user feedback
5. Test on all target platforms
6. Deploy to production

Good luck! 🚀
