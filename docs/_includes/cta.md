{% assign section = site.data.cta[include.id] %}

<div class="col-md-6">
  <div class="cta-box">
    <div class="cta-box-header">{{ section.title }}</div>

    <ul class="cta-links list-unstyled">
      {% for link in section.links %}
        <li class="link">
          {% if link[1].icon %}{{ link[1].icon }}{% endif %}          
          {% if link[1].content %}
            {{ link[1].content }}
          {% else %}
            <a href="{{ link[1].path }}" {% if link[1].target %}target="{{ link[1].target }}"{% endif %}>{{ link[1].title }}</a>
          {% endif %}          
        </li>
      {% endfor %}
    </ul>

  </div>
</div>
