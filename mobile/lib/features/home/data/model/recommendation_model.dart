import 'package:mobile/core/share/data/model/product_model.dart';

class RecommendationModel {
  final List<Product> product;

  final String query;

  RecommendationModel({required this.product, required this.query});
}
