import 'package:flutter/foundation.dart';

import '../../../core/domain/date_only.dart';

String? _blankToNull(String? value) =>
    value == null || value.trim().isEmpty ? null : value.trim();

/// Contacts modifiables de la fiche (`PATCH /me`).
@immutable
class ContactUpdate {
  const ContactUpdate({
    required this.phone,
    required this.email,
    required this.city,
    this.whatsapp,
    this.address,
  });

  final String phone;
  final String? whatsapp;
  final String email;
  final String? address;
  final String city;

  Map<String, Object?> toJson() => {
    'phone': phone.trim(),
    'whatsapp': _blankToNull(whatsapp),
    'email': email.trim(),
    'address': _blankToNull(address),
    'city': city.trim(),
  };
}

/// Une formation (`/me/educations`).
@immutable
class EducationInput {
  const EducationInput({
    required this.level,
    required this.school,
    required this.fieldOfStudy,
    this.diploma,
    this.startYear,
    this.endYear,
  });

  final String level;
  final String school;
  final String fieldOfStudy;
  final String? diploma;
  final int? startYear;

  /// `null` : formation en cours.
  final int? endYear;

  Map<String, Object?> toJson() => {
    'level': level,
    'school': school.trim(),
    'field_of_study': fieldOfStudy.trim(),
    'diploma': _blankToNull(diploma),
    'start_year': startYear,
    'end_year': endYear,
  };
}

/// Une expérience (`/me/experiences`).
@immutable
class ExperienceInput {
  const ExperienceInput({
    required this.title,
    required this.organization,
    required this.startedOn,
    this.endedOn,
    this.location,
    this.description,
  });

  final String title;
  final String organization;
  final String? location;
  final DateTime startedOn;

  /// `null` : poste occupé actuellement.
  final DateTime? endedOn;
  final String? description;

  Map<String, Object?> toJson() => {
    'title': title.trim(),
    'organization': organization.trim(),
    'location': _blankToNull(location),
    'started_on': const DateOnlyConverter().toJson(startedOn),
    'ended_on': const NullableDateOnlyConverter().toJson(endedOn),
    'description': _blankToNull(description),
  };
}

/// Une réalisation (`/me/portfolio-items`), avec un fichier facultatif.
@immutable
class PortfolioInput {
  const PortfolioInput({
    required this.title,
    this.description,
    this.url,
    this.filePath,
  });

  final String title;
  final String? description;
  final String? url;

  /// Fichier local à envoyer (`file`), s'il y en a un.
  final String? filePath;

  Map<String, Object?> toJson() => {
    'title': title.trim(),
    'description': _blankToNull(description),
    'url': _blankToNull(url),
  };
}
