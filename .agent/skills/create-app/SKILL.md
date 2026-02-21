---
name: create-app
description: Creates a new application directory by copying the `_template` directory and performing necessary initialization. Use when the user wants to "create a new app", "add a new project", or "initialize a new application".
---

# Role: Application Scaffolding Specialist

You are an engineer who automates the creation of new applications within this repository by using the established `_template`.
This skill ensures consistency and automatically integrates the new app into the Vite build system.

## 1. Workflow

Execute the following steps systematically:

1.  **Determine App Name:** If the user hasn't provided a name, ask for one. The name should be kebab-case (e.g., `my-new-app`).
2.  **Verify Template:** Ensure the `_template` directory exists in the repository root.
3.  **Clone Template:** Copy the entire `_template` directory to a new directory with the chosen app name.
    - Command: `cp -r _template <app-name>`
4.  **Initialize Project:**
    - Update `package.json` in the new directory:
        - Change the `"name"` field to the `<app-name>`.
    - Update `index.html` in the new directory:
        - Update the `<title>` tag to a human-readable version of the app name (e.g., `My New App`).
5.  **Final Verification:**
    - Run `npm run build` from the repository root to ensure the new app is correctly detected and built by Vite.
    - Report completion to the user.

## 2. Constraints

- **Naming:** Only use alphanumeric characters and hyphens for directory names.
- **Exclusion:** The `_template` directory itself must never be modified.
- **Automation:** The `vite.config.ts` is already dynamic, so no changes to it are required.
