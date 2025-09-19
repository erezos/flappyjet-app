# Apple In-App Purchase Setup Guide

## Current Issue
Apple App Store rejected the app because in-app purchase receipt validation is not properly configured. The app needs to validate receipts with Apple's servers to ensure purchases are legitimate.

## Required Steps

### 1. Generate Apple Shared Secret

1. **Go to App Store Connect**: https://appstoreconnect.apple.com/
2. **Navigate to your app** → **Features** → **In-App Purchases**
3. **Click "App-Specific Shared Secret"** in the top right
4. **Generate** a new shared secret if one doesn't exist
5. **Copy the shared secret** (it looks like: `1234567890abcdef1234567890abcdef`)

### 2. Configure the App

Update `lib/config/iap_config.dart`:

```dart
class IAPConfig {
  // Replace with your actual shared secret from App Store Connect
  static const String _appleSharedSecretDev = 'YOUR_SHARED_SECRET_HERE';
  static const String _appleSharedSecretProd = 'YOUR_SHARED_SECRET_HERE';
  
  // ... rest of the file
}
```

### 3. Security Best Practices

**For Production:**
- Store the shared secret in environment variables
- Use different secrets for development and production
- Never commit secrets to version control

**Current Implementation:**
- The app will now properly validate receipts with Apple
- Production receipts are tried first, then sandbox (as required by Apple)
- Failed validation will prevent purchase completion

### 4. Testing

**Sandbox Testing:**
- Use sandbox Apple ID accounts for testing
- Receipts from sandbox will automatically fallback to sandbox validation
- Test both successful and failed purchase scenarios

**Production Testing:**
- Real purchases will be validated against production servers
- Sandbox receipts in production will properly fallback to sandbox validation

## Apple's Requirements Met

✅ **Production-first validation**: App tries production server first  
✅ **Sandbox fallback**: Falls back to sandbox when status code 21007 is received  
✅ **Proper error handling**: Failed validation prevents purchase completion  
✅ **Receipt authentication**: All purchases are validated with Apple servers  

## Error Codes Handled

- `21007`: Sandbox receipt in production → Retry with sandbox
- `21008`: Production receipt in sandbox → Handle appropriately  
- `21004`: Invalid shared secret → Clear error message
- `21003`: Receipt authentication failed → Reject purchase

## References

- [Apple Receipt Validation Guide](https://developer.apple.com/documentation/storekit/validating-receipts-with-the-app-store)
- [Sandbox Testing Guide](https://developer.apple.com/help/app-store-connect/test-in-app-purchases/manage-sandbox-apple-account-settings/)
- [App Store Connect IAP Setup](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/generate-keys-for-in-app-purchases)
