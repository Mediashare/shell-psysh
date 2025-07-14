# StandBy
## Features
- intégration des opérateurs (|, &&, ;;, ect...) dans le shell psysh
- phpunit:[TAB]create
- Commandes avec $code en argument sans quotes ""
## Prompts
### Refactorization
#### Synchronisation shell <-> phpunit:*
Etablie un ensemble de tests phpunit testant des combinaisons d'expressions/commands shell psysh et commandes phpunit:*. Etablie des workflows (ou scénarios d'usages) et mets les à l'épreuves dans des tests unitaires. Le but étant que l'usages des commandes shell psysh soient le plus intuitifs possible, et couvre l'entièreté des cas d'usages lors de l'execution de workflow.
### AutoCompletion
[OK] Autorise les suggestion pour les tabulation comme : phpunit:[TAB]run
Pour cette class autoloadé dans le projet:

namespace App\Service;

class Test {

public function __construct(private string $name, ?bool $isBool = true) {}

public function getMethod(array $data, ?int $index = 1) {

return $data[$index];

 }
}

Est il possible d'ajouter l'autocompletion dans le shell psysh interactif (composer package psy/psysh) pour ces cas d'usages ? Quel est la meilleur manière d'intégrer ces suggestions d'autocompletion ? Faut il créer une class AutoCompleter & Matchers ?

Voici les cas d'usages:
$test = new Ap[TAB]p[END_TAB]\Ser[TAB]vice[END_TAB]([TAB]name: ""[END_TAB], [TAB]isBool: false[END_TAB]);
$te[TAB]st[END_TAB]-[TAB]>[END_TAB]getM[TAB]ethod[END_TAB]([TAB] data: [END_TAB][1,2,3,4], [TAB] index: [END_TAB]2);
### Commandes
#### Helpers
Ajoute tous les helper pour les commandes provenant de ./src/Command
Il faut ajouter une getComplexHelp avec description détaillé des usages et fonctionnement A TOUTES LES COMMANDES
un helper standard quand use command help into shell psysh quand command here: help phpunit
and helper complex with more usage into helper: help phpunit:debug 
#### phpunit:code
Vérifier si les objets complexe créer dans le shell psysh principal est bien partagé avec le shell phpunit:code
#### phpunit:assert argument from expression
Il doit être possible de lancer la commande phpunit:assert $result === 42 sans les quotes
### Composer Require Package
Quelle est la meilleur manière d"extend la commande psysh à partir d'un composer require package ? Le but étant d'être le plus flexible possible pour rajouter les fonctionnalités du package composer et cela de manière intelligente. Il faut savoir que l'extension de psysh comprend des nouvelles commandes psysh shell avec des extends Psy\Command\Command (provenant du package psy/psysh) et l'autoloading automatique du projet et de ces principal où l'on require le package d'extension psysh, car cela permet d'avoir de l'auto suggestion sur les namespaces et permet aussi d'avoir accès par exemple au $container et services de symfony si le projet principal est un symfony ...
### ./tests
#### Symfony
Dans des tests en shell testant les commandes custom psysh j'ai une partie qui test l'implémentation du package dans un projet symfony (du genre récupération des variables $container, $em, ect... dans le shell psysh avec l'option --config config/config.php), mais je ne sais pas comment faire pour tester ces features... suis je obligé d'installer un projet symfony dans le package ? Puis je passer par un composer require --dev du package symfony ?
#### Standard
Ajoute des nouveaux tests sur l'implémentation de l'autoloader, des nouvelles commandes et des features ajoutés à bin/psysh --config config/config.php
#### Nouveux tests commandes PhpUnit
Ajoutes des nouveaux tests des commandes phpunit:* avec la structure ./tests/Command/Phpunit/{Create, Add, Code, Assert, Run, ...}
Soit très complet en testant toutes les fonctionnalités, combinaisons et options possibles, tests tous, il y a aussi les exemples de tests de synchro entre les shell psysh et phpunit:code
#### Functions & Architecture
##### Méthodes de test ultra modulaire

Créer un fichier EXAMPLES.md avec tous les usages possibles et combiné des custom commandes psysh extended et avec des explication de la bonne manière