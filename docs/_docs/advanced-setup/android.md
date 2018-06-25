---
title: Setup Android
---

## Automatic Install

Open a command-prompt or terminal and run the following command:

    lime setup android

If you intend to use an Android emulator, create an AVD with hardware acceleration that targets Android 4.1 or greater. If you are using an Android device, you may need to install drivers before it will be recognized by the Android tools.

## Manual Install

Similar to standard Android native development, you will need the following installed:

 * [Android SDK](http://developer.android.com/sdk/index.html)
 * [Android NDK](http://developer.android.com/tools/sdk/ndk/index.html)
 * [Apache Ant](http://ant.apache.org/bindownload.cgi)
 * [Java JDK](http://www.oracle.com/technetwork/java/javasebusiness/downloads/java-archive-downloads-javase6-419409.html#jdk-6u45-oth-JPR)

After installing the Android SDK, you should install the `Android SDK platform-tools` and `Android API 19` packages from the Android SDK Manager. Unfortunately, Gradle requires specific versions of the `Android SDK Build Tools`. We currently are linked against version 24.0.1.

Lime uses API 19 to support modern Android features, but is still compatible with API 9 devices. You only need to install the newer API package.

Using the latest HXCPP, and targeting modern Android platforms properly, requires NDK version r13b. Newer versions have not been tested, but may also work.

The Android build tools did not properly support new versions of Java for a long time, but now Java 8 is recommended to work properly with the current Android Gradle build system. Make sure that you have a JDK version installed.

After these tools are installed, Lime still needs to know where they are installed. Open a command-prompt or terminal and run the following command:

    lime setup android

When prompted to automatically download and install each component, type "n" and press enter. At the end, the setup process will ask for each location. When prompted, enter the path to where the Android SDK, NDK and other components are installed.

If you intend to use an Android emulator, create an AVD with hardware acceleration that targets Android 4.1 or greater. You may also need to install drivers for your Android device, before you can deploy to it. Note that x86 emulators and devices are supported.

## Forums

If you encounter any problems when setting up Lime for Android, please visit the [forums](http://community.openfl.org/c/help).
