#!/usr/bin/env node

/**
 * WorkSafe Citrix Login Automation
 *
 * Automates daily login to WorkSafe Citrix portal.
 * Password loaded from WORKSAFE_TOKEN env var (via .env).
 *
 * Usage: node ~/code/dotfiles/bin/worksafe/worksafe-login.mjs
 */

import puppeteer from "puppeteer";
import readline from "readline";

const CONFIG = {
	url: "https://ctxprod.worksafe.vic.gov.au/",
	username: "VALEN1",
	password: process.env.WORKSAFE_TOKEN,
	pin: "2105",
};

// Validate password from env
if (!CONFIG.password) {
	console.error("❌ Missing WORKSAFE_TOKEN environment variable");
	console.error("\n💡 Add it to ~/code/dotfiles/.env");
	process.exit(1);
}

function createReadline() {
	return readline.createInterface({
		input: process.stdin,
		output: process.stdout,
	});
}

function askQuestion(rl, question) {
	return new Promise((resolve) => {
		rl.question(question, (answer) => {
			resolve(answer.trim());
		});
	});
}

async function waitForLoginPage(page) {
	console.log("⏳ Waiting for login page to load...");

	try {
		await page.waitForSelector("#Enter\\ user\\ name", { timeout: 10000 });
		console.log("✅ Login page loaded");
		return true;
	} catch {
		console.error("❌ Login page failed to load");
		return false;
	}
}

async function fillLoginForm(page, rsaToken) {
	console.log("📝 Filling login form...");

	const passcode = CONFIG.pin + rsaToken;

	await page.evaluate(
		(username, password, passcode) => {
			document.getElementById("Enter user name").value = username;
			document.getElementById("passwd").value = password;
			document.getElementById("passwd1").value = passcode;
		},
		CONFIG.username,
		CONFIG.password,
		passcode,
	);

	console.log("✅ Form filled");
}

async function submitLogin(page) {
	console.log("🚀 Submitting login...");
	await page.click("#Log_On");
}

async function handleWorkspaceDetection(page) {
	console.log("⏳ Waiting for Workspace detection...");

	try {
		// Wait for either the Workspace detection page or the StoreFront
		await page.waitForNavigation({ timeout: 15000 });

		// Try to detect and click the "Detect Citrix Workspace app" button
		const clicked = await page.evaluate(() => {
			const button = document.getElementById(
				"protocolhandler-welcome-installButton",
			);
			if (button) {
				button.click();
				return true;
			}
			return false;
		});

		if (clicked) {
			console.log("✅ Workspace detection handled");
			await page.waitForNavigation({ timeout: 10000 }).catch(() => {});
		}
	} catch {
		console.log("⚠️  Workspace detection timeout (may already be on apps page)");
	}
}

async function navigateToApps(page) {
	console.log("📱 Navigating to Apps...");

	try {
		const appsClicked = await page.evaluate(() => {
			const appsLink = Array.from(
				document.querySelectorAll('a, button, [role="button"]'),
			).find((el) => el.textContent.trim() === "Apps");
			if (appsLink) {
				appsLink.click();
				return true;
			}
			return false;
		});

		if (appsClicked) {
			console.log("✅ Apps page loaded");
			// Wait a bit for apps to load
			await new Promise((resolve) => setTimeout(resolve, 2000));
		}
	} catch {
		console.log("⚠️  Could not navigate to Apps automatically");
	}
}

async function login() {
	const rl = createReadline();
	let browser;

	try {
		console.log("🚀 Starting WorkSafe Citrix login...\n");

		// Launch browser in app mode
		browser = await puppeteer.launch({
			headless: false,
			defaultViewport: { width: 1280, height: 900 },
			args: ["--app=" + CONFIG.url, "--start-maximized"],
		});

		// Get the existing page (app mode already opens the URL)
		const pages = await browser.pages();
		const page = pages[0];

		// Wait for the page to load
		console.log("🌐 Waiting for Citrix portal to load...");

		// Step 2: Wait for login page to load
		const pageLoaded = await waitForLoginPage(page);
		if (!pageLoaded) {
			throw new Error("Login page failed to load");
		}

		// Step 3: Ask for RSA token
		console.log("\n📱 Open RSA Authenticator app on your phone");
		const rsaToken = await askQuestion(rl, "🔑 Enter 8-digit RSA token: ");

		if (rsaToken.length !== 8 || !/^\d+$/.test(rsaToken)) {
			throw new Error("Invalid RSA token - must be 8 digits");
		}

		// Step 4: Fill and submit form
		await fillLoginForm(page, rsaToken);
		await submitLogin(page);

		// Step 5: Handle Workspace detection
		await handleWorkspaceDetection(page);

		// Step 6: Navigate to Apps
		await navigateToApps(page);

		console.log("\n✨ Login complete! You can now access:");
		console.log("   • Outlook");
		console.log("   • Azure DevOps");
		console.log("   • Dynamics\n");

		console.log("🌐 Browser will remain open for you to work\n");

		// Keep browser open - don't close it
	} catch (error) {
		console.error("\n❌ Login failed:", error.message);

		if (error.message.includes("Invalid RSA token")) {
			console.log(
				"💡 Tip: Make sure you entered exactly 8 digits from your RSA Authenticator app\n",
			);
		} else if (error.message.includes("timeout")) {
			console.log("💡 Tips:");
			console.log("   • Check your internet connection");
			console.log("   • Verify the Citrix portal is accessible");
			console.log("   • Try again with a fresh RSA token\n");
		}

		if (browser) {
			await browser.close();
		}
		process.exit(1);
	} finally {
		rl.close();
	}
}

// Handle errors
process.on("unhandledRejection", (error) => {
	console.error("\n❌ Unexpected error:", error.message);
	process.exit(1);
});

// Run
login();
