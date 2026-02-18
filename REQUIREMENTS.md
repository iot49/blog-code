# Blogging Website

* all code in this folder, `iot/blog`
* Free, ideally
* Using Astro
* Theme with following features:
    * Single author (for now)
    * Support for multiple topics:
        * blog (general thoughts, adventures - e.g. outings)
        * modelrailroad
        * software
        * ... (maybe others in the future)
    * Support for code, ideally live
        * jupyter notebooks
        * what other options are available?
    * Tags
    * Multilingual, ideally with auto-translation
    * e.g. https://themefisher.com/products/bookworm-light-astro
* Host on Cloudflare
    * setup entirely from CLI
    * ideally no need for Cloudflare GUI at all, except perhaps getting an API token
* DOMAIN: blog.boser-guyon.org
* Authentication & authorization
    * single sign-on (except public content, for which no sign-on is required)
    * using Cloudflare app (set up via CLI, not GUI)
    * support one-time email password and email lists
    * some way to protect posts with Cloudflare policies
        * E.g. posts hosted in some folder (say, `friends`) are accessible only to users with their email specified in the "friends" policy, etc.
        * host in folder `public` are accessible to all with no authentication required
* Host content in private github repo
* Local development server
* Push to github updates the public site on Cloudflare
    * means to exclude select posts from publishing, e.g. with an attribute "draft"
* Other
    * omissions?
    * better solutions?
    * are there any requested features that cannot be supported?

## Update Site Appearance

* icon: create a placeholder showing a mountain, e.g. Matterhorn
* Name: AstroWind -> Boser-Guyon
* Nav (top of page):
    * Blog: shows the blog list
    * Railroad: shows posts tagged railroad
    * About: A few words about me (create a dummy for now - where? - for me to edit)
* Keep the light/dark button
* Remove RSS button (what is it for?)
* Remove download button
* Remove the top bar indicating a new version of Astro is available
* Remove all content no longer needed, e.g. blog posts without the iso date in the file name