import { Page, expect, test } from '@playwright/test';

test('Homepage loads', async ({ page }) => {
    await page.goto('/');
    for (let i = 0; i <= 100; i = i + 1) {
        const count = i + 2;
        await page.getByRole('button', { name: 'Create' }).click();
        console.log("Clicked", count);
        await page.waitForURL('/');
        await expect(page.getByRole('table').getByRole('row')).toHaveCount(count);
    }
});

