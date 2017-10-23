{% assign section = site.data.cta[include.id] %}

  <div class="card hero">

      <h2 class="card-heading">
        {{ section.title }}      
      </h2>

      {% if section.text %}
        <p class="card-content">{{ section.text }}</p>
      {% endif %}

      <div class="btn-wrap">
        {% for link in section.links %}
          <a class="conjur-btn {{ link[1].class }}" href="{{ link[1].path }}" {% if link[1].target %}target="{{ link[1].target }}"{% endif %}>{{ link[1].title }}</a>
        {% endfor %}
      </div>

  </div><!-- /.card .hero -->
