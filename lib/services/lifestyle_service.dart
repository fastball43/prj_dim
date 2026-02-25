import '../core/algorithms/lifestyle_scoring.dart';
import '../core/database/lifestyle_dao.dart';
import '../core/database/profile_dao.dart';
import '../data/app_database.dart';

class LifestyleService {
  Future<double> saveCheckin({
    required LifestyleInput input,
    required UserProfile profile,
  }) async {
    final subScores = computeSubScores(input);
    final modifier = computeBaselineModifier(
      age: profile.age,
      familyHistory: profile.familyHistory,
      educationYears: profile.educationYears ?? 12,
    );
    final score =
        lifestyleScore(subScores: subScores, baselineModifier: modifier);

    final subScoresNamed = <String, double>{
      'sleep': subScores[0] ?? 0,
      'exercise': subScores[1] ?? 0,
      'diet': subScores[2] ?? 0,
      'social': subScores[3] ?? 0,
      'cognitiveStim': subScores[4] ?? 0,
      'vascular': subScores[5] ?? 0,
      'substance': subScores[6] ?? 0,
      'hearing': subScores[7] ?? 0,
    };

    final checkin = LifestyleCheckin(
      checkedAt: DateTime.now(),
      sleepHours: input.sleepHours,
      sleepQuality: input.sleepQuality,
      exerciseDays: input.exerciseDays,
      exerciseMinutes: input.exerciseMinutes,
      dietScore: input.dietCheckedItems,
      socialFreq: input.socialFreqCode,
      cognitiveStimFreq: input.cognitiveStimFreqCode,
      systolicBp: input.systolicBp,
      hearingDifficulty: input.hearingDifficulty,
      alcoholFreq: input.alcoholFreq,
      isSmoker: input.isSmoker,
      subScores: subScoresNamed,
      lifestyleScore: score,
      baselineModifier: modifier,
    );

    final db = await AppDatabase.instance;
    await LifestyleDao(db).insertCheckin(checkin);
    return score;
  }

  Future<LifestyleCheckin?> getLatestCheckin() async {
    final db = await AppDatabase.instance;
    return LifestyleDao(db).getLatestCheckin();
  }
}
