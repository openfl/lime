package lime.tools.helpers;


import lime.project.HXProject;
import lime.project.Platform;
import sys.FileSystem;


class AIRHelper {
	
	
	public static function build (project:HXProject, workingDirectory:String, targetPlatform:Platform, targetPath:String, applicationXML:String, files:Array<String>, fileDirectory:String = null):String {
		
		//var airTarget = "air";
		//var extension = ".air";
		var airTarget = "bundle";
		var extension = "";
		
		switch (targetPlatform) {
			
			case MAC:
				
				// extension = ".app";
			
			case IOS:
				
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
				
				// extension = ".ipa";
			
			case ANDROID:
				
				if (project.debug) {
					
					airTarget = "apk-debug";
					
				} else {
					
					airTarget = "apk";
					
				}
				
				// extension = ".apk";
			
			default:
			
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
		
		// TODO: Is this an old workaround fixed in newer AIR SDK?
		
		if (airTarget == "air" || airTarget == "bundle") {
			
			args = args.concat (signingOptions);
			args.push ("-target");
			args.push (airTarget);
			
		} else {
			
			args.push ("-target");
			args.push (airTarget);
			args = args.concat (signingOptions);
			
		}
		
		if (targetPlatform == IOS) {
			
			var provisioningProfile = IOSHelper.getProvisioningFile (project);
			
			if (provisioningProfile != "") {
				
				args.push ("-provisioning-profile");
				args.push (provisioningProfile);
				
			}
			
		}
		
		args = args.concat ([ targetPath + extension, applicationXML ]);
		
		if (targetPlatform == IOS && PlatformHelper.hostPlatform == Platform.MAC) {
			
			args.push ("-platformsdk");
			args.push (IOSHelper.getSDKDirectory (project));
			
		}
		
		if (fileDirectory != null && fileDirectory != "") {
			
			args.push ("-C");
			args.push (fileDirectory);
			
		}
		
		args = args.concat (files);
		
		if (targetPlatform == ANDROID) {
			
			Sys.putEnv ("AIR_NOANDROIDFLAIR", "true");
			
		}
		
		ProcessHelper.runCommand (workingDirectory, project.defines.get ("AIR_SDK") + "/bin/adt", args);
		
		return targetPath + extension;
		
	}
	
	
	public static function run (project:HXProject, workingDirectory:String, targetPlatform:Platform, applicationXML:String, rootDirectory:String = null):Void {
		
		if (targetPlatform == ANDROID) {
			
			AndroidHelper.initialize (project);
			AndroidHelper.install (project, FileSystem.fullPath (workingDirectory) + "/" + (rootDirectory != null ? rootDirectory + "/" : "") + project.app.file + ".apk");
			AndroidHelper.run (project.meta.packageName + "/.AppEntry");
			
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
			ProcessHelper.runCommand (workingDirectory, project.defines.get ("AIR_SDK") + "/bin/adt", [ "-installApp" ].concat (args).concat ([ "-package", FileSystem.fullPath (workingDirectory) + "/" + (rootDirectory != null ? rootDirectory + "/" : "") + project.app.file + ".ipa" ]));
			
			if (project.targetFlags.exists ("simulator")) {
				
				ProcessHelper.runCommand ("", "open", [ "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Applications/iPhone Simulator.app/" ]);
				
			}
			
		} else {
			
			var args = [ "-profile", "desktop" ];
			
			if (!project.debug) {
				
				args.push ("-nodebug");
				
			}
			
			args.push (applicationXML);
			
			if (rootDirectory != null && rootDirectory != "") {
				
				args.push (rootDirectory);
				
			}
			
			ProcessHelper.runCommand (workingDirectory, project.defines.get ("AIR_SDK") + "/bin/adl", args);
			
		}
		
	}
	
	
	public static function trace (project:HXProject, workingDirectory:String, targetPlatform:Platform, applicationXML:String, rootDirectory:String = null) {
		
		if (targetPlatform == ANDROID) {
			
			AndroidHelper.initialize (project);
			var deviceID = null;
			var adbFilter = null;
			
			// if (!LogHelper.verbose) {
				
				if (project.debug) {
					
					adbFilter = project.meta.packageName + ":I ActivityManager:I *:S";
					
				} else {
					
					adbFilter = project.meta.packageName + ":I *:S";
					
				}
				
			// }
			
			AndroidHelper.trace (project, project.debug, deviceID, adbFilter);
			
		}
		
	}
	
	
	public static function uninstall (project:HXProject, workingDirectory:String, targetPlatform:Platform, applicationXML:String, rootDirectory:String = null) {
		
		if (targetPlatform == ANDROID) {
			
			AndroidHelper.initialize (project);
			var deviceID = null;
			AndroidHelper.uninstall (project.meta.packageName, deviceID);
			
		}
		
	}
	
	
}