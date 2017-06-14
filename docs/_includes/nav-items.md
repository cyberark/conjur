<ul>
{% for item_hash in include.items %}
{% assign item = item_hash[1] %}
<li>
    {% if item.path %}
        <a href="{{ site.baseurl }}{{ item.path }}">{{ item.title }}</a>
    {% else %}
        {{ item.title }}
    {% endif %}
</li>
{% endfor %}
</ul>
