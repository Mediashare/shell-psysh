# Bug Fix: phpunit:add Command Not Working

## 🐛 Problem Description

The `phpunit:add` command was not working properly. After creating a test with `phpunit:create`, the `phpunit:add` command would fail with the error:

```
❌ Aucun test actuel. Créez d'abord un test avec phpunit:create
```

## 🔍 Root Cause

The issue was that each PHPUnit command was creating its own instance of the `PHPUnitService`, which meant that the state (active tests, current test) was not shared between commands.

The original code in `PHPUnitCommandTrait.php` used static variables:

```php
private static $phpunitService;
private static $currentTest = null;
```

However, these static variables were not properly shared between different command instances in the PsySH environment.

## ✅ Solution

The fix was to use PHP's `$GLOBALS` superglobal to share state between command instances:

### Before (Not working):
```php
trait PHPUnitCommandTrait
{
    private static $phpunitService;
    private static $currentTest = null;

    protected function getPhpunitService()
    {
        if (!self::$phpunitService) {
            self::$phpunitService = new \Mediashare\Psysh\Service\PHPUnitService();
        }
        return self::$phpunitService;
    }

    protected function getCurrentTest(): ?string
    {
        return self::$currentTest;
    }

    protected function setCurrentTest(?string $testName): void
    {
        self::$currentTest = $testName;
    }
}
```

### After (Working):
```php
trait PHPUnitCommandTrait
{
    protected function getPhpunitService()
    {
        if (!isset($GLOBALS['phpunit_service'])) {
            $GLOBALS['phpunit_service'] = \Mediashare\Psysh\Service\PHPUnitService::getInstance();
        }
        return $GLOBALS['phpunit_service'];
    }

    protected function getCurrentTest(): ?string
    {
        return $GLOBALS['phpunit_current_test'] ?? null;
    }

    protected function setCurrentTest(?string $testName): void
    {
        $GLOBALS['phpunit_current_test'] = $testName;
    }
}
```

## 🧪 Testing

After the fix, the workflow now works correctly:

```bash
>>> phpunit:create App\Service\InvoiceService
✅ Test créé : InvoiceServiceTest (mode interactif)

>>> phpunit:add testCalculate
✅ Méthode testCalculate ajoutée

>>> phpunit:list
📋 Tests actifs :
- InvoiceService::testCalculate [0 lignes, 0 assertions]
```

## 📝 Files Modified

- `.psysh/Traits/PHPUnitCommandTrait.php` - Fixed to use `$GLOBALS` instead of static variables

## 🔧 Verification

Run the verification script to confirm everything works:

```bash
./psysh/verify.sh
```

All tests should now pass successfully.

## 🎯 Impact

This fix ensures that:
- Tests created with `phpunit:create` are properly tracked
- `phpunit:add` can add methods to existing tests
- `phpunit:code`, `phpunit:assert`, `phpunit:run` all work with the same test instance
- State is properly shared across all PHPUnit commands in the same PsySH session
