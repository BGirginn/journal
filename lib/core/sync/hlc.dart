import 'dart:math';

/// Hybrid Logical Clock (HLC)
///
/// Combines physical time with a logical counter to provide a total ordering of events
/// across distributed systems, while keeping close to physical time.
///
/// Structure: `millis:counter:nodeId`
class Hlc implements Comparable<Hlc> {
  final int millis;
  final int counter;
  final String nodeId;

  const Hlc(this.millis, this.counter, this.nodeId);

  /// Create an HLC representing the current wall time (counter=0).
  factory Hlc.now(String nodeId) {
    return Hlc(DateTime.now().millisecondsSinceEpoch, 0, nodeId);
  }

  /// Create an HLC from a formatted string "millis:counter:nodeId".
  factory Hlc.parse(String timestamp) {
    try {
      final parts = timestamp.split(':');
      if (parts.length != 3) {
        throw FormatException('Invalid HLC format: $timestamp');
      }
      return Hlc(int.parse(parts[0]), int.parse(parts[1]), parts[2]);
    } catch (e) {
      throw FormatException('Invalid HLC format: $timestamp');
    }
  }

  /// Parse or return null on error
  static Hlc? tryParse(String? timestamp) {
    if (timestamp == null) return null;
    try {
      return Hlc.parse(timestamp);
    } catch (_) {
      return null;
    }
  }

  /// Generates a new HLC for a local event.
  ///
  /// Maintains the property: next.millis >= prev.millis && next > prev
  Hlc send(int wallTimeMillis) {
    // If wall time has progressed, reset counter.
    // Else (if wall time is same or backwards), increment counter.
    final millisPhysical = wallTimeMillis;

    if (millisPhysical > millis) {
      return Hlc(millisPhysical, 0, nodeId);
    } else {
      return Hlc(millis, counter + 1, nodeId);
    }
  }

  /// Updates the local HLC upon receiving a remote HLC.
  ///
  /// Ensures local clock catches up to remote clock if needed.
  Hlc receive(Hlc remote, int wallTimeMillis) {
    final millisPhysical = wallTimeMillis;

    // We must be greater than both local(this), remote, and physical time.
    final millisMax = max(max(millis, remote.millis), millisPhysical);

    if (millisMax == millis && millis == remote.millis) {
      // Tie on millis, increment max counter
      return Hlc(millisMax, max(counter, remote.counter) + 1, nodeId);
    } else if (millisMax == millis) {
      // Local is ahead (or same millis but local counter higher? handled above)
      // Actually strictly: if new millis is same as old local, increment.
      return Hlc(millisMax, counter + 1, nodeId);
    } else if (millisMax == remote.millis) {
      // Remote is ahead
      return Hlc(millisMax, remote.counter + 1, nodeId);
    } else {
      // Physical time is ahead
      return Hlc(millisMax, 0, nodeId);
    }
  }

  @override
  String toString() => '$millis:${counter.toString().padLeft(4, '0')}:$nodeId';

  @override
  int compareTo(Hlc other) {
    if (millis != other.millis) {
      return millis.compareTo(other.millis);
    }
    if (counter != other.counter) {
      return counter.compareTo(other.counter);
    }
    return nodeId.compareTo(other.nodeId);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hlc &&
          runtimeType == other.runtimeType &&
          millis == other.millis &&
          counter == other.counter &&
          nodeId == other.nodeId;

  @override
  int get hashCode => millis.hashCode ^ counter.hashCode ^ nodeId.hashCode;

  bool operator <(Hlc other) => compareTo(other) < 0;
  bool operator <=(Hlc other) => compareTo(other) <= 0;
  bool operator >(Hlc other) => compareTo(other) > 0;
  bool operator >=(Hlc other) => compareTo(other) >= 0;
}
