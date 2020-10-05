$tag = "$(git rev-parse --short=8 HEAD)"
$run_dev = $true

Write-Host "Building Conjur Docker image"
& docker build -t conjur .

Write-Host "Tagging conjur:${tag}"
& docker tag conjur "conjur:${tag}"

Write-Host "Building test container"
& docker build -t conjur-test -f Dockerfile.test .

if ($run_dev) {
    Write-Host "Building dev container"
    & docker build -t conjur-dev -f dev/Dockerfile.dev . 
}
