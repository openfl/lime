---
title: Create New Project
---

## Using the "create" Command

Lime includes a new project template you can use to generate a project quickly. Open a command-prompt or terminal, and run the following command, using the name you want for your project (such as "JetGame" or "Platformer") instead of "MyProject":

    lime create project MyProject

This will create a new directory with the same name as the project by default. If you want to use a different output directory, you can add an additional argument:

    lime create project MyProject ~/Projects/MyProject

## Manually

You can also create a project by hand, you will need a project file and an entry class to get started.

There are two different forms of project files, *.xml or *.hxp, so you can decide which type of project file to use.

An XML project file will generally remain compatible with the command-line tools, regardless of the version. However, a Haxe project file can include robust logic, and can call other process as part of the build process... even generate assets dynamically. It is up to you to decide what best matches your taste.

### Project XML

You can call an XML project file "project.lime" or "project.xml", or technically any file name that you prefer, although the command-line tools search for *.lime then *.xml files when running commands that do not specify the project file name.

Here is an example of a project XML file:

    <?xml version="1.0" encoding="utf-8"?>
    <project>

        <meta title="My Project" package="com.mycompany.myproject" version="1.0.0" company="My Company" />
        <app main="Main" path="Export" file="MyProject" />

        <source path="Source" />

        <haxelib name="lime" />

        <assets path="Assets" rename="assets" exclude="lime.svg" />
        <icon path="Assets/lime.svg" />

    </project>

This is just the start, you can read more about the full project XML format here: [Project XML Format](../project-files/xml-format.md).

### Haxe Project

For a Haxe-based project file, use the name of your project file class, with an *.hxp extension, for example, a class called "Project" may have a file called "project.hxp".

Here is a sample Haxe project file:

```java
import lime.project.*;

class Project extends HXProject {

    public function new () {

        super ();

        meta = { title: "My Project", packageName: "com.mycompany.myproject", version: "1.0.0", company: "My Company" };
        app = { main: "Main", path: "Export", file: "MyProject" };

        sources.push ("Source");

        haxelibs.push (new Haxelib ("lime"));

        includeAssets ("Assets", "assets", [ "*" ], [ "lime.svg" ]);

        icons.push (new Icon ("Assets/lime.svg"));

   }

}
```

### Haxe Main Class

You also need a Haxe entry class. This does not need to be very complicated.

"Main" is the default, but you can use any name you want, so long as it is a valid Haxe class. If you specify a different name, you will need to set the `<app main="" />` or `app.main` value in your project file (depending on the type).

You will also want to create it in the source path. For example, if the project includes "Source" as a source path, create "Source\Main.hx" for a class called "Main".

Here is a sample entry class:

```java
package;

import flash.display.Sprite;

class Main extends Sprite {

    public function new () {

        super ();

    }

}
```
