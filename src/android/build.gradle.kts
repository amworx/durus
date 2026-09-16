allprojects {
    repositories {
        // dl.google.com is filtered on this machine -> use Aliyun Google Maven mirror first.
        maven { url = uri("https://maven.aliyun.com/repository/google") }
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
// Plugin subprojects (e.g. flutter_local_notifications) declare their own buildscript
// repositories with google(); ensure the Aliyun mirror is checked FIRST so their
// hardcoded AGP classpath (8.11.1) resolves despite dl.google.com being filtered.
subprojects {
    buildscript {
        repositories {
            maven { url = uri("https://maven.aliyun.com/repository/google") }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
