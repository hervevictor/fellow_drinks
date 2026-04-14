import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const _features = [
    _Feature('🥤', 'Jus naturels',      'Fruits, légumes, plantes — 100 % pur'),
    _Feature('🍯', 'Sans sucre / miel', 'Idéal pour diabétiques et régimes'),
    _Feature('👶', 'Tous les âges',     'Des enfants aux seniors'),
    _Feature('💚', 'Bienfaits santé',   'Chaque boisson a un rôle précis'),
  ];

  static const _chips = [
    '🌺 Bissap', '🥕 Carotte', '🫚 Gingembre',
    '🌴 Baobab', '🥭 Mangue', '✨ Élégance', '🧠 Béta cocktail',
  ];

  static const _socials = [
    _Social('WhatsApp',  _SocialIcon.whatsapp,  Color(0xFF25D366),
        AppConstants.whatsappUrl),
    _Social('Facebook',  _SocialIcon.facebook,  Color(0xFF1877F2),
        AppConstants.facebookUrl),
    _Social('Instagram', _SocialIcon.instagram, Color(0xFFE4405F),
        AppConstants.instagramUrl),
    _Social('TikTok',    _SocialIcon.tiktok,    Color(0xFF010101),
        AppConstants.tiktokUrl),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _HeroBanner()),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionLabel('Ce que nous offrons'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: _features
                      .map((f) => _FeatureCard(feature: f))
                      .toList(),
                ),
                const SizedBox(height: 20),
                _sectionLabel('Nos saveurs'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _chips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _DrinkChip(label: _chips[i]),
                  ),
                ),
                const SizedBox(height: 24),
                _sectionLabel('Nous contacter'),
                const SizedBox(height: 12),

                // Réseaux sociaux avec vraies icônes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _socials
                      .map((s) => _SocialBtn(social: s))
                      .toList(),
                ),
                const SizedBox(height: 14),

                // Numéro téléphone
                GestureDetector(
                  onTap: () => launchUrl(
                      Uri.parse('tel:${AppConstants.appPhone}')),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_outlined,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(AppConstants.appPhone,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Boutons auth
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: Text('Se connecter',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      )),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => context.go('/register'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                          color: AppColors.primary, width: 2),
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(12)),
                      ),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    child: const Text('Créer un compte'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go('/about'),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                        text: 'En savoir plus → ',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        )),
                      TextSpan(
                        text: 'À propos de nous',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        )),
                    ])),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
      letterSpacing: 0.8,
    ),
  );
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      color: AppColors.primary,
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color.fromRGBO(255, 255, 255, 0.35)),
            ),
            child: const Icon(Icons.local_drink,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 14),
          Text('Fellow Drink',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            )),
          Text('La Passion du Naturel',
            style: GoogleFonts.poppins(
              fontSize: 12, color: Colors.white70,
              letterSpacing: 0.8,
            )),
          const SizedBox(height: 14),
          Text(
            'Breuvages sains & rafraîchissants,\nconçus pour votre bien-être au quotidien.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color.fromRGBO(255, 255, 255, 0.88),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modèles ──────────────────────────────────────────────────────────────────

class _Feature {
  final String emoji, title, desc;
  const _Feature(this.emoji, this.title, this.desc);
}

enum _SocialIcon { whatsapp, facebook, instagram, tiktok }

class _Social {
  final String label;
  final _SocialIcon icon;
  final Color color;
  final String url;
  const _Social(this.label, this.icon, this.color, this.url);
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
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
          Text(feature.emoji,
              style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(feature.title,
            style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(feature.desc,
            style: GoogleFonts.poppins(
              fontSize: 11, color: AppColors.textSecondary,
              height: 1.4),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DrinkChip extends StatelessWidget {
  final String label;
  const _DrinkChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Text(label,
        style: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: const Color(0xFFC45F00))),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final _Social social;
  const _SocialBtn({required this.social});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(social.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri,
              mode: LaunchMode.externalApplication);
        }
      },
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: social.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _SocialSvgIcon(icon: social.icon),
            ),
          ),
          const SizedBox(height: 6),
          Text(social.label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            )),
        ],
      ),
    );
  }
}

// Icônes SVG inline des réseaux sociaux
class _SocialSvgIcon extends StatelessWidget {
  final _SocialIcon icon;
  const _SocialSvgIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    switch (icon) {
      case _SocialIcon.whatsapp:
        return SvgPicture.string(
          '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white">
          <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
          </svg>''',
          width: 28, height: 28,
        );
      case _SocialIcon.facebook:
        return SvgPicture.string(
          '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white">
          <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
          </svg>''',
          width: 26, height: 26,
        );
      case _SocialIcon.instagram:
        return SvgPicture.string(
          '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white">
          <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/>
          </svg>''',
          width: 26, height: 26,
        );
      case _SocialIcon.tiktok:
        return SvgPicture.string(
          '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="white">
          <path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/>
          </svg>''',
          width: 26, height: 26,
        );
    }
  }
}