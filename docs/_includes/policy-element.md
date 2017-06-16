{{ include.element.description }}

{% if include.element.attributes_description %}

#### Attributes

{% for attr in include.element.attributes_description %}
* **{{ attr[0] }}** {{attr[1]}}
{% endfor %}

{% endif %}

{% if include.element.privileges_description %}

#### Privileges

The following privileges are applied by the core API services and standard extension API services:

{% for attr in include.element.privileges_description %}
* **{{ attr[0] }}** {{attr[1]}}
{% endfor %}

{% endif %}

#### Example

{% highlight yaml %}
{{ include.element.example }}
{% endhighlight %}
