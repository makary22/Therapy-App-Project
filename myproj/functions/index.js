const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const morningMessages = [
  'Good morning. Start your day with one calm breath.',
  'A gentle start makes a better day. You got this.',
  'You are stronger than yesterday. Keep moving.',
  'Start small today. Small wins still count.',
  'Be kind to yourself this morning.',
  'Take 2 minutes now to reset your focus.',
  'New day, new chance. Open Safe Space for a quick check-in.',
];

const nightMessages = [
  'Good night. You did enough for today.',
  'Take a deep breath and let the day go.',
  'Rest is progress too. Sleep peacefully.',
  'You handled today well. Tomorrow is another chance.',
  'Slow down, relax, and recharge your mind.',
  'Close the day with gratitude for one small thing.',
  'End your day calmly. You are doing better than you think.',
];

/**
 * Pick a deterministic message based on date
 * Same date will always get the same message
 */
function pickDailyMessage(messages) {
  const today = new Date();
  const seed = today.getFullYear() * 1000 + (today.getMonth() + 1) * 100 + today.getDate();
  const index = seed % messages.length;
  return messages[index];
}

/**
 * Send morning notification at 9:00 AM
 * Triggered daily by Cloud Scheduler
 */
exports.sendMorningNotification = functions
  .pubsub.schedule('0 9 * * *') // 9:00 AM every day (UTC)
  .timeZone('Africa/Cairo') // Adjust to Cairo time
  .onRun(async (context) => {
    const message = pickDailyMessage(morningMessages);

    const notification = {
      notification: {
        title: 'Safe Space',
        body: message,
      },
      data: {
        type: 'morning',
        timestamp: new Date().toISOString(),
      },
    };

    try {
      const response = await admin.messaging().sendToTopic('daily_notifications', notification);
      console.log(`Morning notification sent successfully. Message ID: ${response}`);
      return null;
    } catch (error) {
      console.error('Error sending morning notification:', error);
      throw error;
    }
  });

/**
 * Send night notification at 9:00 PM
 * Triggered daily by Cloud Scheduler
 */
exports.sendNightNotification = functions
  .pubsub.schedule('0 21 * * *') // 9:00 PM (21:00) every day (UTC)
  .timeZone('Africa/Cairo') // Adjust to Cairo time
  .onRun(async (context) => {
    const message = pickDailyMessage(nightMessages);

    const notification = {
      notification: {
        title: 'Safe Space',
        body: message,
      },
      data: {
        type: 'night',
        timestamp: new Date().toISOString(),
      },
    };

    try {
      const response = await admin.messaging().sendToTopic('daily_notifications', notification);
      console.log(`Night notification sent successfully. Message ID: ${response}`);
      return null;
    } catch (error) {
      console.error('Error sending night notification:', error);
      throw error;
    }
  });
