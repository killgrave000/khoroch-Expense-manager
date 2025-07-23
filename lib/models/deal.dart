class Deal {
  final String title;
  final String price;
  final String image;
  final String link;

  Deal({required this.title, required this.price, required this.image, required this.link});

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      title: json['title'],
      price: json['price'],
      image: json['image'],
      link: json['link'],
    );
  }
}
