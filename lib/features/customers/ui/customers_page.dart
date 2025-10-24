import 'package:flutter/material.dart';
import '../../shared/widgets/entity_chip.dart';
import '../../shared/data/unlocked_store.dart';
import '../data/customers_repository.dart';
import '../model/customer.dart';
import 'customer_detail_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final repo = CustomersRepository.instance;
  final store = UnlockedStore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: FutureBuilder<List<Customer>>(
        future: repo.all(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final customers = snap.data!;
          List<Customer> tag(String t) =>
              customers.where((c) => c.tags.contains(t)).toList();

          return AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              return SingleChildScrollView(
                child: Column(children: [
                  _section(context, 'All', customers),
                  _section(context, 'Restaurant', tag('restaurant')),
                  _section(context, 'Special', tag('special')),
                  _section(context, 'Booth Owner', tag('booth_owner')),
                  _section(context, 'Seasonal', tag('seasonal')),
                  _section(context, 'Performer', tag('performer')),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Customer> list) {
    return ExpansionTile(
      title: Text(title),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final c = list[i];
              final isUnlocked = store.isUnlocked('customer', c.id);
              return EntityChip(
                label: c.name,
                checked: isUnlocked,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomerDetailPage(customer: c),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}