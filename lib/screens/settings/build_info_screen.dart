import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../config/app_config.dart';
import '../../config/supabase_config.dart';
import '../../config/theme.dart';

/// Build Info screen - accessible in ALL builds (not debug-only)
/// Shows critical configuration status to prevent shipping misconfigured builds
class BuildInfoScreen extends StatefulWidget {
  const BuildInfoScreen({super.key});

  @override
  State<BuildInfoScreen> createState() => _BuildInfoScreenState();
}

class _BuildInfoScreenState extends State<BuildInfoScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMapbox = AppConfig.isMapboxConfigured;
    final hasSupabaseUrl = SupabaseConfig.url.isNotEmpty;
    final hasSupabaseAnon = SupabaseConfig.anonKey.isNotEmpty;
    final isAuthenticated = SupabaseConfig.isAuthenticated;

    // Count critical issues
    final criticalIssues = [
      !hasMapbox,
      !hasSupabaseUrl,
      !hasSupabaseAnon,
    ].where((issue) => issue).length;

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Build Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: () => _copyToClipboard(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: criticalIssues > 0
                    ? DCTheme.error.withValues(alpha: 0.1)
                    : DCTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: criticalIssues > 0
                      ? DCTheme.error.withValues(alpha: 0.3)
                      : DCTheme.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    criticalIssues > 0 ? Icons.warning : Icons.check_circle,
                    color: criticalIssues > 0 ? DCTheme.error : DCTheme.success,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      criticalIssues > 0
                          ? '$criticalIssues critical configuration issue${criticalIssues > 1 ? 's' : ''}'
                          : 'All systems configured',
                      style: TextStyle(
                        color: criticalIssues > 0
                            ? DCTheme.error
                            : DCTheme.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Info Section
            _buildSectionHeader('App Version'),
            _buildInfoCard([
              _InfoRow(
                label: 'Version',
                value: _packageInfo?.version ?? 'Loading...',
                status: _InfoStatus.neutral,
              ),
              _InfoRow(
                label: 'Build Number',
                value: _packageInfo?.buildNumber ?? 'Loading...',
                status: _InfoStatus.neutral,
              ),
              _InfoRow(
                label: 'Package Name',
                value: _packageInfo?.packageName ?? 'Loading...',
                status: _InfoStatus.neutral,
              ),
            ]),
            const SizedBox(height: 24),

            // Configuration Status Section
            _buildSectionHeader('Configuration Status'),
            _buildInfoCard([
              _InfoRow(
                label: 'Mapbox Token',
                value: hasMapbox ? 'Present' : 'MISSING',
                status: hasMapbox ? _InfoStatus.success : _InfoStatus.error,
                detail: hasMapbox
                    ? '${AppConfig.mapboxAccessToken.length} chars'
                    : 'Maps will not work',
              ),
              _InfoRow(
                label: 'Supabase URL',
                value: hasSupabaseUrl ? 'Present' : 'MISSING',
                status:
                    hasSupabaseUrl ? _InfoStatus.success : _InfoStatus.error,
                detail: hasSupabaseUrl
                    ? _truncateUrl(SupabaseConfig.url)
                    : 'Backend will not work',
              ),
              _InfoRow(
                label: 'Supabase Anon Key',
                value: hasSupabaseAnon ? 'Present' : 'MISSING',
                status:
                    hasSupabaseAnon ? _InfoStatus.success : _InfoStatus.error,
                detail: hasSupabaseAnon
                    ? '${SupabaseConfig.anonKey.length} chars'
                    : 'Auth will not work',
              ),
              _InfoRow(
                label: 'OneSignal App ID',
                value: AppConfig.isOneSignalConfigured ? 'Present' : 'Not set',
                status: AppConfig.isOneSignalConfigured
                    ? _InfoStatus.success
                    : _InfoStatus.warning,
                detail: AppConfig.isOneSignalConfigured
                    ? '${AppConfig.oneSignalAppId.length} chars'
                    : 'Push notifications disabled',
              ),
            ]),
            const SizedBox(height: 24),

            // Auth Status Section
            _buildSectionHeader('Auth Status'),
            _buildInfoCard([
              _InfoRow(
                label: 'Authenticated',
                value: isAuthenticated ? 'Yes' : 'No',
                status:
                    isAuthenticated ? _InfoStatus.success : _InfoStatus.neutral,
              ),
              if (isAuthenticated && SupabaseConfig.currentUser != null) ...[
                _InfoRow(
                  label: 'User ID',
                  value: _truncateId(SupabaseConfig.currentUserId ?? ''),
                  status: _InfoStatus.neutral,
                ),
                _InfoRow(
                  label: 'Email',
                  value: SupabaseConfig.currentUser?.email ?? 'N/A',
                  status: _InfoStatus.neutral,
                ),
              ],
            ]),
            const SizedBox(height: 24),

            // Build Environment Section
            _buildSectionHeader('Build Environment'),
            _buildInfoCard([
              _InfoRow(
                label: 'Debug Mode',
                value: AppConfig.debugMode ? 'Enabled' : 'Disabled',
                status: AppConfig.debugMode
                    ? _InfoStatus.warning
                    : _InfoStatus.success,
              ),
              _InfoRow(
                label: 'Deep Link Scheme',
                value: AppConfig.deepLinkScheme,
                status: _InfoStatus.neutral,
              ),
              _InfoRow(
                label: 'Support Email',
                value: AppConfig.supportEmail,
                status: _InfoStatus.neutral,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: DCTheme.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          final row = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: const TextStyle(
                              color: DCTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          if (row.detail != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              row.detail!,
                              style: TextStyle(
                                color: DCTheme.textMuted.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          row.value,
                          style: TextStyle(
                            color: _getStatusColor(row.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _getStatusIcon(row.status),
                          color: _getStatusColor(row.status),
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getStatusColor(_InfoStatus status) {
    switch (status) {
      case _InfoStatus.success:
        return DCTheme.success;
      case _InfoStatus.warning:
        return DCTheme.warning;
      case _InfoStatus.error:
        return DCTheme.error;
      case _InfoStatus.neutral:
        return DCTheme.text;
    }
  }

  IconData _getStatusIcon(_InfoStatus status) {
    switch (status) {
      case _InfoStatus.success:
        return Icons.check_circle;
      case _InfoStatus.warning:
        return Icons.warning;
      case _InfoStatus.error:
        return Icons.error;
      case _InfoStatus.neutral:
        return Icons.info_outline;
    }
  }

  String _truncateUrl(String url) {
    if (url.length <= 30) return url;
    return '${url.substring(0, 30)}...';
  }

  String _truncateId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}...${id.substring(id.length - 4)}';
  }

  void _copyToClipboard(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('=== Direct Cuts Build Info ===');
    buffer.writeln('Version: ${_packageInfo?.version ?? 'N/A'}');
    buffer.writeln('Build: ${_packageInfo?.buildNumber ?? 'N/A'}');
    buffer.writeln('Package: ${_packageInfo?.packageName ?? 'N/A'}');
    buffer.writeln('');
    buffer.writeln('=== Configuration ===');
    buffer.writeln(
        'Mapbox: ${AppConfig.isMapboxConfigured ? "✓ Configured" : "✗ MISSING"}');
    buffer.writeln(
        'Supabase URL: ${SupabaseConfig.url.isNotEmpty ? _redactUrl(SupabaseConfig.url) : "✗ MISSING"}');
    buffer.writeln(
        'Supabase Anon: ${SupabaseConfig.anonKey.isNotEmpty ? "✓ Configured" : "✗ MISSING"}');
    buffer.writeln(
        'OneSignal: ${AppConfig.isOneSignalConfigured ? "✓ Configured" : "○ Not set"}');
    buffer.writeln('');
    buffer.writeln('=== Auth ===');
    buffer.writeln(
        'Authenticated: ${SupabaseConfig.isAuthenticated ? "Yes" : "No"}');
    if (SupabaseConfig.isAuthenticated) {
      // Redact user ID to first 8 chars only
      buffer
          .writeln('User ID: ${_redactId(SupabaseConfig.currentUserId ?? "")}');
    }
    buffer.writeln('');
    buffer
        .writeln('Debug Mode: ${AppConfig.debugMode ? "ENABLED" : "disabled"}');
    buffer.writeln('');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');

    // Final redaction pass - remove anything that looks like a key/token
    final redactedOutput = _redactSensitivePatterns(buffer.toString());

    Clipboard.setData(ClipboardData(text: redactedOutput));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Build info copied to clipboard (redacted)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Redact URL to show only hostname
  String _redactUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.host}';
    } catch (_) {
      return '[redacted]';
    }
  }

  /// Redact ID to first 8 chars
  String _redactId(String id) {
    if (id.isEmpty) return 'N/A';
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }

  /// Final redaction pass - catch any leaked keys/tokens
  String _redactSensitivePatterns(String input) {
    // Patterns that look like API keys, tokens, or secrets
    final patterns = [
      // Long alphanumeric strings (likely tokens/keys) - 32+ chars
      RegExp(r'[A-Za-z0-9_-]{32,}'),
      // Base64-ish patterns
      RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
      // UUID patterns (keep first 8 chars)
      RegExp(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
          caseSensitive: false),
    ];

    var result = input;
    for (final pattern in patterns) {
      result = result.replaceAllMapped(pattern, (match) {
        final value = match.group(0) ?? '';
        if (value.length <= 8) return value;
        return '${value.substring(0, 8)}[REDACTED]';
      });
    }
    return result;
  }
}

enum _InfoStatus { success, warning, error, neutral }

class _InfoRow {
  final String label;
  final String value;
  final _InfoStatus status;
  final String? detail;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.status,
    this.detail,
  });
}
