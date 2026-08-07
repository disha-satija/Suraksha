import 'package:flutter/foundation.dart';
import '../models/safe_spot.dart';
import '../models/safe_spot_verification.dart';
import '../models/safe_spot_submission.dart';
import '../repositories/contribute_repository.dart';

/// One yes/no prompt about a specific safe spot.
class ContributeQuestion {
  final SafeSpot spot;
  final String text;

  const ContributeQuestion({required this.spot, required this.text});

  String get spotId => spot.id;
}

/// Drives the Contribute screen — picks unverified nearby spots, asks short
/// yes/no questions about them, and records the answers.
class ContributeViewModel extends ChangeNotifier {
  final ContributeRepository _repo;

  ContributeViewModel({required ContributeRepository repo}) : _repo = repo;

  /// Never ask more than this many questions in one sitting.
  static const int maxQuestions = 2;

  List<ContributeQuestion> _questions = [];
  int _answeredCount = 0;
  bool _isLoading = true;
  bool _hasNearbySpots = false;
  final Set<String> _answeredSpotIds = {};
  List<SafeSpotSubmission> _mySubmissions = [];

  List<ContributeQuestion> get questions => _questions;
  int get answeredCount => _answeredCount;
  bool get isLoading => _isLoading;
  bool get isComplete => !_isLoading && _answeredCount >= _questions.length;

  /// This device's own suggested safe places, newest first.
  List<SafeSpotSubmission> get mySubmissions => _mySubmissions;

  /// Whether any nearby spots existed at all, regardless of whether they were
  /// already answered — distinguishes "nothing nearby" from "already helped
  /// with everything nearby" in the empty state.
  bool get hasNearbySpots => _hasNearbySpots;

  /// Build the question list from spots the user hasn't answered about recently.
  Future<void> loadQuestions(List<SafeSpot> nearbySpots) async {
    _isLoading = true;
    _answeredCount = 0;
    _answeredSpotIds.clear();
    notifyListeners();

    final alreadyVerified = await _repo.recentlyVerifiedSpotIds();
    final candidates = nearbySpots
        .where((s) => !alreadyVerified.contains(s.id))
        .take(maxQuestions)
        .toList();

    _hasNearbySpots = nearbySpots.isNotEmpty;
    _questions = [
      for (var i = 0; i < candidates.length; i++)
        ContributeQuestion(
          spot: candidates[i],
          // Alternate the two templates so consecutive cards differ.
          text: i.isEven
              ? 'Is ${candidates[i].name} well-lit at night?'
              : 'Is ${candidates[i].name} still open and operating?',
        ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  /// Record a yes/no answer and advance the progress counter.
  ///
  /// Deduping here (rather than in the view) protects against a fast
  /// double-tap writing two rows and pushing [answeredCount] past
  /// [questions.length] — the widget's own answered-set updates a frame late.
  Future<void> answer(ContributeQuestion question, bool value) async {
    if (!_answeredSpotIds.add(question.spotId)) return;

    _answeredCount++;
    notifyListeners();

    try {
      await _repo.submitVerification(
        SafeSpotVerification(
          localId:
              '${question.spotId}-${DateTime.now().microsecondsSinceEpoch}',
          spotId: question.spotId,
          spotName: question.spot.name,
          question: question.text,
          answer: value,
          answeredAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // The repository already persists the answer locally (outbox write)
      // before any remote sync, so the answer is not lost — just not yet
      // synced. Nothing further to do here.
    }
  }

  /// Submit a user-suggested safe place. The row is persisted locally by the
  /// repository before any remote sync is attempted, so a failure here never
  /// loses the suggestion — just leaves it pending sync.
  Future<void> submitSafeSpot(SafeSpotSubmission submission) async {
    try {
      await _repo.submitSafeSpot(submission);
    } catch (_) {
      // Already persisted locally — nothing further to do here.
    }
    notifyListeners();
  }

  /// Refresh this device's own suggestion history.
  Future<void> loadMySubmissions() async {
    _mySubmissions = await _repo.mySubmissions();
    notifyListeners();
  }
}
