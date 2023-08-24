import { Page, expect, test } from '@playwright/test';

test('Homepage loads', async ({ page }) => {
    await page.goto('/');
    for (let i = 0; i <= 100; i = i + 1) {
        await page.getByRole('button', { name: 'Create' }).click();
        await page.waitForURL('/');
        expect(await page.getByRole('table').getByRole('row')).toHaveCount(1 + i);
    }
});

