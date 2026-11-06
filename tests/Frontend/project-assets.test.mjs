import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { cmsAssets } from '../../vendor/dbravoan/dbcms-core/resources/vite.mjs';

test('the installed Composer appearance packages are available to the project asset build', () => {
    const assets = cmsAssets();
    assert.ok(existsSync(resolve(assets.aliases['@dbcms'], 'js/app.js')));
    for (const appearance of ['dbcms-theme-db-cyber', 'dbcms-admin-theme-dbcms']) {
        assert.ok(assets.inputs.some(input => input.includes(appearance) && existsSync(resolve(input))), `${appearance} stylesheet is missing`);
    }
    assert.equal(assets.plugin.resolveId('virtual:dbcms-modules'), '\0dbcms-modules');
    assert.match(assets.plugin.load('\0dbcms-modules'), /export default function register/);
});
