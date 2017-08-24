package lime.tools.helpers;


import lime.project.HXProject;
import lime.project.Platform;
import sys.FileSystem;


class AIRHelper {
	
	
	public static function build (project:HXProject, targetPlatform:Platform, workingDirectory:String, targetPath:String, applicationXML:String, files:Array<String>):Void {
		
		var airTarget = "air";
		var extension = ".air";
		
		if (targetPlatform == IOS) {
			
			if (project.targetFlags.exists ("simulator")) {
				
				if (project.debug) {
					
					airTarget = "ipa-debug-interpreter-simulator";
					
				} else {
					
					airTarget = "ipa-test-interpreter-simulator";
					
				}
				
			} else {
				
				if (project.debug) {
					
					airTarget = "ipa-debug";
					
				} else {
					
					airTarget = "ipa-test";
					
				}
				
			}
			
			extension = ".ipa";
			
		} else if (targetPlatform == ANDROID) {
			
			if (project.debug) {
				
				airTarget = "apk-debug";
				
			} else {
				
				airTarget = "apk";
				
			}
			
			extension = ".apk";
			
		}
		
		var signingOptions = [];
		
		if (project.defines.exists ("KEY_STORE")) {
			
			var keystore = project.defines.get ("KEY_STORE");
			var keystoreType = "pkcs12";
			
			if (project.defines.exists ("KEY_STORE_TYPE")) {
				
				keystoreType = project.defines.get ("KEY_STORE_TYPE");
				
			}
			
			signingOptions.push ("-storetype");
			signingOptions.push (keystoreType);
			signingOptions.push ("-keystore");
			signingOptions.push (keystore);
			
			if (project.defines.exists ("KEY_STORE_ALIAS")) {
				
				signingOptions.push ("-alias");
				signingOptions.push (project.defines.get ("KEY_STORE_ALIAS"));
				
			}
			
			if (project.defines.exists ("KEY_STORE_PASSWORD")) {
				
				signingOptions.push ("-storepass");
				signingOptions.push (project.defines.get ("KEY_STORE_PASSWORD"));
				
			}
			
			if (project.defines.exists ("KEY_STORE_ALIAS_PASSWORD")) {
				
				signingOptions.push ("-keypass");
				signingOptions.push (project.defines.get ("KEY_STORE_ALIAS_PASSWORD"));
				
			}
			
		} else {
			
			signingOptions.push ("-storetype");
			signingOptions.push ("pkcs12");
			signingOptions.push ("-keystore");
			signingOptions.push (PathHelper.findTemplate (project.templatePaths, "air/debug.pfx"));
			signingOptions.push ("-storepass");
			signingOptions.push ("samplePassword");
			
		}
		
		var args = [ "-package" ];
		
		if (airTarget == "air") {
			
			args = args.concat (signingOptions);
			args.push ("-target");
			args.push ("air");
			
		} else {
			
			args.push ("-target");
			args.push (airTarget);
			args = args.concat (signingOptions);
			
		}
		
		if (targetPlatform == IOS) {
			
			args.push ("-provisioning-profile");
			args.push (IOSHelper.getProvisioningFile ());
			
		}
		
		args = args.concat ([ targetPath, applicationXML ]);
		
		if (targetPlatform == IOS) {
			
			args.push ("-platformsdk");
			args.push (IOSHelper.getSDKDirectory (project));
			
		}
		
		args = args.concat (files);
		
		ProcessHelper.runCommand (workingDirectory, project.defines.get ("AIR_SDK") + "/bin/adt", args);
		
	}
	
	
	public static function run (project:HXProject, targetPlatform:Platform, workingDirectory:String):Void {
		
		if (targetPlatform == ANDROID) {
			
			AndroidHelper.install (project, FileSystem.fullPath (workingDirectory) + "/" + project.app.file + ".apk");
			AndroidHelper.run ("air." + project.meta.packageName + "/.AppEntry");
			
		} else if (targetPlatform == IOS) {
			
			var args = [ "-platform", "ios" ];
			
			if (project.targetFlags.exists ("simulator")) {
				
				args.push ("-device");
				args.push ("ios-simulator");
				args.push ("-platformsdk");
				args.push (IOSHelper.getSDKDirectory (project));
				
				ProcessHelper.runCommand ("", "killall", [ "iPhone Simulator" ], true, true);
				
			}
			
			ProcessHelper.runCommand (workingDirectory, project.defines.get ("AIR_SDK") + "/bin/adt", [ "-uninstallApp" ].concat (args).concat ([ "-appid", project.meta.packageName ]));
			ProcessHelper.runCommand (workingDirectory, project.defines.get ("AIR_SDK") + "/bin/adt", [ "-installApp" ].concat (args).concat ([ "-package", FileSystem.fullPath (workingDirectory) + "/" + project.app.file + ".ipa" ]));
			
			if (project.targetFlags.exists ("simulator")) {
				
				ProcessHelper.runCommand ("", "open", [ "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app/" ]);
				
			}
			
		} else {
			
			var args = [ "-profile", "desktop" ];
			
			if (!project.debug) {
				
				args.push ("-nodebug");
				
			}
			
			args.push ("application.xml");
			
			ProcessHelper.runCommand (workingDirectory, project.defines.get ("AIR_SDK") + "/bin/adl", args);
			
		}
		
	}
	
	
}