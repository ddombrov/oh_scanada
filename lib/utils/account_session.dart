enum AccountMode { user, guest, example }

class AccountSession {
  static AccountMode mode = AccountMode.user;

  static bool get isGuest => mode == AccountMode.guest;
  static bool get isExample => mode == AccountMode.example;
}

// Local demo data for the "Example Account" option, so the app can be shown
// with a populated history without needing a real Firebase account.
class ExampleAccount {
  static const String name = 'Example User';
  static const String email = 'example.user@example.com';

  static const List<Map<String, String>> recentScans = [
    {
      'name': 'Maple Syrup - Grade A',
      'date': 'March 20, 2025',
      'image':
          'https://nwknitwear.com/cdn/shop/products/Hutchinson_sOrganicMapleSyrup_250ml_-MapleLeafbottle_534x700.png?v=1619637206',
    },
    {
      'name': 'Canadian Cheddar Cheese',
      'date': 'March 18, 2025',
      'image':
          'https://assets.shop.loblaws.ca/products/20134710/b2/en/front/20134710_front_a06_@2.png',
    },
    {'name': 'Ketchup Chips', 'date': 'March 15, 2025'},
    {'name': 'Nanaimo Bars', 'date': 'March 12, 2025'},
    {'name': 'Butter Tarts', 'date': 'March 9, 2025'},
  ];

  static const List<String> searchHistory = [
    'maple syrup',
    'ketchup chips',
    'cheddar cheese',
    'butter tarts',
    'coffee',
  ];

  static const Map<String, dynamic> rewardInfo = {
    'currentPoints': 340,
    'currentReward': {'points': 250, 'reward': 'Canadian Snack Sample'},
    'nextReward': {'points': 500, 'reward': 'Digital Postcard Collection'},
  };
}
