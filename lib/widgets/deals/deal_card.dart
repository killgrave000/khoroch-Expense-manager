import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/deal.dart';

class DealCard extends StatelessWidget {
  final Deal deal;

  const DealCard({super.key, required this.deal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        leading: Image.network(deal.image, width: 60, fit: BoxFit.cover),
        title: Text(deal.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(deal.price, style: const TextStyle(color: Colors.green)),
        onTap: () => launchUrl(Uri.parse(deal.link), mode: LaunchMode.externalApplication),
      ),
    );
  }
}
