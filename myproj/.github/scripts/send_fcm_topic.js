const admin = require('firebase-admin');

const MORNING_MESSAGES = [
  'Good morning. Start your day with one calm breath.',
  'A gentle start makes a better day. You got this.',
  'You are stronger than yesterday. Keep moving.',
  'Start small today. Small wins still count.',
  'Be kind to yourself this morning.',
  'Take 2 minutes now to reset your focus.',
  'New day, new chance. Open Safe Space for a quick check-in.'
];

const NIGHT_MESSAGES = [
  'Good night. You did enough for today.',
  'Take a deep breath and let the day go.',
  'Rest is progress too. Sleep peacefully.',
  'You handled today well. Tomorrow is another chance.',
  'Slow down, relax, and recharge your mind.',
  'Close the day with gratitude for one small thing.',
  'End your day calmly. You are doing better than you think.'
];

function getCairoNow() {
  const now = new Date();
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Africa/Cairo',
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    hour: 'numeric',
    hour12: false
  }).formatToParts(now);

  const get = (type) => Number(parts.find((p) => p.type === type)?.value);

  return {
    year: get('year'),
    month: get('month'),
    day: get('day'),
    hour: get('hour')
  };
}

function pickDailyMessage(messages, dateParts) {
  const seed = dateParts.year * 1000 + dateParts.month * 100 + dateParts.day;
  const index = seed % messages.length;
  return messages[index];
}

function resolveType(forcedType, cairoNow) {
  if (forcedType === 'morning' || forcedType === 'night') {
    return forcedType;
  }

  if (cairoNow.hour === 9) {
    return 'morning';
  }

  if (cairoNow.hour === 21) {
    return 'night';
  }

  return null;
}

async function main() {
  const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!json) {
    throw new Error('Missing FIREBASE_SERVICE_ACCOUNT_JSON secret.');
  }

  const serviceAccount = JSON.parse(json);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });

  const cairoNow = getCairoNow();
  const forcedType = process.argv[2];
  const type = resolveType(forcedType, cairoNow);

  if (!type) {
    console.log('Skipping run. Cairo hour is not 9 or 21.');
    return;
  }

  const isMorning = type === 'morning';
  const title = isMorning ? 'Safe Space Morning' : 'Safe Space Night';
  const body = pickDailyMessage(
    isMorning ? MORNING_MESSAGES : NIGHT_MESSAGES,
    cairoNow
  );

  const message = {
    topic: 'daily_notifications',
    notification: { title, body },
    data: {
      type,
      tz: 'Africa/Cairo',
      date: `${cairoNow.year}-${String(cairoNow.month).padStart(2, '0')}-${String(
        cairoNow.day
      ).padStart(2, '0')}`
    }
  };

  const response = await admin.messaging().send(message);
  console.log(`Sent ${type} notification. Message ID: ${response}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
