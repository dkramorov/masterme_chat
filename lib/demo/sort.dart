void testSort() {
  List<Map<String, dynamic>> list= [
    {'name': 'Shoes', 'price': 100},
    {'name': 'Pants', 'price': 50},
  ];

  // from low to high according to price
  list.sort((a, b) => a['price'].compareTo(b['price']));


  // from high to low according to price
  list.sort((a, b) => b['price'].compareTo(a['price']));
}