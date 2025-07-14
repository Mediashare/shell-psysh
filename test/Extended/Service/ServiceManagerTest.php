<?php

namespace Psy\Test\Extended\Service;

use Psy\Configuration;
use Psy\Extended\Service\ServiceManager;
use Psy\Extended\Service\PHPUnitService;
use Psy\Shell;
use Psy\Test\TestCase;

class ServiceManagerTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        ServiceManager::reset();
    }
    
    protected function tearDown(): void
    {
        parent::tearDown();
        ServiceManager::reset();
    }
    
    /**
     * Test singleton pattern
     */
    public function testSingletonPattern()
    {
        $instance1 = ServiceManager::getInstance();
        $instance2 = ServiceManager::getInstance();
        
        $this->assertSame($instance1, $instance2);
    }
    
    /**
     * Test getting PHPUnit service
     */
    public function testGetPHPUnitService()
    {
        $manager = ServiceManager::getInstance();
        $service = $manager->getService('phpunit');
        
        $this->assertInstanceOf(PHPUnitService::class, $service);
        
        // Test that same instance is returned
        $service2 = $manager->getService('phpunit');
        $this->assertSame($service, $service2);
    }
    
    /**
     * Test getting environment service
     */
    public function testGetEnvironmentService()
    {
        $manager = ServiceManager::getInstance();
        $service = $manager->getService('environment');
        
        $this->assertIsObject($service);
    }
    
    /**
     * Test getting sync service with shell
     */
    public function testGetSyncServiceWithShell()
    {
        $manager = ServiceManager::getInstance();
        $shell = new Shell(new Configuration());
        $manager->setShell($shell);
        
        $service = $manager->getService('sync');
        $this->assertIsObject($service);
    }
    
    /**
     * Test getting monitor service
     */
    public function testGetMonitorService()
    {
        $manager = ServiceManager::getInstance();
        $service = $manager->getService('monitor');
        
        $this->assertIsObject($service);
    }
    
    /**
     * Test registering custom service
     */
    public function testRegisterCustomService()
    {
        $manager = ServiceManager::getInstance();
        $customService = new \stdClass();
        $customService->name = 'custom';
        
        $manager->registerService('custom', $customService);
        
        $retrieved = $manager->getService('custom');
        $this->assertSame($customService, $retrieved);
    }
    
    /**
     * Test getting non-existent service throws exception
     */
    public function testGetNonExistentServiceThrowsException()
    {
        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage("Service 'nonexistent' not found");
        
        $manager = ServiceManager::getInstance();
        $manager->getService('nonexistent');
    }
    
    /**
     * Test configuration management
     */
    public function testConfigurationManagement()
    {
        $manager = ServiceManager::getInstance();
        
        // Test default config
        $defaultConfig = $manager->getConfig();
        $this->assertIsArray($defaultConfig);
        $this->assertArrayHasKey('debug_mode', $defaultConfig);
        $this->assertArrayHasKey('test_directory', $defaultConfig);
        
        // Test getting specific config
        $this->assertFalse($manager->getConfig('debug_mode'));
        $this->assertEquals('tests/Generated', $manager->getConfig('test_directory'));
        
        // Test setting config
        $manager->setConfig('debug_mode', true);
        $this->assertTrue($manager->getConfig('debug_mode'));
        
        // Test non-existent config returns null
        $this->assertNull($manager->getConfig('nonexistent_key'));
    }
    
    /**
     * Test reset functionality
     */
    public function testReset()
    {
        $manager1 = ServiceManager::getInstance();
        $manager1->setConfig('test_key', 'test_value');
        
        ServiceManager::reset();
        
        $manager2 = ServiceManager::getInstance();
        $this->assertNotSame($manager1, $manager2);
        $this->assertNull($manager2->getConfig('test_key'));
    }
    
    /**
     * Test setting shell updates sync service
     */
    public function testSettingShellUpdatesSyncService()
    {
        $manager = ServiceManager::getInstance();
        $shell1 = new Shell(new Configuration());
        $shell2 = new Shell(new Configuration());
        
        // Set first shell and get sync service
        $manager->setShell($shell1);
        $sync1 = $manager->getService('sync');
        
        // Set second shell
        $manager->setShell($shell2);
        $sync2 = $manager->getService('sync');
        
        // Should be different instances since shell changed
        $this->assertNotSame($sync1, $sync2);
    }
    
    /**
     * Test lazy loading of services
     */
    public function testLazyLoadingOfServices()
    {
        $manager = ServiceManager::getInstance();
        
        // Services should not exist initially
        $reflection = new \ReflectionClass($manager);
        $servicesProperty = $reflection->getProperty('services');
        $servicesProperty->setAccessible(true);
        $services = $servicesProperty->getValue($manager);
        
        $this->assertEmpty($services);
        
        // Get a service
        $manager->getService('phpunit');
        
        // Now it should exist
        $services = $servicesProperty->getValue($manager);
        $this->assertArrayHasKey('phpunit', $services);
    }
}
