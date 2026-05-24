# Website

This website is built using [docusaurus](https://docusaurus.io)

## Installation

```bash
mise trust
mise install
```

## Local Development

```bash
cd my-website
bun install
bun run start
```


## Build

```bash
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
cd my-website
# Extract strings for a specific locale (e.g., zh-Hant)
bun run write-translations -- --locale en
```

This generates `i18n/<locale>/code.json` and theme configs under `i18n/<locale>/...`. Update the `message` fields in these JSON files.

### 3. Translate Markdown Content

Copy the Markdown files from `docs/`, `blog/`, or `src/pages/` to their respective translation folders:

```bash
cd my-website
# Translate docs
mkdir -p i18n/zh-Hant/docusaurus-plugin-content-docs/current
cp -r docs/. i18n/zh-Hant/docusaurus-plugin-content-docs/current

# Translate blog posts
mkdir -p i18n/zh-Hant/docusaurus-plugin-content-blog
cp -r blog/. i18n/zh-Hant/docusaurus-plugin-content-blog
```

Then edit the copied Markdown files.

### 4. Preview and Build

To run the local development server for a specific locale:

```bash
cd my-website
bun run start -- --locale en
```

Building the website with `bun run build` will build all configured locales automatically.

## update docusaurus
```
bun update
bun install
```

# banner prompt

```
give me 'The Terminator' style 
about objects in kubernetes
with text:objects in kubernetes
```

