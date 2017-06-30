{% capture command_name %}{{ include.command }}{% endcapture %}

{% capture command_file %}shell/{{ command_name }}-cmd.txt{% endcapture %}
{% capture output_file %}shell/{{ command_name }}-out.txt{% endcapture %}

{% capture shell_cmd_raw %}{% include {{ command_file }} %}{% endcapture %}
{% capture shell_cmd %}{{ shell_cmd_raw | rstrip }}{% endcapture %}

{% include clipboard-copy-text-btn.html button_id=command_name text=shell_cmd %}

{% highlight shell %}
$ {{ shell_cmd }}
{% include {{ output_file }} %}
{% endhighlight %}
