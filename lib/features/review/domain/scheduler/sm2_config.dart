class Sm2Config {
  final List<Duration> learningSteps;
  final List<Duration> relearningSteps;
  final int graduatingIntervalDays;
  final int easyIntervalDays;
  final double startingEase;
  final double minEase;
  final double hardIntervalMultiplier;
  final double easyBonusMultiplier;
  final double againEaseDelta;
  final double hardEaseDelta;
  final double easyEaseDelta;
  final double lapseIntervalMultiplier;
  final int minimumIntervalDays;
  final int maxIntervalDays;

  const Sm2Config({
    this.learningSteps = const [Duration(minutes: 1), Duration(minutes: 10)],
    this.relearningSteps = const [Duration(minutes: 10)],
    this.graduatingIntervalDays = 1,
    this.easyIntervalDays = 4,
    this.startingEase = 2.5,
    this.minEase = 1.3,
    this.hardIntervalMultiplier = 1.2,
    this.easyBonusMultiplier = 1.3,
    this.againEaseDelta = -0.20,
    this.hardEaseDelta = -0.15,
    this.easyEaseDelta = 0.15,
    this.lapseIntervalMultiplier = 0.0,
    this.minimumIntervalDays = 1,
    this.maxIntervalDays = 36500,
  });
}
