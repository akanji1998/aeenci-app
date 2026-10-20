import 'package:aeenci_app/core/domain/enums.dart';
import 'package:aeenci_app/features/profile/domain/professional_profile.dart';
import 'package:aeenci_app/features/profile/domain/profile_rules.dart';
import 'package:flutter_test/flutter_test.dart';

ProfessionalProfile profile({
  String? headline,
  String? domain,
  String? city,
  String? summary,
  List<String> skills = const [],
  List<Language> languages = const [],
  List<Experience> experiences = const [],
  String? cv,
  String? linkedin,
  List<PortfolioItem> portfolio = const [],
}) => ProfessionalProfile(
  headline: headline,
  domain: domain,
  city: city,
  summary: summary,
  skills: skills,
  languages: languages,
  experiences: experiences,
  cvUrl: cv,
  linkedinUrl: linkedin,
  portfolio: portfolio,
  isPublic: false,
  showcaseStatus: ShowcaseStatus.private,
);

void main() {
  test('profil vide : 0 %', () {
    expect(profileCompletion(profile()), 0);
  });

  test('chaque critère vaut 12,5 %', () {
    expect(profileCompletion(profile(headline: 'Titre')), 13);
    expect(
      profileCompletion(profile(headline: 'Titre', domain: 'Domaine')),
      25,
    );
    expect(
      profileCompletion(
        profile(
          headline: 'T',
          domain: 'D',
          city: 'V',
          summary: 'P',
          skills: ['Flutter'],
          languages: [const Language(name: 'Français')],
        ),
      ),
      75,
    );
  });

  test('profil complet : 100 %', () {
    expect(
      profileCompletion(
        profile(
          headline: 'T',
          domain: 'D',
          city: 'V',
          summary: 'P',
          skills: ['Flutter'],
          languages: [const Language(name: 'Français')],
          experiences: [
            Experience(
              id: 1,
              title: 'Poste',
              organization: 'Org',
              startedOn: DateTime(2024),
            ),
          ],
          cv: 'https://exemple.com/cv',
        ),
      ),
      100,
    );
  });

  test(
    'texte vide ou espaces : non compté ; LinkedIn et réalisations : bonus',
    () {
      expect(profileCompletion(profile(headline: '   ')), 0);
      expect(
        profileCompletion(
          profile(
            linkedin: 'https://linkedin.com/in/test',
            portfolio: [const PortfolioItem(id: 1, title: 'R')],
          ),
        ),
        0,
      );
    },
  );
}
