class WeatherForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final double rain;
  final double humidity;
  final double windSpeed;
  final String description;
  final String icon;

  WeatherForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.rain,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
  });
}