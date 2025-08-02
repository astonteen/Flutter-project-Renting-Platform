# 🔥 Supabase to Firebase Migration Plan

## 📋 Executive Summary

This document outlines the comprehensive migration strategy for RentEase from Supabase to Firebase. The migration involves transitioning authentication, database, storage, and real-time features while maintaining application functionality and data integrity.

## 🎯 Migration Scope

### Current Supabase Implementation
- **Project ID**: `rent_ease` (iwefwascboexieneeaks.supabase.co)
- **Authentication**: Email/password with user profiles
- **Database**: PostgreSQL with 8 main tables
- **Storage**: File storage for listing images
- **Real-time**: Auth state changes and data subscriptions
- **Security**: Row Level Security (RLS) policies

### Target Firebase Implementation
- **Project ID**: `rent-ease-8071d`
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Real-time**: Firestore real-time listeners
- **Security**: Firestore Security Rules

## 🗄️ Database Schema Migration

### Current Supabase Tables

1. **profiles** - User profile information
2. **categories** - Item categories
3. **items** - Rental items/listings
4. **item_images** - Item image references
5. **rentals** - Rental transactions
6. **deliveries** - Delivery information
7. **messages** - User messaging
8. **reviews** - User reviews and ratings
9. **saved_addresses** - User saved addresses
10. **wishlists** - User wishlist items
11. **viewed_items** - Item view tracking

### Firebase Firestore Collections Structure

```
firestore/
├── users/
│   ├── {userId}/
│   │   ├── profile: ProfileData
│   │   ├── savedAddresses/
│   │   │   └── {addressId}: SavedAddressData
│   │   ├── wishlist/
│   │   │   └── {itemId}: WishlistData
│   │   └── viewedItems/
│   │       └── {itemId}: ViewedItemData
├── categories/
│   └── {categoryId}: CategoryData
├── items/
│   ├── {itemId}/
│   │   ├── details: ItemData
│   │   └── images/
│   │       └── {imageId}: ImageData
├── rentals/
│   ├── {rentalId}/
│   │   ├── details: RentalData
│   │   └── delivery/
│   │       └── details: DeliveryData
├── messages/
│   └── {conversationId}/
│       └── messages/
│           └── {messageId}: MessageData
└── reviews/
    └── {reviewId}: ReviewData
```

## 🔐 Authentication Migration

### Current Supabase Auth Features
- Email/password authentication
- User metadata storage
- Auth state management
- Profile creation on signup

### Firebase Auth Implementation
```dart
// Replace SupabaseService auth methods
class FirebaseAuthService {
  static Future<UserCredential> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    
    // Create user profile in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .set({
      'profile': userData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return credential;
  }
}
```

## 📊 Data Migration Strategy

### Phase 1: Schema Preparation
1. **Enable Firebase Services**
   - ✅ Firestore Database
   - ❌ Firebase Authentication (needs enabling)
   - ❌ Firebase Storage (needs enabling)
   - ❌ Firebase Functions (for complex migrations)

2. **Create Firestore Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Nested collections
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Public read access for items and categories
    match /items/{itemId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### Phase 2: Data Export and Transform
1. **Export Supabase Data**
   - Use Supabase CLI or direct SQL exports
   - Transform relational data to document-based structure
   - Handle foreign key relationships as references

2. **Data Transformation Script**
```dart
class DataMigrationService {
  static Future<void> migrateSupabaseToFirestore() async {
    // Export users and profiles
    final users = await SupabaseService.client.from('profiles').select();
    
    for (final user in users) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user['id'])
          .set({
        'profile': {
          'fullName': user['full_name'],
          'email': user['email'],
          'phoneNumber': user['phone_number'],
          'avatarUrl': user['avatar_url'],
          'location': user['location'],
          'bio': user['bio'],
          'primaryRole': user['primary_role'],
          'roles': user['roles'],
          'enableNotifications': user['enable_notifications'],
        },
        'createdAt': user['created_at'],
        'updatedAt': user['updated_at'],
      });
    }
  }
}
```

### Phase 3: Service Layer Migration

#### Replace SupabaseService with FirebaseService
```dart
class FirebaseService {
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;
  
  // Auth methods
  static Future<UserCredential> signUp({...}) async { /* Implementation */ }
  static Future<UserCredential> signIn({...}) async { /* Implementation */ }
  static Future<void> signOut() async { /* Implementation */ }
  
  // Database methods
  static Future<List<Map<String, dynamic>>> getItems({...}) async {
    Query query = firestore.collection('items');
    
    if (category != null) {
      query = query.where('categoryId', isEqualTo: category);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.where('name', isGreaterThanOrEqualTo: searchQuery)
                  .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff');
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
  }
}
```

## 🔄 Repository Layer Updates

### Update All Repository Classes

1. **AuthRepository**
```dart
class AuthRepository {
  Future<UserCredential> signUp({...}) async {
    return await FirebaseService.signUp(...);
  }
  
  Stream<User?> get authStateChanges => 
      FirebaseAuth.instance.authStateChanges();
}
```

2. **HomeRepository, BookingRepository, etc.**
- Replace Supabase queries with Firestore queries
- Update data models to match Firestore structure
- Implement proper error handling for Firebase exceptions

## 📱 Frontend Code Changes

### Dependencies Update (pubspec.yaml)
```yaml
dependencies:
  # Remove Supabase
  # supabase_flutter: ^2.0.0
  
  # Add Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  firebase_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  cloud_firestore: ^4.13.6
```

### Main.dart Updates
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Remove Supabase initialization
  // await SupabaseService.initialize(...);
  
  runApp(const RentEaseApp());
}
```

## 🗂️ File Storage Migration

### Current Supabase Storage
- Bucket: `listing-images`
- Public access with RLS policies

### Firebase Storage Implementation
```dart
class FirebaseStorageService {
  static Future<String> uploadImage({
    required File file,
    required String path,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
  
  static Future<void> deleteImage(String path) async {
    await FirebaseStorage.instance.ref().child(path).delete();
  }
}
```

## 🔒 Security Rules Migration

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User profile access
    match /users/{userId} {
      allow read: if true; // Public profiles
      allow write: if request.auth != null && request.auth.uid == userId;
      
      match /savedAddresses/{addressId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /wishlist/{itemId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Items access
    match /items/{itemId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        request.auth.uid == resource.data.ownerId;
    }
    
    // Rentals access
    match /rentals/{rentalId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.renterId || 
         request.auth.uid == resource.data.ownerId);
    }
  }
}
```

### Firebase Storage Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /listing-images/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    match /user-avatars/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 📋 Migration Checklist

### Pre-Migration
- [ ] Enable required Firebase services
- [ ] Set up Firebase project configuration
- [ ] Create data export scripts
- [ ] Set up development/staging environments
- [ ] Create rollback plan

### Migration Execution
- [ ] Export all Supabase data
- [ ] Transform data to Firestore format
- [ ] Import data to Firestore
- [ ] Update authentication system
- [ ] Update all repository classes
- [ ] Update service layer
- [ ] Update dependencies
- [ ] Test all features

### Post-Migration
- [ ] Verify data integrity
- [ ] Test authentication flows
- [ ] Test all CRUD operations
- [ ] Test real-time features
- [ ] Performance testing
- [ ] Security audit
- [ ] Update documentation
- [ ] Monitor for issues

## ⚠️ Risk Assessment

### High Risk Areas
1. **Data Loss**: Ensure complete data backup before migration
2. **Authentication**: Users may need to re-authenticate
3. **Real-time Features**: Different implementation patterns
4. **Query Performance**: Firestore has different optimization patterns

### Mitigation Strategies
1. **Phased Migration**: Migrate feature by feature
2. **Parallel Running**: Run both systems temporarily
3. **Comprehensive Testing**: Test all user flows
4. **Rollback Plan**: Ability to revert to Supabase

## 📊 Timeline Estimate

### Phase 1: Preparation (1-2 weeks)
- Firebase setup and configuration
- Data export and analysis
- Development environment setup

### Phase 2: Core Migration (2-3 weeks)
- Authentication system migration
- Database schema and data migration
- Service layer updates

### Phase 3: Feature Migration (2-3 weeks)
- Repository layer updates
- Frontend integration
- Storage migration

### Phase 4: Testing and Deployment (1-2 weeks)
- Comprehensive testing
- Performance optimization
- Production deployment

**Total Estimated Time: 6-10 weeks**

## 🔧 Tools and Scripts Needed

1. **Data Export Script**: Extract all Supabase data
2. **Data Transformation Script**: Convert to Firestore format
3. **Migration Verification Script**: Ensure data integrity
4. **Performance Testing Suite**: Compare before/after performance
5. **Rollback Scripts**: Emergency reversion capability

## 📞 Next Steps

1. **Review and Approve Plan**: Stakeholder approval
2. **Set Up Development Environment**: Firebase project setup
3. **Create Migration Scripts**: Data export/import tools
4. **Begin Phase 1**: Firebase service enablement
5. **Schedule Regular Check-ins**: Progress monitoring

---

**Note**: This migration plan requires careful execution and thorough testing. Consider running a pilot migration with a subset of data first to validate the approach.