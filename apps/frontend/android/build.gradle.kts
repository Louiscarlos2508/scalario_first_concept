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
subprojects {
    project.evaluationDependsOn(":app")

    fun applyNamespace(p: Project) {
        val android = p.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null && android.namespace == null) {
            val manifestFile = android.sourceSets.getByName("main").manifest.srcFile
            if (manifestFile.exists()) {
                val manifestContent = manifestFile.readText()
                val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestContent)
                val packageName = packageMatch?.groupValues?.get(1)
                    ?: "com.isar.isar_flutter_libs" // Fallback SPECIFICALLY for isar if match fails
                android.namespace = packageName
            } else {
                // If it's the isar_flutter_libs specifically and we can't find manifest
                if (p.name.contains("isar_flutter_libs")) {
                    android.namespace = "dev.isar.isar_flutter_libs"
                } else {
                    android.namespace = "com.example.${p.name.replace("-", ".")}"
                }
            }
        }
    }

    if (project.state.executed) {
        applyNamespace(project)
    } else {
        project.afterEvaluate {
            applyNamespace(project)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
