import Danger 

let danger = Danger()

let github = danger.github

// Changelog entries are required for changes to library files.
let allSourceFiles = danger.git.modifiedFiles + danger.git.createdFiles
let changelogChanged = allSourceFiles.contains("CHANGELOG.md")
let sourceChanges = allSourceFiles.first(where: { $0.hasPrefix("Sources") }) != nil
let isTrivial = (danger.github != nil) && danger.github.pullRequest.title.contains("#trivial")
if !isTrivial, !changelogChanged, sourceChanges {
    danger.warn("""
         Any changes to library code should be reflected in the Changelog.
         Please consider adding a note there and adhere to the [Changelog Guidelines](https://github.com/Moya/contributors/blob/master/Changelog%20Guidelines.md).
        """)
}

// Make it more obvious that a PR is a work in progress and shouldn't be merged yet
if danger.github.pullRequest.title.contains("WIP") {
    warn("PR is classed as Work in Progress")
}

// Warn, asking to update Chinese docs if only English docs are updated and vice-versa
let enDocsModified = danger.git.modifiedFiles.first { $0.contains("docs/") } != nil
let cnDocsModified = danger.git.modifiedFiles.first { $0.contains("docs_CN/") } != nil
if (enDocsModified && !cnDocsModified) || (!enDocsModified && cnDocsModified) {
    warn("Consider **also** updating the \(enDocsModified ? "English" : "Chinese") docs. For Chinese translations, request the modified file(s) to be added to the list [here](https://github.com/Moya/Moya/issues/1357) for someone else to translate, if you can't do so yourself.")
}

// Warn, asking to update Chinese README if only English README are updated and vice-versa
let enReameModified = danger.git.modifiedFiles.first { $0.contains("Readme.md") } != nil
let chReameModified = danger.git.modifiedFiles.first { $0.contains("Readme_CN.md") } != nil
if (enReameModified && !chReameModified) || (!enReameModified && chReameModified) {
    warn("Consider **also** updating the \(enReameModified ? "Chinese" : "English") README. For Chinese translations, request the modified file(s) to be added to the list [here](https://github.com/Moya/Moya/issues/1357) for someone else to translate, if you can't do so yourself.")
}

// Warn when there is a big PR
if danger.git.createdFiles.count + danger.git.modifiedFiles.count - danger.git.deletedFiles.count > 500 {
    warn("Big PR, try to keep changes smaller if you can")
}

// Don't let testing shortcuts get into master by accident
if danger.utils.exec("grep -r \"fit Demo/Tests/\"").count > 1 {
    fail("fit left in tests")
}

// Added (or removed) library files need to be added (or removed) from the
// Carthage Xcode project to avoid breaking things for our Carthage users.
let addedSwiftLibraryFiles = danger.git.createdFiles.first { $0.fileType == .swift && $0.hasPrefix("Sources") } != nil
let deletedSwiftLibraryFiles = danger.git.deletedFiles.first { $0.fileType == .swift && $0.hasPrefix("Sources") } != nil
let modifiedCarthageXcodeProject = danger.git.modifiedFiles.first { $0.contains("Moya.xcodeproj") } != nil
if (addedSwiftLibraryFiles || deletedSwiftLibraryFiles) && !modifiedCarthageXcodeProject {
    fail("Added or removed library files require the Carthage Xcode project to be updated. See the Readme")
}

let missingDocChanges = danger.git.modifiedFiles.first { $0.contains("docs") } != nil
let docChangeRaccomanded = (danger.github.pullRequest.additions ?? 0) > 15
if sourceChanges && missingDocChanges && docChangeRaccomanded && !isTrivial {
    warn("Consider adding supporting documentation to this change. Documentation can be found in the `docs` directory.")
}
