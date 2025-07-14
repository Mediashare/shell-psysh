<?php

namespace Psy\Extended\Trait;

trait CommandHelpTrait
{
    /**
     * Get standard help for command (for 'help' command in PsySH)
     */
    protected function getStandardHelp(): string
    {
        return $this->getDescription() . "\n\n" . $this->getUsageExamples();
    }

    /**
     * Format complex help using array structure
     */
    protected function formatComplexHelp(array $helpData): string
    {
        $help = "";
        $commandName = $helpData['name'] ?? $this->getName();
        
        // Header
        $help .= "\n╔" . str_repeat("═", 80) . "╗\n";
        $help .= "║" . str_pad(" 🚀 " . strtoupper($commandName) . " - GUIDE COMPLET", 80, " ", STR_PAD_BOTH) . "║\n";
        $help .= "╚" . str_repeat("═", 80) . "╝\n\n";
        
        // Description
        if (!empty($helpData['description'])) {
            $help .= "📋 Description:\n";
            $help .= "   " . $helpData['description'] . "\n\n";
        }
        
        // Usage patterns
        if (!empty($helpData['usage'])) {
            $help .= "🔧 Usage:\n";
            foreach ($helpData['usage'] as $usage) {
                $help .= "   ▶️  " . $usage . "\n";
            }
            $help .= "\n";
        }
        
        // Options/Parameters
        if (!empty($helpData['options'])) {
            $help .= "⚙️  Options:\n";
            foreach ($helpData['options'] as $option => $description) {
                $help .= "   📌 " . $option . "\n";
                $help .= "      " . $description . "\n";
            }
            $help .= "\n";
        }
        
        // Examples
        if (!empty($helpData['examples'])) {
            $help .= "📚 Examples:\n";
            foreach ($helpData['examples'] as $example => $description) {
                $help .= "   ✅ " . $example . "\n";
                $help .= "      " . $description . "\n\n";
            }
        }
        
        // Tips
        if (!empty($helpData['tips'])) {
            $help .= "💡 Tips:\n";
            foreach ($helpData['tips'] as $tip) {
                $help .= "   🔸 " . $tip . "\n";
            }
            $help .= "\n";
        }
        
        // Advanced features
        if (!empty($helpData['advanced'])) {
            $help .= "🚀 Advanced Features:\n";
            foreach ($helpData['advanced'] as $feature) {
                $help .= "   ⭐ " . $feature . "\n";
            }
            $help .= "\n";
        }
        
        // Workflows
        if (!empty($helpData['workflows'])) {
            $help .= "🔄 Recommended Workflows:\n";
            foreach ($helpData['workflows'] as $workflow => $steps) {
                $help .= "   📋 " . $workflow . ":\n";
                foreach ($steps as $step) {
                    $help .= "      → " . $step . "\n";
                }
                $help .= "\n";
            }
        }
        
        // Troubleshooting
        if (!empty($helpData['troubleshooting'])) {
            $help .= "❓ Troubleshooting:\n";
            foreach ($helpData['troubleshooting'] as $issue) {
                $help .= "   🔧 " . $issue . "\n";
            }
            $help .= "\n";
        }
        
        // Related commands
        if (!empty($helpData['related'])) {
            $help .= "🔗 Related Commands:\n";
            foreach ($helpData['related'] as $command => $description) {
                $help .= "   📎 " . $command . " - " . $description . "\n";
            }
            $help .= "\n";
        }
        
        // Footer
        $help .= "┌" . str_repeat("─", 78) . "┐\n";
        $help .= "│ 💬 Pour aide rapide: help " . str_pad($commandName, 40) . "│\n";
        $help .= "│ 📖 Documentation complète: " . str_pad($commandName . ":help", 33) . "│\n";
        $help .= "└" . str_repeat("─", 78) . "┘\n";
        
        return $help;
    }

    /**
     * Get detailed help for command (for 'command:help' or 'command:debug help')
     */
    protected function getDetailedHelp(): string
    {
        $help = "";
        $help .= "╔" . str_repeat("═", 78) . "╗\n";
        $help .= "║" . str_pad(" " . $this->getName() . " - AIDE DÉTAILLÉE", 78) . "║\n";
        $help .= "╚" . str_repeat("═", 78) . "╝\n\n";
        
        $help .= "📋 DESCRIPTION:\n";
        $help .= "   " . $this->getDescription() . "\n\n";
        
        $help .= "🔧 SYNTAXE:\n";
        $help .= $this->getSyntaxHelp() . "\n\n";
        
        $help .= "📚 EXEMPLES D'UTILISATION:\n";
        $help .= $this->getUsageExamples() . "\n\n";
        
        $help .= "⚙️  OPTIONS:\n";
        $help .= $this->getOptionsHelp() . "\n\n";
        
        $help .= "💡 CONSEILS:\n";
        $help .= $this->getTipsHelp() . "\n\n";
        
        if ($this->hasAdvancedFeatures()) {
            $help .= "🚀 FONCTIONNALITÉS AVANCÉES:\n";
            $help .= $this->getAdvancedHelp() . "\n\n";
        }
        
        $help .= "❓ DÉPANNAGE:\n";
        $help .= $this->getTroubleshootingHelp() . "\n";
        
        return $help;
    }

    /**
     * Get command syntax help
     */
    protected function getSyntaxHelp(): string
    {
        $syntax = "   " . $this->getName();
        
        foreach ($this->getDefinition()->getArguments() as $argument) {
            if ($argument->isRequired()) {
                $syntax .= " <" . $argument->getName() . ">";
            } else {
                $syntax .= " [" . $argument->getName() . "]";
            }
        }
        
        foreach ($this->getDefinition()->getOptions() as $option) {
            if ($option->isValueRequired()) {
                $syntax .= " [--" . $option->getName() . "=VALUE]";
            } elseif ($option->isValueOptional()) {
                $syntax .= " [--" . $option->getName() . "[=VALUE]]";
            } else {
                $syntax .= " [--" . $option->getName() . "]";
            }
        }
        
        return $syntax;
    }

    /**
     * Get options help
     */
    protected function getOptionsHelp(): string
    {
        $help = "";
        
        // Arguments
        foreach ($this->getDefinition()->getArguments() as $argument) {
            $help .= "   " . $argument->getName();
            if ($argument->isRequired()) {
                $help .= " (requis)";
            } else {
                $help .= " (optionnel)";
            }
            $help .= " - " . $argument->getDescription() . "\n";
        }
        
        // Options
        foreach ($this->getDefinition()->getOptions() as $option) {
            $help .= "   --" . $option->getName();
            if ($option->getShortcut()) {
                $help .= ", -" . $option->getShortcut();
            }
            $help .= " - " . $option->getDescription() . "\n";
        }
        
        return $help ?: "   Aucune option disponible.\n";
    }

    /**
     * Get default usage examples (to be overridden by specific commands)
     */
    protected function getUsageExamples(): string
    {
        return "   " . $this->getName() . " # Utilisation basique\n";
    }

    /**
     * Get default tips (to be overridden by specific commands)
     */
    protected function getTipsHelp(): string
    {
        return "   • Utilisez 'help " . $this->getName() . "' pour une aide rapide\n" .
               "   • Utilisez '" . $this->getName() . ":help' pour cette aide détaillée\n";
    }

    /**
     * Check if command has advanced features (to be overridden by specific commands)
     */
    protected function hasAdvancedFeatures(): bool
    {
        return false;
    }

    /**
     * Get advanced features help (to be overridden by specific commands)
     */
    protected function getAdvancedHelp(): string
    {
        return "   Aucune fonctionnalité avancée disponible.\n";
    }

    /**
     * Get troubleshooting help (to be overridden by specific commands)
     */
    protected function getTroubleshootingHelp(): string
    {
        return "   • Vérifiez que les paramètres sont corrects\n" .
               "   • Consultez la documentation en ligne\n" .
               "   • Activez le mode debug avec --debug ou -d\n";
    }

    /**
     * Display help in a formatted way
     */
    protected function displayHelp(\Symfony\Component\Console\Output\OutputInterface $output, bool $detailed = false): void
    {
        if ($detailed) {
            $output->writeln($this->getDetailedHelp());
        } else {
            $output->writeln($this->getStandardHelp());
        }
    }
}
