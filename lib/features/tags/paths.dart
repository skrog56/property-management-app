const tagsPath = '/tags';

/// [query] carries the list's search to the next page, which draws the list
/// again beside the tag on a wide window.
String tagPath(String tagId, {String query = ''}) => Uri(
  path: '$tagsPath/$tagId',
  queryParameters: query.isEmpty ? null : {'q': query},
).toString();
