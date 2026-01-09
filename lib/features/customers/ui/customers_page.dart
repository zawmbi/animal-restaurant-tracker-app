import 'package:flutter/material.dart';
import '../data/customers_repository.dart';
import '../model/customer.dart';
import 'customer_detail_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Regular'),
            Tab(text: 'Booth Owner'),
            Tab(text: 'Performer'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _CustomersList(),
          _CustomersList(tag: 'regular'),
          _CustomersList(tag: 'booth_owner'),
          _CustomersList(tag: 'performer'),
        ],
      ),
    );
  }
}

class _CustomersList extends StatelessWidget {
  final String? tag;
  const _CustomersList({this.tag});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Customer>>(
      future: tag == null
          ? CustomersRepository.instance.all()
          : CustomersRepository.instance.withTag(tag!),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final customers = snap.data!;

        return ListView.separated(
          itemCount: customers.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final c = customers[i];
            return ListTile(
              title: Text(c.name),
              subtitle: Text(c.customerDescription),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailPage(customer: c),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
