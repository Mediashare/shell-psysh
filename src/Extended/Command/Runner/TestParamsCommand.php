<?php

namespace Psy\Extended\Command\Runner;


use Psy\Command\Command;
use Psy\Extended\Command\BaseCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;use Symfony\Component\Console\Input\InputArgument;

/**
 * Test command for named parameters completion
 */
class TestParamsCommand extends \Psy\Extended\Command\BaseCommand
{protected static $defaultName = 'test:params';
    protected static $defaultDescription = 'Test named parameters completion';

    protected function configure(): void
    {
        $this
            ->setName('test:params')
            ->setDescription('Test named parameters completion')
            ->setAliases(['tp'])
            ->addArgument('expression', InputArgument::OPTIONAL, 'Expression to test', 'new TestService(')
            ->setHelp(<<<'HELP'
Test named parameters completion functionality.

Examples:
  <return>>>> test:params</return>
  <return>>>> test:params "new TestService("</return>
  <return>>>> test:params "$service->process("</return>
HELP
            );
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $expression = $input->getArgument('expression');
        
        $output->writeln('<info>Testing named parameters for:</info> ' . $expression);
        
        // Create test service
        $code = <<<'PHP'
class TestService {
    public function __construct(
        private array $config = [],
        private ?string $name = 'default',
        private bool $debug = false
    ) {}
    
    public function process(
        string $input,
        bool $validate = true,
        ?array $options = null
    ) {
        return "Processing: $input";
    }

    public function getComplexHelp(): array
    {
        return [
            "description" => $this->getDescription(),
            "usage" => [$this->getName()],
            "examples" => []
        ];
    }}
PHP;
        
        eval($code);
        
        // Test the matcher
        $matcher = new \Mediashare\Psysh\TabCompletion\Matcher\NamedParametersMatcher();
        
        // Create a fake context
        $context = new \Psy\Context();
        $context->setAll([
            'service' => new \TestService(),
            'em' => new \stdClass(),
            'container' => new \stdClass()
        ]);
        $matcher->setContext($context);
        
        // Tokenize the expression
        $tokens = token_get_all('<?php ' . $expression);
        
        // Test if matcher matches
        if ($matcher->hasMatched($tokens)) {
            $output->writeln('<comment>✓ Matcher activated</comment>');
            
            // Get matches
            $info = [
                'line_buffer' => $expression,
                'point' => strlen($expression),
                'end' => strlen($expression)
            ];
            
            $matches = $matcher->getMatches($tokens, $info);
            
            if (empty($matches)) {
                $output->writeln('<error>✗ No parameter suggestions found</error>');
            } else {
                $output->writeln('<comment>Parameter suggestions:</comment>');
                foreach ($matches as $match) {
                    $output->writeln('  - <info>' . $match . '</info>');
                }
            }
        } else {
            $output->writeln('<error>✗ Matcher did not activate</error>');
            $output->writeln('<comment>Debug info:</comment>');
            $output->writeln('  Tokens: ' . json_encode(array_map(function($t) {
                return is_array($t) ? token_name($t[0]) . ':' . $t[1] : $t;
            }, $tokens)));
        }
        
        return 0;
    }

    public function getComplexHelp(): array
    {
        return [
            "description" => $this->getDescription(),
            "usage" => [$this->getName()],
            "examples" => []
        ];
    }}
