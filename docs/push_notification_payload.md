# Push notification timestamp contract

Android displays an FCM notification payload itself while the app is in the
background or terminated. Flutter does not get a chance to replace that row
before it is shown. Consequently, the backend owns the timestamp for this
delivery path.

## Required backend fix

For messages that contain the top-level `notification` object:

- Prefer omitting `android.notification.event_time`. Android will then use the
  notification post time.
- If an event time is required, send it as a current RFC 3339 UTC timestamp,
  for example `2026-10-06T12:35:41Z`. Never send a formatted display date such
  as `1/3/01`, a two-digit year, or seconds where milliseconds are expected.
- Include `data.createdAt` as an ISO-8601 timestamp. The app uses this value for
  foreground/local notifications and for the in-app notification list.

Example FCM HTTP v1 payload (native display in the background):

```json
{
  "message": {
    "token": "<FCM token>",
    "notification": {
      "title": "Test",
      "body": "Test"
    },
    "data": {
      "title": "Test",
      "body": "Test",
      "createdAt": "2026-10-06T12:35:41Z"
    },
    "android": {
      "priority": "HIGH",
      "notification": {
        "channel_id": "high_importance_channel"
      }
    }
  }
}
```

Do not add `event_time` unless the product intentionally needs a time different
from the delivery time.

## Fully app-controlled alternative

To make foreground, background, and terminated-state rendering use the same
Flutter code, send a high-priority data-only message (omit the top-level
`notification` object) and put `title`, `body`, and `createdAt` under `data`.
The existing background handler will create the local notification. This option
must be tested on the target Android devices because OS battery policies can
delay data-only delivery, and force-stopped apps do not receive messages until
they are opened again.

## Client-side safety net

The app validates both `data.createdAt` and FCM `sentTime`. Values outside the
supported 2020-2100 range are discarded and the current device time is used, so
a malformed timestamp cannot produce another 2001 local notification. This
safety net applies to notifications built by the app; it cannot rewrite an FCM
row that Android has already displayed natively.
