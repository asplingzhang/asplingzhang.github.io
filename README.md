# WebRTC A/V Sync Deep Dive Documentation

This repository contains the source files for a GitHub Pages site explaining Audio/Video synchronization in WebRTC. The site is built using Jekyll and the `jekyll-theme-hacker`.

## Adding New Content

To add a new Markdown document to this site, follow these steps:

1.  **Place your Markdown file in the `/docs` directory.**
    *   Create your new content as a `.md` file (e.g., `my-new-page.md`).
    *   Place this file directly into the `/docs` directory. You can also create subdirectories within `/docs` to organize your content (e.g., `/docs/section/my-new-page.md`).

2.  **Add Jekyll Front Matter.**
    *   For your new Markdown file to be processed by Jekyll and rendered correctly with the site's theme, you **must** include "front matter" at the very beginning of the file.
    *   This is a block of YAML code between triple-dashed lines (`---`).
    *   Here is a minimal example:
        ```yaml
        ---
        layout: default
        title: Your Document Title
        ---
        ```
    *   Replace `"Your Document Title"` with the actual title you want for your page. This title will often appear in the browser tab and potentially within the page content depending on the theme.
    *   The `layout: default` line tells Jekyll to use the default layout provided by the theme (`jekyll-theme-hacker`), which ensures consistent styling.

3.  **Commit and Push Your Changes.**
    *   Add your new file to Git, commit your changes, and push them to the `main` branch of this repository.
    *   Example:
        ```bash
        git add docs/my-new-page.md
        git commit -m "Add new document: My New Page"
        git push origin main
        ```

4.  **Automatic Rebuild and Publish.**
    *   GitHub Pages will automatically detect the changes pushed to the `main` branch.
    *   It will rebuild the Jekyll site, incorporating your new document.
    *   After a short while (usually a minute or two), your new document should be live and accessible on the GitHub Pages site. The URL will typically correspond to the filename (e.g., `.../my-new-page.html` or `.../section/my-new-page.html` if you used a subdirectory).

That's it! Your new content will be part of the published site.
