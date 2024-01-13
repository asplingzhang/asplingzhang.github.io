---
layout: default
title:  "Support GA4(google analytics) with github pages"
date:   2024-01-13 12:31:33 +0800
categories: jekyll
---

# Abstract
Make **GA4**(new kind of google analytics,instead of old **UA**) working with github pages.

# Resolution for supporting GA4
Since `Google Analytics(Universal Analytics)` is no longer supported by Google until 2023.7.1,so we need find a way to support GA4.
## Current Problems
* Jeklly only support google analytics of **UA**
* `Google Analytics(Universal Analytics)` is no longer supported by Google until 2023.7.1.

## New way to support GA4(Include gtag.js in each article mannually.)
* Add a new file under `_includes` directory,named `google-analytics.html`.Code below is copied from `Google Analytics`,nothing has been modifed,including tracing-id like `G-xxxx`.that's fine here.
```html
<!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-your-id"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-your-id');
</script>
```
* Update the default layout file `_layouts/default.html` to include the `_includes/google_analytics.html` in its default template.It's recommended that `{\% include google-analytics.html \%}` followd the `<head>`.
![add_it_followed_head_immediately](/image/add_it_followed_head_immediately.jpg)
**Note:** if you do not know your default layout default.html,you can get them from github.For example,I use **cayman** template,and I could get the default.html form [cayman github repo](https://github.com/pages-themes/cayman/blob/master/_layouts/default.html).
* Republished our sit
* Check that if the `google_analytics.html` was included correctly.
If it was included correctly,you will see these codes in your souce code.Entrance is `View->Developer->View Source`.
```html
 <!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-your-id"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-your-id');
</script>
```



