enum ResourceCategory {
  all('All Resources'),
  programDocuments('Program Documents'),
  templates('Templates'),
  worksheets('Worksheets'),
  studyMaterials('Study Materials'),
  mentorMaterials('Mentor Materials');

  final String displayName;
  const ResourceCategory(this.displayName);

  static ResourceCategory fromString(String category) {
    return ResourceCategory.values.firstWhere(
      (e) => e.displayName == category,
      orElse: () => ResourceCategory.all,
    );
  }
}