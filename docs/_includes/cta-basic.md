{% assign section = site.data.cta[include.id] %}

<div class="card">

  <span class="card-type">
    {{ section.type }}      
  </span>

  <h2 class="card-heading">
    {{ section.title }}      
  </h2>

  {% if section.text-secondary %}
    <p class="card-secondary">{{ section.text-secondary }}</p>
  {% endif %}

  {% if section.text %}
    <p class="card-content">{{ section.text }}</p>
  {% endif %}

  <div class="btn-wrap">
    {% for link in section.link %}
      <a class="conjur-btn {{ link[1].class }}" href="{{ link[1].url }}" {% if link[1].target %}target="{{ link[1].target }}"{% endif %}>{{ link[1].button-text }}</a>
    {% endfor %}
  </div>

</div><!-- /.card .hero -->
