<?php

declare(strict_types=1);

use DbCms\Core\Content\Pages\Models\Page;
use DbCms\Core\Http\Middleware\EnsureCmsIsInstalled;
use DbCms\Core\Models\Language;
use DbCms\Core\Models\Market;
use Illuminate\Support\Facades\View;

test('the project can publish a registered Blade page with locale and publication isolation', function (): void {
    $this->withoutMiddleware(EnsureCmsIsInstalled::class);
    $this->withoutVite();
    $language = Language::create(['code' => 'es', 'name' => 'Español', 'native_name' => 'Español', 'is_active' => true, 'is_default' => true]);
    $market = Market::create(['code' => 'es', 'name' => 'España', 'currency' => 'EUR', 'default_locale' => 'es', 'is_active' => true, 'is_default' => true]);
    $market->languages()->attach($language, ['is_default' => true]);
    View::addNamespace('project-tests', base_path('tests/Fixtures'));
    config(['cms.page_views' => ['project-preview' => 'project-tests::project-page']]);
    $page = Page::create(['template' => 'blade:project-preview', 'is_published' => true]);
    $page->translations()->create(['locale' => 'es', 'title' => 'Project page', 'slug' => 'project-page']);
    $this->get('/es/es/project-page')->assertOk()->assertSee('Project page')->assertSee('lang="es"', false);
    $this->get('/es/fr/project-page')->assertNotFound();
    $page->update(['is_published' => false]);
    $this->get('/es/es/project-page')->assertNotFound();
});
