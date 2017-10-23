{% assign section = site.data.navigation.main[include.section] %}

<ul class="sidebar-nav list-unstyled">
  <li class="section">
    <a href="{{ section.path }}">{{ section.title }}</a>
  <li>

  {% for item in section.items %}
    <li class="item{% if item[1].items %} parent-item{% endif %}"><a href="{{ item[1].path }}">{{ item[1].title }}</a></li>
    {% for item in item[1].items %}
      <li class="item sub-item"><a href="{{ item[1].path }}">{{ item[1].title }}</a></li>
    {% endfor %}
  {% endfor %}
</ul>

{% if section %}
<hr/>
{% endif %}

<ul class="sidebar-nav list-unstyled">
  <li class="item"><a class="event-click" id="side-nav-button-enterprise" href="https://www.cyberark.com/products/privileged-account-security-solution/cyberark-conjur/" target="_blank">CyberArk Conjur Enterprise</a></li>
  <li class="item"><a href="https://github.com/cyberark/conjur/blob/master/CONTRIBUTING.md">Contributing</a></li>
  <li class="item"><a href="/support.html">Support</a></li>
</ul>

<ul class="sidebar-nav list-unstyled">
  <li class="item"><a id="side-nav-button-github" class="event-click" href="https://github.com/cyberark/conjur" target="_blank"><i class="fa fa-github-alt"></i> GitHub</a></li>
  <li class="item"><a id="side-nav-button-dockerhub" class="event-click" href="https://hub.docker.com/r/cyberark/conjur/" target="_blank"><div class="icon-docker-hub"></div> DockerHub</a></li>
  <li class="item"><a id="side-nav-button-cloud-formation" class="event-click" href="https://s3.amazonaws.com/conjur-ci-public/cloudformation/conjur-latest.yml"><i class="fa fa-cloud"></i> AWS CloudFormation</a></li>
  <li class="item"><a id="side-nav-button-slack" class="event-click" href="https://slackin-conjur.herokuapp.com/" target="_blank"><i class="fa fa-slack"></i> Slack</a></li>
</ul>

<!-- Webinar CTAs -->
<div class="cta-box-webinar">
  <p class="header">WEBINAR</p>
  <p class="description">Orchestrating Trust in Your DevOps Pipeline</p>
  <p class="date">October 26 / 11AM EST</p>
  <div class="link">
    <a href="https://pages.cloudbees.com/orchestratingtrust-devops-pipeline-webinar-registration" class="conjur-webinar-btn" target="_blank">Register</a>
  </div>
</div>

<div class="cta-box-webinar">
  <p class="header">WEBINAR</p>
  <p class="description">Delivering Infrastructure and Security Policy as Code with Puppet and CyberArk Conjur</p>
  <p class="date">November 8 / 11AM EST</p>
  <div class="link">
    <a href="https://www.cyberark.com/puppet-technical-partner-series/" class="conjur-webinar-btn" target="_blank">Register</a>
  </div>
</div>
