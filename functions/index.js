/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const nodemailer = require("nodemailer");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: functions.config().gmail.email,
    pass: functions.config().gmail.password,
  },
});

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
functions.setGlobalOptions({maxInstances: 10});

// Background function to check for app updates every 30 minutes
exports.checkAppUpdates = functions.pubsub
    .schedule("every 30 minutes")
    .onRun(async (context) => {
      try {
        console.log("Starting app update check...");

        // Get latest version from app_versions collection
        const versionDoc = await admin.firestore()
            .collection("app_versions")
            .doc("current")
            .get();

        if (!versionDoc.exists) {
          console.log("No version document found");
          return null;
        }

        const latestVersion = versionDoc.data();
        console.log(`Latest version: ${latestVersion.version}`);

        // Get all users who should be notified
        const usersSnapshot = await admin.firestore()
            .collection("currentUser")
            .get();

        if (usersSnapshot.empty) {
          console.log("No users found");
          return null;
        }

        // Send notifications to all users
        const notificationPromises = usersSnapshot.docs.map(async (userDoc) => {
          const userData = userDoc.data();
          const fcmToken = userData.fcmToken;

          if (fcmToken) {
            try {
              const message = {
                token: fcmToken,
                notification: {
                  title: latestVersion.title || "App Update Available",
                  body: `Version ${latestVersion.version} is available. Open app to download!`,
                },
                data: {
                  type: "app_update",
                  version: latestVersion.version,
                  downloadUrl: latestVersion.downloadUrl || "",
                },
                android: {
                  priority: "high",
                  notification: {
                    channelId: "app_updates",
                    priority: "high",
                    defaultSound: true,
                  },
                },
                apns: {
                  payload: {
                    aps: {
                      sound: "default",
                      badge: 1,
                    },
                  },
                },
              };

              await admin.messaging().send(message);
              console.log(`Notification sent to user: ${userData.email}`);
            } catch (error) {
              console.error(`Error sending notification to user ${userData.email}:`, error);
            }
          }
        });

        await Promise.all(notificationPromises);
        console.log("App update check completed");
        return null;
      } catch (error) {
        console.error("Error in app update check:", error);
        return null;
      }
    });

// Background function to check currency alerts every 5 minutes
exports.checkCurrencyAlerts = functions.pubsub
    .schedule("every 5 minutes")
    .onRun(async (context) => {
      try {
        console.log("Starting currency alert check...");

        // Get all active alerts
        const alertsSnapshot = await admin.firestore()
            .collection("alerts")
            .get();

        if (alertsSnapshot.empty) {
          console.log("No active alerts found");
          return null;
        }

        // Group alerts by base currency to minimize API calls
        const alertsByBaseCurrency = {};
        alertsSnapshot.forEach((doc) => {
          const alert = doc.data();
          const baseCurrency = alert.baseCurrency;
          if (!alertsByBaseCurrency[baseCurrency]) {
            alertsByBaseCurrency[baseCurrency] = [];
          }
          alertsByBaseCurrency[baseCurrency].push({
            id: doc.id,
            ...alert,
          });
        });

        // Check alerts for each base currency
        for (const [baseCurrency, alerts] of Object.entries(alertsByBaseCurrency)) {
          try {
            // Fetch current rates for this base currency
            const response = await axios.get(
                `https://open.er-api.com/v6/latest/${baseCurrency}`,
            );

            if (response.data.result === "success") {
              const rates = response.data.rates;

              // Check each alert
              for (const alert of alerts) {
                const currentRate = rates[alert.targetCurrency];
                if (currentRate === undefined) continue;

                const shouldTrigger = alert.isAbove ?
                  currentRate >= alert.targetRate :
                  currentRate <= alert.targetRate;

                if (shouldTrigger) {
                  console.log(`Alert triggered: ${alert.id}`);

                  // Send push notification to user
                  await sendPushNotification(alert, currentRate);

                  // Send email notification
                  await sendAlertNotification(alert, currentRate);

                  // Save to alert history
                  await admin.firestore().collection("alert_history").add({
                    userId: alert.userId,
                    alertId: alert.id,
                    baseCurrency: alert.baseCurrency,
                    targetCurrency: alert.targetCurrency,
                    targetRate: alert.targetRate,
                    isAbove: alert.isAbove,
                    triggeredAt: admin.firestore.FieldValue.serverTimestamp(),
                    currentRate: currentRate,
                    notificationTitle: "Currency Rate Alert!",
                    notificationBody: `1 ${alert.baseCurrency} = ${currentRate.toFixed(4)} ${alert.targetCurrency} (${alert.isAbove ? "above" : "below"} ${alert.targetRate})`,
                    sound: "notification.mp3",
                  });

                  // Remove the alert
                  await admin.firestore().collection("alerts").doc(alert.id).delete();
                }
              }
            }
          } catch (error) {
            console.error(`Error checking alerts for ${baseCurrency}:`, error);
          }
        }

        console.log("Currency alert check completed");
        return null;
      } catch (error) {
        console.error("Error in checkCurrencyAlerts:", error);
        return null;
      }
    });

// Function to send push notification
async function sendPushNotification(alert, currentRate) {
  try {
    // Get user's FCM token
    const userDoc = await admin.firestore()
        .collection("currentUser")
        .doc(alert.userId)
        .get();

    if (!userDoc.exists) {
      console.log(`User ${alert.userId} not found`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log(`No FCM token found for user ${alert.userId}`);
      return;
    }

    // Send push notification
    const message = {
      token: fcmToken,
      notification: {
        title: "Currency Rate Alert!",
        body: `1 ${alert.baseCurrency} = ${currentRate.toFixed(4)} ${alert.targetCurrency} (${alert.isAbove ? "above" : "below"} ${alert.targetRate})`,
      },
      data: {
        alertId: alert.id,
        baseCurrency: alert.baseCurrency,
        targetCurrency: alert.targetCurrency,
        targetRate: alert.targetRate.toString(),
        currentRate: currentRate.toString(),
        isAbove: alert.isAbove.toString(),
        type: "currency_alert",
      },
      android: {
        notification: {
          sound: "default",
          channelId: "currency_alerts",
          priority: "high",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`Push notification sent successfully: ${response}`);
  } catch (error) {
    console.error("Error sending push notification:", error);
  }
}

// Function to send alert notification
async function sendAlertNotification(alert, currentRate) {
  try {
    // Get user's notification preferences
    const userDoc = await admin.firestore()
        .collection("currentUser")
        .doc(alert.userId)
        .get();

    if (!userDoc.exists) {
      console.log(`User ${alert.userId} not found`);
      return;
    }

    const userData = userDoc.data();
    const userEmail = userData.email || alert.userEmail;
    const fcmToken = userData.fcmToken; // Get FCM token for push notifications

    if (!userEmail) {
      console.log(`No email found for user ${alert.userId}`);
      return;
    }

    // Send push notification if FCM token is available
    if (fcmToken) {
      try {
        const message = {
          token: fcmToken,
          notification: {
            title: "Currency Rate Alert!",
            body: `1 ${alert.baseCurrency} = ${currentRate.toFixed(4)} ${alert.targetCurrency} (${alert.isAbove ? "above" : "below"} ${alert.targetRate})`,
          },
          data: {
            alertId: alert.id,
            baseCurrency: alert.baseCurrency,
            targetCurrency: alert.targetCurrency,
            targetRate: alert.targetRate.toString(),
            currentRate: currentRate.toString(),
            isAbove: alert.isAbove.toString(),
            type: "currency_alert",
          },
          android: {
            notification: {
              sound: "default",
              channelId: "currency_alerts",
              priority: "high",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
              },
            },
          },
        };

        const response = await admin.messaging().send(message);
        console.log(`Push notification sent successfully: ${response}`);
      } catch (pushError) {
        console.error("Error sending push notification:", pushError);
      }
    }

    // Send email notification
    const mailOptions = {
      from: "\"CurrenSee Pro\" <" + functions.config().gmail.email + ">",
      to: userEmail,
      subject: "Currency Rate Alert Triggered!",
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <div style="background: linear-gradient(135deg, #1E3A8A 0%, #3B82F6 100%); color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
            <h2>Currency Rate Alert!</h2>
          </div>
          <div style="padding: 20px; background: #f8f9fa; border-radius: 0 0 8px 8px;">
            <p>Hello,</p>
            <p>Your currency alert has been triggered:</p>
            <div style="background: white; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #1E3A8A;">
              <p><strong>Base Currency:</strong> ${alert.baseCurrency}</p>
              <p><strong>Target Currency:</strong> ${alert.targetCurrency}</p>
              <p><strong>Condition:</strong> Rate is ${alert.isAbove ? "above" : "below"} ${alert.targetRate}</p>
              <p><strong>Current Rate:</strong> ${currentRate.toFixed(4)}</p>
              <p><strong>Time:</strong> ${new Date().toLocaleString()}</p>
            </div>
            <p>You can set new alerts in the CurrenSee Pro app.</p>
            <p style="margin-top: 20px; font-size: 12px; color: #6c757d;">
              This is an automated message. Please do not reply.
            </p>
          </div>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log(`Alert notification sent to ${userEmail}`);
  } catch (error) {
    console.error("Error sending alert notification:", error);
  }
}

exports.sendSupportEmail = functions.firestore
    .document("support_queries/{queryId}")
    .onCreate(async (snap, context) => {
      const data = snap.data();
      const mailOptions = {
        from: "\"Currency Support\" <" + functions.config().gmail.email + ">",
        to: "festoeventure@gmail.com",
        subject: "New Support Query: " + data.name,
        html:
        "<div style=\"font-family: Arial, sans-serif; max-width: 600px;\">" +
        "<h2 style=\"color: #1E3A8A;\">New Support Request</h2>" +
        "<div style=\"background: #f8f9fa; padding: 20px; \">" +
        "<p><strong>Name:</strong> " + data.name + "</p>" +
        "<p><strong>Email:</strong> " + data.email + "</p>" +
        "<p><strong>Timestamp:</strong> " +
        (data.timestamp && data.timestamp.toDate ?
          data.timestamp.toDate().toLocaleString() :
          "") +
        "</p>" +
        "<h4 style=\"margin-top: 20px;\">Message:</h4>" +
        "<p style=\"background: white; padding: 15px; border-radius: 4px; " +
        "border-left: 4px solid #1E3A8A;\">" +
        data.message +
        "</p></div>" +
        "<p style=\"margin-top: 20px; font-size: 0.9em; color: #6c757d;\">" +
        "This email was automatically generated by CurrencyApp support system" +
        "</p></div>",
      };
      try {
        await transporter.sendMail(mailOptions);
        console.log(
            "Support email sent successfully",
        );
        return null;
      } catch (error) {
        console.error(
            "Error sending support email:",
            error,
        );
        throw new functions.https.HttpsError(
            "internal",
            "Support email failed",
        );
      }
    });

exports.sendWelcomeEmail = functions.firestore
    .document("welcome_emails/{emailId}")
    .onCreate(async (snap, context) => {
      const data = snap.data();
      const mailOptions = {
        from: "\"CurrencyApp Team\" <" + functions.config().gmail.email + ">",
        to: data.email,
        subject: "Welcome to CurrenSee Pro!",
        html:
        "<div style=\"font-family: Arial, sans-serif; max-width: 600px;\">" +
        "<h2 style=\"color: #1E3A8A;\">Welcome to CurrenSee Pro!</h2>" +
        "<p>Hi " + (data.name || "") + ",</p>" +
        "<p>We're thrilled to have you on board." +
        "</p>" +
        "<p>— The CurrenSee Pro Team</p>" +
        "</div>",
      };
      try {
        await transporter.sendMail(mailOptions);
        console.log(
            "Welcome email sent to",
            data.email,
        );
        return null;
      } catch (error) {
        console.error(
            "Error sending welcome email:",
            error,
        );
        throw new functions.https.HttpsError(
            "internal",
            "Welcome email failed",
        );
      }
    });

// Cloud Function to add status field to existing users
exports.addStatusToExistingUsers = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    const usersRef = db.collection("currentUser");

    // Get all users
    const snapshot = await usersRef.get();

    let updatedCount = 0;
    const batch = db.batch();

    snapshot.docs.forEach((doc) => {
      const userData = doc.data();

      // Only add status if it doesn't exist
      if (!Object.prototype.hasOwnProperty.call(userData, "status")) {
        batch.update(doc.ref, {
          status: "active", // Default to active for existing users
          statusUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        updatedCount++;
      }
    });

    // Commit the batch
    if (updatedCount > 0) {
      await batch.commit();
      console.log(`Updated ${updatedCount} users with status field`);
    }

    res.json({
      success: true,
      message: `Successfully updated ${updatedCount} users with status field`,
      updatedCount: updatedCount,
    });
  } catch (error) {
    console.error("Error updating users:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Cloud Function to block a user
exports.blockUser = functions.https.onRequest(async (req, res) => {
  try {
    const {uid, reason} = req.body;

    if (!uid) {
      return res.status(400).json({
        success: false,
        error: "User ID is required",
      });
    }

    const db = admin.firestore();
    const userRef = db.collection("currentUser").doc(uid);

    await userRef.update({
      status: "blocked",
      blockedAt: admin.firestore.FieldValue.serverTimestamp(),
      blockedReason: reason || "No reason provided",
      blockedBy: "admin", // You can modify this to track who blocked the user
    });

    res.json({
      success: true,
      message: `User ${uid} has been blocked successfully`,
    });
  } catch (error) {
    console.error("Error blocking user:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Cloud Function to unblock a user
exports.unblockUser = functions.https.onRequest(async (req, res) => {
  try {
    const {uid} = req.body;

    if (!uid) {
      return res.status(400).json({
        success: false,
        error: "User ID is required",
      });
    }

    const db = admin.firestore();
    const userRef = db.collection("currentUser").doc(uid);

    await userRef.update({
      status: "active",
      unblockedAt: admin.firestore.FieldValue.serverTimestamp(),
      unblockedBy: "admin", // You can modify this to track who unblocked the user
    });

    res.json({
      success: true,
      message: `User ${uid} has been unblocked successfully`,
    });
  } catch (error) {
    console.error("Error unblocking user:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

// Initialize default news categories
exports.initializeNewsCategories = functions.https.onCall(async (data, context) => {
  // Check if user is admin
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const adminUid = context.auth.uid;
  const adminDoc = await admin.firestore().collection("currentUser").doc(adminUid).get();
  
  if (!adminDoc.exists || adminDoc.data().role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Only admins can initialize news categories");
  }

  try {
    const defaultCategories = [
      {
        id: "business",
        name: "Business",
        apiCategory: "business",
        status: "active",
        maxArticles: 20,
        description: "Latest business news and updates",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "economy",
        name: "Economy",
        apiCategory: "economy",
        status: "active",
        maxArticles: 20,
        description: "Economic news and financial updates",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "finance",
        name: "Finance",
        apiCategory: "finance",
        status: "active",
        maxArticles: 20,
        description: "Financial markets and investment news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "technology",
        name: "Technology",
        apiCategory: "technology",
        status: "active",
        maxArticles: 20,
        description: "Technology and innovation news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "world",
        name: "World",
        apiCategory: "world",
        status: "active",
        maxArticles: 20,
        description: "International news and global updates",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "cryptocurrency",
        name: "Cryptocurrency",
        apiCategory: "cryptocurrency",
        status: "active",
        maxArticles: 20,
        description: "Cryptocurrency and blockchain news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "stock-market",
        name: "Stock Market",
        apiCategory: "stock market",
        status: "active",
        maxArticles: 20,
        description: "Stock market and trading news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    ];

    const batch = admin.firestore().batch();
    
    defaultCategories.forEach((category) => {
      const docRef = admin.firestore().collection("news_categories").doc(category.id);
      batch.set(docRef, category);
    });

    await batch.commit();

    return { success: true, message: "News categories initialized successfully" };
  } catch (error) {
    console.error("Error initializing news categories:", error);
    throw new functions.https.HttpsError("internal", "Failed to initialize news categories");
  }
});

// Initialize news configuration
exports.initializeNewsConfig = functions.https.onCall(async (data, context) => {
  // Check if user is admin
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const adminUid = context.auth.uid;
  const adminDoc = await admin.firestore().collection("currentUser").doc(adminUid).get();
  
  if (!adminDoc.exists || adminDoc.data().role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Only admins can initialize news configuration");
  }

  try {
    const defaultConfig = {
      apiKey: "b2254f48318f9db55c21821b24d057bd",
      baseUrl: "https://gnews.io/api/v4/top-headlines",
      defaultLanguage: "en",
      defaultCountry: "us",
      maxArticlesPerCategory: 20,
      refreshInterval: 300, // 5 minutes
      enableCaching: true,
      cacheDuration: 600, // 10 minutes
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await admin.firestore()
      .collection("app_config")
      .doc("news_settings")
      .set(defaultConfig);

    return { success: true, message: "News configuration initialized successfully" };
  } catch (error) {
    console.error("Error initializing news configuration:", error);
    throw new functions.https.HttpsError("internal", "Failed to initialize news configuration");
  }
});

// Initialize ALL news categories (comprehensive list)
exports.initializeAllNewsCategories = functions.https.onCall(async (data, context) => {
  // Check if user is admin
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const adminUid = context.auth.uid;
  const adminDoc = await admin.firestore().collection("currentUser").doc(adminUid).get();
  
  if (!adminDoc.exists || adminDoc.data().role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Only admins can initialize news categories");
  }

  try {
    const allCategories = [
      {
        id: "business",
        name: "Business",
        apiCategory: "business",
        status: "active",
        maxArticles: 20,
        description: "Latest business news and updates",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "economy",
        name: "Economy",
        apiCategory: "economy",
        status: "active",
        maxArticles: 20,
        description: "Economic news and financial updates",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "finance",
        name: "Finance",
        apiCategory: "finance",
        status: "active",
        maxArticles: 20,
        description: "Financial markets and investment news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "technology",
        name: "Technology",
        apiCategory: "technology",
        status: "active",
        maxArticles: 20,
        description: "Technology and innovation news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "world",
        name: "World",
        apiCategory: "world",
        status: "active",
        maxArticles: 20,
        description: "International news and global updates",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "cryptocurrency",
        name: "Cryptocurrency",
        apiCategory: "cryptocurrency",
        status: "active",
        maxArticles: 20,
        description: "Cryptocurrency and blockchain technology news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "stock-market",
        name: "Stock Market",
        apiCategory: "stock market",
        status: "active",
        maxArticles: 20,
        description: "Stock market updates and trading news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "real-estate",
        name: "Real Estate",
        apiCategory: "real estate",
        status: "active",
        maxArticles: 15,
        description: "Real estate market and property news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "healthcare",
        name: "Healthcare",
        apiCategory: "health",
        status: "active",
        maxArticles: 15,
        description: "Healthcare and pharmaceutical industry news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "energy",
        name: "Energy",
        apiCategory: "energy",
        status: "active",
        maxArticles: 15,
        description: "Energy sector and oil market updates",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "automotive",
        name: "Automotive",
        apiCategory: "automotive",
        status: "active",
        maxArticles: 15,
        description: "Automotive industry and car market news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "entertainment",
        name: "Entertainment",
        apiCategory: "entertainment",
        status: "active",
        maxArticles: 15,
        description: "Entertainment and media industry updates",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "sports-business",
        name: "Sports Business",
        apiCategory: "sports",
        status: "active",
        maxArticles: 15,
        description: "Sports business and industry news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "politics",
        name: "Politics",
        apiCategory: "politics",
        status: "active",
        maxArticles: 15,
        description: "Political news affecting business and economy",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "science",
        name: "Science",
        apiCategory: "science",
        status: "active",
        maxArticles: 15,
        description: "Scientific research and innovation news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "education",
        name: "Education",
        apiCategory: "education",
        status: "active",
        maxArticles: 15,
        description: "Education sector and EdTech industry news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        id: "travel",
        name: "Travel",
        apiCategory: "travel",
        status: "active",
        maxArticles: 15,
        description: "Travel industry and tourism business news",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    ];

    const batch = admin.firestore().batch();
    
    allCategories.forEach((category) => {
      const docRef = admin.firestore().collection("news_categories").doc(category.id);
      batch.set(docRef, category);
    });

    await batch.commit();

    console.log(`✅ All ${allCategories.length} news categories initialized successfully!`);
    return { 
      success: true, 
      message: `All ${allCategories.length} news categories initialized successfully!`,
      count: allCategories.length
    };
  } catch (error) {
    console.error("Error initializing all news categories:", error);
    throw new functions.https.HttpsError("internal", "Failed to initialize all news categories");
  }
});
