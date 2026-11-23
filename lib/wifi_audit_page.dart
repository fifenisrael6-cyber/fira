// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'services/wifi_audit.dart';

class WifiAuditPage extends StatefulWidget {
  const WifiAuditPage({super.key, required this.serverUrl});
  final String serverUrl;
  @override
  State<WifiAuditPage> createState() => _WifiAuditPageState();
}

class _WifiAuditPageState extends State<WifiAuditPage> {
  final _service = WifiAuditService();
  String _security = 'unknown', _wps = 'unknown', _firmware = 'unknown';
  String _adminPassword = 'unknown', _remoteAdmin = 'unknown', _guest = 'unknown', _iot = 'unknown';
  bool _authorized = false, _loading = false;
  String? _error;
  WifiAuditResult? _result;

  bool? _asBool(String value) => value == 'yes' ? true : value == 'no' ? false : null;

  Future<void> _audit() async {
    if (!_authorized) { setState(() => _error = 'Confirmez que vous êtes autorisé à administrer ce routeur.'); return; }
    if (widget.serverUrl.trim().isEmpty) { setState(() => _error = 'Configurez d’abord le serveur FIRA dans Réglages.'); return; }
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final result = await _service.audit(serverUrl: widget.serverUrl, answers: {
        'authorization_confirmed': true, 'security_mode': _security,
        'wps_enabled': _asBool(_wps), 'firmware_updated': _asBool(_firmware),
        'admin_password_changed': _asBool(_adminPassword), 'remote_admin_enabled': _asBool(_remoteAdmin),
        'guest_network_enabled': _asBool(_guest), 'iot_network_separated': _asBool(_iot),
      });
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Widget _choice(String label, String value, ValueChanged<String?> onChanged, {bool security = false}) {
    final options = security
      ? const <DropdownMenuItem<String>>[
          DropdownMenuItem(value: 'unknown', child: Text('Non vérifié')),
          DropdownMenuItem(value: 'wpa3', child: Text('WPA3-Personal')),
          DropdownMenuItem(value: 'wpa2-aes', child: Text('WPA2-AES')),
          DropdownMenuItem(value: 'wpa2-tkip', child: Text('WPA2-TKIP')),
          DropdownMenuItem(value: 'wep', child: Text('WEP')),
          DropdownMenuItem(value: 'open', child: Text('Ouvert / sans mot de passe')),
        ]
      : const <DropdownMenuItem<String>>[
          DropdownMenuItem(value: 'unknown', child: Text('Je ne sais pas')),
          DropdownMenuItem(value: 'yes', child: Text('Oui')),
          DropdownMenuItem(value: 'no', child: Text('Non')),
        ];
    return Padding(padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(initialValue: value, isExpanded: true,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: options, onChanged: onChanged));
  }

  @override
  void dispose() { _service.close(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Audit de sécurité Wi-Fi')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Vérification de votre routeur', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Répondez à partir des paramètres officiels de votre propre routeur. FIRA évalue la configuration et propose des corrections sans se connecter au réseau.',
        style: TextStyle(height: 1.45, color: Color(0xFF687187))),
      const SizedBox(height: 18),
      _choice('Sécurité Wi-Fi', _security, (v) => setState(() => _security = v ?? 'unknown'), security: true),
      _choice('WPS activé ?', _wps, (v) => setState(() => _wps = v ?? 'unknown')),
      _choice('Micrologiciel à jour ?', _firmware, (v) => setState(() => _firmware = v ?? 'unknown')),
      _choice('Mot de passe administrateur par défaut changé ?', _adminPassword, (v) => setState(() => _adminPassword = v ?? 'unknown')),
      _choice('Administration distante depuis Internet activée ?', _remoteAdmin, (v) => setState(() => _remoteAdmin = v ?? 'unknown')),
      _choice('Réseau invité configuré ?', _guest, (v) => setState(() => _guest = v ?? 'unknown')),
      _choice('Objets connectés isolés sur un réseau séparé ?', _iot, (v) => setState(() => _iot = v ?? 'unknown')),
      CheckboxListTile(contentPadding: EdgeInsets.zero, value: _authorized,
        onChanged: (v) => setState(() => _authorized = v ?? false),
        title: const Text('Je suis propriétaire ou autorisé à administrer ce routeur.'),
        controlAffinity: ListTileControlAffinity.leading),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: _loading ? null : _audit,
        icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.shield_outlined),
        label: Text(_loading ? 'Évaluation…' : 'Évaluer la configuration')),
      if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
      if (_result != null) ...[
        const SizedBox(height: 20),
        Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Niveau global : ${_result!.level.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const Divider(height: 22),
            ..._result!.findings.map((item) => Padding(padding: const EdgeInsets.only(bottom: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('[${(item['level'] ?? 'info').toString().toUpperCase()}] ${item['title'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text((item['recommendation'] ?? '').toString(), style: const TextStyle(height: 1.4)),
              ]))),
            Text(_result!.disclaimer, style: const TextStyle(fontSize: 11, color: Color(0xFF687187))),
          ]))),
      ],
    ]),
  );
}
