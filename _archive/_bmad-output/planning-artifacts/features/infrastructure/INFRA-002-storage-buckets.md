# INFRA-002: Storage Buckets Configuration

> **Priority:** P1 - Critical
> **Epic:** Infrastructure Automation
> **Effort:** Small (0.5 day)
> **Dependencies:** INFRA-001 (Done)
> **Status:** To Do

---

## Context

The FUG application needs storage buckets for:
- User profile pictures (avatars)
- Event images
- Future: Chat media, documents

Currently, no storage buckets are configured via migrations, meaning:
1. Manual setup required on new deployments
2. Inconsistent permissions across environments
3. No version control for bucket configurations

## Goal

**100% automated storage bucket setup via migrations.**

After running migrations:
- All required buckets exist
- Proper permissions configured
- File size limits enforced
- Allowed MIME types defined

---

## Requirements

### R1: Profile Pictures Bucket
- [ ] Bucket ID: `avatars`
- [ ] Max file size: 5MB
- [ ] Allowed types: image/jpeg, image/png, image/webp
- [ ] Permissions: Authenticated users can read all, write own

### R2: Event Images Bucket
- [ ] Bucket ID: `event-images`
- [ ] Max file size: 10MB
- [ ] Allowed types: image/jpeg, image/png, image/webp
- [ ] Permissions: Any user can read, event creator can write

### R3: Migration Implementation
- [ ] Create migration: `015_storage_buckets.js`
- [ ] Idempotent (safe to run multiple times)
- [ ] Rollback support (delete buckets)

---

## Technical Design

### Bucket Configuration

```javascript
const BUCKETS = [
  {
    id: 'avatars',
    name: 'User Avatars',
    permissions: [
      Permission.read(Role.users()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
    fileSizeLimit: 5 * 1024 * 1024, // 5MB
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    compression: 'gzip',
    encryption: true,
    antivirus: true,
  },
  {
    id: 'event-images',
    name: 'Event Images',
    permissions: [
      Permission.read(Role.any()),
      Permission.create(Role.users()),
      Permission.update(Role.users()),
      Permission.delete(Role.users()),
    ],
    fileSizeLimit: 10 * 1024 * 1024, // 10MB
    allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    compression: 'gzip',
    encryption: true,
    antivirus: true,
  },
];
```

### Migration Structure

```javascript
export default {
  name: '015_storage_buckets',
  type: 'upgrade',

  async up(client, databases, log, config, context) {
    const storage = new Storage(client);

    for (const bucket of BUCKETS) {
      try {
        await storage.getBucket(bucket.id);
        log.info(`Bucket ${bucket.id} already exists`);
      } catch (error) {
        if (error.code === 404) {
          await storage.createBucket(
            bucket.id,
            bucket.name,
            bucket.permissions,
            bucket.fileSizeLimit,
            bucket.allowedExtensions,
            bucket.compression,
            bucket.encryption,
            bucket.antivirus
          );
          log.success(`Created bucket: ${bucket.id}`);
        } else {
          throw error;
        }
      }
    }
  },

  async down(client, databases, log, config) {
    const storage = new Storage(client);

    for (const bucket of BUCKETS.reverse()) {
      try {
        await storage.deleteBucket(bucket.id);
        log.success(`Deleted bucket: ${bucket.id}`);
      } catch (error) {
        if (error.code !== 404) {
          throw error;
        }
      }
    }
  },
};
```

---

## Stories Breakdown

### INFRA-002-A: Create Storage Migration
**Effort:** 0.5 day

- Create `015_storage_buckets.js` migration
- Configure avatars bucket
- Configure event-images bucket
- Test on development environment

---

## Acceptance Criteria

1. [ ] Migration creates both buckets
2. [ ] Buckets have correct permissions
3. [ ] File size limits enforced
4. [ ] Only allowed file types accepted
5. [ ] Migration is idempotent
6. [ ] Rollback works correctly

---

## Usage After Implementation

```dart
// Flutter - Upload avatar
final storage = Storage(client);
final file = await storage.createFile(
  bucketId: 'avatars',
  fileId: ID.unique(),
  file: InputFile.fromPath(path: imagePath),
);

// Get avatar URL
final url = storage.getFilePreview(
  bucketId: 'avatars',
  fileId: file.$id,
  width: 200,
  height: 200,
);
```

---

*Created: 2026-01-22*
*Author: BMAD System*
