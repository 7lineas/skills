async page => {
  const outputPath = "OUTPUT_PATH_PLACEHOLDER";

  const width = 1920;
  const height = 1080;

  await page.addInitScript(() => {
    if (window.__showCursorInstalled) {
      return;
    }
    window.__showCursorInstalled = true;

    const install = () => {
      if (document.getElementById("show-cursor")) {
        return;
      }

      const style = document.createElement("style");
      style.textContent = "* { cursor: none !important; }";
      document.documentElement.appendChild(style);

      const cursor = document.createElement("div");
      cursor.id = "show-cursor";
      cursor.style.cssText =
        "position:fixed;left:0;top:0;width:28px;height:28px;pointer-events:none;z-index:2147483647;filter:drop-shadow(0 1px 2px rgba(0,0,0,0.45));";
      cursor.innerHTML =
        '<svg width="28" height="28" viewBox="0 0 24 24" aria-hidden="true"><path fill="#ffffff" stroke="#111111" stroke-width="1.25" d="M4 4l7 18 2.5-7.5L20 12z"/></svg>';
      document.documentElement.appendChild(cursor);

      window.__showSetCursor = (x, y) => {
        cursor.style.left = `${x}px`;
        cursor.style.top = `${y}px`;
      };

      document.addEventListener("mousemove", (event) => {
        window.__showSetCursor(event.clientX, event.clientY);
      });
    };

    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", install);
    } else {
      install();
    }
  });

  await page.setViewportSize({ width, height });
  await page.screencast.start({
    path: outputPath,
    size: { width, height },
  });

  const moveTo = async (locator) => {
    const box = await locator.boundingBox();
    if (!box) {
      return;
    }

    const x = box.x + box.width / 2;
    const y = box.y + box.height / 2;
    await page.mouse.move(x, y, { steps: 35 });
    await page.evaluate(({ px, py }) => window.__showSetCursor?.(px, py), {
      px: x,
      py: y,
    });
    await page.waitForTimeout(180);
  };

  // --- replace from here per demo ---
  await page.goto("https://labs.7lineas.com", { waitUntil: "domcontentloaded" });
  await page.waitForSelector("h1", { state: "visible" });
  await page.mouse.move(width * 0.55, height * 0.35, { steps: 20 });
  await page.evaluate(
    ({ px, py }) => window.__showSetCursor?.(px, py),
    { px: width * 0.55, py: height * 0.35 },
  );
  await page.waitForTimeout(350);
  // --- end demo body ---

  await page.screencast.stop();
}
