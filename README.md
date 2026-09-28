# Website

This website is built using [docusaurus](https://docusaurus.io)

## Installation

```bash
mise trust
mise install
mise run install
```

## Quick Start (with mise tasks)

You can manage all tasks directly from the project root using `mise run`:

| Task | Command | Description |
| :--- | :--- | :--- |
| **Install** | `mise run install` | Install website dependencies |
| **Dev** | `mise run dev` | Start development server (supports flags, e.g. `mise run dev -- --locale en`) |
| **Build** | `mise run build` | Build static website for production |
| **Update** | `mise run update` | Update dependencies (`bun update && bun install`) |
| **i18n Extract** | `mise run i18n:extract -- [locale]` | Extract translation strings (defaults to `en`) |
| **i18n Copy** | `mise run i18n:copy-content` | Copy docs & blog content to `i18n/zh-Hant/` |

List all available tasks:
```bash
mise tasks
```

---

## Traditional Commands (Manual)

### Local Development

```bash
cd my-website
bun install
bun run start
```

### Build

```bash
cd my-website
bun run build
```
This command generates static content into the `build` directory and can be served using any static contents hosting service.

## Internationalization (i18n)

This website supports multiple locales. The source texts and translations are located under `my-website/i18n/`.

### 1. Translate React Code

Mark your custom React elements using the `@docusaurus/Translate` API:
- JSX components: `<Translate id="homepage.welcome">Welcome</Translate>`
- Inline strings: `translate({ id: 'homepage.title', message: 'Welcome' })`

### 2. Extract & Translate JSON files

Extract all marked strings from the codebase to the translation directory:

```bash
# Using mise:
mise run i18n:extract -- en

# Or manually:
cd my-website
bun run write-translations -- --locale en
```

This generates `i18n/<locale>/code.json` and theme configs under `i18n/<locale>/...`. Update the `message` fields in these JSON files.

### 3. Translate Markdown Content

Copy the Markdown files from `docs/`, `blog/`, or `src/pages/` to their respective translation folders:

```bash
# Using mise:
mise run i18n:copy-content

# Or manually:
cd my-website
mkdir -p i18n/zh-Hant/docusaurus-plugin-content-docs/current
cp -r docs/. i18n/zh-Hant/docusaurus-plugin-content-docs/current

mkdir -p i18n/zh-Hant/docusaurus-plugin-content-blog
cp -r blog/. i18n/zh-Hant/docusaurus-plugin-content-blog
```

Then edit the copied Markdown files.

### 4. Preview and Build

To run the local development server for a specific locale:

```bash
# Using mise:
mise run dev -- --locale en

# Or manually:
cd my-website
bun run start -- --locale en
```

Building the website with `mise run build` (or `bun run build`) will build all configured locales automatically.

## Update Docusaurus

```bash
# Using mise:
mise run update

# Or manually:
cd my-website
bun update
bun install
```

# banner prompt

```
give me 'The Terminator' style 
about objects in kubernetes
with text:objects in kubernetes
```

