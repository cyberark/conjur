{% capture policy_name %}{{ include.policy }}{% endcapture %}
{% assign yaml_file = site.data.policies[policy_name] %}

{% include clipboard-copy-element-btn.html target_id=policy_name %}

<div id='{{ policy_name }}'>
{% highlight yaml %}
{{ yaml_file }}
{% endhighlight %}
</div>
