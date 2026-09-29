plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Restore the exact user-supplied icon before Android merges resources.
val iconSource = layout.projectDirectory.file("icon/teacher_notebook.webp.base64")
val iconOutput = layout.projectDirectory.file("src/main/res/drawable-nodpi/teacher_notebook.webp")
val generateTeacherNotebookIcon = tasks.register("generateTeacherNotebookIcon") {
    inputs.file(iconSource)
    outputs.file(iconOutput)
    doLast {
        val image = java.util.Base64.getMimeDecoder().decode(iconSource.asFile.readText())
        iconOutput.asFile.parentFile.mkdirs()
        iconOutput.asFile.writeBytes(image)
    }
}
tasks.named("preBuild").configure { dependsOn(generateTeacherNotebookIcon) }

android {
    namespace = "com.example.tuition2027"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.tuition2027"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = "2.6" // User-facing Android version; pubspec uses semantic 2.6.0.
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
