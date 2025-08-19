// Root: android/build.gradle.kts
plugins {
    // Let Flutter provide AGP/Kotlin on the classpath; don't pin versions here.
    id("dev.flutter.flutter-gradle-plugin") apply false

    // Google Services plugin (no need to apply at root)
    id("com.google.gms.google-services") version "4.4.3" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: relocate root build dir outside /android
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// Root clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
