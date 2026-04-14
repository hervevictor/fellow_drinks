# Fellow Drink 🥤

**Application mobile de gestion de vente de boissons naturelles** — Plateforme complète pour gérer des produits, des ventes, des livraisons et des statistiques en temps réel.

## 📱 À propos

**Fellow Drink** est une application Flutter cross-platform permettant de :
- 📊 Gérer l'inventaire des produits (boissons naturelles)
- 💰 Suivre les ventes et le chiffre d'affaires
- 📈 Consulter des statistiques détaillées et graphiques
- 🚚 Gérer les livraisons et services
- 💬 Communiquer avec les clients via chat intégré
- 🔔 Recevoir des notifications en temps réel
- 📄 Générer et imprimer des rapports PDF
- 🔐 Authentification sécurisée avec rôles (admin, client, livreur)

## 🛠️ Stack Technique

### Frontend
- **Framework** : Flutter 3.1+
- **Language** : Dart 3.1+
- **State Management** : Riverpod 2.4+
- **Navigation** : Go Router 13.2+
- **Design** : Material Design 3
- **UI**:
  - Google Fonts (Poppins)
  - Font Awesome Icons
  - SVG Support
  - Shimmer Effects

### Backend & Services
- **Database** : Supabase (PostgreSQL)
- **Auth** : Supabase Auth (Email/Password)
- **Notifications** : Flutter Local Notifications
- **Storage** : SharedPreferences (local caching)
- **Connectivity** : Connectivity Plus

### Modules & Librairies Clés
- `fl_chart` - Graphiques et statistiques (bar charts, line charts)
- `pdf` / `printing` - Génération & impression de rapports
- `cached_network_image` - Images optimisées & cachées
- `image_picker` - Sélection d'images depuis galerie/caméra
- `intl` - Internationalisation et formatage de dates
- `equatable` - Comparaison d'objets
- `dartz` - Programmation fonctionnelle (Either, Option)

## 📁 Architecture du Projet

```
lib/
├── core/
│   ├── constants/      # Constantes globales (URL Supabase, clés, etc.)
│   ├── router/         # Configuration Go Router
│   ├── theme/          # Thème Material & AppColors
│   └── widgets/        # Widgets réutilisables
│
├── features/           # Modules métier (feature-driven architecture)
│   ├── auth/
│   │   ├── data/       # Models, repositories
│   │   └── presentation/
│   │
│   ├── landing/        # Landing page publique
│   ├── home/           # Accueil
│   ├── products/       # Gestion des produits
│   ├── sales/          # Gestion des ventes
│   ├── statistics/     # Statistiques & Analytics
│   ├── deliveries/     # Gestion des livraisons
│   ├── chat/           # Messaging
│   └── about/          # À propos
│
├── main.dart           # Point d'entrée
├── app.dart            # Config app & routing
└── shared/             # Code partagé
```

## 🔄 État du Développement

### ✅ Complété
| Feature | État | Notes |
|---------|------|-------|
| **Authentication** | Complété | Login/Register avec Supabase |
| **Landing Page** | Complété | Hero banner, features showcase, socials |
| **Navigation** | Complété | Go Router avec routes protégées |
| **Theme & Design** | Complété | Material Design 3, Material Colors |
| **Project Setup** | Complété | Riverpod, Supabase init, notifications |

### 🟡 En Développement
| Feature | État | Notes |
|---------|------|-------|
| **Home Page** | Étape 6 | Placeholder UI de base avec bottom nav |
| **Products** | Stub | Pages créées, logique à implémenter |
| **Sales** | Stub | Gestion des ventes, receipt page |
| **Statistics** | Stub | Dashboard avec graphiques FL Chart |
| **Deliveries** | Stub | Tracking & gestion livraisons |
| **Chat** | Stub | Real-time messaging |

### 🔳 Non Commencé
| Feature | Détails |
|---------|---------|
| **About Page** | Standalone page |

## 🚀 Installation & Démarrage

### Prérequis
- Flutter SDK 3.1.0+
- Dart 3.1.0+
- Xcode (pour iOS)
- Android Studio (pour Android)
- Visual Studio Code ou Android Studio

### Étapes d'installation

1. **Cloner le repository**
```bash
git clone https://github.com/hervevictor/fellow_drinks.git
cd fellow_drinks
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Générer le code (Riverpod, JSON serialization)**
```bash
flutter pub run build_runner build
```

4. **Configurer les variables d'environnement**
   - Ajouter les clés Supabase dans `lib/core/constants/app_constants.dart`

5. **Lancer l'application**
```bash
flutter run
```

## 📦 Dépendances Complètes

**Principales** : supabase_flutter, flutter_riverpod, go_router, fl_chart, google_fonts, pdf, printing, flutter_local_notifications

Voir [pubspec.yaml](pubspec.yaml) pour la liste complète avec versions.

## 🏗️ Architecture & Patterns

### Feature-Driven Architecture
Chaque feature suit la structure :
```
feature/
├── data/        # Models, repositories, API calls
├── domain/      # Entities, use cases
└── presentation/# Pages, widgets, providers
```

### State Management: Riverpod
- **StateNotifierProvider** pour états mutables
- **FutureProvider** pour appels async
- **Provider** pour computations pures

### Routing: Go Router
- Configuration centralisée dans `core/router/app_router.dart`
- Guards d'authentification basées sur session Supabase

## 🔧 Configuration & Constantes

Les constantes sont centralisées dans :
- **`lib/core/constants/app_constants.dart`**
  - `supabaseUrl` - URL Supabase
  - `supabaseAnonKey` - Clé anonyme
  - URLs sociales

Les thèmes sont dans :
- **`lib/core/theme/app_theme.dart`**
  - `AppColors` avec palette Material Design

## 📖 Commandes Utiles

```bash
# Générer code
flutter pub run build_runner build

# Nettoyer et régénérer
flutter clean && flutter pub get && flutter pub run build_runner build

# Vérifier la syntaxe
flutter analyze

# Build Android
flutter build apk --release

# Build iOS
flutter build ios --release
```

## 🤝 Contribution

Fork → Feature branch → Commit → Push → Pull Request

## 🐛 Issues & Support

Ouvrir une [issue GitHub](https://github.com/hervevictor/fellow_drinks/issues) pour signaler un bug ou proposer une amélioration.

## 📄 Licence

Tous droits réservés © 2026 Fellow Drink

---

**Dernière mise à jour** : 14 avril 2026
