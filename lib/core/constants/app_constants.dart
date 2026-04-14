class AppConstants {
  // Supabase
  static const String supabaseUrl = 'https://slsipllfnorwlmftzflr.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNsc2lwbGxmbm9yd2xtZnR6ZmxyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2OTAyOTEsImV4cCI6MjA5MTI2NjI5MX0.AHFdFCbYvZke3_YEEtqwHR1P9NcLhsFvvVDCyW7Hlc0';

  // App info
  static const String appName = 'Fellow Drink';
  static const String appPhone = '+228 90 08 43 74';
  static const String appVersion = '1.0.0';

  // Réseaux sociaux
  static const String facebookUrl = 'https://facebook.com/fellowdrink';
  static const String instagramUrl = 'https://instagram.com/fellowdrink';
  static const String whatsappUrl = 'https://wa.me/22890084374';
  static const String tiktokUrl = 'https://tiktok.com/@fellowdrink';

  // Catégories de boissons (depuis l'image)
  static const List<String> drinkCategories = [
    'Tous',
    'Jus naturels',
    'Jus de fruits',
    'Sodas',
    'Baobab',
    'Bissap',
    'Gingembre',
    'Citron',
    'Cocktails',
  ];

  // Statuts
  static const String saleCompleted  = 'completed';
  static const String saleCancelled  = 'cancelled';
  static const String deliveryPending    = 'pending';
  static const String deliveryTransit    = 'in_transit';
  static const String deliveryDelivered  = 'delivered';
  static const String deliveryFailed     = 'failed';

  // Rôles utilisateur
  static const String roleAdmin  = 'admin';
  static const String roleClient = 'client';

  // Sons
  static const String chatSoundPath = 'sounds/chat_notif.mp3';
}

