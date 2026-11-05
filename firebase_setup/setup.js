const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

const serviceAccount = require("./serviceAccountKey.json");

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

console.log("Firebase connected successfully!");

const collections = {

  users: {
    uid: "",
    name: "",
    email: "",
    phone: "",
    role: "CLIENT",
    photoUrl: "",
    createdAt: Timestamp.now()
  },

  vendeurs: {
    userId: "",
    nomCommerce: "",
    description: "",
    adresse: "",
    telephone: "",
    horaires: "",
    logoUrl: "",
    isActive: true,
    createdAt: Timestamp.now()
  },

  livreurs: {
    userId: "",
    name: "",
    phone: "",
    vehicle: "",
    isAvailable: true,
    createdAt: Timestamp.now()
  },

  product: {
    name: "",
    description: "",
    price: 0,
    imageUrl: "",
    categoryId: "",
    sellerId: "",
    isAvailable: true,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now()
  },

  categorie: {
    name: "",
    description: "",
    imageUrl: ""
  },

  orders: {
    clientId: "",
    sellerId: "",
    items: [
      {
        productId: "",
        productName: "",
        quantity: 1,
        unitPrice: 0,
        subtotal: 0
      }
    ],
    total: 0,
    deliveryAddress: "",
    paymentMethod: "cash",
    status: "pending",
    note: "",
    createdAt: Timestamp.now()
  },

  deliveries: {
    orderId: "",
    sellerId: "",
    clientId: "",
    deliveryPersonId: "",
    pickupAddress: "",
    deliveryAddress: "",
    status: "pending",
    assignedAt: null,
    deliveredAt: null
  },

  payments: {
    orderId: "",
    clientId: "",
    sellerId: "",
    amount: 0,
    method: "cash",
    status: "pending",
    createdAt: Timestamp.now()
  },

  reviews: {
    clientId: "",
    sellerId: "",
    deliveryPersonId: "",
    orderId: "",
    sellerRating: 0,
    deliveryRating: 0,
    comment: "",
    createdAt: Timestamp.now()
  },

  notifications: {
    userId: "",
    title: "",
    body: "",
    type: "",
    orderId: "",
    isRead: false,
    createdAt: Timestamp.now()
  },

  reclamations: {
    clientId: "",
    orderId: "",
    description: "",
    response: "",
    status: "new",
    createdAt: Timestamp.now()
  },

  addresses: {
    userId: "",
    address: "",
    city: "",
    latitude: 0,
    longitude: 0,
    isDefault: false
  }

};

async function setupFirebase() {

  console.log("Starting Firebase setup...\n");

  const existingCollections = await db.listCollections();

  const existingNames = existingCollections.map(
    collection => collection.id
  );

  for (const [name, fields] of Object.entries(collections)) {

    try {

      if (existingNames.includes(name)) {

        const snapshot = await db
          .collection(name)
          .limit(1)
          .get();

        if (!snapshot.empty) {
          console.log(`SKIPPED: ${name} already contains data`);
          continue;
        }

      }

      await db
        .collection(name)
        .doc("schema_template")
        .set({
          ...fields,
          isTemplate: true
        });

      console.log(`CREATED: ${name}`);

    } catch (error) {

      console.error(`ERROR in ${name}:`, error.message);

    }

  }

  console.log("\nFirebase setup completed!");

}

setupFirebase()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });