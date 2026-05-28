import 'package:deligood/core/network/api.dart';
import 'package:deligood/core/session/session_manager.dart';
import 'package:deligood/features/auth/providers/auth_state.dart';
import 'package:deligood/features/auth/screens/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LogoutCoordinator {
  LogoutCoordinator._();

  static final _session = SessionManager();

  /// Déclenche le processus de déconnexion avec confirmation préalable
  static Future<void> logout(
    BuildContext context, {
    int? orderId,
    bool callBackend = true,
  }) async {
    // 1️⃣ Affiche la confirmation
    final confirmed = await _showLogoutConfirmationDialog(context);
    if (!confirmed || !context.mounted) return;

    // 2️⃣ Récupère le token
    final token = _session.token ?? await _session.getToken();

    // 3️⃣ Appel backend (optionnel)
    if (callBackend && token != null && token.isNotEmpty) {
      await _safeBackendLogout(token);
    }

    // 4️⃣ Nettoyage local
    await _session.clearSession();
    AuthState.instance.clear();

    // 5️⃣ Navigation sécurisée
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(orderId: orderId, onLoginSuccess: (_) {}),
      ),
      (_) => false,
    );
  }

  /// Nettoyage local sans appel backend ni confirmation
  static Future<void> clearLocalSessionOnly() async {
    await _session.clearSession();
    AuthState.instance.clear();
  }

  /// 🎨 Dialogue de confirmation professionnel
  static Future<bool> _showLogoutConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Empêche la fermeture par tapotement extérieur
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Text(
                'Déconnexion',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Souhaitez-vous vraiment vous déconnecter ?\n'
            'Vous devrez saisir vos identifiants pour revenir.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Annuler',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    ).then((result) => result ?? false); // Retourne `false` si annulé ou fermé
  }

  static Future<void> _safeBackendLogout(String token) async {
    final url = Uri.parse('${ApiService.baseUrl}/api/users/logout/');
    try {
      await http
          .post(
            url,
            headers: {
              'Authorization': Api.authHeaderValue(token),
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));
    } catch (error) {
      debugPrint('🔙 Logout backend ignoré : $error');
    }
  }
}