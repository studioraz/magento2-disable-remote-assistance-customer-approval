# Magento 2 Disable Customer Remote Assistance Consent

A Magento 2 module that **bypasses the customer consent requirement for the Login As Customer (remote assistance) feature**, allowing admin users to log in as customers without requiring explicit customer opt-in.

---

## Overview

Magento's built-in [Login As Customer](https://experienceleague.adobe.com/docs/commerce-admin/customers/customer-accounts/manage/login-as-customer.html) feature requires customers to explicitly grant consent before an admin can log in as them. While this is suitable for many stores, some business workflows — such as internal support, QA testing, or B2B account management — require admins to assist customers without prior consent interaction.

This module removes that friction by disabling the consent check entirely, so the "Login As Customer" capability works seamlessly for all customers.

---

## Features

- **Disables the consent resolver** — nullifies the `is_allowed` resolver in `IsLoginAsCustomerEnabledForCustomerChain`, so Login As Customer is always permitted regardless of the customer's stored consent value.
- **Removes consent UI from the frontend** — hides the opt-in checkbox block (`login_as_customer_opt_in_create`) from both the customer registration and account edit pages, keeping the frontend clean.
- **Disables the customer data plugin** — turns off the `add_assistance_allowed_to_customer_data` plugin on the frontend to prevent consent state from being surfaced to the storefront JS.
- **Admin menu integration** — adds a dedicated menu entry under the SR Base admin menu for quick access to the module's configuration section (`sr_LoginAsCustomer`).
- **ACL protected** — the configuration resource is guarded by a dedicated ACL entry (`SR_DisableCustomerRemoteAssistanceConsent::config`).

---

## Requirements

| Dependency | Version |
|---|---|
| PHP | `>= 8.1` |
| `magento/framework` | `>= 103` |
| `studioraz/magento2-base` | `^1.0` |

---

## Installation

Install via Composer:

```bash
composer require studioraz/magento2-disable-customer-remote-assistance-consent
```

Then enable the module and run setup:

```bash
bin/magento module:enable SR_DisableCustomerRemoteAssistanceConsent
bin/magento setup:upgrade
bin/magento cache:flush
```

---

## How It Works

### 1. Consent check bypass (`src/etc/di.xml`)

The global DI configuration nullifies the `is_allowed` resolver used by `IsLoginAsCustomerEnabledForCustomerChain`:

```xml
<type name="Magento\LoginAsCustomerApi\Model\IsLoginAsCustomerEnabledForCustomerChain">
    <arguments>
        <argument name="resolvers" xsi:type="array">
            <item name="is_allowed" xsi:type="null"/>
        </argument>
    </arguments>
</type>
```

This means Login As Customer is **always available** for any customer, without checking stored consent.

### 2. Frontend consent UI removal (`src/view/frontend/layout/`)

The opt-in block is removed from both the registration and account-edit pages so customers never see a consent checkbox:

- `customer_account_create.xml` — removes `login_as_customer_opt_in_create`
- `customer_account_edit.xml` — removes `login_as_customer_opt_in_edit`

### 3. Customer data plugin disabled (`src/etc/frontend/di.xml`)

The plugin that exposes the consent flag to storefront JavaScript is disabled:

```xml
<type name="Magento\Customer\Model\CustomerExtractor">
    <plugin name="add_assistance_allowed_to_customer_data" disabled="true"/>
</type>
```

---

## Module Structure

```
src/
├── etc/
│   ├── acl.xml                     # ACL resource definition
│   ├── di.xml                      # Global: disables consent resolver
│   ├── module.xml                  # Module declaration
│   ├── adminhtml/
│   │   └── menu.xml                # Admin menu entry
│   └── frontend/
│       └── di.xml                  # Frontend: disables consent data plugin
├── view/
│   └── frontend/
│       └── layout/
│           ├── customer_account_create.xml   # Removes opt-in block on registration
│           └── customer_account_edit.xml     # Removes opt-in block on account edit
└── registration.php                # Module registration
```

---

## Support

- **Email:** [support@studioraz.co.il](mailto:support@studioraz.co.il)
- **Website:** [https://studioraz.co.il](https://studioraz.co.il)

---

## License

[MIT](LICENCE) © 2025 Studio Raz
