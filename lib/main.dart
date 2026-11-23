import 'package:flutter/material.dart';

void main() => runApp(const FiraApp());

class FiraApp extends StatelessWidget {
  const FiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xFF7867F5);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FIRA AI',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        colorScheme: ColorScheme.fromSeed(seedColor: violet, brightness: Brightness.light),
        fontFamily: 'Roboto',
      ),
      home: const FiraHome(),
    );
  }
}

class FiraHome extends StatefulWidget {
  const FiraHome({super.key});
  @override
  State<FiraHome> createState() => _FiraHomeState();
}

class _FiraHomeState extends State<FiraHome> {
  int _tab = 0;
  final _input = TextEditingController();
  final List<_ChatMessage> _messages = [];

  void _send([String? suggestion]) {
    final value = (suggestion ?? _input.text).trim();
    if (value.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(value, true));
      _messages.add(_ChatMessage(
        "Je suis prête à travailler sur cette demande. Le moteur IA n’est pas encore connecté : cette version prépare l’interface et le flux de travail. La prochaine étape ajoutera le fournisseur IA et l’exécution contrôlée des tâches.",
        false,
      ));
      _input.clear();
      _tab = 0;
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _chatPage(),
      const _ProjectsPage(),
      const _HistoryPage(),
      const _SettingsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FC),
        titleSpacing: 20,
        title: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: const Color(0xFF171D32), borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 11),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FIRA AI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: .5)),
            Text('Votre atelier de développement', style: TextStyle(fontSize: 11, color: Color(0xFF778096))),
          ]),
        ]),
        actions: [
          IconButton(onPressed: () => setState(() => _messages.clear()), icon: const Icon(Icons.add_comment_outlined), tooltip: 'Nouvelle conversation'),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Assistant'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: 'Projets'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historique'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Réglages'),
        ],
      ),
    );
  }

  Widget _chatPage() {
    return Column(children: [
      Expanded(
        child: _messages.isEmpty
          ? ListView(padding: const EdgeInsets.fromLTRB(20, 30, 20, 20), children: [
              const SizedBox(height: 24),
              Center(child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(color: const Color(0xFFECEAFF), borderRadius: BorderRadius.circular(25)),
                child: const Icon(Icons.auto_awesome, size: 38, color: Color(0xFF7867F5)),
              )),
              const SizedBox(height: 22),
              const Text('Que souhaitez-vous\nconstruire aujourd’hui ?', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 27, height: 1.18, fontWeight: FontWeight.w800, color: Color(0xFF171D32))),
              const SizedBox(height: 12),
              const Text('Décrivez votre idée. FIRA vous aidera à planifier, coder, tester et améliorer vos projets.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF778096))),
              const SizedBox(height: 30),
              _Suggestion(icon: Icons.code, title: 'Créer une application', subtitle: 'Préparer un nouveau projet Flutter', onTap: () => _send('Aide-moi à créer une application Flutter.')),
              _Suggestion(icon: Icons.bug_report_outlined, title: 'Corriger un problème', subtitle: 'Analyser une erreur et proposer un correctif', onTap: () => _send('Aide-moi à analyser et corriger un bug.')),
              _Suggestion(icon: Icons.science_outlined, title: 'Concevoir une architecture', subtitle: 'Organiser les modules et les services', onTap: () => _send('Conçois l’architecture technique de mon projet.')),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final item = _messages[index];
                return Align(
                  alignment: item.fromUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 330),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: item.fromUser ? const Color(0xFF171D32) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: item.fromUser ? null : Border.all(color: const Color(0xFFE9EBF2)),
                    ),
                    child: Text(item.text, style: TextStyle(color: item.fromUser ? Colors.white : const Color(0xFF30384B), height: 1.45)),
                  ),
                );
              },
            ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE9EBF2)))),
        child: Row(children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.attach_file_outlined), color: const Color(0xFF778096)),
          Expanded(child: TextField(
            controller: _input,
            minLines: 1, maxLines: 5,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: 'Écrivez à FIRA…',
              filled: true, fillColor: const Color(0xFFF4F5F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
            ),
          )),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: _send, icon: const Icon(Icons.arrow_upward), style: IconButton.styleFrom(backgroundColor: const Color(0xFF7867F5), foregroundColor: Colors.white)),
        ]),
      ),
    ]);
  }
}

class _ChatMessage {
  const _ChatMessage(this.text, this.fromUser);
  final String text;
  final bool fromUser;
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: Color(0xFFE9EBF2))),
    child: ListTile(
      onTap: onTap,
      leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFECEAFF), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: const Color(0xFF7867F5))),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF171D32))),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF778096))),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9AA1B2)),
    ),
  );
}

class _ProjectsPage extends StatelessWidget {
  const _ProjectsPage();
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Mes projets', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF171D32))),
    const SizedBox(height: 8),
    const Text('Retrouvez ici les espaces de travail de FIRA.', style: TextStyle(color: Color(0xFF778096))),
    const SizedBox(height: 22),
    _ProjectCard(icon: Icons.phone_android, title: 'Application mobile', detail: 'Flutter · Android et iOS', status: 'Espace prêt à configurer'),
    _ProjectCard(icon: Icons.memory, title: 'Moteur IA', detail: 'Python · API et orchestration', status: 'Structure à connecter'),
    _ProjectCard(icon: Icons.terminal, title: 'Agent développeur', detail: 'Fichiers · Tests · Diagnostics', status: 'Mode sécurisé à construire'),
  ]);
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.icon, required this.title, required this.detail, required this.status});
  final IconData icon; final String title; final String detail; final String status;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17), side: const BorderSide(color: Color(0xFFE9EBF2))),
    child: ListTile(contentPadding: const EdgeInsets.all(15),
      leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFECEAFF), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFF7867F5))),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text('$detail\n$status', style: const TextStyle(height: 1.5, fontSize: 12, color: Color(0xFF778096)))),
    ),
  );
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage();
  @override
  Widget build(BuildContext context) => const Center(child: Padding(
    padding: EdgeInsets.all(30),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.history, size: 54, color: Color(0xFFAAA6E9)),
      SizedBox(height: 15),
      Text('Aucune conversation enregistrée', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      SizedBox(height: 7),
      Text('Vos prochaines sessions apparaîtront ici.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF778096))),
    ]),
  ));
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: const [
    Text('Réglages', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: Color(0xFF171D32))),
    SizedBox(height: 18),
    _SettingTile(icon: Icons.psychology_outlined, title: 'Autonomie', value: 'Élevée · validation des actions sensibles'),
    _SettingTile(icon: Icons.shield_outlined, title: 'Sécurité', value: 'Sensible · environnement isolé prévu'),
    _SettingTile(icon: Icons.language, title: 'Langue', value: 'Français'),
    _SettingTile(icon: Icons.info_outline, title: 'Version', value: 'FIRA 0.1.0 · Fondation'),
  ]);
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.title, required this.value});
  final IconData icon; final String title; final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 7),
    leading: Icon(icon, color: const Color(0xFF7867F5)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(value, style: const TextStyle(color: Color(0xFF778096))),
  );
}
