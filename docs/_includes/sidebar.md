{% assign section = site.data.sidebar.main[include.section] %}

<ul class="sidebar-nav list-unstyled">
  <li class="section">
    <a href="{{ section.path }}">{{ section.title }}</a>
  <li>

  {% for item in section.items %}
    <li class="item"><a href="{{ item[1].path }}">{{ item[1].title }}</a></li>
  {% endfor %}
</ul>

{% if section %}
<hr/>
{% endif %}

<ul class="sidebar-nav list-unstyled">
  <li class="item"><a href="https://www.cyberark.com/products/privileged-account-security-solution/cyberark-conjur/" target="_blank">CyberArk Conjur Enterprise</a></li>
  <li class="item"><a href="https://github.com/cyberark/conjur/blob/master/CONTRIBUTING.md">Contributing</a></li>
  <li class="item"><a href="/support.html">Support</a></li>
</ul>

<hr/>

<ul class="sidebar-nav list-unstyled">
  <li class="item"><a id=”side-nav-button-github” class="event-click" href="https://github.com/cyberark/conjur" target="_blank"><i class="fa fa-github-alt"></i> GitHub</a></li>
  <li class="item"><a id=”side-nav-button-dockerhub” class=“event-click” href="https://hub.docker.com/r/cyberark/conjur/" target="_blank"><div class="icon-docker-hub"></div> DockerHub</a></li>
  <li class="item coming-soon"><a id=”side-nav-button-cloud-formation” class=“event-click” href="#"><i class="fa fa-cloud"></i> Cloud Formation <span>(Coming Soon)</span></a></li>
  <li class="item"><a id=”side-nav-button-slack” class=“event-click” href="https://slackin-conjur.herokuapp.com/" target="_blank"><i class="fa fa-slack"></i> Slack</a></li>
</ul>
