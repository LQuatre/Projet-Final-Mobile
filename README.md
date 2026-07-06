# Hub d'Activités Mobiles 🧠🗺️

Ce projet est l'application finale pour l'évaluation mobile (B3), fusionnant deux applications distinctes sous un portail unique de type **Dashboard Bento**.

## Structure du Projet

L'application s'articule autour de la Clean Architecture (Domain / Data / Presentation / UI) et propose un menu de sélection Bento (`DashboardScreen`) regroupant :

### 1. Explorateur de Merveilles 🏛️
Une application de géolocalisation et de découverte des monuments historiques mondiaux :
- **Validation par GPS :** Vérifie via le capteur de position (`geolocator`) si vous êtes à proximité (< 200m) du monument sélectionné.
- **Caméra de validation :** Utilise l'appareil photo du téléphone (`camera`) pour capturer une photo du monument et valider la visite.
- **Sauvegarde persistante :** Stocke votre progression et la liste des monuments explorés localement via `shared_preferences`.

### 2. Quizzty - Quiz de Culture Générale 🎮
Un jeu de quiz dynamique et interactif :
- **Configuration sur mesure :** Sélectionnez le nombre de questions, la catégorie, la difficulté et le type de questions.
- **Traduction automatique à la volée :** Les questions et réponses sont chargées en anglais (OpenTDB API) et traduites en temps réel en français (MyMemory API).
- **Support bilingue :** Un bouton de bascule en bas de page permet d'afficher l'intégralité du quiz (question et options) en version anglaise originale à tout moment.
- **Effets visuels (Confetti) :** Une animation physique et native de projection de paillettes sur les côtés de l'écran se déclenche lors d'une bonne réponse.

---

## Installation & Lancement

1. **Récupérer les dépendances :**
   ```bash
   flutter pub get
   ```
2. **Lancer l'application :**
   ```bash
   flutter run
   ```

## Exécution des Tests

Le projet inclut une suite complète de tests unitaires couvrant la logique du quiz :
```bash
flutter test
```
