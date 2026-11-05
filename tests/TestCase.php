<?php

declare(strict_types=1);

namespace ProjectTests;

use Illuminate\Foundation\Testing\TestCase as LaravelTestCase;
use ProjectTests\Support\BootstrapCacheIsolation;

abstract class TestCase extends LaravelTestCase
{
    private ?BootstrapCacheIsolation $bootstrapCaches = null;

    public function createApplication()
    {
        $this->bootstrapCaches = new BootstrapCacheIsolation;

        return parent::createApplication();
    }

    protected function tearDown(): void
    {
        try {
            parent::tearDown();
        } finally {
            $this->bootstrapCaches?->restore();
            $this->bootstrapCaches = null;
        }
    }
}
