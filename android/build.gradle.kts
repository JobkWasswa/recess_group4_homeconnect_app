plugins {
    // your existing plugins
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// ✅ Add this block
tasks.register("kotlinVersion") {
    doLast {
        val kotlinPlugin = buildscript.configurations
            .flatMap { it.dependencies }
            .find { it.group == "org.jetbrains.kotlin" }

        println(">>> Kotlin plugin: $kotlinPlugin")
    }
}
