import 'package:flutter/material.dart';

void main() {
  runApp(const TopBuyDealsApp());
}

class TopBuyDealsApp extends StatelessWidget {
  const TopBuyDealsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TopBuy Deals',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class Product {
  final String name;
  final int price;
  final int oldPrice;
  final String category;
  final IconData icon;

  const Product({
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.category,
    required this.icon,
  });

  int get discount {
    return ((oldPrice - price) * 100 / oldPrice).round();
  }
}

const List<Product> products = [
  Product(
    name: 'Smart Watch',
    price: 249000,
    oldPrice: 399000,
    category: 'Elektronika',
    icon: Icons.watch,
  ),
  Product(
    name: 'Wireless Earbuds',
    price: 179000,
    oldPrice: 299000,
    category: 'Elektronika',
    icon: Icons.headphones,
  ),
  Product(
    name: 'Sport Krossovka',
    price: 329000,
    oldPrice: 499000,
    category: 'Kiyim',
    icon: Icons.directions_run,
  ),
  Product(
    name: 'Ryukzak',
    price: 159000,
    oldPrice: 249000,
    category: 'Aksessuar',
    icon: Icons.backpack,
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
final TextEditingController searchController =
    TextEditingController();

String searchText = '';
  final Set<String> favorites = {};
  final List<Product> cart = [];

  void addToCart(Product product) {
    setState(() {
      cart.add(product);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} savatchaga qo‘shildi'),
      ),
    );
  }

  void toggleFavorite(Product product) {
    setState(() {
      if (favorites.contains(product.name)) {
        favorites.remove(product.name);
      } else {
        favorites.add(product.name);
      }
    });
  }

  void openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage(
          product: product,
          onAddToCart: () => addToCart(product),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TopBuy Deals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
           onPressed: () {
  showSearch(
    context: context,
    delegate: ProductSearchDelegate(products),
  );
},
            icon: const Icon(Icons.search),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartPage(cart: cart),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 4,
                  top: 4,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${cart.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _buildHome(),
          _buildCategories(),
          _buildFavorites(),
          _buildProfile(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Bosh sahifa',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Kategoriyalar',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saralangan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF6B35),
                Color(0xFFFF8A5B),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BUGUNGI AKSIYA 🔥',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Eng yaxshi narxlarni\nTopBuy Deals\'da toping!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Mashhur mahsulotlar',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            final isFavorite = favorites.contains(product.name);

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => openProduct(product),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                              child: Icon(
                                product.icon,
                                size: 70,
                                color: Colors.deepOrange,
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '-${product.discount}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                onPressed: () {
                                  toggleFavorite(product);
                                },
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product.category,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${product.price} so‘m',
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${product.oldPrice} so‘m',
                        style: const TextStyle(
                          color: Colors.grey,
                          decoration:
                              TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategories() {
    const categoryNames = [
      'Elektronika',
      'Kiyim',
      'Aksessuar',
      'Uy uchun',
      'Sport',
      'Kosmetika',
    ];

    const categoryIcons = [
      Icons.phone_android,
      Icons.checkroom,
      Icons.watch,
      Icons.home,
      Icons.sports_soccer,
      Icons.face,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Kategoriyalar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        for (int i = 0; i < categoryNames.length; i++)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(categoryIcons[i]),
              ),
              title: Text(categoryNames[i]),
              trailing:
                  const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                final filtered = products
                    .where(
                      (product) =>
                          product.category == categoryNames[i],
                    )
                    .toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryPage(
                      title: categoryNames[i],
                      products: filtered,
                      onAddToCart: addToCart,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFavorites() {
    final favoriteProducts = products
        .where((product) => favorites.contains(product.name))
        .toList();

    if (favoriteProducts.isEmpty) {
      return const Center(
        child: Text(
          'Saralangan mahsulotlar yo‘q ❤️',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final product in favoriteProducts)
          Card(
            child: ListTile(
              leading: Icon(product.icon),
              title: Text(product.name),
              subtitle: Text('${product.price} so‘m'),
              trailing: const Icon(
                Icons.favorite,
                color: Colors.red,
              ),
              onTap: () => openProduct(product),
            ),
          ),
      ],
    );
  }

  Widget _buildProfile() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 45,
            child: Icon(Icons.person, size: 50),
          ),
          SizedBox(height: 15),
          Text(
            'TopBuy Deals',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text('Profil bo‘limi'),
        ],
      ),
    );
  }
}

class CategoryPage extends StatelessWidget {
  final String title;
  final List<Product> products;
  final void Function(Product) onAddToCart;

  const CategoryPage({
    super.key,
    required this.title,
    required this.products,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: products.isEmpty
          ? const Center(
              child: Text(
                'Bu kategoriyada mahsulot yo‘q',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final product in products)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(product.icon),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.price} so‘m',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          onAddToCart(product);
                        },
                        child: const Text('Savatchaga'),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class ProductDetailsPage extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;

  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahsulot'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              product.icon,
              size: 120,
              color: Colors.deepOrange,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(product.category),
          const SizedBox(height: 20),
          Text(
            '${product.price} so‘m',
            style: const TextStyle(
              fontSize: 28,
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${product.oldPrice} so‘m',
            style: const TextStyle(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chegirma: ${product.discount}%',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: () {
                onAddToCart();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text(
                'Savatchaga qo‘shish',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  final List<Product> cart;

  const CartPage({
    super.key,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savatcha'),
      ),
      body: cart.isEmpty
          ? const Center(
              child: Text(
                'Savatcha bo‘sh',
                style: TextStyle(fontSize: 20),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final product in cart)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Icon(product.icon),
                      ),
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.price} so‘m',
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> products;

  ProductSearchDelegate(this.products);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = products.where(
      (product) => product.name
          .toLowerCase()
          .contains(query.toLowerCase()),
    );

    return ListView(
      children: results.map(
        (product) {
          return ListTile(
            leading: Icon(product.icon),
            title: Text(product.name),
            subtitle: Text('${product.price} so‘m'),
          );
        },
      ).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = products.where(
      (product) => product.name
          .toLowerCase()
          .contains(query.toLowerCase()),
    );

    return ListView(
      children: suggestions.map(
        (product) {
          return ListTile(
            leading: Icon(product.icon),
            title: Text(product.name),
          );
        },
      ).toList(),
    );
  }
}