import 'package:flutter/material.dart';
import 'common.dart';

class LegalPage extends StatelessWidget {
  final String title, asset;
  const LegalPage({super.key, required this.title, required this.asset});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: cream, appBar: AppBar(title: Text(title), backgroundColor: cream, foregroundColor: forest),
    body: FutureBuilder<String>(future: DefaultAssetBundle.of(context).loadString(asset), builder: (context, snap) => snap.hasData
      ? SingleChildScrollView(padding: const EdgeInsets.all(22), child: SelectableText(snap.data!, style: const TextStyle(color: forest, height: 1.55, fontSize: 14)))
      : const Center(child: CircularProgressIndicator())));
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: cream, appBar: AppBar(title: const Text('Contact'), backgroundColor: cream, foregroundColor: forest),
    body: const Padding(padding: EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Need a hand?', style: TextStyle(fontSize: 25, color: forest, fontWeight: FontWeight.w900)),
      SizedBox(height: 12), Text('For support, feedback, privacy questions or account-related requests, contact:', style: TextStyle(color: forest, height: 1.5)),
      SizedBox(height: 14), SelectableText('munazzashan99@gmail.com', style: TextStyle(color: Color(0xFF438C4B), fontWeight: FontWeight.bold, fontSize: 17)),
      SizedBox(height: 16), Text('Please include your device model and a description of the issue. Do not send passwords or sensitive personal information.', style: TextStyle(color: forest, height: 1.5)),
    ])));
}

