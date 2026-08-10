import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends StatefulWidget {
  final Widget child;

  const ConnectivityService({
    super.key,
    required this.child,
  });

  @override
  State<ConnectivityService> createState() =>
      _ConnectivityServiceState();
}

class _ConnectivityServiceState
    extends State<ConnectivityService> {
  bool _isOffline = false;
  bool _showBackOnline = false;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();

    _checkConnection();

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_updateConnection);
  }

  Future<void> _checkConnection() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnection(result);
  }

  void _updateConnection(List<ConnectivityResult> result) {
    final offline =
        result.isEmpty ||
            result.every(
                  (r) => r == ConnectivityResult.none,
            );

    if (!mounted) return;

    if (offline) {
      setState(() {
        _isOffline = true;
        _showBackOnline = false;
      });
    } else if (_isOffline) {
      setState(() {
        _isOffline = false;
        _showBackOnline = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showBackOnline = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        if (_isOffline || _showBackOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: _isOffline
                    ? Colors.red.shade700
                    : Colors.green.shade700,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isOffline
                            ? Icons.wifi_off
                            : Icons.wifi,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isOffline
                            ? 'No Internet Connection'
                            : 'Back Online',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}