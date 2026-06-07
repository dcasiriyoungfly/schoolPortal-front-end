import 'package:flutter/material.dart';
import 'package:schoolwebsite/models/models.dart';
import 'package:schoolwebsite/screens/login_screen.dart';
import 'package:schoolwebsite/services/file_picker_service.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';

// ── Colour palette (matches school brand) ─────────────────────────────────────
const _navy = Color(0xFF0D2240);
const _navyLight = Color(0xFF1E3A5F);
const _accent = Color(0xFF2563EB);
const _gold = Color(0xFFF59E0B);
const _white = Colors.white;
const _offWhite = Color(0xFFF8FAFC);
const _textGrey = Color(0xFF64748B);

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();
  final _homeKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _studentsKey = GlobalKey();
  final _applyKey = GlobalKey();

  bool _navScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 60;
      if (scrolled != _navScrolled) setState(() => _navScrolled = scrolled);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
  }

  void _goToPortal() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;

    return Scaffold(
      backgroundColor: _offWhite,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Spacer for the fixed navbar height
                const SizedBox(height: 72),
                _HeroSection(
                  key: _homeKey,
                  isMobile: isMobile,
                  onApply: () => _scrollTo(_applyKey),
                  onPortal: _goToPortal,
                ),
                _AboutSection(key: _aboutKey, isMobile: isMobile),
                _StudentsLifeSection(key: _studentsKey, isMobile: isMobile),
                _ApplicationSection(key: _applyKey, isMobile: isMobile, onPortal: _goToPortal),
                _Footer(onPortal: _goToPortal),
              ],
            ),
          ),
          // Fixed navigation bar
          _NavBar(
            scrolled: _navScrolled,
            isMobile: isMobile,
            onHome: () => _scrollTo(_homeKey),
            onAbout: () => _scrollTo(_aboutKey),
            onStudents: () => _scrollTo(_studentsKey),
            onApply: () => _scrollTo(_applyKey),
            onPortal: _goToPortal,
          ),
        ],
      ),
    );
  }
}

// ── Navigation Bar ────────────────────────────────────────────────────────────

class _NavBar extends StatefulWidget {
  final bool scrolled;
  final bool isMobile;
  final VoidCallback onHome;
  final VoidCallback onAbout;
  final VoidCallback onStudents;
  final VoidCallback onApply;
  final VoidCallback onPortal;

  const _NavBar({
    required this.scrolled,
    required this.isMobile,
    required this.onHome,
    required this.onAbout,
    required this.onStudents,
    required this.onApply,
    required this.onPortal,
  });

  @override
  State<_NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<_NavBar> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 72,
            color: widget.scrolled
                ? _navy.withValues(alpha: 0.98)
                : _navy,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Logo
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.school_rounded, color: _navy, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Excellence',
                          style: TextStyle(color: _white, fontSize: 15,
                              fontWeight: FontWeight.w800, height: 1.1)),
                        Text('High School',
                          style: TextStyle(color: _gold, fontSize: 11,
                              fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                if (!widget.isMobile) ...[
                  _NavLink('Home', widget.onHome),
                  _NavLink('About', widget.onAbout),
                  _NavLink('Students Life', widget.onStudents),
                  _NavLink('Apply', widget.onApply),
                  const SizedBox(width: 12),
                  _NavButton('Portal Login', widget.onPortal),
                ] else
                  IconButton(
                    icon: Icon(_menuOpen ? Icons.close : Icons.menu,
                        color: _white),
                    onPressed: () => setState(() => _menuOpen = !_menuOpen),
                  ),
              ],
            ),
          ),
          // Mobile dropdown menu
          if (widget.isMobile && _menuOpen)
            Container(
              color: _navyLight,
              child: Column(
                children: [
                  _MobileNavItem('Home', widget.onHome, () => setState(() => _menuOpen = false)),
                  _MobileNavItem('About', widget.onAbout, () => setState(() => _menuOpen = false)),
                  _MobileNavItem('Students Life', widget.onStudents, () => setState(() => _menuOpen = false)),
                  _MobileNavItem('Apply', widget.onApply, () => setState(() => _menuOpen = false)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: _navy,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: widget.onPortal,
                        child: const Text('Portal Login', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hovered ? _gold : _white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavButton(this.label, this.onTap);

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _gold : Colors.transparent,
            border: Border.all(color: _hovered ? _gold : _white.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hovered ? _navy : _white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onClose;
  const _MobileNavItem(this.label, this.onTap, this.onClose);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () { onTap(); onClose(); },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: _white.withValues(alpha: 0.1))),
        ),
        child: Text(label, style: const TextStyle(color: _white, fontSize: 15)),
      ),
    );
  }
}

// ── Hero Section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onApply;
  final VoidCallback onPortal;

  const _HeroSection({
    super.key,
    required this.isMobile,
    required this.onApply,
    required this.onPortal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: isMobile ? 520 : 620),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'lib/images/Facebook-St-Georges-College-1-min.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: _navyLight),
            ),
          ),
          // Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _navy.withValues(alpha: 0.92),
                    _navy.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 80,
              vertical: 64,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.15),
                    border: Border.all(color: _gold.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Academic Year 2025 / 2026',
                    style: TextStyle(color: _gold, fontSize: 12,
                        fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Inspiring\nExcellence\nThrough Education',
                  style: TextStyle(
                    color: _white,
                    fontSize: isMobile ? 34 : 54,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Shaping the next generation of leaders through\nacademic excellence, character, and purpose.',
                  style: TextStyle(
                    color: _white.withValues(alpha: 0.8),
                    fontSize: isMobile ? 14 : 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 40),
                // Stats row
                if (!isMobile)
                  Row(
                    children: [
                      _StatBadge('96%', 'Pass Rate'),
                      const SizedBox(width: 32),
                      _StatBadge('12:1', 'Student-Teacher\nRatio'),
                      const SizedBox(width: 32),
                      _StatBadge('50+', 'Co-Curricular\nActivities'),
                    ],
                  )
                else
                  Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: const [
                      _StatBadge('96%', 'Pass Rate'),
                      _StatBadge('12:1', 'S/T Ratio'),
                      _StatBadge('50+', 'Activities'),
                    ],
                  ),
                const SizedBox(height: 40),
                // CTA buttons
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _HeroButton(
                      label: 'Apply Now',
                      primary: true,
                      onTap: onApply,
                    ),
                    _HeroButton(
                      label: 'Student Portal',
                      primary: false,
                      onTap: onPortal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  const _StatBadge(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
          style: const TextStyle(
            color: _gold, fontSize: 28,
            fontWeight: FontWeight.w900,
          )),
        Text(label,
          style: TextStyle(
            color: _white.withValues(alpha: 0.7),
            fontSize: 11,
            height: 1.3,
            letterSpacing: 0.3,
          )),
      ],
    );
  }
}

class _HeroButton extends StatefulWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _HeroButton({required this.label, required this.primary, required this.onTap});

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: widget.primary
                ? (_hovered ? _gold : _accent)
                : Colors.transparent,
            border: Border.all(
              color: widget.primary ? Colors.transparent : _white.withValues(alpha: 0.6),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.primary ? _white : _white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── About Section ─────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final bool isMobile;

  const _AboutSection({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 56 : 88,
      ),
      child: isMobile
          ? _AboutContent(isMobile: true)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(flex: 5, child: _AboutContent(isMobile: false)),
                const SizedBox(width: 64),
                Expanded(flex: 4, child: _AboutImage()),
              ],
            ),
    );
  }
}

class _AboutContent extends StatelessWidget {
  final bool isMobile;
  const _AboutContent({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionBadge('About Us'),
        const SizedBox(height: 16),
        Text(
          'A Legacy of\nAcademic Excellence',
          style: TextStyle(
            color: _navy,
            fontSize: isMobile ? 26 : 36,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Excellence High School has been a beacon of quality education for over four decades. '
          'We nurture curious minds, foster discipline, and develop well-rounded individuals '
          'prepared to excel in university, careers, and life.',
          style: TextStyle(color: _textGrey, fontSize: 15, height: 1.7),
        ),
        const SizedBox(height: 20),
        const Text(
          'Our dedicated staff, world-class facilities, and rich co-curricular programme '
          'ensure every student receives a holistic education aligned with national and '
          'international standards.',
          style: TextStyle(color: _textGrey, fontSize: 15, height: 1.7),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 20,
          runSpacing: 16,
          children: const [
            _FeaturePill(Icons.emoji_events_rounded, 'Nationally Accredited'),
            _FeaturePill(Icons.groups_rounded, 'Inclusive Community'),
            _FeaturePill(Icons.science_rounded, 'STEM Focused'),
            _FeaturePill(Icons.sports_soccer_rounded, 'Sports & Arts'),
          ],
        ),
        if (isMobile) ...[
          const SizedBox(height: 32),
          _AboutImage(),
        ],
      ],
    );
  }
}

class _AboutImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.asset(
          'lib/images/WhatsApp Image 2026-03-31 at 09.40.33.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: _navyLight.withValues(alpha: 0.15),
            child: const Icon(Icons.school_rounded, size: 80, color: _navyLight),
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accent, size: 15),
          const SizedBox(width: 6),
          Text(label,
            style: const TextStyle(color: _navyLight, fontSize: 12,
                fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Students Life Section ─────────────────────────────────────────────────────

class _StudentsLifeSection extends StatelessWidget {
  final bool isMobile;

  const _StudentsLifeSection({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _offWhite,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 56 : 88,
      ),
      child: Column(
        children: [
          const _SectionBadge('Students Life'),
          const SizedBox(height: 16),
          Text(
            'Life at Excellence High School',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _navy,
              fontSize: isMobile ? 26 : 36,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Beyond the classroom — discover a vibrant campus life filled with sport,\n'
            'arts, leadership, and community.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _textGrey, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 48),
          // Image grid
          isMobile
              ? Column(
                  children: [
                    _LifeCard(
                      imageAsset: 'lib/images/WhatsApp Image 2026-03-31 at 09.40.33 (1).jpeg',
                      title: 'Sports & Athletics',
                      description: 'Championship-winning teams across football, athletics, basketball and swimming.',
                      icon: Icons.sports_soccer_rounded,
                    ),
                    const SizedBox(height: 20),
                    _LifeCard(
                      imageAsset: 'lib/images/WhatsApp Image 2026-03-31 at 09.40.34.jpeg',
                      title: 'Arts & Culture',
                      description: 'Drama, music, debate and fine arts clubs that celebrate creativity and expression.',
                      icon: Icons.palette_rounded,
                    ),
                    const SizedBox(height: 20),
                    _LifeCard(
                      imageAsset: 'lib/images/Facebook-St-Georges-College-1-min.jpg',
                      title: 'Leadership & Service',
                      description: 'Student council, community outreach and leadership programmes building tomorrow\'s leaders.',
                      icon: Icons.star_rounded,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _LifeCard(
                        imageAsset: 'lib/images/WhatsApp Image 2026-03-31 at 09.40.33 (1).jpeg',
                        title: 'Sports & Athletics',
                        description: 'Championship-winning teams across football, athletics, basketball and swimming.',
                        icon: Icons.sports_soccer_rounded,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _LifeCard(
                        imageAsset: 'lib/images/WhatsApp Image 2026-03-31 at 09.40.34.jpeg',
                        title: 'Arts & Culture',
                        description: 'Drama, music, debate and fine arts clubs that celebrate creativity and expression.',
                        icon: Icons.palette_rounded,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _LifeCard(
                        imageAsset: 'lib/images/Facebook-St-Georges-College-1-min.jpg',
                        title: 'Leadership & Service',
                        description: 'Student council, community outreach and leadership programmes building leaders.',
                        icon: Icons.star_rounded,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _LifeCard extends StatefulWidget {
  final String imageAsset;
  final String title;
  final String description;
  final IconData icon;

  const _LifeCard({
    required this.imageAsset,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  State<_LifeCard> createState() => _LifeCardState();
}

class _LifeCardState extends State<_LifeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: _hovered ? 0.15 : 0.06),
              blurRadius: _hovered ? 24 : 12,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        transform: _hovered
            ? Matrix4.translationValues(0.0, -4.0, 0.0)
            : Matrix4.identity(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  widget.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: _navyLight.withValues(alpha: 0.12),
                    child: Icon(widget.icon, size: 60, color: _navyLight),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(widget.icon, color: _accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(widget.title,
                            style: const TextStyle(
                              color: _navy, fontSize: 16,
                              fontWeight: FontWeight.w800,
                            )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(widget.description,
                      style: const TextStyle(
                        color: _textGrey, fontSize: 13, height: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Application Section ───────────────────────────────────────────────────────

class _ApplicationSection extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onPortal;

  const _ApplicationSection({
    super.key,
    required this.isMobile,
    required this.onPortal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _navy,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: isMobile ? 56 : 88,
      ),
      child: isMobile
          ? _ApplicationContent(isMobile: true, onPortal: onPortal)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _ApplicationContent(isMobile: false, onPortal: onPortal),
                ),
                const SizedBox(width: 64),
                const Expanded(flex: 4, child: _ApplicationForm()),
              ],
            ),
    );
  }
}

class _ApplicationContent extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onPortal;
  const _ApplicationContent({required this.isMobile, required this.onPortal});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.15),
            border: Border.all(color: _gold.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text('Admissions 2026',
            style: TextStyle(color: _gold, fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 20),
        Text(
          'Begin Your\nJourney with Us',
          style: TextStyle(
            color: _white,
            fontSize: isMobile ? 28 : 38,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'We welcome applications from highly motivated students who share '
          'our passion for learning and excellence. Enrolment is open for '
          'Form 1 and limited positions in Form 2–4.',
          style: TextStyle(
            color: _white.withValues(alpha: 0.75),
            fontSize: 15,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 32),
        ...[
          _ApplyStep('1', 'Submit your enquiry form below'),
          _ApplyStep('2', 'Receive application pack via email'),
          _ApplyStep('3', 'Sit the entrance assessment'),
          _ApplyStep('4', 'Await admission decision within 2 weeks'),
        ],
        const SizedBox(height: 32),
        _OutlineButton(
          label: 'Student & Staff Portal Login',
          icon: Icons.login_rounded,
          onTap: onPortal,
        ),
        if (isMobile) const SizedBox(height: 40),
        if (isMobile) const _ApplicationForm(),
      ],
    );
  }
}

class _ApplyStep extends StatelessWidget {
  final String step;
  final String text;
  const _ApplyStep(this.step, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(step, style: const TextStyle(
                color: _navy, fontSize: 12, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text, style: TextStyle(
                color: _white.withValues(alpha: 0.8), fontSize: 14, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          decoration: BoxDecoration(
            color: _hovered ? _gold : Colors.transparent,
            border: Border.all(color: _hovered ? _gold : _gold.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                color: _hovered ? _navy : _gold, size: 18),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  color: _hovered ? _navy : _gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationForm extends StatefulWidget {
  const _ApplicationForm();

  @override
  State<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<_ApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _prevSchoolController = TextEditingController();
  final _reasonController = TextEditingController();
  String _selectedForm = 'Form 1';
  bool _submitted = false;
  String? _resultsFileName;
  bool _pickingFile = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _prevSchoolController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _pickingFile = true);
    final name = await pickResultsFile();
    if (mounted) setState(() { _resultsFileName = name; _pickingFile = false; });
  }

  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final app = StudentApplication(
        id: '',
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        formApplyingFor: _selectedForm,
        previousSchool: _prevSchoolController.text.trim(),
        reasonForLeaving: _reasonController.text.trim(),
        resultsFileName: _resultsFileName,
        submittedAt: DateTime.now(),
      );
      await AppStateProvider.read(context).submitApplication(app);
      if (mounted) setState(() => _submitted = true);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _navyLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _white.withValues(alpha: 0.1)),
      ),
      child: _submitted
          ? _SuccessState()
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Application Form',
                      style: TextStyle(
                          color: _white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Complete all fields and attach your previous term results.',
                      style: TextStyle(
                          color: _white.withValues(alpha: 0.6), fontSize: 13)),
                  const SizedBox(height: 24),

                  // ── Personal details ──────────────────────────────────────
                  _FormField(
                    controller: _nameController,
                    label: "Student's Full Name",
                    hint: 'e.g. Takudzwa Musere',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 14),
                  _FormField(
                    controller: _emailController,
                    label: 'Parent / Guardian Email',
                    hint: 'email@example.com',
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 14),
                  _FormField(
                    controller: _phoneController,
                    label: 'Contact Phone Number',
                    hint: '+263 77 123 4567',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Phone is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Form level ────────────────────────────────────────────
                  _DropdownField(
                    label: 'Applying For',
                    value: _selectedForm,
                    items: const ['Form 1', 'Form 2', 'Form 3', 'Form 4'],
                    onChanged: (v) => setState(() => _selectedForm = v!),
                  ),
                  const SizedBox(height: 14),

                  // ── Previous school ───────────────────────────────────────
                  _FormField(
                    controller: _prevSchoolController,
                    label: 'Previous School Attended',
                    hint: 'e.g. St. John\'s Primary School',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Previous school is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Reason for leaving ────────────────────────────────────
                  _FormField(
                    controller: _reasonController,
                    label: 'Reason for Leaving Previous School',
                    hint: 'Briefly describe why you are leaving...',
                    maxLines: 3,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Please provide a reason' : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Results file upload ───────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Previous Term Results',
                          style: TextStyle(
                              color: _white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Attach a photo or PDF of your last report card.',
                          style: TextStyle(
                              color: _white.withValues(alpha: 0.45),
                              fontSize: 11)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickingFile ? null : _pickFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _white.withValues(alpha: 0.07),
                            border: Border.all(
                                color: _resultsFileName != null
                                    ? _gold.withValues(alpha: 0.6)
                                    : _white.withValues(alpha: 0.2),
                                width: _resultsFileName != null ? 1.5 : 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _resultsFileName != null
                                    ? Icons.check_circle_rounded
                                    : Icons.attach_file_rounded,
                                color: _resultsFileName != null
                                    ? _gold
                                    : _white.withValues(alpha: 0.5),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _pickingFile
                                    ? Text('Opening file picker…',
                                        style: TextStyle(
                                            color: _white.withValues(alpha: 0.5),
                                            fontSize: 13))
                                    : Text(
                                        _resultsFileName ??
                                            'Tap to attach results (image or PDF)',
                                        style: TextStyle(
                                            color: _resultsFileName != null
                                                ? _white
                                                : _white.withValues(alpha: 0.4),
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                              if (_resultsFileName != null)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _resultsFileName = null),
                                  child: Icon(Icons.close_rounded,
                                      color: _white.withValues(alpha: 0.4),
                                      size: 16),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _navy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _navy,
                              ),
                            )
                          : const Text('Submit Application'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: _white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _white.withValues(alpha: 0.07),
            border: Border.all(color: _white.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: _navyLight,
              style: const TextStyle(color: _white, fontSize: 14),
              iconEnabledColor: _white,
              items: items
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: _gold, size: 36),
        ),
        const SizedBox(height: 20),
        const Text('Enquiry Submitted!',
          style: TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Text(
          'Thank you for your interest. Our admissions team will contact you within 48 hours.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _white.withValues(alpha: 0.7), fontSize: 14, height: 1.6),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: const TextStyle(color: _white, fontSize: 12,
              fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(color: _white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _white.withValues(alpha: 0.35), fontSize: 14),
            filled: true,
            fillColor: _white.withValues(alpha: 0.07),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _white.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _white.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _gold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final VoidCallback onPortal;
  const _Footer({required this.onPortal});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF060F1A),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Branding
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.school_rounded, color: _navy, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text('Excellence High School',
                          style: TextStyle(color: _white, fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Shaping tomorrow\'s leaders\nthrough academic excellence.',
                      style: TextStyle(
                        color: _white.withValues(alpha: 0.5),
                        fontSize: 13, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Quick links
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Links',
                      style: TextStyle(color: _white.withValues(alpha: 0.4),
                          fontSize: 11, letterSpacing: 0.8,
                          fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...[
                      'About Us', 'Students Life', 'Admissions', 'Portal Login',
                    ].map((link) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: link == 'Portal Login' ? onPortal : null,
                        child: Text(link,
                          style: TextStyle(
                            color: _white.withValues(alpha: 0.6),
                            fontSize: 13)),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Contact
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact',
                      style: TextStyle(color: _white.withValues(alpha: 0.4),
                          fontSize: 11, letterSpacing: 0.8,
                          fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...[
                      ('info@excellencehigh.ac.zw', Icons.email_rounded),
                      ('+263 242 123 456', Icons.phone_rounded),
                      ('123 Excellence Road, Harare', Icons.location_on_rounded),
                    ].map(((String, IconData) item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.$2,
                            color: _gold.withValues(alpha: 0.7), size: 13),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item.$1,
                              style: TextStyle(
                                color: _white.withValues(alpha: 0.55),
                                fontSize: 12, height: 1.4)),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: _white.withValues(alpha: 0.08)),
          const SizedBox(height: 16),
          Text(
            '© 2026 Excellence High School. All rights reserved. · Academic Year 2025/2026 · Term 1',
            style: TextStyle(color: _white.withValues(alpha: 0.3), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionBadge extends StatelessWidget {
  final String label;
  const _SectionBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.08),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label.toUpperCase(),
        style: const TextStyle(
          color: _accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        )),
    );
  }
}
