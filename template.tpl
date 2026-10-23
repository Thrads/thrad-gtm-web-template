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
    "type": "GROUP",
    "name": "eventSettings",
    "displayName": "Event settings",
    "groupStyle": "NO_ZIPPY",
    "enablingConditions": [
      {
        "paramName": "mode",
        "paramValue": "event",
        "type": "EQUALS"
      }
    ],
    "subParams": [
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
        "help": "Optional business fields: product_id, content_id, content_name, content_type, quantity, items, contents, cart_id, plan_id. Use dedicated fields for identity/value/currency. Customer identity and credentials are not supported."
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// GTM sandbox adapter to the existing browser SDK.
const copy = require('copyFromWindow');
const set = require('setInWindow');
const granted = require('isConsentGranted');
const listen = require('addConsentListener');
const call = require('callInWindow');
const later = require('callLater');
const now = require('getTimestampMillis');
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
    const match = raw.match('^(\\d+)(?:\\.(\\d+))?$');
    const fraction = match && match[2] || '';
    // Validate the SDK's hundredths range without converting the dispatched value.
    const amount = match ? makeNumber(match[1]) * 100 + makeNumber((fraction + '00').slice(0, 2)) +
      (makeNumber(fraction[2] || '0') >= 5 ? 1 : 0) : -1;
    const currency = typeof data.currency === 'string' ? data.currency.trim().toUpperCase() : '';
    if (!business.order_id || amount < 0 || amount > 9007199254740991 || !currency.match('^[A-Z]{3}$')) {
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
    if (!business.event_id || (eventType === 'custom' && (!eventName.match('^[A-Za-z0-9](?:[A-Za-z0-9_-]*[A-Za-z0-9])?$') ||
        eventName.length > 64 || purchaseNames.indexOf(eventName.split('-').join('_')) !== -1 || standardNames.indexOf(eventName) !== -1))) {
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
// The CDN entrypoint can itself load a versioned SDK. Its script onload is
// not SDK readiness. Reuse the same bounded wait for a loading manual snippet.
const waitForReady = () => {
  const deadline = now() + 10000;
  const check = () => {
    if (copy('thradTag.__thradTag') === true) return finish(true);
    if (now() >= deadline) return finish(false);
    later(check);
  };
  check();
};
if (existing) {
  // The manual snippet owns its script request. Never insert another SDK.
  waitForReady();
} else {
  inject('https://cdn.thrad.ai/tag.min.js',
    waitForReady,
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
                    "string": "thradTagGtmConsent"
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

scenarios:
- name: Concurrent loader preserves early payload and completes each firing once
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    runCode({ tagId: 'account-a', mode: 'event', eventType: 'lead', eventId: 'lead:1', parameters: [{ key: 'quantity', value: 0 }] });
    runCode({ tagId: 'account-b', mode: 'install' });
    assertThat(injections).hasLength(1);
    assertThat(injections[0].url).isEqualTo('https://cdn.thrad.ai/tag.min.js');
    assertApi('gtmOnSuccess').wasNotCalled();
    const event = globals.thradTag.q.filter((entry) => entry[0] === 'event')[0];
    assertThat(event[2]).isEqualTo({ event_id: 'lead:1', quantity: 0, send_to: 'account-a' });
    assertThat(globals.thradTag.q.filter((entry) => entry[0] === 'event' && entry[1] === 'page_viewed')).hasLength(0);
    injections[0].success();
    assertApi('gtmOnSuccess').wasNotCalled();
    ready(); timers.shift()(); injections[0].success();
    assertApi('gtmOnSuccess').wasCalled(); assertApi('gtmOnFailure').wasNotCalled();
- name: Ready manual SDK is reused without a new script or page view
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    stub(); ready();
    runCode({ tagId: 'account-a' });
    assertThat(injections).hasLength(0); assertApi('gtmOnSuccess').wasCalled();
    assertThat(globals.thradTag.q.filter((entry) => entry[0] === 'event')).hasLength(0);
- name: Pending manual queue is preserved while waiting for readiness
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    stub(); globals.thradTag('event', 'page_viewed', { send_to: 'manual' });
    runCode({ tagId: 'account-a' });
    assertThat(injections).hasLength(0); assertApi('gtmOnSuccess').wasNotCalled();
    assertThat(globals.thradTag.q[0]).isEqualTo(['event', 'page_viewed', { send_to: 'manual' }]);
    ready(); timers.shift()();
    assertApi('gtmOnSuccess').wasCalled();
- name: SDK load failure completes every waiter once
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    runCode({ tagId: 'account-a' }); runCode({ tagId: 'account-b' });
    injections[0].failure(); injections[0].failure(); injections[0].success();
    assertApi('gtmOnFailure').wasCalled(); assertApi('gtmOnSuccess').wasNotCalled();
- name: Invalid Tag ID fails before SDK or global access
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    runCode({ tagId: '   ' });
    assertApi('gtmOnFailure').wasCalled(); assertThat(injections).hasLength(0);
    assertApi('createArgumentsQueue').wasNotCalled();
- name: Denial prevents loading and grant resumes installation without event replay
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    consent.ad_storage = false;
    runCode({ tagId: 'account-a' });
    runCode({ tagId: 'account-a', mode: 'event', eventType: 'purchase', orderId: 'order-1', value: 0, currency: 'USD' });
    assertThat(injections).hasLength(0);
    assertThat(globals.thradTagGtmConsent.measurement).isFalse();
    update('ad_storage', true);
    assertThat(injections).hasLength(1);
    assertThat(globals.thradTag.q.filter((entry) => entry[0] === 'event')).hasLength(0);
    ready(); injections[0].success();
    assertApi('gtmOnSuccess').wasCalled();
- name: Withdrawal removes pending tracking and preserves personalization denial
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    consent.ad_personalization = false;
    runCode({ tagId: 'account-a', mode: 'event', eventType: 'lead', eventId: 'lead:1' });
    assertThat(globals.thradTagGtmConsent.personalization).isFalse();
    update('analytics_storage', false); update('analytics_storage', true);
    assertThat(globals.thradTagGtmConsent.revision).isEqualTo(1);
    assertThat(globals.thradTag.q.filter((entry) => entry[0] === 'event')).hasLength(0);
    ready(); injections[0].success();
    assertApi('gtmOnSuccess').wasCalled();
- name: Script callback without SDK readiness is failure rather than receipt proof
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    runCode({ tagId: 'account-a' }); injections[0].success();
    while (timers.length) timers.shift()();
    assertApi('gtmOnFailure').wasCalled(); assertApi('gtmOnSuccess').wasNotCalled();
- name: Purchase form keeps zero and order identity in the conversion command
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    runCode({ tagId: 'account-a', mode: 'event', eventType: 'purchase', orderId: 123, value: 0, currency: 'usd' });
    const call = globals.thradTag.q.filter((entry) => entry[0] === 'conversion')[0];
    assertThat(call[1]).isEqualTo({ order_id: '123', value: 0, currency: 'USD', send_to: 'account-a' });
    ready(); injections[0].success(); assertApi('gtmOnSuccess').wasCalled();
- name: Lead form keeps submission identity without an order
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    runCode({ tagId: 'account-a', mode: 'event', eventType: 'lead', eventId: 'lead:1' });
    const call = globals.thradTag.q.filter((entry) => entry[0] === 'event')[0];
    assertThat(call[1]).isEqualTo('lead_created');
    assertThat(call[2]).isEqualTo({ event_id: 'lead:1', send_to: 'account-a' });
- name: Custom form preserves the supported custom name and identity
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    runCode({ tagId: 'account-a', mode: 'event', eventType: 'custom', customEventName: 'Quote-Requested', customEventId: 'quote:1' });
    const call = globals.thradTag.q.filter((entry) => entry[0] === 'event')[0];
    assertThat(call[1]).isEqualTo('quote-requested');
    assertThat(call[2]).isEqualTo({ event_id: 'quote:1', send_to: 'account-a' });
- name: Invalid business fields and parameter collisions never dispatch
  code: |-
    const globals = {};
    const memory = {};
    const callbacks = {};
    const consent = {};
    const timers = []; let clock = 0;
    mock('getTimestampMillis', () => clock);
    mock('callLater', (callback) => timers.push(() => { clock += 100; callback(); }));
    const injections = [];


    mockObject('templateStorage', {
      getItem: (key) => memory[key], setItem: (key, value) => { memory[key] = value; }
    });
    mock('isConsentGranted', (name) => consent[name] !== false);
    mock('addConsentListener', (name, callback) => { callbacks[name] = callback; });
    mock('copyFromWindow', (path) => path.split('.').reduce((value, key) => value && value[key], globals));
    mock('setInWindow', (path, value) => {
      const parts = path.split('.'); const last = parts.pop();
      parts.reduce((value, key) => value[key], globals)[last] = value;
      return true;
    });
    const stub = () => {
      const fn = (a, b, c) => fn.q.push([a, b, c]); fn.q = [];
      globals.thradTag = fn; return fn;
    };
    mock('createArgumentsQueue', stub);
    mock('callInWindow', (path, a, b, c) => {
      globals.thradTag(a, b, c);
    });
    mock('injectScript', (url, success, failure) => injections.push({ url: url, success: success, failure: failure }));
    const ready = () => { globals.thradTag.__thradTag = true; };
    const update = (name, value) => { consent[name] = value; callbacks[name](name, value); };
    runCode({ tagId: 'account-a', mode: 'event', eventType: 'purchase', orderId: '', value: 0, currency: 'USD' });
    runCode({ tagId: 'account-a', mode: 'event', eventType: 'lead', eventId: 'lead:1', parameters: [{ key: 'event_id', value: 'replacement' }] });
    assertApi('gtmOnFailure').wasCalled(); assertThat(injections).hasLength(0);
    assertApi('createArgumentsQueue').wasNotCalled();
    runCode({ tagId: 'account-a', mode: 'event', eventType: 'purchase', orderId: 'order-1', value: '1.2.3', currency: 'USD' });
    runCode({ tagId: 'account-a', mode: 'event', eventType: 'purchase', orderId: 'order-1', value: 0, currency: 'US1' });
    ['-bad', 'bad!', 'purchase-completed'].forEach((name) => runCode({ tagId: 'account-a', mode: 'event', eventType: 'custom', customEventId: 'custom:1', customEventName: name }));
    assertApi('createArgumentsQueue').wasNotCalled();
    assertThat(injections).hasLength(0);


___NOTES___

Mocked template tests establish loader behavior, not Google permission enforcement, durable receipt or provider acceptance. Run the release checklist in a real GTM container before distribution.


