{% capture policy_name %}{{ include.policy }}{% endcapture %}
{% assign yaml_file = site.data.policies[policy_name] %}

{% highlight yaml %}
{{ yaml_file }}
{% endhighlight %}