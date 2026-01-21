# Apple Sign-In Configuration Guide

> **For:** Michel (macOS)
> **Prerequisite:** Apple Developer Account ($99/year)
> **Priority:** OPTIONAL - Only if iOS release is decided

---

## Important Decision

**Apple Developer Program costs $99/year.** Before proceeding:

1. Decide if iOS version is needed for MVP
2. Google Sign-In works on Android + Web (free)
3. Apple Sign-In is only required for iOS App Store

If iOS is deferred, skip this guide entirely.

---

## Overview

Apple Sign-In requires configuration in **two places**:
1. **Apple Developer Console** (manual - requires Apple account)
2. **Appwrite** (automated via script)

This guide covers the Apple Developer Console steps. The Appwrite configuration will be done automatically by the setup script once you provide the credentials.

---

## Step 1: Access Apple Developer Console

1. Go to https://developer.apple.com/account
2. Sign in with your Apple Developer account
3. Navigate to **Certificates, Identifiers & Profiles**

---

## Step 2: Create an App ID

1. Click **Identifiers** in the sidebar
2. Click the **+** button to create a new identifier
3. Select **App IDs** → Continue
4. Select **App** → Continue
5. Fill in:
   - **Description:** `FUG App`
   - **Bundle ID:** `com.develobeers.fug` (Explicit)
6. Scroll down to **Capabilities** and check **Sign In with Apple**
7. Click **Continue** → **Register**

---

## Step 3: Create a Services ID (for OAuth)

1. Click **Identifiers** in the sidebar
2. Click the **+** button
3. Select **Services IDs** → Continue
4. Fill in:
   - **Description:** `FUG Sign In with Apple`
   - **Identifier:** `com.develobeers.fug.signin` (different from App ID!)
5. Click **Continue** → **Register**
6. Click on the newly created Services ID
7. Check **Sign In with Apple** → Click **Configure**
8. In the configuration:
   - **Primary App ID:** Select `FUG App (com.develobeers.fug)`
   - **Domains:** Add your domain (e.g., `fug-app.com`)
   - **Return URLs:** Add:
     ```
     https://[YOUR_APPWRITE_DOMAIN]/v1/account/sessions/oauth2/callback/apple/[PROJECT_ID]
     ```
     For local dev:
     ```
     http://localhost:9000/v1/account/sessions/oauth2/callback/apple/697015400010787139b8
     ```
9. Click **Save** → **Continue** → **Save**

---

## Step 4: Create a Key for Sign In with Apple

1. Click **Keys** in the sidebar
2. Click the **+** button
3. Fill in:
   - **Key Name:** `FUG Apple Sign In Key`
4. Check **Sign In with Apple** → Click **Configure**
5. Select **Primary App ID:** `FUG App (com.develobeers.fug)`
6. Click **Save** → **Continue** → **Register**
7. **IMPORTANT:** Download the key file (`.p8`)
   - You can only download it **ONCE**!
   - Save it securely
8. Note the **Key ID** displayed on screen

---

## Step 5: Collect Your Credentials

After completing the steps above, you should have:

| Credential | Where to find it | Example |
|------------|------------------|---------|
| **Team ID** | Membership → Team ID | `ABCD1234EF` |
| **Key ID** | Keys → Your key | `XYZ9876543` |
| **Services ID** | Identifiers → Services ID | `com.develobeers.fug.signin` |
| **Private Key** | Downloaded `.p8` file | `-----BEGIN PRIVATE KEY-----...` |

---

## Step 6: Configure Appwrite (Automated)

Once you have the credentials, create a file with them:

```bash
# Create credentials file (DO NOT COMMIT!)
cat > infrastructure/setup/.apple-credentials << 'EOF'
APPLE_TEAM_ID=your_team_id
APPLE_KEY_ID=your_key_id
APPLE_SERVICE_ID=com.develobeers.fug.signin
APPLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
paste_your_key_here
-----END PRIVATE KEY-----"
EOF
```

Then run the setup script:

```bash
cd infrastructure/setup
./configure-oauth.sh
```

---

## Verification Checklist

- [ ] Apple Developer account is active
- [ ] App ID created with Sign In with Apple enabled
- [ ] Services ID created and configured with domains/return URLs
- [ ] Key created and `.p8` file downloaded
- [ ] Team ID, Key ID, Services ID noted
- [ ] Private key stored securely
- [ ] Appwrite configuration script executed

---

## Troubleshooting

### "Invalid client_id" error
- Verify the Services ID (not the App ID!) is used in Appwrite
- Check the identifier matches exactly

### "Invalid redirect_uri" error
- Verify the Return URL in Apple matches the Appwrite callback URL
- Check for trailing slashes

### "Invalid key" error
- Ensure the private key includes the full `-----BEGIN/END PRIVATE KEY-----` markers
- Check there are no extra spaces or line breaks

---

## Security Notes

1. **Never commit** the `.p8` private key file to git
2. **Never share** the private key
3. Store credentials in a **password manager** or **secrets vault**
4. The `.apple-credentials` file is in `.gitignore`

---

## References

- [Apple Sign In with Apple Docs](https://developer.apple.com/sign-in-with-apple/)
- [Appwrite Apple OAuth2 Docs](https://appwrite.io/docs/products/auth/oauth2#apple)
- [Configure Sign In with Apple for the web](https://developer.apple.com/documentation/sign_in_with_apple/configuring_your_environment_for_sign_in_with_apple)

---

*Last updated: 2026-01-21*
