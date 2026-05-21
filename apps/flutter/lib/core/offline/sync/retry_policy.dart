class RetryPolicy {
  static const int maxBackoffSeconds = 1800;

  Duration nextBackoff(int retryCount) {
    int seconds;
    if (retryCount <= 0) {
      seconds = 1;
    } else if (retryCount >= 11) {
      seconds = maxBackoffSeconds;
    } else {
      seconds = 1 << retryCount;
    }
    return Duration(seconds: seconds);
  }
}
