# Website

This website is built using [hugo](https://gohugo.io), Hugo is one of the most popular open-source static site generators. With its amazing speed and flexibility, Hugo makes building websites fun again.  

theme source [hextra](https://imfing.github.io/hextra/)

## Installation

```bash
mise trust
mise install
```

## Local Development

```bash
hugo server --buildDrafts --disableFastRender
```

This command starts a local development server and opens up a browser window. Most changes are reflected live without having to restart the server.

## new post

```bash
hugo new content [path] [flags]

eg.
hugo new content content/docs/20251110_rke2_vs_k3s/index.md
```

## Build

```bash
hugo
```

This command generates static content into the `build` directory and can be served using any static contents hosting service.

# banner prompt

```
give me 'The Terminator' style 
about objects in kubernetes
with text:objects in kubernetes
```

