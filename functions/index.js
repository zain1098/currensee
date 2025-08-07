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

// Background function to check currency alerts every 5 minutes
exports.checkCurrencyAlerts = functions.pubsub
    .schedule('every 5 minutes')
    .onRun(async (context) => {
      try {
        console.log('Starting currency alert check...');
        
        // Get all active alerts
        const alertsSnapshot = await admin.firestore()
            .collection('alerts')
            .get();
        
        if (alertsSnapshot.empty) {
          console.log('No active alerts found');
          return null;
        }
        
        // Group alerts by base currency to minimize API calls
        const alertsByBaseCurrency = {};
        alertsSnapshot.forEach(doc => {
          const alert = doc.data();
          const baseCurrency = alert.baseCurrency;
          if (!alertsByBaseCurrency[baseCurrency]) {
            alertsByBaseCurrency[baseCurrency] = [];
          }
          alertsByBaseCurrency[baseCurrency].push({
            id: doc.id,
            ...alert
          });
        });
        
        // Check alerts for each base currency
        for (const [baseCurrency, alerts] of Object.entries(alertsByBaseCurrency)) {
          try {
            // Fetch current rates for this base currency
            const response = await axios.get(
              `https://open.er-api.com/v6/latest/${baseCurrency}`
            );
            
            if (response.data.result === 'success') {
              const rates = response.data.rates;
              
              // Check each alert
              for (const alert of alerts) {
                const currentRate = rates[alert.targetCurrency];
                if (currentRate === undefined) continue;
                
                const shouldTrigger = alert.isAbove
                  ? currentRate >= alert.targetRate
                  : currentRate <= alert.targetRate;
                
                        if (shouldTrigger) {
          console.log(`Alert triggered: ${alert.id}`);
          
          // Send push notification to user
          await sendPushNotification(alert, currentRate);
          
          // Send email notification
          await sendAlertNotification(alert, currentRate);
          
          // Save to alert history
          await admin.firestore().collection('alert_history').add({
            userId: alert.userId,
            alertId: alert.id,
            baseCurrency: alert.baseCurrency,
            targetCurrency: alert.targetCurrency,
            targetRate: alert.targetRate,
            isAbove: alert.isAbove,
            triggeredAt: admin.firestore.FieldValue.serverTimestamp(),
            currentRate: currentRate,
            notificationTitle: 'Currency Rate Alert!',
            notificationBody: `1 ${alert.baseCurrency} = ${currentRate.toFixed(4)} ${alert.targetCurrency} (${alert.isAbove ? 'above' : 'below'} ${alert.targetRate})`,
            sound: 'notification.mp3',
          });
          
          // Remove the alert
          await admin.firestore().collection('alerts').doc(alert.id).delete();
        }
              }
            }
          } catch (error) {
            console.error(`Error checking alerts for ${baseCurrency}:`, error);
          }
        }
        
        console.log('Currency alert check completed');
        return null;
      } catch (error) {
        console.error('Error in checkCurrencyAlerts:', error);
        return null;
      }
    });

// Function to send push notification
async function sendPushNotification(alert, currentRate) {
  try {
    // Get user's FCM token
    const userDoc = await admin.firestore()
        .collection('currentUser')
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
        title: 'Currency Rate Alert!',
        body: `1 ${alert.baseCurrency} = ${currentRate.toFixed(4)} ${alert.targetCurrency} (${alert.isAbove ? 'above' : 'below'} ${alert.targetRate})`
      },
      data: {
        alertId: alert.id,
        baseCurrency: alert.baseCurrency,
        targetCurrency: alert.targetCurrency,
        targetRate: alert.targetRate.toString(),
        currentRate: currentRate.toString(),
        isAbove: alert.isAbove.toString(),
        type: 'currency_alert'
      },
      android: {
        notification: {
          sound: 'default',
          channelId: 'currency_alerts',
          priority: 'high'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };
    
    const response = await admin.messaging().send(message);
    console.log(`Push notification sent successfully: ${response}`);
    
  } catch (error) {
    console.error('Error sending push notification:', error);
  }
}

// Function to send alert notification
async function sendAlertNotification(alert, currentRate) {
  try {
    // Get user's notification preferences
    const userDoc = await admin.firestore()
        .collection('currentUser')
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
            title: 'Currency Rate Alert!',
            body: `1 ${alert.baseCurrency} = ${currentRate.toFixed(4)} ${alert.targetCurrency} (${alert.isAbove ? 'above' : 'below'} ${alert.targetRate})`
          },
          data: {
            alertId: alert.id,
            baseCurrency: alert.baseCurrency,
            targetCurrency: alert.targetCurrency,
            targetRate: alert.targetRate.toString(),
            currentRate: currentRate.toString(),
            isAbove: alert.isAbove.toString(),
            type: 'currency_alert'
          },
          android: {
            notification: {
              sound: 'default',
              channelId: 'currency_alerts',
              priority: 'high'
            }
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1
              }
            }
          }
        };
        
        const response = await admin.messaging().send(message);
        console.log(`Push notification sent successfully: ${response}`);
      } catch (pushError) {
        console.error('Error sending push notification:', pushError);
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
              <p><strong>Condition:</strong> Rate is ${alert.isAbove ? 'above' : 'below'} ${alert.targetRate}</p>
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
    console.error('Error sending alert notification:', error);
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
