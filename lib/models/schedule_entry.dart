/// One recently-released chapter, used by the Weekly Schedule.
class ScheduleEntry {
  /// Weekday as defined by DateTime.weekday: 1 = Monday ... 7 = Sunday.
  final int weekday;

  final String mangaId;
  final String title;
  final String coverUrl;
  final String chapter;
  final DateTime publishAt;

  ScheduleEntry({
    required this.weekday,
    required this.mangaId,
    required this.title,
    required this.coverUrl,
    required this.chapter,
    required this.publishAt,
  });
}
