// lib/screens/rounds_of_match_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:box_sensors/services/riverpod_imports.dart';
import 'package:box_sensors/services/database_helper.dart';
import 'package:box_sensors/services/providers.dart';
import 'package:box_sensors/widgets/display_row.dart';
import 'package:box_sensors/widgets/match_data_table.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:box_sensors/utils/device_config.dart';
import 'package:box_sensors/models/sensor_data.dart';

class RoundsOfMatchScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> match;
  final String eventId;

  const RoundsOfMatchScreen({
    super.key,
    required this.match,
    required this.eventId,
  });

  @override
  ConsumerState<RoundsOfMatchScreen> createState() =>
      _RoundsOfMatchScreenState();
}

class _RoundsOfMatchScreenState extends ConsumerState<RoundsOfMatchScreen> {
  static const int _messagePageSize = 200;

  late final DatabaseHelper dbHelper;
  List<Map<String, dynamic>> roundsList = [];
  Map<String, dynamic>? selectedRound;
  List<SensorData> _sensorDataList = [];
  Map<String, int> _punchCounts = {
    DeviceConfig.blueBoxer: 0,
    DeviceConfig.redBoxer: 0,
  };
  int _totalMessageCount = 0;
  int? _oldestMessageId;
  int _messageLoadGeneration = 0;
  bool _isLoadingMessages = true;
  bool _isLoadingMoreMessages = false;
  bool _hasMoreMessages = false;

  @override
  void initState() {
    super.initState();
    dbHelper = ref.read(databaseHelperProvider);
    unawaited(_loadRounds());
  }

  void _captureSentryException(Object error, {StackTrace? stackTrace}) {
    if (!Sentry.isEnabled) return;
    Sentry.captureException(error, stackTrace: stackTrace);
  }

  Future<void> _loadRounds() async {
    final generation = ++_messageLoadGeneration;
    try {
      final allRounds = await dbHelper.fetchRounds();
      if (!mounted || generation != _messageLoadGeneration) return;
      final filtered =
          allRounds
              .where(
                (r) =>
                    r['matchId'] == widget.match['id'] &&
                    r['eventId'] == widget.eventId,
              )
              .toList()
            ..sort((a, b) => (a['round'] as int).compareTo(b['round'] as int));

      if (filtered.isEmpty) {
        setState(() {
          roundsList = [];
          selectedRound = null;
          _sensorDataList = [];
          _punchCounts = {DeviceConfig.blueBoxer: 0, DeviceConfig.redBoxer: 0};
          _totalMessageCount = 0;
          _oldestMessageId = null;
          _isLoadingMessages = false;
          _isLoadingMoreMessages = false;
          _hasMoreMessages = false;
        });
        return;
      }

      setState(() => roundsList = filtered);
      await _loadMessagesForRound(filtered.first);
    } catch (e, stackTrace) {
      _captureSentryException(e, stackTrace: stackTrace);
      if (!mounted || generation != _messageLoadGeneration) return;
      setState(() {
        roundsList = [];
        selectedRound = null;
        _sensorDataList = [];
        _punchCounts = {DeviceConfig.blueBoxer: 0, DeviceConfig.redBoxer: 0};
        _totalMessageCount = 0;
        _oldestMessageId = null;
        _isLoadingMessages = false;
        _isLoadingMoreMessages = false;
        _hasMoreMessages = false;
      });
    }
  }

  Future<void> _loadMessagesForRound(Map<String, dynamic> round) async {
    final generation = ++_messageLoadGeneration;
    final roundId = round['id'] as int;

    setState(() {
      selectedRound = round;
      _sensorDataList = [];
      _punchCounts = {DeviceConfig.blueBoxer: 0, DeviceConfig.redBoxer: 0};
      _totalMessageCount = 0;
      _oldestMessageId = null;
      _isLoadingMessages = true;
      _isLoadingMoreMessages = false;
      _hasMoreMessages = false;
    });

    try {
      final pageFuture = dbHelper.fetchMessagesPageByRoundId(
        roundId,
        limit: _messagePageSize,
      );
      final countsFuture = dbHelper.getRoundPunchCounts(roundId);
      final totalFuture = dbHelper.getMessageCountByRoundId(roundId);

      final page = await pageFuture;
      final counts = await countsFuture;
      final total = await totalFuture;
      if (!mounted || generation != _messageLoadGeneration) return;

      setState(() {
        _sensorDataList = page.reversed
            .map(SensorData.fromMap)
            .toList(growable: true);
        _punchCounts = counts;
        _totalMessageCount = total;
        _oldestMessageId = page.isEmpty ? null : page.last['id'] as int;
        _isLoadingMessages = false;
        _hasMoreMessages = page.length < total;
      });
    } catch (e, stackTrace) {
      _captureSentryException(e, stackTrace: stackTrace);
      if (!mounted || generation != _messageLoadGeneration) return;
      setState(() {
        _sensorDataList = [];
        _totalMessageCount = 0;
        _oldestMessageId = null;
        _isLoadingMessages = false;
        _hasMoreMessages = false;
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    final round = selectedRound;
    final beforeId = _oldestMessageId;
    if (round == null ||
        beforeId == null ||
        _isLoadingMessages ||
        _isLoadingMoreMessages ||
        !_hasMoreMessages) {
      return;
    }

    final generation = _messageLoadGeneration;
    setState(() => _isLoadingMoreMessages = true);

    try {
      final page = await dbHelper.fetchMessagesPageByRoundId(
        round['id'] as int,
        limit: _messagePageSize,
        beforeId: beforeId,
      );
      if (!mounted || generation != _messageLoadGeneration) return;

      final olderRows = page.reversed
          .map(SensorData.fromMap)
          .toList(growable: false);
      setState(() {
        _sensorDataList.insertAll(0, olderRows);
        _oldestMessageId = page.isEmpty ? beforeId : page.last['id'] as int;
        _isLoadingMoreMessages = false;
        _hasMoreMessages =
            page.isNotEmpty && _sensorDataList.length < _totalMessageCount;
      });
    } catch (e, stackTrace) {
      _captureSentryException(e, stackTrace: stackTrace);
      if (!mounted || generation != _messageLoadGeneration) return;
      setState(() => _isLoadingMoreMessages = false);
    }
  }

  bool _handleMessageScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical &&
        notification.metrics.extentAfter < 400) {
      unawaited(_loadMoreMessages());
    }
    return false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tableWidth = screenWidth * 0.95 < 350.0 ? 350.0 : screenWidth * 0.95;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            DisplayRow(
              title: 'Game Rounds',
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
                  onPressed: _loadRounds,
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            DisplayRow(
              fontSize: 14,
              title: 'Rounds for ${widget.match['matchName']}',
            ),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: roundsList.length,
                itemBuilder: (context, index) {
                  final round = roundsList[index];
                  final isSelected = selectedRound?['id'] == round['id'];
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        foregroundColor: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                      onPressed: () {
                        unawaited(_loadMessagesForRound(round));
                      },
                      child: Text(
                        'Round ${round['round']}',
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: _isLoadingMessages
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        DisplayRow(
                          fontSize: 14,
                          title:
                              'Punches ➜ '
                              'BlueBoxer: ${_punchCounts[DeviceConfig.blueBoxer] ?? 0} - '
                              'RedBoxer: ${_punchCounts[DeviceConfig.redBoxer] ?? 0}',
                        ),
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: _handleMessageScroll,
                            child: MatchDataTable(
                              rows: _sensorDataList,
                              tableWidthProvider: () => tableWidth,
                            ),
                          ),
                        ),
                        if (_isLoadingMoreMessages)
                          const LinearProgressIndicator(minHeight: 2),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
