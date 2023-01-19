# Default Jekyll Structure

Conjur uses Jekyll for its static websites, including documentation and informational sites. This document is meant to outline the default structure and naming conventions for a Conjur Jekyll implementation so developers and designers can hit the ground quickly when editing an existing static site or creating a new one.

## Directory Structure

Jekyll has a default directory structure [outlined in its documentation](https://jekyllrb.com/docs/structure/) which we use as a starting point.

The main directories to keep in mind are:

|Directory|Description|Filetype|Notes|
|---|---|---|---|
| `./_data`|Contains files that house most of the static "data" the site uses.|`.yml`|Default structure.|
| `./_deploy`|A custom directory containing scripts for development and deployment.|Various|Conjur custom.|
|`./_site`|Static site generator output viewing and/or publishing.|Various|Default structure. Ignored by source. Consider these to be read-only.|
|`./_includes`|Contains partials and snippets used for page templates and content.|`.md`|Default structure. Page-specific includes should go into sub-folders named appropriately.|
|`./_includes/page-layout`|HTML structure includes used for modular page layout.|`.html`| |
|`./_includes/partials`|HTML snippets used repeatedly.|`.html`| |
|`./_layouts`|HTML templates for different page displays and display formats.|`.html`|Default structure.|
|`./_plugins`|Directory for custom or 3rd-party Jekyll plugins.|`.rb`|Default structure. Optional.|
|`./_sass`|SASS partials to be included in site generation.|`.scss`|Default structure.|
|`css`|Statically hosted and served CSS files that are not SCSS.|One single main `.scss` file and other `.css` files.|Custom. Copied verbatim.|
|`fonts`|Statically hosted and served font files.|Various.|Custom. Copied verbatim.|
|`img`|Statically hosted and served images.|Various|Custom. Copied verbatim.|
|`javascript`|Statically hosted and served JS files.|`.js`|Custom. Copied verbatim.|

Other files and folders that live within the root directory where Jekyll is configured to check for source will be run through the generator. For more information, see Jeykll's documentation on [Creating Pages](https://jekyllrb.com/docs/pages/).


## Best Practices

- **Custom directories** that should be excluded from site generation (i.e. `_deploy`) should be prepended with an underscore.
- **Custom files** that should be excluded from site generation should be added to the `_config.yml` file using the _exclude_ syntax as shown in the [Jekyll docs here](https://jekyllrb.com/docs/configuration/).
- Static HTML files should use the extension `.html`.  Files that will be processed into HTML files for the final site should use the extension `.md`.
- Partials or includes used in generated files should be prepended with an underscore (i.e. `_webservice.md`).
- File names should be spaced out using hyphens (`-`) so the final URL structure is sound and consistent.

## More Info

There is a lot of documentation, including other site structure examples, on the [Jeykll documentation site](https://jekyllrb.com/docs/).  When in doubt, go with the best practices and/or standards outlined in those docs.
