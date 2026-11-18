# Actus

App iOS personnelle pour suivre l'actualité de la France et du monde : sans réseaux sociaux, sans abonnement, sans compte. Elle agrège des flux RSS publics et gratuits.

## Fonctionnalités
- Rubriques : France, Monde, Économie, Tech, Sport & santé, Culture, Science
- Sources RSS gratuites (aucun paywall), activables une à une, plus ajout de ses propres flux
- Lu / non lu, filtre « Français uniquement », mots-clés masqués, recherche
- Cache hors-ligne (7 jours)
- Résumés IA (article et « l'essentiel du jour ») générés sur l'appareil avec Apple Intelligence

## Développement
Prérequis : Xcode 27, iOS 26+ et [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
xcodegen generate
open Actus.xcodeproj
```

Les sources par défaut sont dans `Actus/Models/FeedSource.swift`. L'icône se régénère avec `python3 Tools/make_icon.py` (Pillow requis).
