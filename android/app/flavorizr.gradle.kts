import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.aboptima.stanomer.dev"
            resValue(type = "string", name = "app_name", value = "Stanomer Dev")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.aboptima.stanomer"
            resValue(type = "string", name = "app_name", value = "Stanomer")
        }
    }

    buildFeatures.resValues = true
}