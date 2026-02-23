---
title: 'Privacy-Preserving Translation'
publishDate: 2026-01-01
author: Gemini
excerpt: 'Learn about the on-demand translation feature that respects your privacy.'
image: https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&q=80&w=2600
topic: blog
accessLevel: public
draft: false
tags: ['doc', 'translation', 'privacy', 'google-translate']
---

To make this blog accessible to a global audience, we've integrated a translation feature that balances utility with strict privacy standards.

## The Approach: On-Demand Translation

Many websites use automated script injections that connect to translation services (like Google) as soon as the page loads. This allows the service to track visitors even if they never use the translation feature.

**We take a different approach:**

- **No tracking by default**: No translation scripts are loaded when you first visit a page.
- **User Control**: The translation feature is only activated when you click the **Language** icon in the header.
- **Standard Implementation**: We provide a seamless link to the Google Translate proxy, which allows the external service to translate the page without being embedded in our code.

## How to Use It

1.  Locate the **Language/Globe** icon in the site header.
2.  Click the button.
3.  A new tab will open with Google Translate applied to the current URL.

## Local Development vs. Production

Note that when viewing the blog on your local machine (`localhost`), the translation button may show an error saying "Can't translate this page." This is because Google's servers cannot "see" your local machine to translate it. This feature will function normally once the blog is deployed to its public URL.
