#### Text search

If the `search` parameter is provided, narrows results to those pertaining to
the search query. Search works across resource IDs and the values of
annotations. It weights results so that those with matching `id` or a matching
value of an annotation called `name` appear first, then those with another
matching annotation value, and finally those with a matching `kind`.
