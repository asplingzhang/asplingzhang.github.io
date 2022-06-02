---
layout: default
title:  "Why google analytics not working with github pages"
date:   2022-06-02 13:31:33 +0800
categories: jekyll
---

# Abstract
Make google analytics working with github pages.
# Problems
No data reports showd at Google analytics,though these things has been done
* Create an account of GA and set up the flow of google analytics.
* Add a new file under `_includes` directory,named `google-analytics.html`.Code below is copied from `Google Analytics`,nothing has been modifed,including tracing-id like `G-xxxx`.that's fine here.
```html
<!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-HDGMRC9MQ1"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-HDGMRC9MQ1');
</script>
```
* Config `google_analytics` at `_config.yml`
```yml
google_analytics: UA-xxxxxx-x
```
* Republished our sit

# Resolution
* Change our account supporting `Google Analytics(Universal Analytics)`,`Google Analytics 4` is not supported by github pages powered by jekyll.Details please see [Set Google Universal Analytics for your site](https://support.google.com/analytics/answer/10269537)
* And set `google_analytics` with tracing-id started with `UA-` rather than `G-`,tracing-id like `G-xxxx` is of `Google Analytics 4`.

**NOTE:** `Google Analytics(Universal Analytics)` is no longer supported by Google until 2023.7.1

