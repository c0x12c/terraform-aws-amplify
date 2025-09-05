# Changelog

All notable changes to this project will be documented in this file.

## [1.1.1]() (2025-09-05)

### Features

* Add Slack message threading for deployment notifications.

## [1.1.0]() (2025-09-05)

### Features

* Enhanced Slack notification Lambda function to show proper Amplify app name instead of app ID.
* Removed Job ID and Status fields from Slack notifications for cleaner messaging.
* Added GitHub commit subject display in notifications.
* Added associated domain name display for Amplify apps.
* Updated Lambda function to use AWS SDK v3 for better Amplify API integration.

## [1.0.2]() (2025-09-04)

### Features

* Add outputs for Amplify app ID

## [1.0.1]() (2025-07-03)

### Features

* Add `enable_auto_build` to handle flag for enabled auto build or not, in case we don't want production to auto build from master.

## [1.0.0]() (2025-07-03)

### Features

* Add `enabled_notification` to enable notification which send messages through webhook to Slack
* Add `slack_webhook_url` add slack webhook which will handle messages

## [0.1.22]() (2024-12-05)

### Features

* Add `var.enable_backend` to enable backend or use frontend format only
* Add `aws_amplify_webhook` to provides an Amplify Webhook resource

## [0.1.4]() (2024-12-05)

### Features

* Update terraform version constraint from `~> 1.9.8` to `>= 1.9.8`

## [0.1.0]() (2024-11-06)

### Features

* Initial commit with all the code
