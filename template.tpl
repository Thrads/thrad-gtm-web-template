___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community Template Gallery Developer Terms of Service.

___INFO___

{
  "type": "TAG",
  "id": "cvt_thrad_web",
  "version": 1,
  "securityGroups": [],
  "displayName": "Thrad",
  "description": "Install the Thrad browser tag and send events.",
  "containerContexts": [
    "WEB"
  ],
  "categories": [
    "ADVERTISING",
    "ATTRIBUTION",
    "CONVERSIONS"
  ]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "SELECT",
    "name": "mode",
    "displayName": "Mode",
    "selectItems": [
      {
        "value": "install",
        "displayValue": "Install tag"
      },
      {
        "value": "event",
        "displayValue": "Send event"
      }
    ],
    "simpleValueType": true,
    "defaultValue": "install"
  },
  {
    "type": "TEXT",
    "name": "tagId",
    "displayName": "Tag ID",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "SELECT",
    "name": "eventType",
    "displayName": "Event",
    "simpleValueType": true,
    "defaultValue": "purchase",
    "selectItems": [
      {
        "value": "purchase",
        "displayValue": "Purchase"
      },
      {
        "value": "lead",
        "displayValue": "Lead"
      },
      {
        "value": "custom",
        "displayValue": "Custom"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "mode",
        "paramValue": "event",
        "type": "EQUALS"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "orderId",
    "displayName": "Order ID",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "mode",
        "paramValue": "event",
        "type": "EQUALS"
      },
      {
        "paramName": "eventType",
        "paramValue": "purchase",
        "type": "EQUALS"
      }
    ],
    "help": "Map the stable transaction/order ID. Numeric IDs must be safe integers; string IDs retain their original identity."
  },
  {
    "type": "TEXT",
    "name": "value",
    "displayName": "Order value",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "mode",
        "paramValue": "event",
        "type": "EQUALS"
      },
      {
        "paramName": "eventType",
        "paramValue": "purchase",
        "type": "EQUALS"
      }
    ],
    "help": "Major currency units, for example 25.99. Zero is valid."
  },
  {
    "type": "TEXT",
    "name": "currency",
    "displayName": "Currency",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "mode",
        "paramValue": "event",
        "type": "EQUALS"
      },
      {
        "paramName": "eventType",
        "paramValue": "purchase",
        "type": "EQUALS"
      }
    ],
    "help": "Three-letter currency, for example USD."
  },
  {
    "type": "TEXT",
    "name": "eventId",
    "displayName": "Event ID",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "mode",
        "paramValue": "event",
        "type": "EQUALS"
      },
      {
        "paramName": "eventType",
        "paramValue": "lead",
        "type": "EQUALS"
      }
    ],
    "help": "Reuse the submission ID on retries. No order ID is required."
  },
  {
    "type": "TEXT",
    "name": "customEventId",
    "displayName": "Event ID",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "mode",
        "paramValue": "event",
        "type": "EQUALS"
      },
      {
        "paramName": "eventType",
        "paramValue": "custom",
        "type": "EQUALS"
      }
    ],
    "help": "Reuse this event ID on retries."
  },
  {
    "type": "TEXT",
    "name": "customEventName",
    "displayName": "Custom event name",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "mode",
        "paramValue": "event",
        "type": "EQUALS"
      },
      {
        "paramName": "eventType",
        "paramValue": "custom",
        "type": "EQUALS"
      }
    ],
    "help": "Use the existing configured custom-event policy; no provider mapping is created here."
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "parameters",
    "displayName": "Event parameters",
    "simpleTableColumns": [
      {
        "type": "TEXT",
        "name": "key",
        "displayName": "Parameter name",
        "isUnique": true
      },
      {
        "type": "TEXT",
        "name": "value",
        "displayName": "Value"
      }
    ],
    "enablingConditions": [
      {
        "paramName": "mode",
        "paramValue": "event",
        "type": "EQUALS"
      }
    ],
    "help": "Optional business fields: product_id, content_id, content_name, content_type, quantity, items, contents, cart_id, plan_id. Use dedicated fields for identity/value/currency. Customer identity and credentials are not supported."
  }
]

___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// GTM sandbox adapter to the existing browser SDK.
const copy = require('copyFromWindow');
const set = require('setInWindow');
const granted = require('isConsentGranted');
const listen = require('addConsentListener');
const call = require('callInWindow');
const queue = require('createArgumentsQueue');
const inject = require('injectScript');
const storage = require('templateStorage');
const json = require('JSON');
const getType = require('getType');
const makeString = require('makeString');
const makeNumber = require('makeNumber');
const tagId = typeof data.tagId === 'string' ? data.tagId.trim() : '';
const mode = data.mode || 'install';
if (!tagId || tagId.length > 255 || (mode !== 'install' && mode !== 'event')) {
  data.gtmOnFailure(); return;
}
const identity = (value) => {
  if (typeof value === 'number' && (value < 0 || value > 9007199254740991 || value % 1 !== 0)) return '';
  if (typeof value !== 'string' && typeof value !== 'number') return '';
  const result = makeString(value).trim();
  return result.length <= 255 ? result : '';
};
const eventType = data.eventType;
let eventName;
const business = {};
if (mode === 'event') {
  if (eventType === 'purchase') {
    business.order_id = identity(data.orderId);
    const raw = (typeof data.value === 'number' || typeof data.value === 'string') ? makeString(data.value) : '';
    const match = /^(\d+)(?:\.(\d+))?$/.exec(raw);
    const fraction = match && match[2] || '';
    // Validate the SDK's hundredths range without converting the dispatched value.
    const amount = match ? makeNumber(match[1]) * 100 + makeNumber((fraction + '00').slice(0, 2)) +
      (makeNumber(fraction[2] || '0') >= 5 ? 1 : 0) : -1;
    const currency = typeof data.currency === 'string' ? data.currency.trim().toUpperCase() : '';
    if (!business.order_id || amount < 0 || amount > 9007199254740991 || !/^[A-Z]{3}$/.test(currency)) {
      data.gtmOnFailure(); return;
    }
    business.value = data.value; business.currency = currency;
    eventName = 'order_created';
  } else if (eventType === 'lead' || eventType === 'custom') {
    business.event_id = identity(eventType === 'lead' ? data.eventId : data.customEventId);
    eventName = eventType === 'lead' ? 'lead_created' :
      (typeof data.customEventName === 'string' ? data.customEventName.trim().toLowerCase() : '');
    const purchaseNames = ['purchase', 'purchase_completed', 'checkout_completed', 'order', 'order_completed', 'conversion', 'order_created'];
    const standardNames = ['page_viewed', 'contents_viewed', 'items_added', 'checkout_started', 'lead_created', 'registration_completed', 'appointment_scheduled', 'subscription_created', 'trial_started', 'app_installed', 'app_opened', 'custom'];
    if (!business.event_id || (eventType === 'custom' && (!/^[A-Za-z0-9](?:[A-Za-z0-9_-]*[A-Za-z0-9])?$/.test(eventName) ||
        eventName.length > 64 || purchaseNames.indexOf(eventName.replace(/[-\s]+/g, '_')) !== -1 || standardNames.indexOf(eventName) !== -1))) {
      data.gtmOnFailure(); return;
    }
  } else { data.gtmOnFailure(); return; }
}
// Snapshot resolved variables before an asynchronous SDK load. Optional undefined
// values are omitted; reserved fields cannot change event identity or targeting.
const params = {};
if (mode === 'event' && data.parameters !== undefined) {
  if (getType(data.parameters) !== 'array') { data.gtmOnFailure(); return; }
  for (let i = 0; i < data.parameters.length; i++) {
    const row = data.parameters[i];
    if (!row || typeof row.key !== 'string' || !row.key.trim()) {
      data.gtmOnFailure(); return;
    }
    const key = row.key.trim();
    if (key === '__proto__' || key === 'constructor' || key === 'prototype' ||
        key === 'send_to' || key === 'tag_id' || key === 'event_name' || key === 'eventName' ||
        key === 'event_id' || key === 'eventId' || key === 'order_id' || key === 'orderId' ||
        key === 'value' || key === 'currency' || key === 'data') {
      data.gtmOnFailure(); return;
    }
    if (row.value === undefined) continue;
    const allowed = ['product_id', 'content_id', 'content_name', 'content_type', 'quantity', 'items', 'contents', 'cart_id', 'plan_id'];
    if (allowed.indexOf(key) === -1) { data.gtmOnFailure(); return; }
    params[key] = row.value;
  }
}
if (mode === 'event') {
  if (eventType === 'purchase') { params.order_id = business.order_id; params.value = business.value; params.currency = business.currency; }
  else params.event_id = business.event_id;
}
params.send_to = tagId;
const snapshot = json.parse(json.stringify(params));
if (!snapshot) { data.gtmOnFailure(); return; }
let completed = false;
const success = () => { if (!completed) { completed = true; data.gtmOnSuccess(); } };
const failure = () => { if (!completed) { completed = true; data.gtmOnFailure(); } };
let consent = storage.getItem('consent');
if (!consent) {
  consent = { snapshot: undefined, revision: 0, initializers: [] };
  storage.setItem('consent', consent);
  const sync = () => {
    const snapshot = {
      ad_storage: granted('ad_storage') ? 'granted' : 'denied',
      analytics_storage: granted('analytics_storage') ? 'granted' : 'denied',
      ad_user_data: granted('ad_user_data') ? 'granted' : 'denied',
      ad_personalization: granted('ad_personalization') ? 'granted' : 'denied'
    };
    snapshot.measurement = snapshot.ad_storage === 'granted' &&
      snapshot.analytics_storage === 'granted' && snapshot.ad_user_data === 'granted';
    snapshot.personalization = snapshot.measurement && snapshot.ad_personalization === 'granted';
    const previous = consent.snapshot;
    if ((!previous || previous.measurement) && !snapshot.measurement) consent.revision++;
    snapshot.revision = consent.revision;
    consent.snapshot = snapshot;
    // Publish synchronously so SDK bootstrap and pending work see withdrawal.
    set('thradTagGtmConsent', snapshot, true);
    if (typeof copy('thradTag') === 'function') {
      if (!snapshot.measurement && copy('thradTag.__thradTag') !== true) {
        const pending = copy('thradTag.q');
        if (getType(pending) === 'array') {
          set('thradTag.q', pending.filter((entry) => entry && (entry[0] === 'set' || entry[0] === 'consent' || entry[0] === 'get')), true);
        }
      }
      call('thradTag', 'consent', 'update', snapshot);
    }
    if (previous && !previous.measurement && snapshot.measurement) {
      consent.initializers.forEach((initialize) => initialize.run());
    }
  };
  sync();
  ['ad_storage', 'analytics_storage', 'ad_user_data', 'ad_personalization'].forEach((name) => listen(name, sync));
}
const start = (emitEvent) => {
  if (!consent.snapshot.measurement) { success(); return; }
let state = storage.getItem('loader');
if (state && state.failed) {
  failure();
  return;
}
const existing = copy('thradTag');
if (existing !== undefined && typeof existing !== 'function') {
  failure();
  return;
}
if (!existing) queue('thradTag', 'thradTag.q');
call('thradTag', 'consent', 'update', consent.snapshot);
call('thradTag', 'set', { tag_id: tagId, channel: 'web' });
if (mode === 'event' && emitEvent) {
  if (eventType === 'purchase') call('thradTag', 'conversion', snapshot);
  else call('thradTag', 'event', eventName, snapshot);
}
if (copy('thradTag.__thradTag') === true) {
  success();
  return;
}
if (state) {
  state.waiters.push({ success: success, failure: failure });
  return;
}
state = { failed: false, done: false, waiters: [
  { success: success, failure: failure }
] };
storage.setItem('loader', state);
const finish = (ok) => {
  if (state.done) return;
  state.done = true;
  state.failed = !ok;
  const waiters = state.waiters;
  state.waiters = [];
  waiters.forEach((waiter) => { if (ok) waiter.success(); else waiter.failure(); });
};
if (existing) {
  // The manual snippet owns its script request. Never insert another SDK.
  // Bounded wait: a stale stub reports failure instead of hanging GTM forever.
  let remaining = 100;
  const check = () => {
    if (copy('thradTag.__thradTag') === true) return finish(true);
    if (!remaining--) return finish(false);
    call('setTimeout', check, 100);
  };
  check();
} else {
  inject('https://cdn.thrad.ai/tag.min.js',
    () => finish(copy('thradTag.__thradTag') === true),
    () => finish(false), 'thrad-web-sdk');
}

};
// Only installation is resumed after grant. Suppressed conversion events are
// discarded, not saved for later replay. One initializer per target/page.
if (mode === 'install' && !consent.initializers.some((entry) => entry.tagId === tagId)) {
  consent.initializers.push({ tagId: tagId, run: () => start(false) });
}
start(true);


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "thradTag"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "thradTag.q"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "thradTag.__thradTag"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "setTimeout"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "thradTagGtmConsent"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "inject_script",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://cdn.thrad.ai/tag.min.js"
              }
            ]
          }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_template_storage",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_consent",
        "versionId": "1"
      },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_storage"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "analytics_storage"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_user_data"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_personalization"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "isRequired": true
  }
]

___TESTS___

scenarios: [
  {
    "name": "Concurrent loader preserves early payload and completes each firing once",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nrunCode({ tagId: 'account-a', mode: 'event', eventType: 'lead', eventId: 'lead:1', parameters: [{ key: 'quantity', value: 0 }] });\nrunCode({ tagId: 'account-b', mode: 'install' });\nassertThat(injections).hasLength(1);\nassertThat(injections[0].url).isEqualTo('https://cdn.thrad.ai/tag.min.js');\nassertThat(successes).isEqualTo(0);\nconst event = globals.thradTag.q.filter((entry) => entry[0] === 'event')[0];\nassertThat(event[2]).isEqualTo({ event_id: 'lead:1', quantity: 0, send_to: 'account-a' });\nassertThat(globals.thradTag.q.filter((entry) => entry[0] === 'event' && entry[1] === 'page_viewed')).hasLength(0);\nready(); injections[0].success(); injections[0].success();\nassertThat(successes).isEqualTo(2); assertThat(failures).isEqualTo(0);"
  },
  {
    "name": "Ready manual SDK is reused without a new script or page view",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nstub(); ready();\nrunCode({ tagId: 'account-a' });\nassertThat(injections).hasLength(0); assertThat(successes).isEqualTo(1);\nassertThat(globals.thradTag.q.filter((entry) => entry[0] === 'event')).hasLength(0);"
  },
  {
    "name": "Pending manual queue is preserved while waiting for readiness",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nstub(); globals.thradTag('event', 'page_viewed', { send_to: 'manual' });\nrunCode({ tagId: 'account-a' });\nassertThat(injections).hasLength(0); assertThat(successes).isEqualTo(0);\nassertThat(globals.thradTag.q[0]).isEqualTo(['event', 'page_viewed', { send_to: 'manual' }]);\nready(); timers.shift()();\nassertThat(successes).isEqualTo(1);"
  },
  {
    "name": "SDK load failure completes every waiter once",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nrunCode({ tagId: 'account-a' }); runCode({ tagId: 'account-b' });\ninjections[0].failure(); injections[0].failure(); injections[0].success();\nassertThat(failures).isEqualTo(2); assertThat(successes).isEqualTo(0);"
  },
  {
    "name": "Invalid Tag ID fails before SDK or global access",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nrunCode({ tagId: '   ' });\nassertThat(failures).isEqualTo(1); assertThat(injections).hasLength(0);\nassertApi('createArgumentsQueue').wasNotCalled();"
  },
  {
    "name": "Denial prevents loading and grant resumes installation without event replay",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nconsent.ad_storage = false;\nrunCode({ tagId: 'account-a' });\nrunCode({ tagId: 'account-a', mode: 'event', eventType: 'purchase', orderId: 'order-1', value: 0, currency: 'USD' });\nassertThat(injections).hasLength(0);\nassertThat(globals.thradTagGtmConsent.measurement).isFalse();\nupdate('ad_storage', true);\nassertThat(injections).hasLength(1);\nassertThat(globals.thradTag.q.filter((entry) => entry[0] === 'event')).hasLength(0);\nready(); injections[0].success();\nassertThat(successes).isEqualTo(2);"
  },
  {
    "name": "Withdrawal removes pending tracking and preserves personalization denial",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nconsent.ad_personalization = false;\nrunCode({ tagId: 'account-a', mode: 'event', eventType: 'lead', eventId: 'lead:1' });\nassertThat(globals.thradTagGtmConsent.personalization).isFalse();\nupdate('analytics_storage', false); update('analytics_storage', true);\nassertThat(globals.thradTagGtmConsent.revision).isEqualTo(1);\nassertThat(globals.thradTag.q.filter((entry) => entry[0] === 'event')).hasLength(0);\nready(); injections[0].success();\nassertThat(successes).isEqualTo(1);"
  },
  {
    "name": "Script callback without SDK readiness is failure rather than receipt proof",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nrunCode({ tagId: 'account-a' }); injections[0].success();\nassertThat(failures).isEqualTo(1); assertThat(successes).isEqualTo(0);"
  },
  {
    "name": "Purchase form keeps zero and order identity in the conversion command",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nrunCode({ tagId: 'account-a', mode: 'event', eventType: 'purchase', orderId: 123, value: 0, currency: 'usd' });\nconst call = globals.thradTag.q.filter((entry) => entry[0] === 'conversion')[0];\nassertThat(call[1]).isEqualTo({ order_id: '123', value: 0, currency: 'USD', send_to: 'account-a' });\nready(); injections[0].success(); assertThat(successes).isEqualTo(1);"
  },
  {
    "name": "Lead form keeps submission identity without an order",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nrunCode({ tagId: 'account-a', mode: 'event', eventType: 'lead', eventId: 'lead:1' });\nconst call = globals.thradTag.q.filter((entry) => entry[0] === 'event')[0];\nassertThat(call[1]).isEqualTo('lead_created');\nassertThat(call[2]).isEqualTo({ event_id: 'lead:1', send_to: 'account-a' });"
  },
  {
    "name": "Custom form preserves the supported custom name and identity",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nrunCode({ tagId: 'account-a', mode: 'event', eventType: 'custom', customEventName: 'Quote-Requested', customEventId: 'quote:1' });\nconst call = globals.thradTag.q.filter((entry) => entry[0] === 'event')[0];\nassertThat(call[1]).isEqualTo('quote-requested');\nassertThat(call[2]).isEqualTo({ event_id: 'quote:1', send_to: 'account-a' });"
  },
  {
    "name": "Invalid business fields and parameter collisions never dispatch",
    "code": "const globals = {};\nconst memory = {};\nconst callbacks = {};\nconst consent = {};\nconst timers = [];\nconst injections = [];\nlet successes = 0;\nlet failures = 0;\nmock('gtmOnSuccess', () => successes++);\nmock('gtmOnFailure', () => failures++);\nmockObject('templateStorage', {\n  getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }\n});\nmock('isConsentGranted', (name) => consent[name] !== false);\nmock('addConsentListener', (name, callback) => { callbacks[name] = callback; });\nmock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));\nmock('setInWindow', (path, value) => {\n  const parts = path.split('.'); const last = parts.pop();\n  parts.reduce((value, key) => value[key], globals)[last] = value;\n  return true;\n});\nconst stub = () => {\n  const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];\n  globals.thradTag = fn; return fn;\n};\nmock('createArgumentsQueue', stub);\nmock('callInWindow', (path, a, b, c) => {\n  if (path === 'setTimeout') { timers.push(a); return 1; }\n  globals.thradTag(a, b, c);\n});\nmock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));\nconst ready = () => { globals.thradTag.__thradTag = true; };\nconst update = (name, value) => { consent[name] = value; callbacks[name](name, value); };\nrunCode({ tagId: 'account-a', mode: 'event', eventType: 'purchase', orderId: '', value: 0, currency: 'USD' });\nrunCode({ tagId: 'account-a', mode: 'event', eventType: 'lead', eventId: 'lead:1', parameters: [{ key: 'event_id', value: 'replacement' }] });\nassertThat(failures).isEqualTo(2); assertThat(injections).hasLength(0);\nassertApi('createArgumentsQueue').wasNotCalled();"
  }
]

___NOTES___

Mocked template tests establish loader behavior, not Google permission enforcement, durable receipt or provider acceptance. Run the release checklist in a real GTM container before distribution.
