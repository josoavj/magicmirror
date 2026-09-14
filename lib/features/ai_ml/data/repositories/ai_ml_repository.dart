/// Repository pour les opérations IA/ML
abstract class AiMlRepository {
  Future<dynamic> analyzeMorphology(String imagePath);
  Future<dynamic> recognizeFaceMetrics(String imagePath);
}
