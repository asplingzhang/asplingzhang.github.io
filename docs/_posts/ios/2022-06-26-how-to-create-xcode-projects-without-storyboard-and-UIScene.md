---
layout: default
title: "How to create(config) Xcode projects without storyboard and UIScene"
date: 2022-06-26 13:09:26 +0800
categories: ios
---

# Abstract

As a default behaviour,Xcode creates new iOS projects using Storyboard and UIScene,However,sometimes we don't want to use storyboard and UIScene,We want to use our own customized view controller.

So this article describes how to create Xcode projects without storyboard and UIScene.

# Config Xcode projects without Storyboard

1. Delete `Main.storyboard` to trash
![remove_main_storyboard.jpg](/image/remove_main_storyboard.jpg)
2. Delete storyboard relative settings in build settings
![delete_storyboard_in_buildsettings.jpg](/image/delete_storyboard_in_buildsettings.jpg)
3. Delete storyboard relative settings in general
![delete_storyboard_in_general.jpg](/image/delete_storyboard_in_general.jpg)

Otherwise,runtime errors reported as below:
```shell
** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: 'Could not find a storyboard named 'Main' in bundle NSBundle </private/var/containers/Bundle/Application/1A650085-EBF7-41C7-97BA-5C91F8B215FC/demo.app> (loaded)'
terminating with uncaught exception of type NSException
```

# Config Xcode projects without UIScene
1. Delete UIScene confit at Info.Plist
![delete_scene_config_at_InfoPlist.jpg](/image/delete_scene_config_at_InfoPlist.jpg)

2. Comment implementations of `UISceneSession lifecycle`.

```objc
#pragma mark - UISceneSession lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}
```

# Add customized view controllers
1. Add a property `_window`.
2. Customized our view controller in `- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions `.

```objc
@implementation AppDelegate{
    UIWindow *_window;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    _window =  [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [_window makeKeyAndVisible];
    ViewController *viewController = [[ViewController alloc] init];

    UINavigationController *root =
        [[UINavigationController alloc] initWithRootViewController:viewController];
    root.navigationBar.translucent = NO;
    _window.rootViewController = root;
    return YES;
}
```

# Copyright notice
All Rights Reserved.Any reprint/reproduce/redistribution of this article MUST indicate the source. 
