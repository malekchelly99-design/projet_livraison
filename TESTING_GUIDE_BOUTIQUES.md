# 🧪 Complete Testing Guide - Automatic Boutique System

**Purpose**: Comprehensive test scenarios to validate the boutique creation and display system

**Duration**: ~30 minutes for all scenarios

---

## 📋 Pre-Test Setup

### Requirements
- ✅ Flutter installed and configured
- ✅ Firebase project `livraison-6f112` active
- ✅ Firestore rules updated (see documentation)
- ✅ Chrome browser available
- ✅ Firebase Console access

### Preparation
1. Clean app: Delete all local data
2. Open Firebase Console in second window
3. Have Firestore viewer open to see changes in real-time
4. Have browser console open (F12) to check for errors

---

## 🧪 Test Scenario 1: New Seller Registration

**Objective**: Verify automatic boutique creation when seller registers

**Duration**: ~5 minutes

### Steps

1. **Start the app**
   ```bash
   flutter run -d chrome
   ```
   - Wait for app to load completely
   - Should see Login view

2. **Navigate to registration**
   - Click "Créer un compte" or "S'inscrire"
   - Should see registration form

3. **Select Seller role**
   - Click "Vendeur" option
   - Form should expand with shop-specific fields

4. **Fill personal information**
   - **Nom complet**: "Ahmed Ali"
   - **Téléphone**: "+216 71 111 111"
   - **Email**: "ahmed.ali@example.tn"
   - **Mot de passe**: "SecurePass123!"
   - **Confirmer mot de passe**: "SecurePass123!"

5. **Fill shop information**
   - **Nom de la boutique**: "Restaurant Ahmed"
   - **Catégorie d'activité**: "Restaurant"
   - **Adresse de la boutique**: "123 Avenue de la Paix"
   - **Ville**: "Tunis"
   - **Description**: "Restaurant traditionnel tunisien"
   - **Horaires d'ouverture**: "09:00 - 22:00"
   - **Matricule fiscal**: "ABC123456789"

6. **Submit registration**
   - Click "S'inscrire" button
   - App should show loading indicator

7. **Verify success**
   - ✅ Should navigate to Home page (no error dialog)
   - ✅ Should see "Espace Vendeur" or vendor dashboard

### Verification in Firebase Console

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com
   - Select project: `livraison-6f112`
   - Navigate to: Firestore → Data

2. **Check users collection**
   - Find new user with email "ahmed.ali@example.tn"
   - **Verify**:
     - `name`: "Ahmed Ali"
     - `email`: "ahmed.ali@example.tn"
     - `phone`: "+216 71 111 111"
     - `role`: "vendeur"
     - `profile.shopName`: "Restaurant Ahmed"
     - `profile.category`: "Restaurant"

3. **Check boutiques collection**
   - **CRITICAL**: Look for new boutique document
   - Document ID should be the seller's UID (from users collection)
   - **Verify fields**:
     - `vendeurId`: Same as document ID
     - `nomBoutique`: "Restaurant Ahmed"
     - `categorie`: "Restaurant"
     - `adresse`: "123 Avenue de la Paix"
     - `ville`: "Tunis"
     - `disponible`: true
     - `email`: "ahmed.ali@example.tn"
     - `telephone`: "+216 71 111 111"
     - `description`: "Restaurant traditionnel tunisien"
     - `horaires`: "09:00 - 22:00"
     - `createdAt`: Current timestamp
     - `rating`: 5.0

### ✅ Test Passes If
- ✓ Registration completes without error
- ✓ Boutique document created with seller UID as ID
- ✓ All boutique fields populated correctly
- ✓ `disponible: true` flag set
- ✓ Timestamp created

---

## 🧪 Test Scenario 2: Client Views Boutiques

**Objective**: Verify boutiques appear in client dashboard

**Duration**: ~5 minutes

### Prerequisites
- ✅ Test 1 completed (seller boutique created)
- ✅ Have second account with client role OR create new client

### Steps

1. **Logout seller (if logged in)**
   - Click profile → "Se déconnecter"
   - Wait for login page

2. **Create or login as client**
   - **Option A**: Create new client account
     - Click "Créer un compte"
     - Select "Client"
     - Fill: Name, Phone, Email, Password
     - Click "S'inscrire"
   - **Option B**: Login with existing client
     - Email: (any existing client email)
     - Password: (correct password)

3. **Navigate to boutiques**
   - Desktop: Click "Boutiques partenaires" in sidebar
   - Mobile: Click Tab 2 (Boutiques icon) in bottom navigation
   - Should see boutiques list page

4. **Verify boutique display**
   - ✅ "Restaurant Ahmed" should appear in list
   - ✅ Card should show:
     - Shop name: "Restaurant Ahmed"
     - Category: "Restaurant"
     - Address: "123 Avenue de la Paix"
     - Status: "Ouvert" (green badge)
   - ✅ "Voir produits" button visible

5. **Test search functionality**
   - Type "Ahmed" in search box
   - ✅ Should filter to show "Restaurant Ahmed"
   - Type "NONEXISTENT" in search box
   - ✅ Should show "Aucune boutique trouvée"
   - Clear search

6. **Test category filter**
   - Type "Restaurant" in search
   - ✅ Should filter by category
   - Type "Burgers" (if available)
   - ✅ Should only show fast-food shops

### ✅ Test Passes If
- ✓ Newly created boutique visible in client dashboard
- ✓ All boutique details display correctly
- ✓ Search functionality works
- ✓ No console errors (F12)

---

## 🧪 Test Scenario 3: Product-Boutique Link

**Objective**: Verify products are linked to boutiques via boutiqueId

**Duration**: ~5 minutes

### Prerequisites
- ✅ Test 1 completed (seller created)
- ✅ Seller logged in

### Steps

1. **Login as seller**
   - Email: "ahmed.ali@example.tn"
   - Password: "SecurePass123!"
   - Should see vendor dashboard

2. **Add a product**
   - Click "Ajouter un produit" or similar
   - Fill form:
     - **Nom**: "Couscous Royal"
     - **Description**: "Couscous avec viande et légumes"
     - **Prix**: "15.99"
     - **Catégorie**: "Plats"
     - **Temps de livraison**: 30
     - **Popular**: (checked or unchecked)
   - Click "Ajouter"

3. **Verify in Firebase**
   - Firebase Console → Firestore → products
   - Find "Couscous Royal" product
   - **Verify fields**:
     - `name`: "Couscous Royal"
     - `shopName`: "Restaurant Ahmed"
     - `vendorId`: "ahmed_seller_uid"
     - **`boutiqueId`: "ahmed_seller_uid"** ← CRITICAL
     - `price`: 15.99
     - `category`: "Plats"

### ✅ Test Passes If
- ✓ Product created successfully
- ✓ Product has `boutiqueId` field
- ✓ `boutiqueId` = seller's UID
- ✓ Product also has `vendorId` (backward compatibility)

---

## 🧪 Test Scenario 4: Seller Login with Missing Boutique

**Objective**: Verify automatic boutique restoration on login

**Duration**: ~10 minutes

### Prerequisites
- ✅ Test 1 completed (seller created)
- ✅ Firebase Console access

### Steps

1. **Prepare: Manually delete boutique**
   - Firebase Console → Firestore → boutiques
   - Find "Restaurant Ahmed" boutique (seller's UID)
   - Click "..." menu → Delete document
   - Click "Delete" to confirm
   - **Verify**: Document removed from console

2. **Logout from app**
   - If logged in: Click profile → "Se déconnecter"
   - Should see login page

3. **Login as seller (boutique deleted)**
   - Email: "ahmed.ali@example.tn"
   - Password: "SecurePass123!"
   - Click "Se connecter"
   - Wait for dashboard to load

4. **Check logs (optional)**
   - Open browser console (F12)
   - Should see message: "[BoutiqueSync] Boutique missing for seller..., restoring..."
   - Should see: "[BoutiqueSync] Boutique created successfully"

5. **Verify in Firebase**
   - Firebase Console → Firestore → boutiques
   - **CRITICAL**: Boutique should be recreated
   - Document ID = seller's UID
   - **Verify** all fields are restored:
     - `nomBoutique`: "Restaurant Ahmed"
     - `categorie`: "Restaurant"
     - `adresse`: "123 Avenue de la Paix"
     - `disponible`: true

### ✅ Test Passes If
- ✓ Login succeeds without error
- ✓ Boutique automatically recreated in Firestore
- ✓ Boutique has correct data
- ✓ No manual intervention needed

---

## 🧪 Test Scenario 5: App Startup Migration

**Objective**: Verify automatic migration of existing sellers without boutiques

**Duration**: ~10 minutes

### Prerequisites
- ✅ Firebase Console access
- ✅ Ability to create Firestore documents

### Preparation: Create test seller without boutique

1. **Go to Firebase Console**
   - Firestore → users collection
   - Click "+ Add document"

2. **Create seller user WITHOUT boutique**
   - Document ID: "test_migration_seller_001"
   - Fields:
     ```json
     {
       "name": "Migration Test Seller",
       "email": "migration.test@example.tn",
       "phone": "+216 71 999 999",
       "role": "vendeur",
       "profile": {
         "shopName": "Migration Test Boutique",
         "category": "Pâtisserie / Boulangerie",
         "address": "999 Test Street",
         "city": "Sousse",
         "taxId": "MIGRATION001",
         "description": "Test boutique for migration",
         "horaires": "08:00 - 20:00"
       },
       "createdAt": (current timestamp)
     }
     ```
   - Click "Save"

3. **Verify NO boutique exists**
   - Go to boutiques collection
   - **Confirm**: No document with ID "test_migration_seller_001"

### Migration Test

1. **Restart the app**
   - Close app (flutter run should stop)
   - `flutter run -d chrome`
   - Wait for full app load
   - Check browser console for migration messages

2. **Check browser logs**
   - Press F12 to open console
   - Look for: "[BoutiqueSync] Starting migration..."
   - Look for: "[BoutiqueSync] Migrated boutique for test_migration_seller_001"
   - Look for: "[BoutiqueSync] Migration complete. Boutiques created/synced: 1"

3. **Verify in Firebase**
   - Firebase Console → Firestore → boutiques
   - **CRITICAL**: New document should exist
   - Document ID: "test_migration_seller_001"
   - **Verify** all fields are migrated from user profile:
     - `nomBoutique`: "Migration Test Boutique"
     - `categorie`: "Pâtisserie / Boulangerie"
     - `adresse`: "999 Test Street"
     - `ville`: "Sousse"
     - `description`: "Test boutique for migration"
     - `disponible`: true

### ✅ Test Passes If
- ✓ App starts successfully
- ✓ Migration runs automatically
- ✓ Boutique created from user profile data
- ✓ Boutique has correct information
- ✓ Console shows migration messages

---

## 🧪 Test Scenario 6: Multiple Sellers & Search

**Objective**: Verify system works with multiple boutiques

**Duration**: ~10 minutes

### Prerequisites
- ✅ Test 1 completed (1st seller)
- ✅ Have ability to create more sellers

### Steps

1. **Register 2-3 more sellers**
   - Repeat Test 1 for additional sellers:
     - Seller 2: "Burger Corner" (Fast-food, Tunis)
     - Seller 3: "Boulangerie Marie" (Pâtisserie, Sousse)
   - Each should create a boutique automatically

2. **Login as client**
   - Create new client or use existing
   - Navigate to "Boutiques partenaires"

3. **Verify all boutiques display**
   - ✅ Should see 3+ boutiques
   - ✅ All boutique details visible
   - ✅ Open/close status displayed

4. **Test comprehensive search**

   **Search by name**:
   - Type "Restaurant" → Shows "Restaurant Ahmed"
   - Type "Burger" → Shows "Burger Corner"
   - Type "Boulangerie" → Shows "Boulangerie Marie"

   **Search by category**:
   - Type "Restaurant" → Shows relevant restaurants
   - Type "Pâtisserie" → Shows bakeries

   **Search by city**:
   - Type "Tunis" → Shows Tunis-based shops
   - Type "Sousse" → Shows Sousse-based shops

5. **Test click-through**
   - Click "Voir produits" on different boutiques
   - Should filter products to show only that shop's items
   - Verify product names include shop name

### ✅ Test Passes If
- ✓ Multiple boutiques display correctly
- ✓ Search filters work accurately
- ✓ Each boutique shows correct data
- ✓ Product filtering by boutique works
- ✓ No duplicate boutiques
- ✓ All boutiques marked as open/available

---

## 🚨 Error Scenarios (What NOT to do)

### Scenario A: Registration error recovery
- **If**: "Email-already-in-use" error appears
  - **Expected**: Dialog should offer login option
  - **Action**: Click to login, then logout fresh account

- **If**: No boutique appears after seller registration
  - **Check**: Firebase Console → users & boutiques collections
  - **Fix**: Restart app (migration will create it)

### Scenario B: Login issues
- **If**: Seller login fails after boutique deleted
  - **Check**: Firebase Console for seller UID
  - **Fix**: Login succeeds, boutique auto-restored

- **If**: Boutiques don't show in client dashboard
  - **Check**: Firestore rules allow read access
  - **Fix**: Update security rules in Firebase Console

### Scenario C: Migration problems
- **If**: Migration shows errors in console
  - **Check**: Browser console (F12) for error messages
  - **Fix**: Verify Firestore rules and user data structure

---

## ✅ Complete Validation Checklist

### Registration & Boutique Creation
- [ ] Seller registration succeeds
- [ ] Boutique created with seller UID as ID
- [ ] All boutique fields populated
- [ ] `disponible: true` flag set

### Client Dashboard Display
- [ ] Boutiques visible in client interface
- [ ] All boutique details display correctly
- [ ] Search functionality works
- [ ] Filtering by category/city works
- [ ] "Ouvert/Fermé" status displays

### Product-Boutique Link
- [ ] Products have `boutiqueId` field
- [ ] `boutiqueId` matches seller UID
- [ ] Products show seller's shop name
- [ ] Can filter products by boutique

### Login & Restoration
- [ ] Seller login succeeds
- [ ] Missing boutique auto-restored on login
- [ ] Restored boutique has correct data
- [ ] No errors in console

### Migration
- [ ] App startup runs migration
- [ ] Existing sellers get boutiques
- [ ] Migrated boutiques have correct data
- [ ] No duplicate boutiques created

### Error Handling
- [ ] Duplicate registration handled
- [ ] Missing boutiques recovered
- [ ] Search doesn't crash with empty results
- [ ] No console errors

---

## 📊 Test Report Template

```
TEST DATE: ___________
TESTER: ___________
FLUTTER VERSION: ___________
BROWSER: ___________

SCENARIO 1: New Seller Registration
- Registration succeeds: ☐ ✓ ☐ ✗
- Boutique created: ☐ ✓ ☐ ✗
- Fields populated: ☐ ✓ ☐ ✗
- Notes: _______________________________

SCENARIO 2: Client Views Boutiques
- Boutiques display: ☐ ✓ ☐ ✗
- Search works: ☐ ✓ ☐ ✗
- Details accurate: ☐ ✓ ☐ ✗
- Notes: _______________________________

SCENARIO 3: Product Link
- Products linked: ☐ ✓ ☐ ✗
- boutiqueId set: ☐ ✓ ☐ ✗
- Filtering works: ☐ ✓ ☐ ✗
- Notes: _______________________________

SCENARIO 4: Restoration
- Missing boutique restored: ☐ ✓ ☐ ✗
- Data correct: ☐ ✓ ☐ ✗
- No errors: ☐ ✓ ☐ ✗
- Notes: _______________________________

SCENARIO 5: Migration
- Migration runs: ☐ ✓ ☐ ✗
- Boutiques created: ☐ ✓ ☐ ✗
- No duplicates: ☐ ✓ ☐ ✗
- Notes: _______________________________

OVERALL: ☐ PASS ☐ FAIL ☐ PARTIAL

Issues found: _______________________________
Recommendations: _______________________________
```

---

## 🎯 Success Criteria

**All tests PASS if**:
- ✅ All 6 scenarios complete without errors
- ✅ All boutiques appear in client dashboard
- ✅ All products have `boutiqueId` field
- ✅ Search and filtering work correctly
- ✅ No console errors
- ✅ Firebase data structure is correct

**System is READY FOR PRODUCTION if**:
- ✓ All success criteria met
- ✓ No breaking changes to existing features
- ✓ All old features still work
- ✓ Scalable to many sellers/products

---

## 📞 Troubleshooting During Tests

| Issue | Solution |
|-------|----------|
| Boutique not created | Check Firebase Console → boutiques collection |
| No boutiques show in client | Verify Firestore read rules allow `allow read: if true;` |
| Product missing `boutiqueId` | Re-create product or update manually in Firestore |
| Migration not running | Check browser console for errors, restart app |
| Search not filtering | Clear search box, try again, check Firestore data |
| Duplicate boutiques | Delete manually, restart app, check for uniqueness |

---

## 🎉 Summary

**Testing Duration**: ~45 minutes for complete validation

**Scenarios Tested**: 6 comprehensive workflows

**Coverage**: 
- ✅ Registration
- ✅ Display
- ✅ Linking
- ✅ Restoration
- ✅ Migration
- ✅ Multi-seller

**Expected Result**: ✅ **ALL TESTS PASS** → System ready for production

---

**Next Step**: Run all tests and compare results with this guide!
