<?php

namespace Psy\Extended\Trait;

trait OutputFormatterTrait
{
    protected function formatComplexHelp(array $help): string
    {
        $output = "\n";
        $commandName = strtoupper($this->getName());
        
        // Header
        $output .= "╔" . str_repeat("═", 80) . "╗\n";
        $title = "🚀 {$commandName} - GUIDE COMPLET";
        $padding = (80 - mb_strlen($title)) / 2;
        $output .= "║" . str_repeat(" ", $padding) . $title . str_repeat(" ", 80 - $padding - mb_strlen($title)) . "║\n";
        $output .= "╚" . str_repeat("═", 80) . "╝\n\n";
        
        // Description
        if (!empty($help['description'])) {
            $output .= "📋 Description:\n";
            $output .= "   {$help['description']}\n\n";
        }
        
        // Usage
        if (!empty($help['usage'])) {
            $output .= "🔧 Usage:\n";
            foreach ((array)$help['usage'] as $usage) {
                $output .= "   ▶️  {$usage}\n";
            }
            $output .= "\n";
        }
        
        // Options
        if (!empty($help['options'])) {
            $output .= "⚙️  Options:\n";
            foreach ($help['options'] as $option => $desc) {
                $output .= "   📌 {$option}\n";
                $output .= "      {$desc}\n";
            }
            $output .= "\n";
        }
        
        // Examples
        if (!empty($help['examples'])) {
            $output .= "📚 Examples:\n";
            foreach ($help['examples'] as $example => $desc) {
                $output .= "   ✅ {$example}\n";
                if ($desc) {
                    $output .= "      {$desc}\n";
                }
                $output .= "\n";
            }
        }
        
        // Tips
        if (!empty($help['tips'])) {
            $output .= "💡 Tips:\n";
            foreach ($help['tips'] as $tip) {
                $output .= "   🔸 {$tip}\n";
            }
            $output .= "\n";
        }
        
        // Related Commands
        if (!empty($help['related'])) {
            $output .= "🔗 Related Commands:\n";
            foreach ($help['related'] as $cmd => $desc) {
                $output .= "   📎 {$cmd} - {$desc}\n";
            }
            $output .= "\n";
        }
        
        // Footer
        $output .= "┌" . str_repeat("─", 78) . "┐\n";
        $output .= "│ 💬 Pour aide rapide: help {$this->getName()}" . str_repeat(" ", 78 - 35 - mb_strlen($this->getName())) . "│\n";
        $output .= "│ 📖 Documentation complète: {$this->getName()}:help" . str_repeat(" ", 78 - 31 - mb_strlen($this->getName() . ":help")) . "│\n";
        $output .= "└" . str_repeat("─", 78) . "┘\n";
        
        return $output;
    }
    
    protected function formatList(array $items): string
    {
        $output = "";
        foreach ($items as $item) {
            $output .= "  • " . $item . "\n";
        }
        return $output;
    }
    protected function displayList(OutputInterface $output, string $title, array $items, ?string $emptyMessage = null): void
    {
        if (empty($items)) {
            if ($emptyMessage) {
                $output->writeln("<comment>{$emptyMessage}</comment>");
            }
            return;
        }
        
        $output->writeln("<info>{$title}:</info>");
        foreach ($items as $key => $value) {
            if (is_numeric($key)) {
                $output->writeln("  - {$value}");
            } else {
                $output->writeln("  - <comment>{$key}:</comment> {$value}");
            }
        }
    }
}
