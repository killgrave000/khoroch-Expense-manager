import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khoroch/models/deal.dart';
import 'package:khoroch/services/deal_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DarazDealsScreen extends StatefulWidget {
  const DarazDealsScreen({super.key});

  @override
  State<DarazDealsScreen> createState() => _DarazDealsScreenState();
}

class _DarazDealsScreenState extends State<DarazDealsScreen> {
  late Future<List<Deal>> _futureDeals;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = 'grocery';
  String _region = 'daraz'; // Default to daraz
  final List<String> _sources = ['daraz', 'chaldal'];

  @override
  void initState() {
    super.initState();
    _searchController.text = _searchTerm;
    _fetchDeals();
  }

  void _fetchDeals() {
    setState(() {
      _futureDeals = DealService.fetchDeals(_region, _searchTerm);
    });
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter at least 2 characters")),
      );
      return;
    }

    _searchTerm = query;
    _fetchDeals();
  }

  void _copyAllDeals(List<Deal> deals) {
    final allText =
        deals.map((d) => '${d.title}\n${d.price}\n${d.link}').join('\n\n');
    Clipboard.setData(ClipboardData(text: allText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ All deals copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Smart Deals')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                DropdownButton<String>(
                  value: _region,
                  items: _sources.map((source) {
                    return DropdownMenuItem(
                      value: source,
                      child: Text(source.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _region = value;
                      });
                      _fetchDeals();
                    }
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search $_region',
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _onSearch,
                  child: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Deal>>(
                future: _futureDeals,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error.toString().replaceAll("Exception: ", "")}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No deals found.'));
                  }

                  final deals = snapshot.data!;
                  return Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.copy_all),
                          label: const Text("Copy All"),
                          onPressed: () => _copyAllDeals(deals),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: deals.length,
                          itemBuilder: (context, index) {
                            final deal = deals[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: Image.network(
                                  deal.image,
                                  width: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image),
                                ),
                                title: Text(
                                  deal.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  deal.price,
                                  style:
                                      const TextStyle(color: Colors.green),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                      text:
                                          '${deal.title}\n${deal.price}\n${deal.link}',
                                    ));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Deal copied!')),
                                    );
                                  },
                                ),
                                onTap: () => launchUrl(
                                  Uri.parse(deal.link),
                                  mode: LaunchMode.externalApplication,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
