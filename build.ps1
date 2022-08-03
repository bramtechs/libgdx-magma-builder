$ErrorActionPreference = "Stop"

Write-Host "Preparing to build!"

if (!$args[0]){
    Write-Host "Pass the name of the gradle project to distribute!"
    return
}

if (Test-Path -Path ./javagame){
    Write-Host "Found javagame"
}
else{
    Write-Host "No symlink to javagame found!"
    return
}

if (-not (Test-Path -Path ./exports)){
    New-Item -ItemType Directory ./exports
}

if (Test-Path -Path ./OpenJDK.zip){
    Write-Host "Found OpenJDK!"
}
else{
    Write-Host "No OpenJDK found! Downloading..."
    wget "https://download.java.net/java/GA/jdk17/0d483333a00540d886896bac774ff48b/35/GPL/openjdk-17_windows-x64_bin.zip" -outfile OpenJDK.zip
}

if (Test-Path -Path ./packr.jar){
    Write-Host "Packr already downloaded!"
}
else{
    Write-Host "Packer not found, downloading..."
    wget "https://github.com/libgdx/packr/releases/download/4.0.0/packr-all-4.0.0.jar" -outfile packr.jar
}

# build the game
cd ./javagame/
./gradlew $1:dist
cd ..

# copy the jar
$name = $args[0]
$jar = ".\javagame\$name\build\libs\$name-1.0.jar"
if (Test-Path -Path $jar){
    Copy-Item $jar ./magmagame.jar
}else {
    Write-Host "Could not find the generated jar! Strange..."
    Write-Host $jar
    return
}

if (Test-Path -Path ./packr-config.json){
    Write-Host "Found packer config"
}
else{
    Write-Host "No ./packr-config.json found! Write it now and rerun the command."
    New-Item -ItemType File ./packr-config.json
    return
}

Write-Host "If the build fails, check packr-config!"

# remove empty folders in exports
$builds = Get-ChildItem -Path ./exports/
foreach ($build in $builds){
    if (-not(Test-Path -Path ./exports/$build/*)){
        Write-Host "Removed empty export dir ./exports/$build"
        Remove-Item ./exports/$build
    }
}

$folderName = (Get-Date).tostring("dd-MM-yyyy-hh-mm-ss") 
New-Item -ItemType Directory -Path "./exports/$folderName"

java -jar .\packr.jar --output .\exports\$folderName -- .\packr-config.json
