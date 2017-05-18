{% assign yaml_file = site.data.policies[include.policy] %}

{% highlight yaml %}
{{ yaml_file }}
{% endhighlight %}
