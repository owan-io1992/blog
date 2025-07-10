# Website

This website is built using [hugo](https://gohugo.io), Hugo is one of the most popular open-source static site generators. With its amazing speed and flexibility, Hugo makes building websites fun again.  

theme source [LoveIt](https://github.com/sulrich/LoveIt)  

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
hugo new content content/posts/20250704_k8s-doc-reading-taint-and-toleration/index.md
```

## Build

```bash
hugo
```

This command generates static content into the `build` directory and can be served using any static contents hosting service.


# upgrade theme 

update folder `themes/LoveIt`  
copy `themes/LoveIt/layouts/robots.txt` "Algolia-Crawler-Verif" to new robots.txt  

# mermaid icon 

use CDN by https://www.jsdelivr.com  
icons from https://icones.js.org/  

update file `themes/LoveIt/layouts/baseof.html:67` 

# banner prompt

```
give me 'The Terminator' style 
about terminate k8s Node
with text:Cluster Administration - Node Shutdowns
```


hextra