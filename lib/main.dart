import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/fira_api.dart';
import 'services/youtube_learning.dart';

void main() => runApp(const FiraApp());

class FiraApp extends StatelessWidget {
  const FiraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FIRA AI',
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7867F5))),
    home: const FiraHome(),
  );
}

class FiraHome extends StatefulWidget {
  const FiraHome({super.key});
  @override
  State<FiraHome> createState() => _FiraHomeState();
}

class _FiraHomeState extends State<FiraHome> {
  final _api = FiraApi();
  final _input = TextEditingController();
  final _messages = <_Message>[];
  String _server = '';
  bool _loading = false;
  bool _settingsReady = false;
  final _youtube = YouTubeLearningService();

  @override
  void initState() { super.initState(); _loadServer(); }

  Future<void> _loadServer() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() { _server = prefs.getString('fira_server_url') ?? ''; _settingsReady = true; });
  }

  Future<void> _saveServer(String value) async {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fira_server_url', normalized);
    if (!mounted) return;
    setState(() => _server = normalized);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adresse du serveur enregistrée.')));
  }

  Future<void> _send([String? prompt]) async {
    final value = (prompt ?? _input.text).trim();
    if (value.isEmpty || _loading) return;
    setState(() { _messages.add(_Message(value, true)); _loading = true; });
    _input.clear();
    try {
      final video = RegExp(r'https?://(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)[\w-]{11}').firstMatch(value);
      final String answer;
      if (video != null) {
        final lesson = await _youtube.analyze(serverUrl: _server, youtubeUrl: video.group(0)!);
        answer = 'Voici mon analyse de la vidéo ${lesson.videoId} :\\n\\n${lesson.analysis}';
      } else {
        final history = _messages.take(_messages.length - 1).toList().reversed.take(20).toList().reversed
          .map((m) => <String, String>{'role': m.user ? 'user' : 'assistant', 'content': m.text}).toList();
        answer = await _api.sendMessage(baseUrl: _server, message: value, history: history);
      }
      if (mounted) setState(() => _messages.add(_Message(answer, false)));
    } on FiraApiException catch (e) {
      if (mounted) setState(() => _messages.add(_Message('Connexion impossible : ${e.message}', false)));
    } catch (_) {
      if (mounted) setState(() => _messages.add(const _Message('Erreur inattendue. Vérifiez le serveur et réessayez.', false)));
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _openSettings() async {
    await showDialog<void>(context: context, builder: (context) => Dialog(
      child: SizedBox(width: 420, height: 560,
        child: _Settings(server: _server, ready: _settingsReady, onSave: (value) {
          _saveServer(value);
          Navigator.of(context).pop();
        }),
      ),
    ));
  }

  @override
  void dispose() { _api.close(); _youtube.close(); _input.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(children: [
        Icon(Icons.auto_awesome, color: Color(0xFF7867F5), size: 28),
        SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FIRA AI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          Text('Assistant intelligent · Python · Dart · Réseau',
            style: TextStyle(fontSize: 10, color: Color(0xFF778096))),
        ]),
      ]),
      actions: [
        IconButton(onPressed: _loading ? null : () => setState(() => _messages.clear()),
          icon: const Icon(Icons.add_comment_outlined), tooltip: 'Nouvelle conversation'),
        IconButton(onPressed: _openSettings, icon: const Icon(Icons.tune), tooltip: 'Réglages'),
      ],
    ),
    body: SafeArea(child: _assistant()),
  );

  Widget _assistant() => Column(children: [
    Expanded(child: _messages.isEmpty
      ? ListView(padding: const EdgeInsets.all(22), children: [
          const SizedBox(height: 35),
          const Icon(Icons.auto_awesome, size: 60, color: Color(0xFF7867F5)),
          const SizedBox(height: 20),
          const Text('Que souhaitez-vous\nconstruire aujourd’hui ?', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.2, color: Color(0xFF171D32))),
          const SizedBox(height: 12),
          const Text('Décrivez votre idée. FIRA peut vous aider à planifier, coder, tester et améliorer vos projets.',
            textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF778096), height: 1.5)),
          const SizedBox(height: 28),
          _Suggestion(icon: Icons.code, title: 'Créer une application', subtitle: 'Préparer un projet Flutter', onTap: () => _send('Aide-moi à créer une application Flutter.')),
          _Suggestion(icon: Icons.bug_report_outlined, title: 'Corriger un problème', subtitle: 'Analyser une erreur', onTap: () => _send('Aide-moi à analyser et corriger un bug.')),
          _Suggestion(icon: Icons.architecture, title: 'Concevoir une architecture', subtitle: 'Organiser les modules', onTap: () => _send('Conçois l’architecture technique de mon projet.')),
        ])
      : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _messages.length + (_loading ? 1 : 0),
          itemBuilder: (context, i) {
            if (_loading && i == _messages.length) return const Padding(padding: EdgeInsets.all(12),
              child: Row(children: [SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 10), Text('FIRA réfléchit…')]));
            final m = _messages[i];
            return Align(alignment: m.user ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(constraints: const BoxConstraints(maxWidth: 340), margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14), decoration: BoxDecoration(
                  color: m.user ? const Color(0xFF171D32) : Colors.white, borderRadius: BorderRadius.circular(17),
                  border: m.user ? null : Border.all(color: const Color(0xFFE9EBF2))),
                child: SelectableText(m.text, style: TextStyle(color: m.user ? Colors.white : const Color(0xFF30384B), height: 1.45))));
          })),
    Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      child: Row(children: [
        Expanded(child: TextField(controller: _input, minLines: 1, maxLines: 5, enabled: !_loading,
          textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
          decoration: InputDecoration(hintText: 'Écrivez à FIRA…', filled: true, fillColor: const Color(0xFFF4F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: _loading ? null : _send, icon: const Icon(Icons.arrow_upward),
          style: IconButton.styleFrom(backgroundColor: const Color(0xFF7867F5), foregroundColor: Colors.white)),
      ])),
  ]);
}

class _Message {
  const _Message(this.text, this.user);
  final String text;
  final bool user;
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(color: Colors.white, elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE9EBF2))),
    child: ListTile(onTap: onTap, leading: Icon(icon, color: const Color(0xFF7867F5)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12))));
}

class _Projects extends StatelessWidget {
  const _Projects();
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: const [
    Text('Mes projets', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
    SizedBox(height: 18),
    _ProjectTile(icon: Icons.phone_android, title: 'Application mobile', detail: 'Flutter · Android et iOS'),
    _ProjectTile(icon: Icons.memory, title: 'Moteur IA', detail: 'Python · API de conversation'),
    _ProjectTile(icon: Icons.terminal, title: 'Agent développeur', detail: 'Planification · Analyse · Tests isolés'),
  ]);
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.icon, required this.title, required this.detail});
  final IconData icon; final String title; final String detail;
  @override
  Widget build(BuildContext context) => Card(color: Colors.white, elevation: 0,
    child: ListTile(leading: Icon(icon, color: const Color(0xFF7867F5)), title: Text(title), subtitle: Text(detail)));
}

class _History extends StatelessWidget {
  const _History();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Historique conservé pendant cette session.'));
}

class _Settings extends StatefulWidget {
  const _Settings({required this.server, required this.ready, required this.onSave});
  final String server; final bool ready; final ValueChanged<String> onSave;
  @override
  State<_Settings> createState() => _SettingsState();
}
class _SettingsState extends State<_Settings> {
  late final TextEditingController _controller;
  @override
  void initState() { super.initState(); _controller = TextEditingController(text: widget.server); }
  @override
  void didUpdateWidget(covariant _Settings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.server != widget.server && _controller.text != widget.server) _controller.text = widget.server;
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Réglages', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
    const ListTile(leading: Icon(Icons.psychology_outlined), title: Text('Autonomie élevée'), subtitle: Text('Planification multi-étapes et vérification')),
    const ListTile(leading: Icon(Icons.shield_outlined), title: Text('Sécurité sensible'), subtitle: Text('Validation obligatoire des actions risquées')),
    const SizedBox(height: 18),
    const Text('Connexion au moteur IA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
    const SizedBox(height: 8),
    const Text('Adresse HTTPS du serveur FIRA. La clé API reste sur le serveur : ne la collez jamais dans l’application.',
      style: TextStyle(color: Color(0xFF778096), height: 1.4)),
    const SizedBox(height: 12),
    TextField(controller: _controller, keyboardType: TextInputType.url,
      decoration: const InputDecoration(hintText: 'https://votre-serveur.example', border: OutlineInputBorder(), prefixIcon: Icon(Icons.dns_outlined))),
    const SizedBox(height: 10),
    FilledButton.icon(onPressed: widget.ready ? () => widget.onSave(_controller.text) : null,
      icon: const Icon(Icons.save_outlined), label: const Text('Enregistrer le serveur')),
    const SizedBox(height: 20),
    const ListTile(leading: Icon(Icons.info_outline), title: Text('FIRA 0.3.0'), subtitle: Text('Moteur IA local · apprentissage YouTube')),
  ]);
}


class _YouTubeLearningPage extends StatefulWidget {
  const _YouTubeLearningPage({required this.server});
  final String server;

  @override
  State<_YouTubeLearningPage> createState() => _YouTubeLearningPageState();
}

class _YouTubeLearningPageState extends State<_YouTubeLearningPage> {
  final _urlController = TextEditingController();
  final _objectiveController = TextEditingController(
    text: 'Explique le tutoriel, les outils et les commandes, puis propose un exercice pratique sûr.',
  );
  final _service = YouTubeLearningService();
  YouTubeLesson? _lesson;
  String? _error;
  bool _loading = false;

  Future<void> _analyze() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || _loading) return;
    if (widget.server.trim().isEmpty) {
      setState(() => _error = 'Configurez d’abord l’adresse du moteur FIRA dans Réglages.');
      return;
    }
    setState(() { _loading = true; _error = null; _lesson = null; });
    try {
      final lesson = await _service.analyze(
        serverUrl: widget.server,
        youtubeUrl: url,
        objective: _objectiveController.text.trim().isEmpty
          ? 'Explique le tutoriel et propose un laboratoire défensif sûr.'
          : _objectiveController.text.trim(),
      );
      if (mounted) setState(() => _lesson = lesson);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _objectiveController.dispose();
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      const Text('Apprendre avec YouTube',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Collez le lien d’une vidéo. FIRA récupère ses sous-titres accessibles et demande au modèle local de transformer le contenu en leçon.',
        style: TextStyle(color: Color(0xFF778096), height: 1.45)),
      const SizedBox(height: 18),
      TextField(
        controller: _urlController,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: 'Lien de la vidéo YouTube',
          hintText: 'https://www.youtube.com/watch?v=…',
          prefixIcon: Icon(Icons.play_circle_outline),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _objectiveController,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Ce que vous voulez apprendre',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: _loading ? null : _analyze,
        icon: _loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.auto_awesome),
        label: Text(_loading ? 'Analyse en cours…' : 'Analyser la vidéo'),
      ),
      const SizedBox(height: 12),
      if (_error != null)
        Card(
          color: const Color(0xFFFFF1F0),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(_error!, style: const TextStyle(color: Color(0xFF9B2922))),
          ),
        ),
      if (_lesson != null) ...[
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Leçon préparée par FIRA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Vidéo : ${_lesson!.videoId} · ${_lesson!.transcriptChars} caractères de transcription',
                style: const TextStyle(fontSize: 12, color: Color(0xFF778096))),
              const Divider(height: 24),
              SelectableText(_lesson!.analysis,
                style: const TextStyle(height: 1.5, color: Color(0xFF30384B))),
            ]),
          ),
        ),
      ],
      const SizedBox(height: 10),
      const Text('Limite actuelle : cette version analyse les sous-titres accessibles, pas directement les images ni le son des vidéos sans transcription.',
        style: TextStyle(fontSize: 12, color: Color(0xFF778096), height: 1.4)),
    ],
  );
}
