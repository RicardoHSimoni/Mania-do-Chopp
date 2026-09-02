import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'models/cliente.dart';
import 'models/produto.dart';
import 'models/tipo_produto.dart';

import 'firebase_options.dart';

import 'screens/home/home_screen.dart';

import 'screens/orcamentos/orcamento_form_screen.dart';
import 'screens/orcamentos/orcamentos_screen.dart';

import 'screens/clientes/cliente_screen.dart';
import 'screens/clientes/cliente_form_screen.dart';
import 'screens/clientes/cliente_update_screen.dart';

import 'screens/produtos/produto_screen.dart';
import 'screens/produtos/produto_form_screen.dart';
import 'screens/produtos/produto_update_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomeScreen(),
      routes: {
        '/orcamentos/orcamento_form_screen': (context) =>
            const OrcamentoFormScreen(),
        '/orcamentos/orcamentos_screen': (context) => const OrcamentosScreen(),

        '/clientes/cliente_screen': (context) => const ClienteScreen(),
        '/clientes/cliente_form_screen': (context) => const ClienteFormScreen(),
        '/clientes/cliente_update_screen': (context) {
          final cliente =
              ModalRoute.of(context)?.settings.arguments as Cliente?;
          return ClienteUpdateScreen(
            cliente:
                cliente ??
                Cliente(
                  nome: '',
                  cpf: '',
                  email: '',
                  telefone: '',
                  endereco: '',
                  numero: '',
                  bairro: '',
                ),
          );
        },
        '/produtos/produto_screen': (context) => const ProdutoScreen(),
        '/produtos/produto_form_screen': (context) => const ProdutoFormScreen(),
        '/produtos/produto_update_screen': (context) {
          final produto =
              ModalRoute.of(context)?.settings.arguments as Produto?;
          return ProdutoUpdateScreen(
            produto:
                produto ??
                Produto(id: '', nome: '', tipo: TipoProduto.outro, preco: 0.0),
          );
        },
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
