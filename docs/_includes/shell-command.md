{% capture command_id %}{{ include.command }}{% endcapture %}

{% capture shell_content %}{% include shell/{{ command_id }}.txt %}{% endcapture %}
{% capture command %}{{ shell_content | newline_to_br | strip_newlines | split: '<br />' | first }}{% endcapture %}

<button id="{{ command_id }}" class="copy-btn">
  Copy to clipboard
</button>

<script language="javascript">
  var copyBtn = document.getElementById("{{ command_id }}");
  copyBtn.setAttribute("data-clipboard-text", "{{ command }}");
  var clipboard = new Clipboard(copyBtn);
</script>

{% highlight shell %}
$ {{ shell_content }}
{% endhighlight %}
