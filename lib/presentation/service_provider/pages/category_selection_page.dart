import 'package:flutter/material.dart';

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({super.key});

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  final List<Map<String, String>> _categories = [
    {'name': 'Roof Cleaning', 'image': 'lib/assets/images/roof_cleaning.png'},
    {
      'name': 'Compound Cleaning',
      'image': 'lib/assets/images/compound_cleaning.jpg',
    },
    {'name': 'Painting', 'image': 'lib/assets/images/painting.png'},
    {'name': 'House Cleaning', 'image': 'lib/assets/images/house_cleaning.jpg'},
    {'name': 'Laundry & Ironing', 'image': 'lib/assets/images/laundry.png'},
    {
      'name': 'Cooking & Dish Washing',
      'image': 'lib/assets/images/cooking.jpg',
    },
    {'name': 'Babysitting', 'image': 'lib/assets/images/babysitting.png'},
    {'name': 'Gardening', 'image': 'lib/assets/images/gardening.jpg'},
    {'name': 'Furniture Repair', 'image': 'lib/assets/images/furn_repair.png'},
  ];

  final List<String> _selectedCategories = [];

  void _toggleCategory(String categoryName) {
    setState(() {
      if (_selectedCategories.contains(categoryName)) {
        _selectedCategories.remove(categoryName);
      } else {
        if (_selectedCategories.length < 3) {
          _selectedCategories.add(categoryName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only select up to 3 categories.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  bool _isSelected(String categoryName) {
    return _selectedCategories.contains(categoryName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Up to 3 Categories")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _isSelected(category['name']!);
            return GestureDetector(
              onTap: () => _toggleCategory(category['name']!),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ],
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.asset(
                          category['image']!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        category['name']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isSelected ? Colors.green[800] : Colors.black87,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Icon(Icons.check_circle, color: Colors.green),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context, _selectedCategories);
          },
          icon: const Icon(Icons.check),
          label: const Text("Done"),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ),
    );
  }
}
