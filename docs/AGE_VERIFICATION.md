# Age Verification Policy — Transitly

> **Version:** 1.0 · **Compliance:** GDPR-ES (Art. 8), LOPDGDD · **Owner:** Legal

## Minimum Age

Transitly requires users to be at least **16 years old** to create an account,
in compliance with the Spanish implementation of GDPR (Ley Orgánica 3/2018 de
Protección de Datos Personales y garantía de los derechos digitales).

---

## Implementation

### Sign-up flow

The sign-up screen (`signup_screen.dart`) collects the user's date of birth:

```dart
// In signup_screen.dart
final birthDate = await showDatePicker(
  context: context,
  initialDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
  firstDate: DateTime(1900),
  lastDate: DateTime.now(),
);

if (birthDate == null) return;

final age = DateTime.now().difference(birthDate).inDays ~/ 365;
if (age < 16) {
  // Show error: must be 16+
  showSnackBar('You must be at least 16 years old to use Transitly');
  return;
}
```

### Database

Age is not stored (privacy-preserving). The sign-up gate validates at the
client side. The birth date is used only for the age check and discarded.

### Terms of Service

The Privacy Policy (`transitly.app/privacy`) states:

> You must be at least 16 years old to use Transitly. By creating an account,
> you confirm that you meet this age requirement.

---

## Legal References

- **GDPR Art. 8**: Conditions applicable to child's consent in relation to
  information society services. Member States may set a lower age, not below 13.
- **LOPDGDD (Spain)**: Sets the minimum age at 14 for general data processing,
  but 16 is adopted by Transitly as the safer, pan-EU standard.
- **DSA (EU 2022/2065)**: Platforms must implement age-appropriate design and
  protections for minors.

---

## Review Cadence

This policy is reviewed annually or when regulatory changes occur.
