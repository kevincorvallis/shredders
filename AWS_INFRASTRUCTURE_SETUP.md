# AWS Infrastructure Setup Summary

**Date**: January 2, 2026
**Status**: Phase 0 - Partially Complete

---

## ✅ Completed

### 1. AWS Cognito User Pool
- **User Pool ID**: `us-west-2_N9XQ8n1Wh`
- **ARN**: `arn:aws:cognito-idp:us-west-2:965819273626:userpool/us-west-2_N9XQ8n1Wh`
- **Region**: `us-west-2`
- **Configuration**:
  - Sign-in with email
  - Auto-verify email addresses
  - Password policy: Min 8 chars, require uppercase, lowercase, numbers
  - MFA: OFF (can be enabled later if needed)

### 2. Cognito User Pool Clients

**Web Client** (Next.js):
- **Client ID**: `7f4tormn7ibkdco8c41chnna8`
- **Client Secret**: `1523qllgf7qi9ujb5b0als5gktnaaiqto540sm8d7p2s4poplrr6`
- **Auth Flows**: ALLOW_USER_SRP_AUTH, ALLOW_REFRESH_TOKEN_AUTH

**iOS Client** (SwiftUI):
- **Client ID**: `46ka2i7673u2e1hlbqpvdvhjtr`
- **Auth Flows**: ALLOW_USER_SRP_AUTH, ALLOW_REFRESH_TOKEN_AUTH (no client secret - uses PKCE)

### 3. AWS S3 Bucket
- **Bucket Name**: `shredders-user-photos-prod`
- **Region**: `us-west-2`
- **ARN**: `arn:aws:s3:::shredders-user-photos-prod`
- **Configuration**:
  - ✅ Server-side encryption enabled (AES256)
  - ✅ CORS configured for `https://shredders-bay.vercel.app` and `http://localhost:3000`
  - ✅ Public access blocked (all 4 settings enabled)
  - ✅ Allowed methods: GET, PUT, POST, DELETE, HEAD
  - ✅ Max age: 3600 seconds

### 4. Environment Variables Updated
Updated `.env.local` with:
```bash
# Cognito
COGNITO_USER_POOL_ID=us-west-2_N9XQ8n1Wh
COGNITO_REGION=us-west-2
COGNITO_ISSUER=https://cognito-idp.us-west-2.amazonaws.com/us-west-2_N9XQ8n1Wh
COGNITO_CLIENT_ID=7f4tormn7ibkdco8c41chnna8
COGNITO_CLIENT_SECRET=1523qllgf7qi9ujb5b0als5gktnaaiqto540sm8d7p2s4poplrr6
COGNITO_IOS_CLIENT_ID=46ka2i7673u2e1hlbqpvdvhjtr

# S3
S3_BUCKET_NAME=shredders-user-photos-prod
S3_REGION=us-west-2
AWS_REGION=us-west-2
```

### 5. PostgreSQL Schema Created
SQL file created at: `/Users/kevin/Downloads/shredders/scripts/setup-social-schema.sql`

**Tables** (7 total):
1. `users` - User profiles and settings
2. `user_photos` - Photo metadata (S3 references)
3. `comments` - Comments on photos, webcams, mountains
4. `check_ins` - User check-ins and trip reports
5. `likes` - Likes on photos, comments, check-ins, webcams
6. `push_notification_tokens` - Device tokens for push notifications
7. `alert_subscriptions` - User alert preferences per mountain

**Triggers**: Auto-update like/comment counts
**Views**: `mountain_recent_activity`

---

## ⏳ Pending

### 1. Run PostgreSQL Schema ❗ ACTION REQUIRED
The schema SQL file was created but couldn't be applied due to network connectivity.

**To complete**:
```bash
# When you have network access to RDS:
/opt/homebrew/opt/postgresql@15/bin/psql "$DATABASE_URL" -f /Users/kevin/Downloads/shredders/scripts/setup-social-schema.sql
```

Or run it from a machine with RDS access.

### 2. Create CloudFront Distribution
CloudFront CDN setup is recommended but optional for initial development.

**To create** (via AWS Console or CLI):
1. Go to CloudFront in AWS Console
2. Create distribution with origin: `shredders-user-photos-prod.s3.us-west-2.amazonaws.com`
3. Use Origin Access Control (OAC)
4. Enable HTTPS redirect
5. Set cache policy: Min 0s, Default 1 day, Max 1 year
6. After creation, add `CLOUDFRONT_DOMAIN` to `.env.local`

**Why optional for now**:
- S3 can serve images directly (slower, but works)
- CloudFront adds ~$0.44/month cost
- Can be added later without code changes

### 3. Create Cognito Identity Pool
Required for direct S3 uploads from iOS app.

**To create**:
```bash
aws cognito-identity create-identity-pool \
  --identity-pool-name shredders-identity-pool \
  --allow-unauthenticated-identities false \
  --cognito-identity-providers \
    ProviderName=cognito-idp.us-west-2.amazonaws.com/us-west-2_N9XQ8n1Wh,ClientId=7f4tormn7ibkdco8c41chnna8 \
    ProviderName=cognito-idp.us-west-2.amazonaws.com/us-west-2_N9XQ8n1Wh,ClientId=46ka2i7673u2e1hlbqpvdvhjtr
```

Then configure IAM role with S3 permissions.

### 4. Create Lambda Post-Confirmation Trigger
Lambda function to auto-create user in PostgreSQL after Cognito signup.

**Steps**:
1. Create Lambda function (see `/lambda-post-confirmation/` directory - to be created)
2. Give Lambda execution role permission to access RDS (VPC, security groups)
3. Add trigger in Cognito User Pool

**For now**: Can skip and manually handle user creation in app code

### 5. Configure OAuth Callback URLs (Optional)
Currently clients don't have OAuth callback URLs configured.

**To add** (if using Hosted UI):
```bash
aws cognito-idp update-user-pool-client \
  --user-pool-id us-west-2_N9XQ8n1Wh \
  --client-id 7f4tormn7ibkdco8c41chnna8 \
  --callback-urls "https://shredders-bay.vercel.app/api/auth/callback" "http://localhost:3000/api/auth/callback" \
  --logout-urls "https://shredders-bay.vercel.app" "http://localhost:3000"
```

---

## 📝 Next Steps

1. **Complete PostgreSQL Schema** ❗
   - Run `setup-social-schema.sql` when RDS is accessible
   - Verify all tables/triggers/views created successfully

2. **Start Phase 1: Authentication**
   - Install backend dependencies (`aws-jwt-verify`, `@aws-sdk/client-cognito-identity-provider`)
   - Create JWT verification utilities
   - Build auth API endpoints
   - Create login UI (web & iOS)

3. **Optional Enhancements** (can do later):
   - Set up CloudFront CDN
   - Create Cognito Identity Pool
   - Add Lambda Post-Confirmation trigger
   - Configure OAuth callback URLs

---

## 💰 Cost Summary

**Current monthly cost**: ~$0 (free tier)

- ✅ Cognito User Pool: Free (under 50k MAU)
- ✅ S3: ~$0.28/month (estimate for 1000 users)
- ⏳ CloudFront (pending): ~$0.44/month
- ✅ Lambda (free tier): 1M requests/month free

**Total estimated**: ~$0.72/month when CloudFront is added

---

## 🔐 Security Notes

1. **Credentials in `.env.local`**: ✅ File is gitignored
2. **S3 Public Access**: ✅ Blocked
3. **Database Password**: ✅ Strong, randomly generated
4. **Client Secret**: ⚠️ Keep secure, never expose to client-side code
5. **API Keys**: ⚠️ OpenAI key is visible in `.env.local` - ensure file permissions are restricted

---

## 📚 Resources

- Cognito User Pool: https://us-west-2.console.aws.amazon.com/cognito/v2/idp/user-pools/us-west-2_N9XQ8n1Wh
- S3 Bucket: https://s3.console.aws.amazon.com/s3/buckets/shredders-user-photos-prod
- RDS Instance: https://us-west-2.console.aws.amazon.com/rds/home?region=us-west-2#database:id=shredders-mountain-data

---

**Last Updated**: January 2, 2026
