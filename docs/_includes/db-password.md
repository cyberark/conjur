{% highlight shell %}
$ password=$(openssl rand -hex 12)
$ echo $password
ac8932bccf835a5a13586100
$ conjur variable values add db/password $password
Value added
$ conjur variable value db/password
ac8932bccf835a5a13586100
{% endhighlight %}
