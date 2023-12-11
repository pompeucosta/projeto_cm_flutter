import 'package:hive/hive.dart';
import 'package:run_route/data/models/session_details.dart';

class RunningSessionDatabase {
  static const String boxName = "running_session";
  late Box<SessionDetails> sessionDetails;

  Future<void> init() async {
    Hive.registerAdapter<SessionDetails>(SessionDetailsAdapter());
    sessionDetails = await Hive.openBox<SessionDetails>(boxName);
  }

  Future<void> insertSession(SessionDetails details) async {
    await sessionDetails.add(details);
  }

  List<SessionDetails> getAllSessionsFromMostRecentToOlder() {
    final sessions = sessionDetails.values.toList();
    sessions.sort((a, b) {
      final dateA = DateTime(a.year, a.month, a.day);
      final dateB = DateTime(b.year, b.month, b.day);
      return dateA.compareTo(dateB);
    });

    return sessions;
  }
}
