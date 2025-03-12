class OnboardingContent {
  final String title;
  final String description;
  final String imagePath;
  final bool isLogo;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.imagePath,
    this.isLogo = false,
  });
}

final List<OnboardingContent> onboardingContents = [
  OnboardingContent(
    title: 'Welcome to our App',
    description: 'The best way to pay for everything',
    imagePath: 'assets/logo_app.png',
    isLogo: true,
  ),
  OnboardingContent(
    title: 'Fastest Payment in the world',
    description:
        'Integrate multiple payment methods to help you up the process quickly',
    imagePath: 'assets/splash_img.png',
  ),
  OnboardingContent(
    title: 'The most Secoure Platfrom for Customer',
    description:
        'Built-in Fingerprint, face recognition and more, keeping you completely safe',
    imagePath: 'assets/splash_imgg.png',
  ),
  OnboardingContent(
    title: 'Paying for Everything is Easy and Convenient',
    description:
        'Built-in Fingerprint, face recognition and more, keeping you completely safe',
    imagePath: 'assets/splash_imggg.png',
  ),
];
