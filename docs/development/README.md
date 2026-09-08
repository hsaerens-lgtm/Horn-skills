# Guide de développement d'Arness (pour non-développeur)

Ce guide explique ce qui est installé, ce qui agit tout seul, ce que vous lancez vous-même, et comment lire un résultat. Détails techniques : [TOOLCHAIN.md](TOOLCHAIN.md). Façon de travailler : [WORKFLOW.md](WORKFLOW.md). Où en est le projet : [STATUS.md](STATUS.md).

## 1. Ce qui est installé et à quoi ça sert

| Élément | À quoi ça sert | Agit tout seul ? |
|---|---|---|
| **TypeScript + Vitest** | le langage du projet et le moteur de tests qui vérifie que le code fait ce qu'on attend | non : `npm test`, `npm run check` |
| **Superpowers** (plugin Claude Code) | la méthode de travail de Claude : cadrer, planifier, tester d'abord, déboguer méthodiquement, vérifier avant de conclure | oui, chargé à chaque session |
| **typescript-lsp** (plugin) | Claude « voit » les erreurs de type après chaque modification et retrouve définitions et références | oui, en arrière-plan |
| **Context7** (`/find-docs`) | documentation à jour des bibliothèques, à la version installée | oui quand Claude en a besoin ; ou à la demande |
| **Gitleaks** | détecte des mots de passe ou clés oubliés dans les fichiers ; les valeurs sont toujours masquées | non : inclus dans `npm run check` |
| **Scripts `scripts/dev/`** | diagnostic, lancement, vérification, préparation d'un paquet | non : vous les lancez |
| **Skills `/horn-*`** | vos six commandes dans Claude Code | non : vous les tapez |
| **Règles `.claude/rules/`** | consignes que Claude suit (tests, sécurité, workflow) | oui |
| **CI GitHub + Dependabot** | rejoueront les contrôles et proposeront des mises à jour **une fois le dépôt sur GitHub** | pas encore : aucun dépôt distant |

## 2. Vos six commandes dans Claude Code

Exemples adaptés au projet actuel (une application qui, pour l'instant, affiche seulement son nom et sa version).

| Commande | Quand | Exemple |
|---|---|---|
| `/horn-feature` | ajouter ou changer un comportement | `/horn-feature Ajouter une commande "arness hello <nom>" qui salue la personne` |
| `/horn-bugfix` | quelque chose ne marche pas | `/horn-bugfix "node dist/index.js --version" affiche "undefined" au lieu de la version` |
| `/horn-check` | savoir si tout passe, sans rien changer | `/horn-check` (rapide) · `/horn-check full` (avant livraison) |
| `/horn-review` | relire avant de valider | `/horn-review` (diff courant) · `/horn-review src/app-info.ts tests/app-info.test.ts` |
| `/horn-release` | préparer un paquet installable, sans publier | `/horn-release` · `/horn-release 0.2.0` (vous confirmez le changement de version) |
| `/horn-resume` | reprendre après une pause | `/horn-resume` |

Ce que fait chaque commande, ses sorties et ses limites sont écrits dans `.claude/skills/horn-*/SKILL.md`.

## 3. Comment les composants travaillent ensemble

Quand vous tapez `/horn-feature …`, Claude lit l'état du projet, reformule le besoin, vous fait valider les choix importants, écrit une fiche de tâche, planifie avec Superpowers, code par petits pas en écrivant les tests d'abord, consulte Context7 pour les bibliothèques, lance `npm run check`, demande une revue séparée et met à jour `STATUS.md`. Chaque étape laisse une trace (fiche, rapport dans `reports/dev/`, diff Git). Le détail est dans [WORKFLOW.md](WORKFLOW.md).

## 4. Utiliser chaque outil séparément

- **Documentation seule** : `/find-docs comment configurer les seuils de couverture Vitest` ou dans un terminal `npx ctx7@latest library vitest "coverage thresholds"`.
- **Tests seuls** : `npm test` (une fois), `npm run test:watch` (relance à chaque sauvegarde), `npm run test:coverage`.
- **Typage seul** : `npm run typecheck`.
- **Secrets seuls** : ouvrir un nouveau terminal puis `gitleaks dir . --config .gitleaks.toml --redact`.
- **Relecture seule** : `git diff` dans le terminal, ou `/horn-review`.
- **Diagnostic de l'environnement** : `npm run doctor`.

## 5. Démarrer, tester, préparer une version

```bash
npm ci
```
Installe exactement les dépendances verrouillées (à faire après un clone ou si `node_modules/` a disparu).

```bash
npm run dev
```
Lance l'application depuis les sources. `npm run dev -- --version` affiche la version.

```bash
npm run check
```
Vérification rapide : typage, tests, secrets. Rapport lisible dans `reports/dev/check-quick-<date>.md`.

```bash
npm run check:full
```
Vérification complète : ajoute couverture, compilation, lancement de la version compilée, historique Git, audit des dépendances.

```bash
npm run package
```
Prépare `dist-packages/arness-<version>.tgz`, son empreinte SHA-256 et `INSTALL-<version>.md` (installation et retour arrière). Refuse de produire le paquet si la vérification complète n'est pas RÉUSSIE. Ne publie rien.

## 6. Comment lire un échec

1. Regardez la dernière ligne de `npm run check` : **SUCCÈS**, **ÉCHEC** (un contrôle obligatoire a échoué) ou **NON VÉRIFIÉ** (un contrôle obligatoire n'a pas pu être lancé, par exemple Gitleaks absent).
2. Ouvrez le rapport indiqué (`reports/dev/check-…md`). Le tableau donne le statut de chaque contrôle : RÉUSSI, ÉCHOUÉ, NON EXÉCUTÉ, NON APPLICABLE.
3. Pour un contrôle ÉCHOUÉ, ouvrez son journal dans `reports/dev/logs/<horodatage>/<contrôle>.log` : pour un test, Vitest indique le fichier, le nom du test, la valeur attendue et la valeur obtenue ; pour le typage, `tsc` indique `fichier(ligne,colonne): erreur`.
4. Demandez ensuite `/horn-bugfix <copie du message>`. Ne modifiez jamais un test pour le faire passer.

Codes de sortie des scripts : 0 succès · 1 échec · 2 non vérifié · 3 usage.

## 7. Désactiver ou désinstaller un composant

Chaque composant a ses commandes exactes dans [TOOLCHAIN.md](TOOLCHAIN.md). En résumé :

- Superpowers ou typescript-lsp : `claude plugin disable <plugin>@claude-plugins-official --scope project` (réversible), `claude plugin uninstall …` (retrait).
- Context7 : `npx ctx7@latest remove --claude --cli` dans le projet.
- Gitleaks : `winget uninstall --id Gitleaks.Gitleaks --exact` (la vérification passera alors en NON VÉRIFIÉ, volontairement).
- Un skill `/horn-*` : supprimer son dossier dans `.claude/skills/`.

## 8. Mettre à jour sans casser l'environnement

1. Lancez `npm run check:full` avant : vous devez partir d'un état SUCCÈS.
2. Mettez à jour un composant à la fois (commandes dans TOOLCHAIN.md : `npm install -D … --save-exact`, `claude plugin update …`, `winget upgrade …`).
3. Relancez `npm run check:full`. Si le résultat change, revenez en arrière (`git checkout -- package.json package-lock.json && npm ci`, ou réinstallez la version précédente) et notez le problème dans STATUS.md.
4. Une fois sur GitHub, Dependabot proposera ces mises à jour en PR ; la CI les vérifiera. Aucune fusion automatique.

## 9. Reprendre après un arrêt de session

Tapez `/horn-resume` : Claude compare `STATUS.md`, les fiches de tâches, l'état Git et le dernier rapport, puis propose une seule prochaine action sûre. Sans Claude : lisez [STATUS.md](STATUS.md), lancez `git status` et `npm run check`.

## Ce que ce dispositif ne garantit pas

- Un test qui simule un service ne prouve pas que le service réel fonctionne.
- Un scan Gitleaks sans détection n'est pas un audit de sécurité.
- Aucune interface n'existe encore : aucun test navigateur ou natif n'est en place ; il faudra en ajouter quand l'interface apparaîtra (voir TOOLCHAIN.md, Playwright).
- La CI n'est pas exécutée tant que le dépôt n'est pas poussé sur GitHub, ce qui ne se fera qu'à votre demande.
