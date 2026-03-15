/// Last-Write-Wins conflict resolution utility.
///
/// Used by sync adapters to decide whether an incoming server record should
/// overwrite the locally stored copy. Financial records (orders, sessions) are
/// NOT subject to LWW — the server is authoritative on pull and local pending
/// records (syncStatus == pending) are never overwritten by pulls.
bool shouldOverwrite(DateTime? existingUpdatedAt, DateTime? incomingUpdatedAt) {
  if (existingUpdatedAt == null) return true;
  if (incomingUpdatedAt == null) return false;
  return incomingUpdatedAt.isAfter(existingUpdatedAt);
}
