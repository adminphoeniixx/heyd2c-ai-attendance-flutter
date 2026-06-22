import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Settings', style: AppTs.h3()),
            Text('SYSTEM', style: AppTs.tag()),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Account ─────────────────────────────────────────────────────────
          const _SectionLabel('ACCOUNT'),
          VeloCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Obx(() => _IntRow(
                      icon: Icons.business_rounded,
                      iconBg: AppColors.primaryGlow,
                      iconColor: AppColors.primaryLight,
                      title: 'Company',
                      subtitle: c.companyName.value.isNotEmpty
                          ? c.companyName.value
                          : 'Not set',
                    )),
                _divider(),
                Obx(() => _IntRow(
                      icon: Icons.person_rounded,
                      iconBg: AppColors.primaryGlow,
                      iconColor: AppColors.primaryLight,
                      title: 'Admin',
                      subtitle: c.adminName.value.isNotEmpty
                          ? c.adminName.value
                          : 'Not set',
                    )),
                _divider(),
                Obx(() => _IntRow(
                      icon: Icons.phone_rounded,
                      iconBg: AppColors.primaryGlow,
                      iconColor: AppColors.primaryLight,
                      title: 'Phone',
                      subtitle: c.adminPhone.value.isNotEmpty
                          ? '+91 ${c.adminPhone.value}'
                          : 'Not set',
                      isLast: true,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Sync ────────────────────────────────────────────────────────────
          const _SectionLabel('SYNC'),
          VeloCard(
            padding: EdgeInsets.zero,
            child: Obx(() => _IntRow(
                  icon: Icons.cloud_sync_rounded,
                  iconBg: AppColors.cyan.withValues(alpha: 0.12),
                  iconColor: AppColors.cyan,
                  title: 'Last Synced',
                  subtitle: c.lastSyncAt.value,
                  isLast: true,
                )),
          ),
          const SizedBox(height: 22),

          // ── Data ────────────────────────────────────────────────────────────
          const _SectionLabel('DATA'),
          VeloCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Obx(() => _IntRow(
                  icon: Icons.sync_rounded,
                  iconBg: AppColors.cyan.withValues(alpha: 0.12),
                  iconColor: AppColors.cyan,
                  title: 'Sync Employees from Server',
                  subtitle: 'Clear local cache & re-fetch all employees',
                  actionLabel: 'Sync',
                  loading: c.isSyncingEmployees.value,
                  onTap: () => _confirm(context,
                      title:   'Sync Employees',
                      body:    'Local employee cache will be cleared and re-fetched from server. Face data already registered on this device is preserved.',
                      onConfirm: c.syncEmployeesFromServer),
                )),
                _divider(),
                _IntRow(
                  icon: Icons.cleaning_services_rounded,
                  iconBg: AppColors.amber.withValues(alpha: 0.12),
                  iconColor: AppColors.amber,
                  title: 'Clear Synced Logs',
                  subtitle: 'Remove already-synced records',
                  actionLabel: 'Clear',
                  onTap: () => _confirm(context,
                      title:   'Clear Synced Logs',
                      body:    'Synced records will be removed. Pending records remain.',
                      onConfirm: c.clearSyncedLogs),
                ),
                _divider(),
                _IntRow(
                  icon: Icons.delete_forever_rounded,
                  iconBg: AppColors.rose.withValues(alpha: 0.12),
                  iconColor: AppColors.rose,
                  title: 'Factory Reset',
                  subtitle: 'Wipe all local data and logout',
                  actionLabel: 'Reset',
                  isDestructive: true,
                  isLast: true,
                  onTap: () => _confirm(context,
                      title:   'Factory Reset',
                      body:    'ALL local data will be deleted. You will be logged out.',
                      onConfirm: c.nukeAll,
                      destructive: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Session ─────────────────────────────────────────────────────────
          const _SectionLabel('SESSION'),
          VeloCard(
            padding: EdgeInsets.zero,
            child: Obx(() => _IntRow(
                  icon: Icons.logout_rounded,
                  iconBg: AppColors.rose.withValues(alpha: 0.12),
                  iconColor: AppColors.rose,
                  title: 'Logout',
                  subtitle: 'Sign out from this kiosk',
                  actionLabel: 'Logout',
                  isDestructive: true,
                  isLast: true,
                  loading: c.isLoggingOut.value,
                  onTap: () => _confirm(context,
                      title:   'Logout',
                      body:    'Are you sure you want to sign out?',
                      onConfirm: c.logout),
                )),
          ),
          const SizedBox(height: 22),

          // ── Danger zone ─────────────────────────────────────────────────────
          const _SectionLabel('DANGER ZONE'),
          VeloCard(
            padding: EdgeInsets.zero,
            borderColor: AppColors.rose.withValues(alpha: 0.30),
            child: Obx(() => _IntRow(
                  icon: Icons.no_accounts_rounded,
                  iconBg: AppColors.rose.withValues(alpha: 0.12),
                  iconColor: AppColors.rose,
                  title: 'Delete Account',
                  subtitle: 'Permanently erase this company account & all data',
                  actionLabel: 'Delete',
                  isDestructive: true,
                  isLast: true,
                  loading: c.isDeletingAccount.value,
                  onTap: () => _confirmDeleteAccount(context, c),
                )),
          ),
          const SizedBox(height: 36),

          // ── App version ──────────────────────────────────────────────────────
          Center(
            child: Text('Pulsara Kiosk  ·  v1.0.0',
                style: AppTs.tag()),
          ),
        ],
      ),
    );
  }

  static Widget _divider() => const Divider(
        height: 1, indent: 60, endIndent: 0,
        color: AppColors.border);

  static void _confirm(
    BuildContext context, {
    required String    title,
    required String    body,
    required VoidCallback onConfirm,
    bool destructive = false,
  }) {
    Get.dialog(AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            onConfirm();
          },
          child: Text(
            'Confirm',
            style: TextStyle(
              color: destructive ? AppColors.rose : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ));
  }

  /// Delete Account requires the admin to type DELETE to confirm — this is
  /// irreversible and wipes the whole company account, not just this device.
  static void _confirmDeleteAccount(BuildContext context, SettingsController c) {
    Get.dialog(_DeleteAccountDialog(onConfirmed: c.deleteAccount));
  }
}

// ── Delete account dialog — type-to-confirm guard for an irreversible op ──────

class _DeleteAccountDialog extends StatefulWidget {
  final VoidCallback onConfirmed;
  const _DeleteAccountDialog({required this.onConfirmed});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _keyword = 'DELETE';
  final _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.rose, size: 22),
          const SizedBox(width: 8),
          Text('Delete Account', style: AppTs.h3(color: AppColors.rose)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This permanently deletes your company account — every employee, '
            'attendance record and registered face. This action cannot be undone.',
            style: AppTs.body(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text('Type $_keyword to confirm', style: AppTs.caption()),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: AppTs.body(),
            decoration: InputDecoration(
              hintText: _keyword,
              hintStyle: AppTs.body(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.rose),
              ),
            ),
            onChanged: (v) =>
                setState(() => _canConfirm = v.trim() == _keyword),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canConfirm
              ? () {
                  Get.back();
                  widget.onConfirmed();
                }
              : null,
          child: Text(
            'Delete Permanently',
            style: TextStyle(
              color: _canConfirm ? AppColors.rose : AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(text,
            style: AppTs.tag(color: AppColors.primaryMid)
                .copyWith(fontSize: 10, letterSpacing: 1.5)),
      );
}

// ── Integration row — mirrors Velo's int-row ──────────────────────────────────

class _IntRow extends StatelessWidget {
  final IconData icon;
  final Color    iconBg;
  final Color    iconColor;
  final String   title;
  final String   subtitle;
  final String?  actionLabel;
  final bool     isLast;
  final bool     isDestructive;
  final bool     loading;
  final VoidCallback? onTap;

  const _IntRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.isLast       = false,
    this.isDestructive = false,
    this.loading       = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 14, 16, isLast ? 14 : 14),
        child: Row(
          children: [
            // Icon box — same shape as Velo int-icon
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border2),
              ),
              child: loading
                  ? SizedBox(
                      width: 18, height: 18,
                      child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: iconColor),
                      ))
                  : Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTs.label(
                          color: isDestructive
                              ? AppColors.rose
                              : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTs.caption()),
                ],
              ),
            ),

            // Action pill or chevron
            if (actionLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.rose.withValues(alpha: 0.10)
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDestructive
                        ? AppColors.rose.withValues(alpha: 0.30)
                        : AppColors.border,
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: AppTs.bodySmall(
                      color: isDestructive
                          ? AppColors.rose
                          : AppColors.textSecondary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  size: 18),
          ],
        ),
      ),
    );
  }
}
