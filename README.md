# Fellow Drink

Application mobile de gestion de vente de boissons - Plateforme complète pour gérer des produits, des ventes et des livraisons.

## 📱 À propos

**Fellow Drink** est une application Flutter cross-platform permettant de :
- 📊 Gérer l'inventaire des produits (boissons)
- 💰 Suivre les ventes et le chiffre d'affaires
- 📈 Consulter des statistiques détaillées
- 🚚 Gérer les livraisons et services
- 💬 Communiquer via chat intégré
- 🔔 Recevoir des notifications en temps réel
- 📄 Générer et imprimer des rapports PDF
- 🔐 Authentification sécurisée

## 🛠️ Architecture & Stack Technique

### Frontend
- **Framework** : Flutter 3.1+
- **State Management** : Riverpod
- **Navigation** : Go Router
- **Design** : Material Design 3
- **Icônes** : Font Awesome, SVG

### Backend & Services
- **Database** : Supabase (PostgreSQL)
- **Notifications** : Flutter Local Notifications
- **Stockage** : Preferences locales
- **Connectivité** : Connectivity Plus

### Modules & Librairies
- `fl_chart` - Graphiques et statistiques
- `pdf` / `printing` - Génération de rapports
- `cached_network_image` - Images optimisées
- `image_picker` - Sélection d'images
- `intl` - Internationalisation

## 📁 Structure du Projet

```
lib/
├── features/              # Modules métier
│   ├── auth/             # Authentification
│   ├── home/             # Écran d'accueil
│   ├── landing/          # Landing page
│   ├── products/         # Gestion des produits
│   ├── sales/            # Gestion des ventes
│   ├── statistics/       # Statistiques & analytics
│   ├── deliveries/       # Gestion des livraisons
│   ├── chat/             # Chat intégré
│   └── about/            # À propos
├── core/                 # Configuration centrale
│   ├── constants/        # Constantes de l'app
│   ├── router/           # Configuration routing
│   └── theme/            # Thème & styles
└── shared/               # Réutilisables
    ├── providers/        # Providers Riverpod partagés
    └── widgets/          # Composants réutilisables
```

## 🚀 Installation & Démarrage

### Prérequis
- Flutter SDK 3.1.0+
- Dart 3.1.0+
- Xcode (pour iOS)
- Android Studio (pour Android)

### Étapes d'installation

1. Cloner le repository
```bash
git clone <repository-url>
cd fellow_drink
```

2. Installer les dépendances
```bash
flutter pub get
```

3. Générer le code (Riverpod, JSON serialization)
```bash
flutter pub run build_runner build
```

4. Lancer l'app
```bash
flutter run
```

## 📦 Dépendances Clés

| Dépendance | Version | Usage |
|-----------|---------|-------|
| supabase_flutter | ^2.3.0 | Backend & API |
| flutter_riverpod | ^2.4.9 | State management |
| go_router | ^13.2.0 | Navigation |
| fl_chart | ^0.67.0 | Graphiques |
| google_fonts | ^6.2.1 | Typographie |
| pdf/printing | ^3.10.8 / ^5.12.0 | Rapports |
| flutter_local_notifications | ^17.0.0 | Notifications |

## 🔧 Configuration

Les constantes de l'app (URLs Supabase, API keys) sont définies dans :
- `lib/core/constants/app_constants.dart`

## 📖 Documentation

Pour plus d'informations sur Flutter, consultez [la documentation officielle](https://docs.flutter.dev/).

## 📄 Licence

Tous droits réservés © 2026 Fellow Drink
