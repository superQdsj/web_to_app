import 'package:flutter/foundation.dart';

/// A simple store to manage the active forum state.
class NgaForumStore {
  NgaForumStore._();

  /// The currently active forum ID (fid).
  /// Defaults to null (no active forum selected).
  static final ValueNotifier<int?> activeFid = ValueNotifier<int?>(null);

  /// Update the active forum ID.
  static void setActiveFid(int fid) {
    if (activeFid.value != fid) {
      activeFid.value = fid;
    }
  }
}
