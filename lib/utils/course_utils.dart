List<Map<String, dynamic>> filterCourses({
  required List<Map<String, dynamic>> allCourses,
  required String topicKey,
  required String levelKey,
  required String searchQuery,
}) {
  return allCourses.where((course) {
    final matchTopic = topicKey == 'all' || course['topic'] == topicKey;
    final matchLevel = levelKey == 'all' || course['level'] == levelKey;
    final matchSearch = searchQuery.isEmpty ||
        course['title'].toLowerCase().contains(searchQuery.toLowerCase());
    return matchTopic && matchLevel && matchSearch;
  }).toList();
}
