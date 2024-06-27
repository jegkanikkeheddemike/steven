#!/bin/bash
flutter build apk

cp -f build/app/outputs/apk/release/app-release.apk binaries/
scp ./binaries/app-release.apk fshare@jensogkarsten.site:~/app-binaries/steven.apk