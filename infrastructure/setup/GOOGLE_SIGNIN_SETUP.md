# Google Sign-In Configuration Guide

> **For:** Development team
> **Prerequisite:** Google Cloud account (free)

---

## Overview

Google Sign-In requires configuration in **two places**:
1. **Google Cloud Console** (manual - requires Google account)
2. **Appwrite** (automated via script)

---

## Step 1: Create a Google Cloud Project

1. Go to https://console.cloud.google.com/
2. Click the project dropdown → **New Project**
3. Fill in:
   - **Project name:** `FUG App`
   - **Organization:** (your org or leave blank)
4. Click **Create**
5. Select the new project

---

## Step 2: Configure OAuth Consent Screen

1. Navigate to **APIs & Services** → **OAuth consent screen**
2. Select **External** → Click **Create**
3. Fill in the App information:
   - **App name:** `FUG`
   - **User support email:** your email
   - **App logo:** (optional) upload FUG logo
4. **App domain:**
   - Application home page: `https://fug-app.com`
   - Privacy policy: `https://fug-app.com/privacy`
   - Terms of service: `https://fug-app.com/terms`
5. **Developer contact:** your email
6. Click **Save and Continue**
7. **Scopes:** Click **Add or Remove Scopes**
   - Select: `email`, `profile`, `openid`
   - Click **Update** → **Save and Continue**
8. **Test users:** (for development)
   - Add your test email addresses
   - Click **Save and Continue**
9. **Summary:** Review and click **Back to Dashboard**

---

## Step 3: Create OAuth 2.0 Credentials

1. Navigate to **APIs & Services** → **Credentials**
2. Click **+ Create Credentials** → **OAuth client ID**
3. **Application type:** Web application
4. **Name:** `FUG Web Client`
5. **Authorized JavaScript origins:**
   ```
   http://localhost:9000
   https://your-appwrite-domain.com
   ```
6. **Authorized redirect URIs:**
   ```
   http://localhost:9000/v1/account/sessions/oauth2/callback/google/697015400010787139b8
   https://your-appwrite-domain.com/v1/account/sessions/oauth2/callback/google/[PROJECT_ID]
   ```
7. Click **Create**
8. **Copy the Client ID and Client Secret** (shown in popup)

---

## Step 4: (Optional) Create Android OAuth Client

For native Android app:

1. Click **+ Create Credentials** → **OAuth client ID**
2. **Application type:** Android
3. **Name:** `FUG Android`
4. **Package name:** `com.develobeers.fug`
5. **SHA-1 certificate fingerprint:**
   ```bash
   # Get debug fingerprint
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
   ```
6. Click **Create**

---

## Step 5: (Optional) Create iOS OAuth Client

For native iOS app:

1. Click **+ Create Credentials** → **OAuth client ID**
2. **Application type:** iOS
3. **Name:** `FUG iOS`
4. **Bundle ID:** `com.develobeers.fug`
5. Click **Create**

---

## Step 6: Collect Your Credentials

After completing the steps above, you should have:

| Credential | Where to find it |
|------------|------------------|
| **Client ID** | Credentials → Web client → Client ID |
| **Client Secret** | Credentials → Web client → Client secret |

Format:
- Client ID: `123456789-abcdefg.apps.googleusercontent.com`
- Client Secret: `GOCSPX-xxxxxxxxxxxxx`

---

## Step 7: Configure Appwrite (Automated)

Create a credentials file:

```bash
# Create credentials file (DO NOT COMMIT!)
cat > infrastructure/setup/.google-credentials << 'EOF'
GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-your_secret
EOF
```

Then run the setup script:

```bash
cd infrastructure/setup
./configure-oauth.sh
```

---

## Verification Checklist

- [ ] Google Cloud project created
- [ ] OAuth consent screen configured
- [ ] Web OAuth client created
- [ ] (Optional) Android OAuth client created
- [ ] (Optional) iOS OAuth client created
- [ ] Client ID and Secret noted
- [ ] Appwrite configuration script executed

---

## Publishing to Production

Before going live:

1. Go to **OAuth consent screen**
2. Click **Publish App**
3. Complete Google's verification process if needed
   - Required if using sensitive scopes
   - May take several days

---

## Troubleshooting

### "Access blocked: This app's request is invalid"
- Verify redirect URI matches exactly (including trailing slashes)
- Check the Client ID is correct

### "Error 400: redirect_uri_mismatch"
- Add the exact callback URL to Authorized redirect URIs
- Wait a few minutes for changes to propagate

### "This app isn't verified"
- Normal during development with test users
- Publish the app for production use

---

## Security Notes

1. **Never commit** credentials to git
2. Use **environment variables** in production
3. Restrict API access to your domains only
4. Rotate secrets periodically

---

## References

- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Appwrite Google OAuth2 Docs](https://appwrite.io/docs/products/auth/oauth2#google)

---

*Last updated: 2026-01-21*
