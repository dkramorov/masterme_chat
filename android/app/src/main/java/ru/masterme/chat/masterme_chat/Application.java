package ru.masterme.chat.masterme_chat;

import io.flutter.app.FlutterApplication;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService;
import io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin;
//import com.github.cloudwebrtc.flutter_callkeep.FlutterCallkeepPlugin;
import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin;
//import me.carda.awesome_notifications.AwesomeNotificationsPlugin;

public class Application extends FlutterApplication implements PluginRegistrantCallback {

    @Override
    public void onCreate() {
        super.onCreate();
        FlutterFirebaseMessagingService.setPluginRegistrant(this);
    }

    @Override
    public void registerWith(PluginRegistry pluginRegistry) {
        FirebaseMessagingPlugin.registerWith(pluginRegistry.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"));
        //FlutterCallkeepPlugin.registerWith(pluginRegistry.registrarFor("com.github.cloudwebrtc.flutter_callkeep.FlutterCallkeepPlugin"));
        FlutterLocalNotificationsPlugin.registerWith(pluginRegistry.registrarFor("com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin"));
        //AwesomeNotificationsPlugin.registerWith(pluginRegistry.registrarFor("me.carda.awesome_notifications.AwesomeNotificationsPlugin"));
    }
}