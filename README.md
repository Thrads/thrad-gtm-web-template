# Thrad for Google Tag Manager

The Thrad web template installs the existing Thrad browser SDK and sends
purchase, lead and custom events using GTM variables.

## Pilot status

This repository distributes the web adapter only. A pilot release is **not a
Community Template Gallery listing** or approval for broad rollout. Check the
release acceptance record before using an artifact. Do not use a candidate
whose real GTM import/tests or deployed SDK compatibility are unverified.

The SDK is loaded from `https://cdn.thrad.ai/tag.min.js`. Its URL is mutable;
the release record identifies the exact SDK build tested. A compatible deployed
SDK must support the `thradTagGtmConsent` bridge. A template download does not
deploy or pin that SDK.

## Install in a controlled web container

1. Download `template.tpl` and `SHA256SUMS` from the same versioned release.
   Run `shasum -a 256 -c SHA256SUMS` beside the downloaded template.
2. Export a backup of your container and record its current published version.
   Use a dedicated workspace; do not overwrite unrelated changes.
3. Under **Templates → Tag Templates → New**, open the editor menu and import
   `template.tpl`. Inspect Info, Fields, Code, Permissions and Tests. Run all
   embedded tests and save the template. Never grant broader permissions to
   work around an error; report it to Thrad.
4. Create a tag using the template. Select **Install tag** and enter the Tag ID
   from your Thrad advertiser account. Use an early sitewide trigger after your
   CMP has set consent defaults. The SDK handles the initial page view.
5. Create separate **Send event** tag instances for completed business events.
   Map existing GTM variables using the table below. An existing data layer is
   required; this template does not instrument your checkout or forms.
6. Preview on the controlled site. Check the resolved fields, trigger timing,
   consent, duplicate installations and SDK network failures. Publish only after
   the site's authorized owner approves the reviewed workspace changes.
7. Verify event receipt in Thrad, then configured destination delivery separately.
   A fired tag or success callback proves neither a recorded nor credited
   conversion. Organic traffic may lack attribution context.

| Event | Required fields | Trigger |
| --- | --- | --- |
| Purchase | Stable order ID, major-unit value, three-letter currency | Completed purchase |
| Lead | Stable event ID for the completed submission | Successful lead submission |
| Custom | Supported custom event name and stable event ID | Completed business event |

Purchase dispatches the SDK conversion command (canonical `order_created`). Lead
uses `lead_created`. Zero purchase value is valid; missing value is not. Use
strings for large order IDs to avoid numeric precision loss. Reuse identities
for retries and use new identities for different orders/submissions. Do not
invent order IDs for leads. Existing platform configuration controls forwarding.

Optional business parameters are `product_id`, `content_id`, `content_name`,
`content_type`, `quantity`, `items`, `contents`, `cart_id` and `plan_id`. Reserved
identity, target, value and currency fields cannot be overridden. Do not pass
credentials or customer identity in these fields.

## Consent and permissions

The template reads `ad_storage`, `analytics_storage`, `ad_user_data` and
`ad_personalization`; it never grants consent or changes CMP defaults.
Measurement requires the first three; personalization also requires the fourth.
GTM treats unset consent as granted, so configure explicit defaults before firing.
Denied events are discarded. A later grant resumes installation, not past events.
Withdrawal invalidates pending tracking; requests already sent cannot be recalled.

Permissions are limited to the fixed SDK URL, template storage, the SDK queue,
readiness markers, consent bridge and timer needed to reuse a loading manual
installation. Avoid a duplicate direct installation. A manual loader is allowed
10 seconds to become ready; refresh after resolving a failed load before retrying.

## Rollback and updates

Keep the previous tested template download, checksum, container export and live
version ID. Preview updates in an isolated workspace first. To abandon an
unpublished change, discard only the changes you own or re-import the previous
tested template. To roll back a publication, inspect intervening edits before
restoring and publishing a prior container version: doing so can revert unrelated
work. Obtain the site owner's approval and repeat Preview and receipt checks.
Restoring a template alone does not change the live container or roll back the
SDK served at the CDN URL. Escalate an incompatible SDK release to Thrad.

## Support and license

Report adapter defects in this repository's Issues. Include the release version,
GTM error and redacted reproduction steps. Do not post credentials, tokens,
customer information or private container exports. Thrad maintains the adapter
and its SDK compatibility; the site owner maintains triggers, data layer and CMP.

Copyright 2026 Thrad. The adapter and documentation in this distribution are
licensed under Apache 2.0; see `LICENSE`. The separately loaded Thrad SDK and
service are not included or licensed by this repository.
