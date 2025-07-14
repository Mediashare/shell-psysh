#!/usr/bin/env php
<?php

/*
 * Script de test pour vérifier que les assertions sont persistées dans phpunit:run
 */

require_once __DIR__ . '/vendor/autoload.php';

use Psy\Configuration;
use Psy\Shell;
use Psy\Extended\Command\Config\PHPUnitCreateCommand;
use Psy\Extended\Command\Assert\PHPUnitAssertCommand;
use Psy\Extended\Command\Runner\PHPUnitRunCommand;
use Psy\Extended\Command\Other\PHPUnitAddCommand;
use Psy\Extended\Command\Config\PHPUnitListCommand;
use Psy\Extended\Service\ServiceManager;

echo "🧪 Test de persistance des assertions PHPUnit\n";
echo str_repeat('=', 60) . "\n";

// Configuration PsySH
$config = new Configuration();
$config->setStartupMessage('');
$shell = new Shell($config);

// Initialiser le gestionnaire de services
$serviceManager = ServiceManager::getInstance();
$serviceManager->setShell($shell);

// Ajouter les commandes PHPUnit
$shell->addCommands([
    new PHPUnitCreateCommand(),
    new PHPUnitAssertCommand(),
    new PHPUnitRunCommand(),
    new PHPUnitAddCommand(),
    new PHPUnitListCommand()
]);

// Définir une variable globale pour le test
$GLOBALS['psysh_shell_variables'] = [
    'res' => 42,
    'name' => 'John Doe',
    'items' => ['a', 'b', 'c']
];

echo "1. Création d'un test...\n";
$createTester = new \Symfony\Component\Console\Tester\CommandTester(new PHPUnitCreateCommand());
$createTester->execute(['service' => 'TestService']);
echo $createTester->getDisplay();

echo "\n2. Ajout d'une méthode de test...\n";
$addTester = new \Symfony\Component\Console\Tester\CommandTester(new PHPUnitAddCommand());
$addTester->execute(['method' => 'testExample']);
echo $addTester->getDisplay();

echo "\n3. Ajout d'assertions...\n";
$assertTester = new \Symfony\Component\Console\Tester\CommandTester(new PHPUnitAssertCommand());

// Première assertion
$assertTester->execute(['expression' => '$res === 42']);
echo $assertTester->getDisplay();

// Deuxième assertion
$assertTester->execute(['expression' => '$name === "John Doe"']);
echo $assertTester->getDisplay();

// Troisième assertion
$assertTester->execute(['expression' => 'count($items) === 3']);
echo $assertTester->getDisplay();

echo "\n4. Vérification que les assertions sont listées...\n";
$listTester = new \Symfony\Component\Console\Tester\CommandTester(new PHPUnitListCommand());
$listTester->execute([]);
echo $listTester->getDisplay();

echo "\n5. Exécution du test avec les assertions persistées...\n";
$runTester = new \Symfony\Component\Console\Tester\CommandTester(new PHPUnitRunCommand());
$runTester->execute([]);
echo $runTester->getDisplay();

echo "\n✅ Test terminé ! Les assertions devraient maintenant être comptabilisées.\n";
