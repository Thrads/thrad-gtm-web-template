# Thrad for Google Tag Manager

Use the Thrad **web** template to install the browser SDK and map existing
purchase, lead and custom events from your website's data layer. It does not
instrument forms or checkout, install GTM, or connect a server-side container.
You need access to the website's web container, its consent manager (CMP),
and the current Tag ID in **Thrad → Attribution → Setup → Google Tag Manager**.
Both the initial setup prompt and the persistent Setup tab reach this flow.

## Pilot release

Use [v0.1.0-pilot.2](https://github.com/Thrads/thrad-gtm-web-template/releases/tag/v0.1.0-pilot.2):
[template.tpl](https://github.com/Thrads/thrad-gtm-web-template/releases/download/v0.1.0-pilot.2/template.tpl),
[SHA256SUMS](https://github.com/Thrads/thrad-gtm-web-template/releases/download/v0.1.0-pilot.2/SHA256SUMS),
and [acceptance record](https://github.com/Thrads/thrad-gtm-web-template/releases/download/v0.1.0-pilot.2/acceptance.md).
The template SHA-256 is `2a91b552385452f1cd67c069ebb57b3f4c09c75b572802db0db67c17175c365d`.
Download the template and checksum into one directory, then run:

```sh
shasum -a 256 -c SHA256SUMS
```

This pilot is **not listed in the Community Template Gallery** and is not
approval for broad rollout. Import it from the download above. If a Gallery
listing becomes available, use only the verified listing linked by Thrad;
do not substitute a similarly named template or broaden permissions to fix an error.

The template loads `https://cdn.thrad.ai/tag.min.js`. This mutable URL currently
serves the consent-compatible SDK identified in the release acceptance record.
The template download does not pin or deploy the SDK. Real GTM Preview,
durable receipt and destination acceptance are separate rollout gates;
editor tests and a successful import do not prove them.

## 1. Import and install

1. Export a container backup and record its published version. Use a dedicated
   workspace and preserve unrelated changes.
2. In **Templates → Tag Templates → New**, open the editor menu and choose
   **Import**. Select the downloaded `template.tpl`. Inspect Info, Fields, Code,
   Permissions and Tests. Run all 12 embedded tests, then save.
3. Create a new tag using **Thrad**. Choose **Mode: Install tag** and paste the
   current account's **Tag ID**. Do not use a GTM container ID (`GTM-…`), an
   advertiser name, a pixel ID or a server credential.
4. Set the site's CMP defaults first using its supported consent template on
   **Consent Initialization – All Pages**. Then trigger the Thrad Install tag
   on **Initialization – All Pages**, or the earliest sitewide event after
   those defaults. The SDK handles the initial page view; do not add a second
   page-view event tag.
5. Keep one Thrad base installation. Follow the migration section before
   enabling this alongside a direct snippet or Custom HTML tag.

The only injectable SDK URL is the fixed CDN URL above. The template reads
four consent types, shares the SDK queue/ready state across tag instances,
and waits up to 10 seconds for a loading manual SDK. It does not grant consent.

## 2. Set up consent

Configure explicit defaults for `ad_storage`, `analytics_storage`,
`ad_user_data` and `ad_personalization` before any Thrad tag can execute.
Use the CMP's supported GTM consent integration, including changes on grant
and withdrawal. Do not put a `gtag('consent', …)` command in a Custom HTML tag
and assume it runs before the next GTM event.

| Visitor choice | Thrad behavior |
| --- | --- |
| Any of ad_storage, analytics_storage or ad_user_data denied | Measurement is blocked; events attempted in this state are discarded. |
| All three granted | Installation may resume; new eligible events can be sent. Previously denied events are not replayed. |
| ad_personalization denied | Measurement can remain allowed, but personalization is disabled. |
| Consent withdrawn | Pending tracking is invalidated; already-sent requests cannot be recalled. Re-grant does not authorize old events to replay. |

GTM considers an **unset** consent type granted. Never use unset state as
consent. Do not enable an option that overrides consent, such as **Always fire**.
The adapter needs to execute to register its consent listeners even when its
own checks suppress measurement. If you add GTM Additional Consent Checks that
block the entire tag, ensure your CMP's post-grant event also triggers the
Install tag; a tag that never ran cannot register a listener. Preview the actual
configuration rather than assuming grant will restart it.

## 3. Map a purchase

Use a **completed** purchase event, not a checkout click. This isolated example
is a GA4-style data-layer shape; the event is `purchase`, with its fields in
`ecommerce`. Reuse an existing equivalent event instead of pushing it again.
Run example values only on an isolated test page; never paste them into a live
advertiser page or browser console that can send production conversions.

```javascript
window.dataLayer = window.dataLayer || [];
window.dataLayer.push({ ecommerce: null });
window.dataLayer.push({
  event: 'purchase',
  ecommerce: {
    transaction_id: 'test-order-1001',
    value: 25.99,
    currency: 'USD',
    items: [{ item_id: 'test-sku-1', item_name: 'Test item', quantity: 1, price: 25.99 }]
  }
});
```

Create **Data Layer Variable** variables with **Data Layer Version 2**. Use
these exact paths for the example; labels such as DLV are your variable names.
In a new Thrad tag, set **Mode: Send event**, **Event: Purchase**, and the same
**Tag ID** as the Install tag. Map:

| Template field | GTM variable | Data layer path |
| --- | --- | --- |
| Order ID | `{{DLV - Order ID}}` | `ecommerce.transaction_id` |
| Order value | `{{DLV - Order value}}` | `ecommerce.value` |
| Currency | `{{DLV - Currency}}` | `ecommerce.currency` |

Use a **Custom Event** trigger with event name exactly `purchase` (not a
regular expression) for this tag. If your site emits another name or nests its
fields under `ecommerce.purchase`, map that actual event and field shape instead;
GTM does not translate names or reshape objects automatically. Inspect values
on the selected purchase event in Preview, not only on a later page-load event.

The template dispatches `conversion` with `order_id`, `value` and `currency`;
the SDK submits canonical `order_created`. Value is in **major** currency units
(`25.99`, not `2599`); zero is valid and missing/negative value is invalid.
Currency must have three letters. Use the stable merchant order ID and retain
it on retries. Large numeric order IDs must be strings to avoid precision loss.
Changing the Tag ID or order ID changes purchase identity. A generic Event ID
does not replace Order ID.

## 4. Map a lead or custom event

Emit an event only after the application confirms a successful submission.
A generic form-submit or button-click trigger can run for failed validation.
Use an opaque submission ID with no email address or customer details:

```javascript
window.dataLayer = window.dataLayer || [];
window.dataLayer.push({
  event: 'thrad_lead_success',
  thrad_lead: { event_id: 'test-lead-submission-1001' }
});
```

Create a Version 2 Data Layer Variable and a Thrad tag with **Mode: Send event**,
**Event: Lead**, and the same **Tag ID**:

| Template field | GTM variable | Data layer path |
| --- | --- | --- |
| Event ID | `{{DLV - Lead event ID}}` | `thrad_lead.event_id` |

Use a **Custom Event** trigger named exactly `thrad_lead_success`.
Thrad sends `lead_created` with the mapped `event_id`. Reuse that ID when the
same submission is retried and use a different ID for a different submission.
Do not invent an order ID, order value or currency for a lead.

For **Event: Custom**, map a supported **Custom event name** and a stable
**Event ID** for that completed business event. Standard names and purchase
aliases are not custom events. Existing account configuration controls custom
event eligibility and destination mapping; creating a GTM tag creates no
provider mapping. For example, a lead forwarded to OpenAI requires the existing
`lead_created` mapping. Ask Thrad to check configuration if it is unavailable.

Optional Event parameters are `product_id`, `content_id`, `content_name`,
`content_type`, `quantity`, `items`, `contents`, `cart_id` and `plan_id`.
Map existing business values only. Leave missing variables unmapped. Dedicated
identity/target/value/currency fields cannot be overridden here. Never pass
credentials, email addresses, phone numbers or customer identity in the table.

## 5. Preview, publish and verify separately

1. Open GTM **Preview** on the controlled test site. Confirm the Install tag,
   resolved Tag ID, conversion trigger and variable values. Test initial denial,
   grant, withdrawal and failed SDK loading; denied events must not replay.
2. Inspect the SDK and config requests in browser Network. A blocked SDK or
   malformed event is an installation/data problem. A success callback or a
   fired tag indicates local execution, not a stored or credited conversion.
3. After review, obtain the site's authorized owner's approval and publish the
   workspace version. Record the version ID. Do not publish unrelated changes.
4. In Thrad **Attribution → Setup**, use **Check your website setup** against the
   published page, then inspect **Status** for matching Tag ID/event receipt.
   The browser visit can detect dynamically injected GTM tags; it cannot
   complete your checkout or submit your forms for you.
5. Verify durable event receipt and configured destination delivery separately.
   An HTTP response, queue dispatch, provider acknowledgment and credited
   conversion are different outcomes. Provider acknowledgment does not promise
   conversion credit.

A correctly installed SDK can load and fire locally without submitting an
attributed conversion. With no supported Thrad click or OpenAI referral context,
organic lead/custom events and purchases can be suppressed by existing
attribution rules. Do not fabricate a click/signature or reference to make a
production test pass. Use an approved controlled attribution flow and inspect
account measurement/custom-event configuration with Thrad. A missing order ID,
invalid value/currency or an invalid signed claim is a different problem from
absent attribution context.

## Existing installations and Custom HTML fallback

For a native-template migration, inventory direct snippets, Custom HTML base
and event tags, plugin/pixel integrations, and server purchase producers.
Preview the replacement in a dedicated workspace; disable/remove only the
installation you are replacing in the same reviewed publication. Keep one
base loader and one producer per intended event. Sharing an SDK request does
not deduplicate every business callback. Preserve order/submission identities;
server/browser purchase deduplication must use the existing canonical contract.

Direct installation remains available under **Website code** in Thrad Setup.
If template import is unavailable and you need the existing **Custom HTML**
fallback, copy that complete manual snippet into a GTM Custom HTML tag using
the same Tag ID. Wire it to your site's approved CMP lifecycle before enabling
it. GTM Additional Consent Checks can gate a future firing, but do **not** stop
an already-loaded manual SDK on withdrawal. Custom HTML does not inherit this
template's consent listeners, discarded-event behavior or pending-work guards.
Your site developer must implement and verify the manual SDK's consent updates
and withdrawal behavior; do not assume it is equivalent to the native adapter.
If that integration is not available, keep this fallback disabled and use the
native template or complete the CMP integration with Thrad. Never add a second
manual loader as a workaround for a failed SDK request.

## Troubleshooting

| Symptom | Check and action |
| --- | --- |
| Download/import fails | Use the exact release above and verify the checksum. Confirm this is a web container. Run all embedded tests; do not expand permissions. |
| SDK blocked or fails | Check ad blockers, CSP `script-src`, CDN/immutable SDK responses and `connect-src` for the configured event endpoint. Request only the required fixed hosts from your site owner; do not disable CSP globally. Refresh after fixing a failed load or a manual stub that did not become ready within 10 seconds. |
| Tag does not fire | Check trigger event name/case, exceptions, consent/default timing and whether GTM exists on that page. Check the selected Preview event. |
| Purchase/lead variables undefined | Inspect the data layer at the completed business event. Match actual nesting, Version 2 variables and field types. Ask the site developer to emit missing data; the template cannot manufacture it. |
| Invalid order/submission | Use a stable non-empty order/submission ID, major-unit non-negative value and three-letter currency for purchases. Do not use purchase fields for a lead or a new random ID on every retry. |
| Consent shows Not set, or nothing resumes on grant | Set explicit CMP defaults before Thrad. Inspect Additional Consent Checks and the CMP's post-grant trigger; distinguish suppressed events from an Install tag that never executed. |
| Fired in Preview but no receipt | Check publication, Tag ID, event validity, consent, SDK/config/transport requests and attribution context. Check Thrad Status; local firing is not persistence evidence. |
| Receipt but no destination conversion | Inspect account measurement configuration, event mapping, destination acceptance/errors and attribution eligibility. Provider credit requires its own evidence. |
| Duplicate events | Check direct+GTM overlap, repeated event pushes, duplicate triggers and multiple integrations. Reuse stable identities and remove the extra producer after review. |
| Hosted checkout has no GTM | A storefront tag cannot read another checkout sandbox/domain. Use that platform's supported checkout integration or the server-events path; do not claim coverage from a storefront page view. |

## Rollback and updates

Keep the prior template/checksum, container export and live version ID. Preview
updates in an isolated workspace first. Discard only your unpublished changes
or restore the previous tested template. For a live rollback, inspect intervening
edits before restoring and publishing a prior container version; it can revert
unrelated work. Obtain the site owner's approval, then repeat Preview and receipt
checks. Restoring a template does not change the live container or roll back the
separately loaded mutable CDN SDK. Escalate SDK compatibility failures to Thrad.

## References, support and license

Google documents [data-layer ecommerce events](https://developers.google.com/analytics/devguides/collection/ga4/ecommerce?client_type=gtm),
[consent APIs](https://developers.google.com/tag-platform/tag-manager/templates/consent-apis)
and [unset consent / listeners](https://developers.google.com/tag-platform/tag-manager/templates/api#addConsentListener).
These describe GTM behavior; Thrad's field and attribution requirements above
are the contract for this adapter.

Report defects in this repository's Issues with the release version, GTM error
and redacted reproduction steps. Do not post tokens, customer information or
private container exports. Thrad maintains the adapter and SDK compatibility;
the site owner maintains GTM triggers, data layer and CMP.

Copyright 2026 Thrad. The adapter and documentation in this distribution are
licensed under Apache 2.0; see `LICENSE`. The separately loaded Thrad SDK and
service are not included or licensed by this repository.
