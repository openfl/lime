package utils.publish;

import haxe.crypto.Base64;
import hxp.Path;
import haxe.Json;
import lime.tools.helpers.CLIHelper;
import lime.tools.helpers.Log;
import lime.tools.helpers.ZipHelper;
import lime.tools.helpers.ProcessHelper;
import lime.graphics.Image;
import lime.net.oauth.*;
import lime.net.*;
import lime.project.HXProject;
import utils.PlatformSetup;
import sys.FileSystem;
import sys.io.File;

class FirefoxMarketplace
{
	private static function compress(project:HXProject):String
	{
		var outputDirectory = project.app.path + "/firefox";
		var source = outputDirectory + "/bin/";
		var packagedFile = project.app.file + ".zip";
		var destination = outputDirectory + "/dist/" + packagedFile;

		System.compress(source, destination);

		return destination;
	}

	public static function isValid(project:HXProject):Bool
	{
		var result = FirefoxHelper.validate(project);

		if (result.errors.length != 0)
		{
			var errorMsg = "The application cannot be published\n";

			for (error in result.errors)
			{
				errorMsg += '\n * ' + error;
			}

			if (Log.verbose) Log.println("");
			Log.error(errorMsg);

			return false;
		}

		return true;
	}

	public static function publish(project:HXProject):Void
	{
		var devServer = project.targetFlags.exists("dev");
		var forceUpload = project.targetFlags.exists("force");
		var answer:Answer;

		/*if (!devServer) {

			Log.println ("In which server do you want to publish your application?");
			Log.println ("\t1. Production server.");
			Log.println ("\t2. Development server.");
			Log.println ("\tq. Quit.");

			answer = CLIHelper.ask ("Which server?", ["1", "2", "q"]);

			switch (answer) {

				case CUSTOM (x):

					switch (x) {

						case "2": devServer = true;
						case "q": Sys.exit (0);

					}

				default:


			}

		}*/

		Log.info("Checking account...");

		var defines = project.defines;
		var existsProd = defines.exists("FIREFOX_MARKETPLACE_KEY") && defines.exists("FIREFOX_MARKETPLACE_SECRET");
		var existsDev = defines.exists("FIREFOX_MARKETPLACE_DEV_KEY") && defines.exists("FIREFOX_MARKETPLACE_DEV_SECRET");

		if ((!existsProd && !devServer) || (!existsDev && devServer))
		{
			setup(false, devServer, cast defines);

			// we need to get all the defines after configuring the account
			Log.mute = true;
			defines = PlatformSetup.getDefines();
			Log.mute = false;
		}

		var baseUrl = devServer ? FirefoxHelper.DEVELOPMENT_SERVER_URL : FirefoxHelper.PRODUCTION_SERVER_URL;
		var appID:Int = -1;
		var appSlug:String = "";
		var appName = project.meta.title;

		var key = defines.get("FIREFOX_MARKETPLACE" + (devServer ? "_DEV_" : "_") + "KEY");
		var secret = defines.get("FIREFOX_MARKETPLACE" + (devServer ? "_DEV_" : "_") + "SECRET");

		var marketplace = new MarketplaceAPI(key, secret, devServer);

		var error = function(r:Dynamic)
		{
			Reflect.deleteField(r, "error");
			// Log.println ("");
			Log.error((r.customError != null ? r.customError : 'There was an error:\n\n$r'));
		};

		var response:Dynamic = marketplace.getUserAccount();

		if (response.error)
		{
			response.customError = "Could not validate your account, please verify your account information";
			error(response);
		}

		// Log.println ("OK");

		var apps:List<Dynamic> = Lambda.filter(marketplace.getUserApps(), function(obj) return appName == Reflect.field(obj.name, "en-US"));

		if (!forceUpload && apps.length > 0)
		{
			var app = apps.first();

			Log.println("This application has already been submitted to the Firefox Marketplace.");
			answer = CLIHelper.ask("Do you want to open the edit page?", ["y", "n"]);

			if (answer == YES)
			{
				System.openURL(baseUrl + '/developers/app/${app.slug}/edit');
			}

			Sys.exit(0);
		}

		// Log.println ("Submitting \"" + appName + "\" to the Firefox " + (devServer ? "development" : "production") + " server");

		var packagedFile = compress(project);

		response = marketplace.submitForValidation(packagedFile);

		if (response.error || response.id == null)
		{
			error(response);
		}

		var uploadID = response.id;

		Log.println("");
		// Log.print ('Server validation ($uploadID)');
		Log.print("Waiting for server");

		do
		{
			Log.print(".");
			response = marketplace.checkValidationStatus(uploadID);
			Sys.sleep(1);
		}
		while (!response.processed);

		Log.println("");

		if (response.valid)
		{
			// Log.println (" VALID");
			Log.info("Sending application details...");
			response = marketplace.createApp(uploadID);

			if (response.error || response.id == null)
			{
				// Log.println ("ERROR");
				error(response);
			}

			appID = response.id;
			appSlug = response.slug;

			// Log.println ("OK");
			// Log.print ("Updating application information... ");
			response = marketplace.updateAppInformation(appID, project);

			if (response.error)
			{
				// Log.println ("ERROR");
				error(response);
			}

			// Log.println ("OK");
			// Log.println ("Updating screenshots:");

			var screenshots:Array<String> = project.config.getArrayString("firefox-marketplace.screenshots.screenshot", "path");

			for (i in 0...screenshots.length)
			{
				response = marketplace.uploadScreenshot(appID, i, screenshots[i]);
				Log.println("");

				if (response.error)
				{
					error(response);
				}
			}

			var urlApp = baseUrl + '/app/$appSlug/';
			var devUrlApp = baseUrl + '/developers/app/$appSlug/';
			var urlContentRatings = devUrlApp + "content_ratings/edit";

			var havePayments = project.config.getString("firefox-marketplace.premium-type", "free") != cast PremiumType.FREE;

			Log.println("");
			Log.info("Application submitted!");
			Sys.sleep(1);
			Log.println("");
			Log.info("Before the application is fully published, you will need to fill out a content");
			Log.info("rating questionnaire, and send the application for review");
			Log.println("");
			var answer = CLIHelper.ask("Would you like to complete your submission now?");

			if (answer == YES || answer == ALWAYS)
			{
				if (Log.verbose) Log.println("");
				System.openURL(urlContentRatings);
			}
			else
			{
				Log.println("");
				Log.info("You can complete your submission later by going to " + devUrlApp);
			}

			/*
				Log.println ("");
				Log.warn ("Before this application can be reviewed & published:");
				Log.warn ("* You will need to fill the contents rating questionnaire *");

				if (havePayments) Log.warn ("* You will need to add or link a payment account *");

				Log.println ("");
				Log.println ("1. Open the contents rating questionnaire page.");
				Log.println ("2. Open the application edit page.");
				Log.println ("3. Open the application listing page.");
				Log.println ("q. I'm fine, thanks.");

				answer = CLIHelper.ask ("Open the questionnaire now?", ["1", "2", "3", "q"]);

				switch (answer) {

					case CUSTOM (x):

						switch (x) {

							case "1": System.openURL (urlContentRatings);
							case "2": System.openURL (devUrlApp);
							case "3": System.openURL (urlApp);
							case _:

						}

					default:


				}

				Log.println ("");
				Log.println ("Your application listing page is:");
				Log.println ('$urlApp');
				Log.println ("");
				Log.println ("Goodbye!"); */
		}
		else
		{
			// Log.println (" FAILED");
			Log.println("");

			var errorMsg = "Application failed server validation";

			var errors:List<Dynamic> = Lambda.filter(response.validation.messages, function(m) return m.type == "error");
			var n = 1;

			for (error in errors)
			{
				errorMsg += ('\n * ${error.description.join(" ")}');
			}

			// errorMsg += "\nPlease refer to the documentation to fix the issues.";
			marketplace.close();
			Log.error(errorMsg);
		}

		marketplace.close();
	}

	public static function setup(askServer:Bool = true, devServer:Bool = false, defines:Map<String, String> = null):Void
	{
		if (defines == null)
		{
			defines = PlatformSetup.getDefines();
		}

		var existsProd = defines.exists("FIREFOX_MARKETPLACE_KEY") && defines.exists("FIREFOX_MARKETPLACE_SECRET");
		var existsDev = defines.exists("FIREFOX_MARKETPLACE_DEV_KEY") && defines.exists("FIREFOX_MARKETPLACE_DEV_SECRET");

		// TODO warning about the override of the account

		Log.println("You need to link your developer account to publish to the Firefox Marketplace");
		var answer = CLIHelper.ask("Would you like to open the developer site now?");

		if (answer == YES || answer == ALWAYS)
		{
			var server = "";

			/*if (askServer) {

				Log.println ("");
				Log.println ("First of all you need to select the server you want to setup your account.");
				Log.println ("Each server has its own configuration and can't be shared.");
				Log.println ("\t1. Production server (" + FirefoxHelper.PRODUCTION_SERVER_URL + ")");
				Log.println ("\t2. Development server (" + FirefoxHelper.DEVELOPMENT_SERVER_URL + ")");
				Log.println("\tq. Cancel");
				answer = CLIHelper.ask ("Choose the server to setup your Firefox Marketplace account.", ["1", "2", "q"]);

			} else {*/

			answer = devServer ? CUSTOM("2") : CUSTOM("1");

			// }

			switch (answer)
			{
				case CUSTOM("1"):
					server = FirefoxHelper.PRODUCTION_SERVER_URL;
					devServer = false;

				case CUSTOM("2"):
					server = FirefoxHelper.DEVELOPMENT_SERVER_URL;
					devServer = true;

				default:
					Sys.exit(0);
			}

			/*if ((existsProd && !devServer) || (existsDev && devServer)) {

				Log.info ("");
				Log.warn ("You will override your account settings!");
				answer = CLIHelper.ask ("Are you sure?", ["y", "n"]);

				if (answer == NO) {

					Sys.exit (0);

				}

			}*/

			Log.println("");
			Log.info("Opening \"" + server + "/developers/api\"...");
			Log.println("");
			Log.info(" * Create a new account or login");
			Log.info(" * Choose \"Command line\" as the client type then press \"Create\"");

			Sys.sleep(3);
			if (Log.verbose) Log.println("");
			System.openURL(server + "/developers/api");
			Sys.sleep(2);

			Log.println("");
			Log.info("\x1b[1mPress any key to continue\x1b[0m");

			try
			{
				Sys.stdin().readLine();
			}
			catch (e:Dynamic)
			{
				Sys.exit(0);
			}
		}

		var key = StringTools.trim(CLIHelper.param("OAuth Key"));
		var secret = StringTools.trim(CLIHelper.param("OAuth Secret"));

		Log.println("");

		var marketplace = new MarketplaceAPI(key, secret, devServer);
		var name:String = "";
		var account:Dynamic;
		var valid = false;

		do
		{
			Log.println("Checking account...");
			account = marketplace.getUserAccount();

			if (account != null && account.display_name != null)
			{
				name = account.display_name;
				valid = true;
			}

			if (!valid)
			{
				Log.println("There was a problem connecting to your developer account");
				answer = CLIHelper.ask("Would you like to try again?");

				if (answer == YES)
				{
					Log.println("");
					key = StringTools.trim(CLIHelper.param("OAuth Key"));
					secret = StringTools.trim(CLIHelper.param("OAuth Secret"));
					Log.println("");

					marketplace.client.consumer.key = key;
					marketplace.client.consumer.secret = secret;
				}
				else
				{
					marketplace.close();
					Sys.exit(0);
				}
			}
		}
		while (!valid);

		Log.println("Hello " + name + "!");

		Log.mute = true;
		defines = PlatformSetup.getDefines();
		Log.mute = false;

		defines.set("FIREFOX_MARKETPLACE" + (devServer ? "_DEV_" : "_") + "KEY", key);
		defines.set("FIREFOX_MARKETPLACE" + (devServer ? "_DEV_" : "_") + "SECRET", secret);

		PlatformSetup.writeConfig(defines.get("LIME_CONFIG"), defines);
		Log.println("");
	}
}

class FirefoxHelper
{
	public static inline var PRODUCTION_SERVER_URL = "https://marketplace.firefox.com";
	public static inline var DEVELOPMENT_SERVER_URL = "https://marketplace-dev.allizom.org";
	private static inline var TITLE_MAX_CHARS = 127;
	private static inline var MAX_CATEGORIES = 2;
	private static var MIN_WH_SCREENSHOT = {width: 320, height: 480};

	private static function isScreenshotValid(path:String):Bool
	{
		if (FileSystem.exists(path))
		{
			var img = Image.fromFile(path);
			var portrait = img.width >= MIN_WH_SCREENSHOT.width && img.height >= MIN_WH_SCREENSHOT.height;
			var landscape = img.width >= MIN_WH_SCREENSHOT.height && img.height >= MIN_WH_SCREENSHOT.width;
			return portrait || landscape;
		}

		return false;
	}

	public static function validate(project:HXProject):{errors:Array<String>, warnings:Array<String>}
	{
		var errors:Array<String> = [];
		var warnings:Array<String> = [];

		// We will check if the project has the minimal required fields for publishing to the Firefox Marketplace

		if (project.meta.title == "")
		{
			errors.push("You need to have a title\n\n\t<meta title=\"Hello World\"/>\n");
		}

		if (project.meta.title.length > TITLE_MAX_CHARS)
		{
			errors.push("Your title is too long (max " + TITLE_MAX_CHARS + " characters)\n");
		}

		if (project.config.getString("firefox-marketplace.description", project.meta.description) == "")
		{
			errors.push("You need to have a description\n\n\t<meta description=\"My description\"/>\n");
		}

		if (project.meta.company == "")
		{
			errors.push("You need to have a company name\n\n\t<meta company=\"Company Name\"/>\n");
		}

		if (project.meta.companyUrl == "")
		{
			errors.push("You need to have a company URL\n\n\t<meta company-url=\"http://www.company.com\"/>\n");
		}

		var categories = project.config.getArrayString("firefox-marketplace.categories.category", "name");

		if (categories.length == 0)
		{
			errors.push("You need to have at least one category\n\n\t<config type=\"firefox-marketplace\">\n\t   <categories>\n\t      <category name=\"games\"/>\n\t   </categories>\n\t</config>\n");
		}
		else if (categories.length > MAX_CATEGORIES)
		{
			errors.push("You cannot have more than two categories");
		}

		if (project.config.getString("firefox-marketplace.privacyPolicy") == "")
		{
			errors.push("You need to have a privacy policy\n\n\t<config type=\"firefox-marketplace\">\n\t   <privacyPolicy>Policy detail</privacyPolicy>\n\t</config>\n");
		}

		if (project.config.getString("firefox-marketplace.support.email") == "")
		{
			errors.push("You need to have a support email address\n\n\t<config type=\"firefox-marketplace\">\n\t   <support email=\"support@company.com\"/>\n\t</config>\n");
		}

		var screenshots = project.config.getArrayString("firefox-marketplace.screenshots.screenshot", "path");

		if (screenshots.length == 0)
		{
			errors.push("You need to have at least one screenshot\n\n\t<config type=\"firefox-marketplace\">\n\t   <screenshots>\n\t      <screenshot path=\"screenshot.png\"/>\n\t   </screenshots>\n\t</config>\n");
		}
		else
		{
			for (path in screenshots)
			{
				if (!isScreenshotValid(path))
				{
					if (!FileSystem.exists(path))
					{
						errors.push("Screenshot \"" + Path.withoutDirectory(path) + "\" does not exist\n");
					}
					else
					{
						errors.push("Screenshot \"" + Path.withoutDirectory(path) + "\" must be at least 320 x 480 in size\n");
					}
				}
			}
		}

		return {errors: errors, warnings: warnings};
	}
}

class MarketplaceAPI
{
	private static inline var API_PATH = "/api/v1/";

	public var client:OAuthClient;

	private var loader:URLLoader;
	private var entryPoint:String;

	public function new(key:String = null, secret:String = null, devServer:Bool = false)
	{
		loader = new URLLoader();

		if (key != null && secret != null)
		{
			client = new OAuthClient(OAuthVersion.V1, new OAuthConsumer(key, secret));
		}

		entryPoint = (devServer ? FirefoxHelper.DEVELOPMENT_SERVER_URL : FirefoxHelper.PRODUCTION_SERVER_URL) + API_PATH;
	}

	public function checkValidationStatus(uploadID:String):Dynamic
	{
		var response = load(GET, 'apps/validation/$uploadID/', null);
		return response;
	}

	public function close():Void
	{
		loader.close();
	}

	public function createApp(uploadID:String):Dynamic
	{
		var response = load(POST, 'apps/app/', Json.stringify({upload: uploadID}));
		return response;
	}

	public function customRequest(method:URLRequestMethod, path:String, ?data:Dynamic):URLRequest
	{
		var request:URLRequest;

		if (client == null)
		{
			request = new URLRequest(entryPoint + path);
		}
		else
		{
			request = client.createRequest(method, entryPoint + path);
		}

		request.method = method;
		request.data = data;
		request.contentType = "application/json";

		return request;
	}

	public function getUserAccount():Dynamic
	{
		var response = load(GET, "account/settings/mine/", null);
		return response;
	}

	public function getUserApps():Array<Dynamic>
	{
		var result:Array<Dynamic> = [];
		var response = load(GET, 'apps/app/', null);

		if (!response.error && response.objects != null)
		{
			for (obj in cast(response.objects, Array<Dynamic>))
			{
				result.push(obj);
			}
		}

		return result;
	}

	private function load(method:URLRequestMethod, path:String, data:String = null, progressMsg:String = null):Dynamic
	{
		var response:Dynamic = {};
		var status = 0;
		var request = customRequest(method, path, data);
		var withProgress = progressMsg != null && progressMsg.length > 0 && data != null;

		var uploadingFunc:URLLoader->Int->Int->Void = null;

		if (withProgress)
		{
			uploadingFunc = function(l, up, dl) CLIHelper.progress('$progressMsg', up, data.length);
			loader.onProgress.add(uploadingFunc);
		}

		loader.onHTTPStatus.add(function(_, s) status = s, true);

		loader.onComplete.add(function(l)
		{
			response = Json.parse(l.data);

			if (withProgress) l.onProgress.remove(uploadingFunc);
		}, true);

		loader.load(request);

		response.error = false;

		if (status >= 400)
		{
			response.error = true;
		}

		return response;
	}

	public function submitForValidation(path:String, type:String = "application/zip"):Dynamic
	{
		var p = new Path(path);
		var response:Dynamic = {};

		if (FileSystem.exists(path) && p.ext == "zip")
		{
			var base = Base64.encode(File.getBytes(path));
			var filename = p.file + "." + p.ext;

			var upload =
				{
					upload:
						{
							type: type,
							name: filename,
							data: base
						}
				};

			response = load(POST, "apps/validation/", Json.stringify(upload), "Uploading:");
		}
		else
		{
			response.error = true;
			response.customError = 'File $path doesn\'t exist';
		}

		return response;
	}

	public function updateAppInformation(appID:Int, project:HXProject):Dynamic
	{
		var object =
			{
				name: project.meta.title,
				categories: project.config.getArrayString("firefox-marketplace.categories.category", "name"),
				description: project.config.getString("firefox-marketplace.description", project.meta.description),
				privacy_policy: project.config.getString("firefox-marketplace.privacyPolicy"),
				homepage: project.config.getString("firefox-marketplace.homepage"),
				support_url: project.config.getString("firefox-marketplace.support.url"),
				support_email: project.config.getString("firefox-marketplace.support.email"),
				device_types: project.config.getArrayString("firefox-marketplace.devices.device", "type", ["firefoxos", "desktop"]),
				premium_type: project.config.getString("firefox-marketplace.premium-type", "free"),
				price: project.config.getString("firefox-marketplace.config.price", "0.99"),
			};

		var response = load(PUT, 'apps/app/$appID/', Json.stringify(object));
		return response;
	}

	public function uploadScreenshot(appID:Int, position:Int, path:String):Dynamic
	{
		var response:Dynamic = {};

		if (FileSystem.exists(path))
		{
			var p = new Path(path);
			var type = p.ext == "png" ? "image/png" : "image/jpeg";
			var base = Base64.encode(File.getBytes(path));
			var filename = p.file + "." + p.ext;

			var screenshot =
				{
					position: position,
					file:
						{
							type: type,
							name: filename,
							data: base,
						}
				};

			response = load(POST, 'apps/app/$appID/preview/', Json.stringify(screenshot), 'Uploading screenshot:');
		}
		else
		{
			response.error = true;
			response.customError = 'File "$path" does not exist';
		}

		return response;
	}
}

@:enum abstract DeviceType(String)
{
	var FIREFOXOS = "firefoxos";
	var DESKTOP = "desktop";
	var MOBILE = "mobile";
	var TABLET = "tablet";
}

@:enum abstract PremiumType(String)
{
	var FREE = "free";
	var FREE_INAPP = "free-inapp";
	var PREMIUM = "premium";
	var PREMIUM_INAPP = "premium-inapp";
	var OTHER = "other";
}
