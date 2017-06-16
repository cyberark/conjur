{% assign item = site.data.toc[page.url][include.key] %}

{% if include.section %}
### {{ item.sections[include.section] }}
{% else %}
    {% if item.title %}
## {{ item.title }}
    {% else %}
## {{ item }}
    {% endif %}
{% endif %}
