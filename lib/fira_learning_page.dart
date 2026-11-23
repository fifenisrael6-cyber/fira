import 'package:flutter/material.dart';
import 'services/fira_learning.dart';

class FiraLearningPage extends StatefulWidget {
  const FiraLearningPage({super.key, required this.serverUrl});
  final String serverUrl;
  @override
  State<FiraLearningPage> createState() => _FiraLearningPageState();
}

class _FiraLearningPageState extends State<FiraLearningPage> {
  final _service = FiraLearningService();
  final _corpus = TextEditingController();
  final _seed = TextEditingController(text: 'FIRA apprend');
  Map<String, dynamic>? _status;
  String? _result;
  String? _error;
  bool _authorized = false;
  bool _loading = false;
  int _epochs = 3;

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    if (widget.serverUrl.trim().isEmpty) {
      setState(() => _error = 'Le moteur Python FIRA doit être hébergé et son adresse configurée avant de lancer un entraînement.');
      return;
    }
    try {
      final value = await _service.status(widget.serverUrl);
      if (mounted) setState(() { _status = value; _error = null; });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _train() async {
    if (_loading || !_authorized || _corpus.text.trim().length < 40) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final response = await _service.train(widget.serverUrl, _corpus.text.trim(), _epochs);
      if (mounted) {
        setState(() {
          _result = 'Entraînement terminé. ${response['model']?['new_tokens'] ?? 0} unités lexicales traitées. Perte finale : ${response['model']?['final_loss'] ?? '—'}.';
          _authorized = false;
        });
        await _refresh();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; _result = null; });
    try {
      final response = await _service.generate(widget.serverUrl, _seed.text.trim());
      if (mounted) setState(() => _result = '${response['text'] ?? ''}\n\nGénération expérimentale : FIRA prédit des mots appris, sans compréhension réelle.');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() { _service.close(); _corpus.dispose(); _seed.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Apprentissage de FIRA')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Mon petit réseau neuronal', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      const Text('Ce modèle est initialisé aléatoirement et apprend à prédire le mot suivant. Il ne s’agit pas encore d’une IA conversationnelle.', style: TextStyle(color: Color(0xFF778096), height: 1.45)),
      const SizedBox(height: 16),
      Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Progression', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Vocabulaire : ${_status?['vocabulary_size'] ?? '—'} mots'),
        Text('Textes entraînés : ${_status?['training_tokens'] ?? '—'} unités lexicales'),
        Text('Époques cumulées : ${_status?['training_steps'] ?? '—'}'),
        Text('Dimensions internes : ${_status?['embedding_size'] ?? '—'}'),
        TextButton.icon(onPressed: _loading ? null : _refresh, icon: const Icon(Icons.refresh), label: const Text('Actualiser')),
      ]))),
      const SizedBox(height: 16),
      const Text('1. Fournir un texte d’apprentissage', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      TextField(controller: _corpus, minLines: 6, maxLines: 12, decoration: const InputDecoration(
        hintText: 'Collez un texte que vous avez écrit ou que vous avez le droit d’utiliser…',
        border: OutlineInputBorder(), alignLabelWithHint: true)),
      CheckboxListTile(contentPadding: EdgeInsets.zero, value: _authorized,
        onChanged: _loading ? null : (value) => setState(() => _authorized = value ?? false),
        title: const Text('Je possède ce texte ou j’ai l’autorisation de l’utiliser pour entraîner FIRA.'),
        controlAffinity: ListTileControlAffinity.leading),
      Row(children: [
        const Text('Époques : '),
        Expanded(child: Slider(value: _epochs.toDouble(), min: 1, max: 10, divisions: 9,
          label: '$_epochs', onChanged: _loading ? null : (v) => setState(() => _epochs = v.round()))),
        Text('$_epochs'),
      ]),
      FilledButton.icon(onPressed: _loading || !_authorized || _corpus.text.trim().length < 40 ? null : _train,
        icon: const Icon(Icons.school_outlined), label: Text(_loading ? 'Entraînement…' : 'Entraîner depuis zéro')),
      const Divider(height: 32),
      const Text('2. Tester la génération', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      TextField(controller: _seed, decoration: const InputDecoration(labelText: 'Début de texte', border: OutlineInputBorder())),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: _loading ? null : _generate, icon: const Icon(Icons.auto_awesome), label: const Text('Générer une suite de texte')),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
      if (_result != null) ...[const SizedBox(height: 12), Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(14), child: SelectableText(_result!)))],
      const SizedBox(height: 16),
      const Text('Conseil : utilise uniquement des textes dont tu détiens les droits. N’entraîne jamais FIRA avec des mots de passe, des clés API ou des données privées.', style: TextStyle(fontSize: 12, color: Color(0xFF778096))),
    ]),
  );
}
