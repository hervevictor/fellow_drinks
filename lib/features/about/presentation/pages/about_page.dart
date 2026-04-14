import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});
  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late String _missionText;
  late String _descriptionText;

  @override
  void initState() {
    super.initState();
    _missionText = 'Fellow Drink est une marque de haute qualité dédiée à offrir '
        'des breuvages sains et rafraîchissants pour tous les âges. Nous proposons '
        'une large variété de jus de fruits et de légumes soigneusement élaborés — '
        'délicieux et bons pour le bien-être. Des options sans sucre et au miel sont '
        'disponibles pour les personnes diabétiques ou attentives à leur consommation de sucre.';
    _descriptionText = 'Chez Fellow Drink, nous associons nature, santé et saveur dans '
        'chaque bouteille pour vous offrir bien plus qu\'une boisson, mais une meilleure '
        'façon de vivre.';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _editText(String field) {
    final ctrl = TextEditingController(
      text: field == 'mission' ? _missionText : _descriptionText,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  field == 'mission'
                      ? 'Modifier la mission'
                      : 'Modifier la description',
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ctrl,
              maxLines: 6,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (field == 'mission') {
                      _missionText = ctrl.text;
                    } else {
                      _descriptionText = ctrl.text;
                    }
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Que voulez-vous modifier ?',
              style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description_outlined,
                  color: AppColors.primary),
              title: Text('Notre mission',
                  style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _editText('mission');
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_quote_outlined,
                  color: AppColors.primary),
              title: Text('Notre philosophie',
                  style: GoogleFonts.poppins(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _editText('description');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text('À propos',
          style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Modifier',
            onPressed: _showEditMenu,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hero ───────────────────────────────────────────────────
          _HeroBanner(),
          const SizedBox(height: 16),

          // ── Mission ────────────────────────────────────────────────
          _EditableCard(
            label: 'Notre mission',
            title: 'Nature, santé & saveur',
            body: _missionText,
            onEdit: () => _editText('mission'),
            badges: const [
              _BadgeData('100 % naturel', Color(0xFFFFF3E0), Color(0xFFC45F00)),
              _BadgeData('Tous les âges', Color(0xFFE8F5E9), Color(0xFF2E7D32)),
              _BadgeData('Sans sucre',    Color(0xFFE3F2FD), Color(0xFF1565C0)),
              _BadgeData('Au miel',       Color(0xFFFFF8E1), Color(0xFFE65100)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Boissons ───────────────────────────────────────────────
          const _DrinksSection(),
          const SizedBox(height: 16),

          // ── Contact ────────────────────────────────────────────────
          _ContactCard(onLaunch: _launchUrl),
          const SizedBox(height: 16),

          // ── Philosophie ────────────────────────────────────────────
          _EditableCard(
            label: 'Notre philosophie',
            title: 'Une meilleure façon de vivre',
            body: _descriptionText,
            onEdit: () => _editText('description'),
          ),
          const SizedBox(height: 24),

          // ── Footer ─────────────────────────────────────────────────
          Column(
            children: [
              Text(
                'Fellow Drink — La Passion du Naturel',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Text(
                  'Version ${AppConstants.appVersion}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 20),

              // Bouton principal → home
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text("Aller à l'accueil"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(12)),
                    ),
                    textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Lien discret → landing
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(
                  "Retour à la page d'accueil →",
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Hero ──────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE87D1E), Color(0xFFC45F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: const Icon(Icons.local_drink,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 14),
          Text(AppConstants.appName,
            style: GoogleFonts.poppins(
              fontSize: 26, fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text('La Passion du Naturel',
            style: GoogleFonts.poppins(
              fontSize: 13, color: Colors.white70, letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carte modifiable ──────────────────────────────────────────────────────

class _BadgeData {
  final String label;
  final Color bg, fg;
  const _BadgeData(this.label, this.bg, this.fg);
}

class _EditableCard extends StatelessWidget {
  final String label, title, body;
  final VoidCallback onEdit;
  final List<_BadgeData> badges;

  const _EditableCard({
    required this.label,
    required this.title,
    required this.body,
    required this.onEdit,
    this.badges = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.primary, letterSpacing: 0.8,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(title,
            style: GoogleFonts.poppins(
              fontSize: 17, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(body,
            style: GoogleFonts.poppins(
              fontSize: 14, height: 1.75,
              color: AppColors.textSecondary,
            ),
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: badges.map((b) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: b.bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: b.fg.withOpacity(0.3)),
                ),
                child: Text(b.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: b.fg,
                  )),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Section boissons ──────────────────────────────────────────────────────

class _DrinksSection extends StatelessWidget {
  const _DrinksSection();

  static const _drinks = [
    _DrinkData('🌿', 'Jus Persil',         'Santé globale'),
    _DrinkData('🟤', 'Jus de Tamarin',     'Digestion & constipation'),
    _DrinkData('🍹', 'Cocktail de fruits', 'Pour les enfants'),
    _DrinkData('🫚', 'Jus de Gingembre',   'Contre le rhume'),
    _DrinkData('🥕', 'Jus de Carotte',    'Améliore la vision'),
    _DrinkData('🌴', 'Tropicana',          'Esprit plage'),
    _DrinkData('🌺', 'Bissap',             'Perte de sang'),
    _DrinkData('🧠', 'Béta cocktail',      'Santé du cerveau'),
    _DrinkData('🥭', 'Jus de Mangue',      'Anti-cancer'),
    _DrinkData('🌰', 'Jus de Baobab',      'Régule le sucre'),
    _DrinkData('✨', 'Jus Élégance',       'Régime amaigrissant'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text('NOS BOISSONS SIGNATURE',
            style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.primary, letterSpacing: 0.8,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10,
            mainAxisSpacing: 10, childAspectRatio: 1.7,
          ),
          itemCount: _drinks.length,
          itemBuilder: (_, i) {
            final d = _drinks[i];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.emoji,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(d.name,
                    style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  Text(d.benefit,
                    style: GoogleFonts.poppins(
                      fontSize: 10, color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DrinkData {
  final String emoji, name, benefit;
  const _DrinkData(this.emoji, this.name, this.benefit);
}

// ─── Contact avec vrais logos ──────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final Future<void> Function(String) onLaunch;
  const _ContactCard({required this.onLaunch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('NOUS CONTACTER',
            style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.primary, letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SocialButton(
                faIcon: FontAwesomeIcons.phone,
                color: const Color(0xFF4CAF50),
                bgColor: const Color(0xFFE8F5E9),
                label: 'Appel',
                onTap: () => onLaunch('tel:${AppConstants.appPhone}'),
              ),
              _SocialButton(
                faIcon: FontAwesomeIcons.whatsapp,
                color: const Color(0xFF25D366),
                bgColor: const Color(0xFFE8F5E9),
                label: 'WhatsApp',
                onTap: () => onLaunch(AppConstants.whatsappUrl),
              ),
              _SocialButton(
                faIcon: FontAwesomeIcons.facebookF,
                color: const Color(0xFF1877F2),
                bgColor: const Color(0xFFE3F2FD),
                label: 'Facebook',
                onTap: () => onLaunch(AppConstants.facebookUrl),
              ),
              _SocialButton(
                faIcon: FontAwesomeIcons.instagram,
                color: const Color(0xFFE1306C),
                bgColor: const Color(0xFFFCE4EC),
                label: 'Instagram',
                onTap: () => onLaunch(AppConstants.instagramUrl),
              ),
              _SocialButton(
                faIcon: FontAwesomeIcons.tiktok,
                color: const Color(0xFF010101),
                bgColor: const Color(0xFFF5F5F5),
                label: 'TikTok',
                onTap: () => onLaunch(AppConstants.tiktokUrl),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => onLaunch('tel:${AppConstants.appPhone}'),
            onLongPress: () {
              Clipboard.setData(
                  ClipboardData(text: AppConstants.appPhone));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Numéro copié !'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.phone,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(AppConstants.appPhone,
                    style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text('Maintenir pour copier',
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData faIcon;
  final Color color;
  final Color bgColor;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.faIcon,
    required this.color,
    required this.bgColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Center(
              child: FaIcon(faIcon, color: color, size: 22),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}