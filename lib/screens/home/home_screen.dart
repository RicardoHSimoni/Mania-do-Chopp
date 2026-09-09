import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mania do Chopp'),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Abrir menu',
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Text(
                  'Mania do Chopp',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Início'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Orçamentos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/orcamentos/orcamentos_screen');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('Pedidos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/pedidos/pedidos_screen');
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outlined),
                title: const Text('Clientes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/clientes/cliente_screen');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('Produtos'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/produtos/produto_screen');
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.today_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Demandas de hoje',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text(
                            'Nenhuma demanda para hoje.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/orcamentos/orcamento_form_screen'),
        icon: const Icon(Icons.add),
        label: const Text('Novo orçamento'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
