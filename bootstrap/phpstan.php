<?php

declare(strict_types=1);
use DbCms\Core\Extensions\ComposerPackages;

foreach (app(ComposerPackages::class)->modules() as $module) {
    $views = $module['directory'].'/Resources/views';
    if (is_dir($views)) {
        app('view')->addNamespace($module['identifier'], $views);
        if (is_dir($views.'/admin')) {
            app('view')->addLocation($views);
        }
    }
}
