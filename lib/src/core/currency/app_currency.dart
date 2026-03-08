class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  final String code;
  final String name;
  final String symbol;

  String get displayLabel => '$code • $name';

  static const values = <AppCurrency>[
    AppCurrency(code: 'USD', name: 'US Dollar', symbol: r'$'),
    AppCurrency(code: 'EUR', name: 'Euro', symbol: '€'),
    AppCurrency(code: 'GBP', name: 'British Pound', symbol: '£'),
    AppCurrency(code: 'PKR', name: 'Pakistani Rupee', symbol: 'Rs'),
    AppCurrency(code: 'INR', name: 'Indian Rupee', symbol: '₹'),
    AppCurrency(code: 'AED', name: 'UAE Dirham', symbol: 'AED'),
    AppCurrency(code: 'SAR', name: 'Saudi Riyal', symbol: 'SAR'),
    AppCurrency(code: 'CAD', name: 'Canadian Dollar', symbol: r'C$'),
    AppCurrency(code: 'AUD', name: 'Australian Dollar', symbol: r'A$'),
    AppCurrency(code: 'JPY', name: 'Japanese Yen', symbol: '¥'),
    AppCurrency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥'),
    AppCurrency(code: 'SGD', name: 'Singapore Dollar', symbol: r'S$'),
  ];

  static AppCurrency? fromCode(String? code) {
    if (code == null || code.isEmpty) {
      return null;
    }

    for (final currency in values) {
      if (currency.code == code) {
        return currency;
      }
    }
    return null;
  }
}
