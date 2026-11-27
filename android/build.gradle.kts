allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// Some plugins pin an older compileSdk (notification_listener_service asks
// for 34) or NDK (jni, from the Supabase packages, asks for 28.2). Build
// every Android library with the app's SDK (Flutter's default, 36) and NDK
// so only one of each needs installing. Registered before the block below,
// which evaluates :app straight away.
subprojects {
    val useAppCompileSdk: Project.() -> Unit = {
        extensions
            .findByType(com.android.build.gradle.LibraryExtension::class.java)
            ?.apply {
                compileSdk = 36
                ndkVersion = "30.0.16248370"
            }
    }
    if (state.executed) useAppCompileSdk() else afterEvaluate { useAppCompileSdk() }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
