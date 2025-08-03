import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/deal.dart';
import '../services/deal_service.dart';

class DarazDealsWidget extends StatefulWidget {
  final String region;
  final String keyword;

  const DarazDealsWidget({
    super.key,
    this.region = 'bd',
    this.keyword = 'grocery',
  });

  @override
  State<DarazDealsWidget> createState() => _DarazDealsWidgetState();
}

class _DarazDealsWidgetState extends State<DarazDealsWidget> {
  late Future<List<Deal>> _futureDeals;

  @override
  void initState() {
    super.initState();
    _futureDeals = DealService.fetchDeals(widget.region, widget.keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔥 Smart Deals for You',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Deal>>(
          future: _futureDeals,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.data == null || snapshot.data!.isEmpty) {
              return const Text('No deals found.');
            }

            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final deal = snapshot.data![index];
                  return GestureDetector(
                    onTap: () => launchUrl(
                      Uri.parse(deal.link),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              deal.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            deal.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            deal.price,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
